package Langertha::Skeid::UsageStore::JsonLog;
our $VERSION = '0.003';
# ABSTRACT: Append-only JSON usage store — one file per event, or one line per event
use Moo;
use strict;
use warnings;
use POSIX qw(strftime);
use IO::Handle;
use Fcntl qw(O_WRONLY O_CREAT O_EXCL LOCK_EX);
use Errno qw(EEXIST EINTR);
use Digest::SHA qw(sha256_hex);
use Time::HiRes ();
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use JSON::MaybeXS qw(encode_json decode_json);
use Langertha::Skeid::UsageStore;


has path => (is => 'ro', required => 1);
has mode => (is => 'ro', default => sub { 'dir' });


has fsync => (is => 'ro', default => sub { 0 });


sub backend { 'jsonlog' }


sub prepare {
  my ($self) = @_;
  my $path = $self->path;
  if ($self->mode eq 'dir') {
    make_path($path) unless -d $path;
  } else {
    my $dir = dirname($path);
    make_path($dir) if length($dir) && $dir ne '.' && !-d $dir;
  }
  return 1;
}


sub disconnect { return }

our %EVENT_ID_STATE;
my $CREATE_ATTEMPTS = 16;
my $PROCESS_NONCE_BYTES = 16;

sub _new_process_nonce {
  my $random = '';
  if (open my $fh, '<:raw', '/dev/urandom') {
    while (length($random) < $PROCESS_NONCE_BYTES) {
      my $chunk = '';
      my $read = sysread($fh, $chunk, $PROCESS_NONCE_BYTES - length($random));
      if (!defined $read) {
        next if $! == EINTR;
        last;
      }
      last unless $read;
      $random .= $chunk;
    }
    close $fh;
  }
  return unpack('H*', $random) if length($random) == $PROCESS_NONCE_BYTES;

  # /dev/urandom is present on supported service platforms. Keep a portable
  # best-effort fallback for other Perl targets without reseeding the process'
  # global PRNG, which belongs to the application as a whole.
  my $marker = {};
  my @entropy = ($$, Time::HiRes::time(), "$marker", map { rand() } 1 .. 4);
  return substr(sha256_hex(join("\0", @entropy)), 0, $PROCESS_NONCE_BYTES * 2);
}

sub _event_id {
  my $pid = $$;
  if (!defined($EVENT_ID_STATE{pid}) || $EVENT_ID_STATE{pid} != $pid) {
    %EVENT_ID_STATE = (
      pid => $pid,
      nonce => _new_process_nonce(),
      sequence => 0,
    );
  }
  my $sequence = ++$EVENT_ID_STATE{sequence};
  my $ts = strftime('%Y%m%d-%H%M%S', gmtime());
  return sprintf('%s-%d-%s-%010d', $ts, $pid, $EVENT_ID_STATE{nonce}, $sequence);
}

sub _io_error {
  my ($operation, $path, $reason) = @_;
  $reason = 'unknown I/O error' unless defined($reason) && length($reason);
  return "Cannot $operation $path: $reason";
}

sub _write_and_close {
  my ($self, $fh, $path, $json, $operation) = @_;
  my $error;

  unless (print {$fh} $json, "\n") {
    $error = _io_error($operation, $path, "$!");
  }
  if (!$error && $self->fsync) {
    unless ($fh->flush) {
      $error = _io_error('flush', $path, "$!");
    }
    unless ($error || $fh->sync) {
      $error = _io_error('sync', $path, "$!");
    }
  }
  unless (close $fh) {
    $error ||= _io_error('close', $path, "$!");
  }

  return $error;
}


sub store {
  my ($self, $event) = @_;

  if ($self->mode eq 'dir') {
    for (1 .. $CREATE_ATTEMPTS) {
      my $id = _event_id();
      my $json = encode_json({ %$event, id => $id });
      my $file = File::Spec->catfile($self->path, "${id}.json");
      my $fh;
      unless (sysopen $fh, $file, O_WRONLY | O_CREAT | O_EXCL, 0666) {
        next if $! == EEXIST;
        return { ok => 0, error => "Cannot write $file: $!" };
      }
      my $error = _write_and_close($self, $fh, $file, $json, 'write');
      if ($error) {
        unlink $file;
        return { ok => 0, error => $error };
      }
      return { ok => 1, id => $id };
    }
    return {
      ok => 0,
      error => "Cannot store usage event: event id collisions exhausted $CREATE_ATTEMPTS attempts",
    };
  }

  my $id = _event_id();
  my $json = encode_json({ %$event, id => $id });
  my $path = $self->path;
  open my $fh, '>>', $path or return { ok => 0, error => "Cannot append $path: $!" };
  unless (flock($fh, LOCK_EX)) {
    my $error = _io_error('lock', $path, "$!");
    close $fh;
    return { ok => 0, error => $error };
  }
  my $error = _write_and_close($self, $fh, $path, $json, 'append');
  return { ok => 0, error => $error } if $error;

  return { ok => 1, id => $id };
}


sub report {
  my ($self, $filters) = @_;
  $filters ||= {};
  my $num = \&Langertha::Skeid::UsageStore::num;

  my @events;
  if ($self->mode eq 'dir') {
    my @files = sort glob(File::Spec->catfile($self->path, '*.json'));
    for my $file (@files) {
      my $text = eval { Langertha::Skeid::UsageStore::read_text_file($file) };
      next unless defined $text;
      my $ev = eval { decode_json($text) };
      push @events, $ev if ref($ev) eq 'HASH';
    }
  } else {
    if (open my $fh, '<', $self->path) {
      while (my $line = <$fh>) {
        chomp $line;
        next unless length $line;
        my $ev = eval { decode_json($line) };
        push @events, $ev if ref($ev) eq 'HASH';
      }
      close $fh;
    }
  }

  if (defined $filters->{since} && length $filters->{since}) {
    @events = grep { ($_->{created_at} // '') ge $filters->{since} } @events;
  }
  if (defined $filters->{api_key_id} && length $filters->{api_key_id}) {
    @events = grep { ($_->{api_key_id} // '') eq $filters->{api_key_id} } @events;
  }
  if (defined $filters->{model} && length $filters->{model}) {
    @events = grep { ($_->{model} // '') eq $filters->{model} } @events;
  }

  my %totals = (requests => 0, input_tokens => 0, output_tokens => 0, total_tokens => 0, cached_tokens => 0, cache_write_tokens => 0, tool_calls => 0, total_cost_usd => 0);
  my (%by_key, %by_model);
  for my $ev (@events) {
    $totals{requests}++;
    $totals{input_tokens}  += $num->($ev->{input_tokens});
    $totals{output_tokens} += $num->($ev->{output_tokens});
    $totals{total_tokens}  += $num->($ev->{total_tokens});
    # Old events predate the field and read undef; num() treats that as zero (k27).
    $totals{cached_tokens} += $num->($ev->{cached_tokens});
    $totals{cache_write_tokens} += $num->($ev->{cache_write_tokens});
    $totals{tool_calls}    += $num->($ev->{tool_calls});
    $totals{total_cost_usd} += $num->($ev->{cost_total_usd});

    my $kid = $ev->{api_key_id} // '';
    $by_key{$kid}{requests}++;
    $by_key{$kid}{total_tokens}   += $num->($ev->{total_tokens});
    $by_key{$kid}{total_cost_usd} += $num->($ev->{cost_total_usd});

    my $mid = $ev->{model} // '';
    $by_model{$mid}{requests}++;
    $by_model{$mid}{total_tokens}   += $num->($ev->{total_tokens});
    $by_model{$mid}{total_cost_usd} += $num->($ev->{cost_total_usd});
  }

  my $limit = $filters->{limit} // 20;
  my @recent = reverse @events;
  @recent = @recent[0 .. $limit - 1] if @recent > $limit;

  return {
    ok      => 1,
    enabled => 1,
    backend  => 'jsonlog',
    log_path => $self->path,
    since    => ($filters->{since} // ''),
    totals  => \%totals,
    by_key  => [ map {
      +{ api_key_id => $_, requests => $by_key{$_}{requests}, total_tokens => $by_key{$_}{total_tokens}, total_cost_usd => $by_key{$_}{total_cost_usd} }
    } sort { ($by_key{$b}{total_cost_usd} || 0) <=> ($by_key{$a}{total_cost_usd} || 0) } keys %by_key ],
    by_model => [ map {
      +{ model => $_, requests => $by_model{$_}{requests}, total_tokens => $by_model{$_}{total_tokens}, total_cost_usd => $by_model{$_}{total_cost_usd} }
    } sort { ($by_model{$b}{total_cost_usd} || 0) <=> ($by_model{$a}{total_cost_usd} || 0) } keys %by_model ],
    recent  => [ map {
      +{
        id => ($_->{id} // ''), created_at => ($_->{created_at} // ''), api_format => ($_->{api_format} // ''),
        endpoint => ($_->{endpoint} // ''), api_key_id => ($_->{api_key_id} // ''), model => ($_->{model} // ''),
        requested_model => ($_->{requested_model} // $_->{model} // ''),
        node_id => ($_->{node_id} // ''), status_code => $num->($_->{status_code}), ok => ($_->{ok} ? 1 : 0),
        input_tokens => $num->($_->{input_tokens}), output_tokens => $num->($_->{output_tokens}),
        total_tokens => $num->($_->{total_tokens}), cached_tokens => $num->($_->{cached_tokens}),
        cache_write_tokens => $num->($_->{cache_write_tokens}),
        tool_calls => $num->($_->{tool_calls}),
        cost_total_usd => $num->($_->{cost_total_usd}),
      }
    } @recent ],
  };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::UsageStore::JsonLog - Append-only JSON usage store — one file per event, or one line per event

=head1 VERSION

version 0.003

=head1 DESCRIPTION

The recommended usage store. Writing an event is an append, so it cannot block the event loop
on a database round-trip the way the DBI backends can, and an append-only file is the easiest
thing to reconcile after an incident.

Reporting reads and aggregates the whole log in memory. That is fine for the volumes this is
meant for and deliberately not optimised — if a deployment outgrows it, the answer is a real
database, not an index on a directory of JSON files.

=head2 path

Required. Directory (C<mode> C<dir>) or file (C<mode> C<file>) the events are written to.

=head2 mode

C<dir> (the default) writes one C<< <id>.json >> per event, created exclusively, which never needs
a lock and is safe with several writers. C<file> appends one JSON line per event under an
exclusive C<flock>; any value other than C<dir> behaves as C<file>. The event id --
UTC time, process id, a per-process random nonce and a sequence number -- is stored in the event
as C<id>.

=head2 fsync

When true, an event's bytes are flushed and C<fsync>'d to disk before C<store> returns, at a
throughput cost. Default off: ADR 0004 already accepts that one in-flight event is lost on a
crash, and the kernel's own writeback covers the rest under normal operation. Opt in where a
crash losing an already-answered request's event is unacceptable.

=head2 backend

Returns C<jsonlog>.

=head2 prepare

Creates the target directory (or the file's parent directory). Called when the store is
configured, not when an event is written.

=head2 disconnect

No-op — nothing is held open between writes.

=head2 store

  my $res = $store->store($event);

Writes one event and returns C<< { ok => 1, id => $id } >>, or C<< { ok => 0, error => … } >>.
A write failure is reported, never thrown: losing a usage event must not also fail the request
that was already served. The proxy logs such an answer at C<error> level as a lost usage event.

=head2 report

  my $report = $store->report(\%filters);

Reads every event, applies the C<since> / C<api_key_id> / C<model> filters, and aggregates
totals plus per-key and per-model breakdowns. C<recent> holds the newest C<limit> events
(default 20). Unreadable files and lines are skipped. The shape is described in
L<Langertha::Skeid::UsageStore/The store contract>.

=head1 SEE ALSO

L<Langertha::Skeid::UsageStore>, L<Langertha::Skeid::UsageStore::DBI>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-skeid/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
