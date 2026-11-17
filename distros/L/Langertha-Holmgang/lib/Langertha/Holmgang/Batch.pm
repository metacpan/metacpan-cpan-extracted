package Langertha::Holmgang::Batch;
# ABSTRACT: Suites against targets and their variants, repeated, with bounded concurrent requests per target, resumable

use Moose;
use namespace::autoclean;
use Carp qw( croak );
use Future;
use Future::AsyncAwait;
use Future::Utils qw( fmap_void );
use JSON::MaybeXS ();
use Scalar::Util qw( blessed );
use Langertha::Holmgang::Report;
use Langertha::Holmgang::Runner;
use Langertha::Holmgang::Target;

our $VERSION = '0.001';


has suites => ( is => 'ro', required => 1 );


has targets => ( is => 'ro', required => 1 );


has repeat => ( is => 'ro' );


has resume => ( is => 'ro' );


has on_event => ( is => 'ro' );


sub runner_class { 'Langertha::Holmgang::Runner' }
sub target_class { 'Langertha::Holmgang::Target' }
sub report_class { 'Langertha::Holmgang::Report' }

sub error_max_length { 2000 }


my $JSON = JSON::MaybeXS->new( utf8 => 0, canonical => 1 );

#### Building

sub BUILD {
  my ( $self ) = @_;
  my $suites = $self->suites;
  croak __PACKAGE__.'->new: suites must be a non-empty array of suites'
    unless ref $suites eq 'ARRAY' && @$suites && !grep { !( blessed $_ && $_->can('cases') ) } @$suites;
  my $targets = $self->targets;
  croak __PACKAGE__.'->new: targets must be a non-empty array' unless ref $targets eq 'ARRAY' && @$targets;
  croak __PACKAGE__.'->new: repeat must be a whole number from 1 to 100'
    if defined $self->repeat && !( $self->repeat =~ /\A[0-9]+\z/ && $self->repeat >= 1 && $self->repeat <= 100 );
  croak __PACKAGE__.'->new: on_event must be a code reference' if defined $self->on_event && ref $self->on_event ne 'CODE';
  my ($first) = map { @{ $_->cases } } @$suites;
  my @runs;
  for my $ti ( 0 .. $#$targets ) {
    my $t = $targets->[$ti];
    my $where = __PACKAGE__.'->new: targets['.$ti.']';
    croak $where.' must be a hash' unless ref $t eq 'HASH';
    croak $where.'.engine must be a code reference or an engine with chat_f'
      unless ref $t->{engine} eq 'CODE' || ( blessed $t->{engine} && $t->{engine}->can('chat_f') );
    my $conc = $t->{concurrency} // 1;
    croak $where.'.concurrency must be a whole number from 1' unless $conc =~ /\A[0-9]+\z/ && $conc >= 1;
    my $variants = $t->{variants} // [ { name => 'default', settings => {} } ];
    croak $where.'.variants must be a non-empty array' unless ref $variants eq 'ARRAY' && @$variants;
    my %seen;
    my @variants;
    for my $vi ( 0 .. $#$variants ) {
      my $v = $variants->[$vi];
      croak $where.'.variants['.$vi.'] needs a name' unless ref $v eq 'HASH' && defined $v->{name} && length $v->{name};
      croak $where.': variant '.$v->{name}.' named twice' if $seen{ $v->{name} }++;
      # the settings checked once without and once against the engine (the first case, slot 0)
      my $settings = $self->target_class->check_variant( $v->{settings} // {} );
      $self->target_class->check_variant( $settings, $self->_engine( $t, $first, 0 ) );
      push @variants, { name => ''.$v->{name}, settings => $settings };
    }
    $self->{_target}[$ti] = { %$t, concurrency => 0 + $conc, variants => \@variants };
    for my $v ( @variants ) {
      for my $suite ( @$suites ) {
        push @runs, {
          ti      => $ti,
          variant => $v,
          suite   => $suite,
          repeat  => 0 + ( $self->repeat // $suite->repeat // 1 ),
          results => {},
        };
      }
    }
  }
  $self->{_runs} = \@runs;
  $self->_take_over( $self->resume ) if defined $self->resume;
  return;
}

sub _engine {
  my ( $self, $t, $case, $slot ) = @_;
  return $t->{engine} unless ref $t->{engine} eq 'CODE';
  my $engine = $t->{engine}->( $case, $slot );
  croak __PACKAGE__.': the engine code of target '.( $t->{target}{label} // '?' ).' returned no engine with chat_f'
    unless blessed $engine && $engine->can('chat_f');
  return $engine;
}

# the identity of a run in a report: target, variant and suite id, as the
# report shapes them (so a url loses its credentials on both sides alike)
sub _key {
  my ( $self, $target, $variant, $suite_id ) = @_;
  return $JSON->encode( [ $target, $variant, $suite_id ] );
}

sub _shaped {
  my ( $self, $run ) = @_;
  my $scratch = $self->report_class->new;
  my $shaped = $scratch->add_run(
    target  => $self->{_target}[ $run->{ti} ]{target} // {},
    variant => $run->{variant},
    suite   => { id => $run->{suite}->id },
    repeat  => $run->{repeat},
    status  => 'complete',
    cases   => [],
  );
  return $self->_key( $shaped->{target}, $shaped->{variant}, $run->{suite}->id );
}

sub _take_over {
  my ( $self, $old ) = @_;
  croak __PACKAGE__.'->new: resume must be a '.$self->report_class
    unless blessed $old && $old->isa( $self->report_class );
  my %run = map { ( $self->_shaped($_) => $_ ) } @{ $self->{_runs} };
  for my $o ( @{ $old->runs } ) {
    my $sid = $o->{suite}{id};
    my $name = 'run of suite '.$sid.', target '.( $o->{target}{label} // '?' ).', variant '.( $o->{variant}{name} // '?' );
    my $run = $run{ $self->_key( $o->{target}, $o->{variant}, $sid ) }
      or croak __PACKAGE__.'->new: resume: the earlier report has a '.$name.' that this batch does not cover';
    my $digest = $run->{suite}->digest;
    croak __PACKAGE__.'->new: resume: suite '.$sid.' has changed since the earlier report (digest)'
      unless defined $o->{suite}{digest} && defined $digest && $o->{suite}{digest} eq $digest;
    croak __PACKAGE__.'->new: resume: the earlier '.$name.' has repeat '.$o->{repeat}.', this batch '.$run->{repeat}
      unless $o->{repeat} == $run->{repeat};
    croak __PACKAGE__.'->new: resume: the earlier report holds the '.$name.' twice' if $run->{resumed}++;
    my %case = map { $_->id => 1 } @{ $run->{suite}->cases };
    for my $c ( @{ $o->{cases} } ) {
      croak __PACKAGE__.'->new: resume: case '.$c->{case_id}.' of the earlier '.$name.' is not in the suite'
        unless $case{ $c->{case_id} };
      for my $r ( @{ $c->{repetitions} } ) {
        $run->{results}{ $c->{case_id} }{ $r->{repetition} } = { %$r, case_id => $c->{case_id} };
      }
    }
  }
  $self->{_started_at} = $old->started_at;
  return;
}

#### Running

sub cancel { my ( $self ) = @_; $self->{_cancelled} = 1; return }


sub cancelled { $_[0]->{_cancelled} ? 1 : 0 }


sub run_f {
  my ( $self ) = @_;
  croak __PACKAGE__.'->run_f: a batch runs once' if $self->{_run_f};
  my @per_target = map { $self->_target_f($_) } 0 .. $#{ $self->{_target} };
  return $self->{_run_f} = Future->needs_all(@per_target)->then( sub {
    $self->_finish;
    return Future->done( $self->report );
  } );
}


sub run {
  my ( $self ) = @_;
  my $f = $self->run_f;
  unless ( $f->is_ready ) {
    # requests on an event loop (Net::Async::HTTP): run the loop until done;
    # IO::Async is optional, as it is for Langertha
    my $loop = eval { require IO::Async::Loop; IO::Async::Loop->new }
      or croak __PACKAGE__.'->run: the batch waits on requests and IO::Async is not available';
    $loop->await($f);
  }
  return $f->get;
}


sub _target_f {
  my ( $self, $ti ) = @_;
  my @jobs;
  for my $run ( grep { $_->{ti} == $ti } @{ $self->{_runs} } ) {
    for my $n ( 1 .. $run->{repeat} ) {
      for my $case ( @{ $run->{suite}->cases } ) {
        push @jobs, { run => $run, case => $case, n => $n } unless $run->{results}{ $case->id }{$n};
      }
    }
  }
  my @free = ( 0 .. $self->{_target}[$ti]{concurrency} - 1 );
  return Future->done unless @jobs;
  return fmap_void {
    my ( $job ) = @_;
    my $slot = shift @free;
    $self->_job_f( $job, $slot )->followed_by( sub { unshift @free, $slot; Future->done } );
  } foreach => \@jobs, concurrent => $self->{_target}[$ti]{concurrency};
}

# one case: never fails; a throw aborts its run
sub _job_f {
  my ( $self, $job, $slot ) = @_;
  my $run = $job->{run};
  return Future->done if $self->{_cancelled} || $run->{aborted};
  my $f = eval { $self->_case_f( $job, $slot ) };
  $f = Future->fail( $@ || 'the case returned no Future' ) unless blessed $f && $f->isa('Future');
  return $f->then(
    sub {
      my ( $result ) = @_;
      return Future->done unless $result;   # the run was aborted while it waited
      my $ok = eval { $self->_record( $job, $result ); 1 };
      $self->_abort( $job, $@ ) unless $ok;
      return Future->done;
    },
    sub {
      my ( $err ) = @_;
      $self->_abort( $job, $err );
      return Future->done;
    },
  );
}

async sub _case_f {
  my ( $self, $job, $slot ) = @_;
  my $run = $job->{run};
  my $no_vision = await $self->_vision_f( $run, $slot );
  return if $run->{aborted};
  my $t = $self->{_target}[ $run->{ti} ];
  my $target = $job->{target} = $self->target_class->for_variant(
    engine   => $self->_engine( $t, $job->{case}, $slot ),
    settings => $run->{variant}{settings},
  );
  my $runner = $self->runner_class->new( target => $target );
  return await $runner->run_case_f( $job->{case}, repetition => $job->{n}, no_vision => $no_vision );
}

# the vision pre-check of a run, once, before its cases (k27): a Future of
# the no_vision reason or undef; a run without images asks nothing
sub _vision_f {
  my ( $self, $run, $slot ) = @_;
  return $run->{vision_f} //= do {
    my ( $seeing ) = grep { $_->has_images } @{ $run->{suite}->cases };
    if ( $seeing ) {
      my $f = eval {
        my $target = $run->{vision_target} = $self->target_class->for_variant(
          engine   => $self->_engine( $self->{_target}[ $run->{ti} ], $seeing, $slot ),
          settings => $run->{variant}{settings},
        );
        $target->vision_check_f;
      };
      $f = Future->fail( $@ || 'the vision check returned no Future' ) unless blessed $f && $f->isa('Future');
      $f->then(
        sub {
          my ( $check ) = @_;
          $self->_event( $run, type => 'vision', check => $check );
          return Future->done( $check->{no_vision} );
        },
        sub {
          my ( $err ) = @_;
          $self->_abort( { run => $run }, $err );
          return Future->done(undef);
        },
      );
    }
    else {
      Future->done(undef);
    }
  };
}

sub _cut {
  my ( $self, $text ) = @_;
  return $text unless defined $text && length $text > $self->error_max_length;
  return substr( $text, 0, $self->error_max_length );
}

sub _record {
  my ( $self, $job, $result ) = @_;
  my $run = $job->{run};
  my %keep = %$result;
  $keep{error} = $self->_cut( $keep{error} );
  # what a report never holds stays out of the batch's memory: the end state,
  # the last text, the transcript
  delete @keep{qw( state answer transcript )};
  $run->{results}{ $job->{case}->id }{ $job->{n} } = \%keep;
  $self->_event( $run, type => 'result', case => $job->{case}, repetition => $job->{n}, result => $result );
  return;
}

# a throw aborts the run, once; the text through the target's scrub (with the
# engine's key where a target was built), cut (ADR 0006 amendment k38)
sub _abort {
  my ( $self, $job, $err ) = @_;
  my $run = $job->{run};
  return if $run->{aborted}++;
  my $text = defined $err ? "$err" : '';
  $text = 'unknown error' unless length $text;
  my $scrubber = $job->{target} // $run->{vision_target} // $self->target_class;
  $text = $scrubber->scrub($text) =~ s/\s+\z//r;
  $run->{error} = $self->_cut($text);
  eval {
    $self->_event( $run, type => 'aborted', error => $run->{error},
      ( $job->{case} ? ( case => $job->{case}, repetition => $job->{n} ) : () ) );
    1;
  };
  return;
}

sub _event {
  my ( $self, $run, %e ) = @_;
  my $cb = $self->on_event or return;
  $cb->( { %e,
    target  => $self->{_target}[ $run->{ti} ]{target},
    variant => $run->{variant}{name},
    suite   => $run->{suite},
  } );
  return;
}

sub _missing {
  my ( $self, $run ) = @_;
  my $n = 0;
  for my $case ( @{ $run->{suite}->cases } ) {
    $n += grep { !$run->{results}{ $case->id }{$_} } 1 .. $run->{repeat};
  }
  return $n;
}

sub _finish {
  my ( $self ) = @_;
  for my $run ( @{ $self->{_runs} } ) {
    $run->{status} = $run->{aborted}       ? 'aborted'
                   : $self->_missing($run) ? 'cancelled'
                   :                         'complete';
  }
  $self->{_finished} = 1;
  return;
}

#### The report

sub report {
  my ( $self ) = @_;
  my $report = $self->report_class->new( defined $self->{_started_at} ? ( started_at => $self->{_started_at} ) : () );
  for my $run ( @{ $self->{_runs} } ) {
    my $suite = $run->{suite};
    my $status = $run->{status} // ( $run->{aborted} ? 'aborted' : undef );
    $report->add_run(
      target  => $self->{_target}[ $run->{ti} ]{target} // {},
      variant => $run->{variant},
      suite   => { id => $suite->id, version => $suite->version, topic => $suite->topic, digest => $suite->digest },
      repeat  => $run->{repeat},
      status  => $status // 'aborted',
      error   => defined $status ? $run->{error} : 'unfinished: the batch was still running when this report was written',
      cases   => [ map { $_->report_meta } @{ $suite->cases } ],
      results => [ map {
        my $c = $_;
        map { $run->{results}{ $c->id }{$_} // () } 1 .. $run->{repeat};
      } @{ $suite->cases } ],
    );
  }
  $report->finish if $self->{_finished};
  return $report;
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Batch - Suites against targets and their variants, repeated, with bounded concurrent requests per target, resumable

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Langertha::Holmgang::Batch;

  my $batch = Langertha::Holmgang::Batch->new(
    suites  => [ $loader->load($dir_a), $loader->load($dir_b) ],
    targets => [ {
      target      => { label => 'local-a', engine => 'vLLM', model => 'm-1', url => 'http://10.0.0.5:8000/v1' },
      engine      => sub { my ( $case, $slot ) = @_; $engines[$slot] //= build_engine() },
      variants    => [
        { name => 'think-off', settings => { enable_thinking => 'off' } },
        { name => 'think-on',  settings => { enable_thinking => 'on', max_tokens => 16000, deadline => 1800 } },
      ],
      concurrency => 4,                          # at most 4 requests at once to this target
    } ],
    repeat   => 3,                               # else each suite's own repeat, else 1
    resume   => Langertha::Holmgang::Report->read('out.json'),   # optional
    on_event => sub { my ( $event ) = @_; print "$event->{type}\n" },
  );

  my $report = $batch->run;                      # or: await $batch->run_f
  $batch->cancel;                                # from a signal handler: no new case starts

=head1 DESCRIPTION

The run over suites (cai-platform C<Eval::Batch::run> and
C<Eval::Runner::run>): for every target, every variant of it and every
suite, one I<run> (ADR 0006) with its C<repeat> repetitions of every case,
each case played by L<Langertha::Holmgang::Runner>. The result is a
L<Langertha::Holmgang::Report> with one run per target, variant and suite, in
that order.

B<Concurrency.> Each target has its own bound (C<concurrency>, default 1):
at most that many cases of that target are in play at once, so at most that
many requests are open against it. Different targets run side by side. A case
in play holds a I<slot> (C<0 .. concurrency-1>) and gets its engine from the
target's C<engine> code with that slot, so a caller can give every slot its
own engine (and with it its own connection). Within a target the cases start
in this order: variant, suite, repetition, case. With C<concurrency> 1 that
is one request at a time, as cai-platform's batch ran.

B<Variants.> A variant is a name and its settings, named and checked by
L<Langertha::Holmgang::Target/check_variant> (C<enable_thinking>,
C<reasoning_effort>, C<max_tokens>, C<temperature>, C<deadline>), against the
engine when the batch is built. The report carries the name and the
normalised settings.

B<Vision.> Before the cases of a run whose suite has images, the target's
L<Langertha::Holmgang::Target/vision_check_f> runs once (with the run's
variant); its C<no_vision> goes to every case of the run.

B<Resume.> With C<resume>, an earlier report of the same batch: every
repetition it holds a result for (whatever the status) is taken over and not
played again; only the missing ones run. A run of the earlier report must
match one of the batch (target, variant, suite) with the same suite digest
and the same C<repeat>; a run the batch does not cover is refused, so
resuming never drops results.

B<Errors.> A target that fails a turn is a status of the case (C<error>,
C<context_exceeded>, C<no_vision>), not a batch error. A case that throws (a
program error) aborts its run: no further case of that run starts, the run is
C<aborted>, its C<error> the text through
L<Langertha::Holmgang::Target/scrub> (with the engine's key) and cut to
L</error_max_length> characters; the other runs go on. Each repetition's
C<error> is cut to the same length.

B<Cancel.> L</cancel> starts no further case; cases in play finish. A run
that then misses results is C<cancelled>.

=head2 suites

Required. The L<Langertha::Holmgang::Suite>s, loaded (and so linted), in the
order of the report.

=head2 targets

Required. One HashRef per target:

=over

=item * C<engine> -- required: a code reference C<< ( $case, $slot ) >> that
returns the engine to play the case on, or one engine for every case.

=item * C<target> -- the report's target, C<< { label, engine, model, url } >>
(ADR 0006); never a key.

=item * C<variants> -- C<< [ { name, settings }, ... ] >>; default one
variant C<default> without settings. Names are unique per target.

=item * C<concurrency> -- the bound, a whole number from 1; default 1.

=back

=head2 repeat

Optional. Repetitions for every suite (1 to 100); without it each suite's own
C<repeat>, else 1.

=head2 resume

Optional. An earlier L<Langertha::Holmgang::Report> of the same batch (see
L</DESCRIPTION>).

=head2 on_event

Optional. A code reference called with a HashRef as things happen, in the
order they happen. Every event carries C<type>, C<target> (the report's
target), C<variant> (its name) and C<suite> (the suite object):

=over

=item * C<result> -- a case played: C<case>, C<repetition>, C<result> (the
runner's result, L<Langertha::Holmgang::Runner/run_case_f>);

=item * C<vision> -- the vision pre-check of a run: C<check> (the HashRef of
L<Langertha::Holmgang::Target/vision_check_f>);

=item * C<aborted> -- a run aborted: C<error> (scrubbed), and C<case> and
C<repetition> when a case threw, none when the vision check did.

=back

An C<on_event> that dies aborts the run the event belongs to.

=head2 error_max_length

  Langertha::Holmgang::Batch->error_max_length;   # 2000

How many characters of an error a run and a repetition keep (cai-platform
cuts at the same length when it stores them).

=head2 cancel

  $batch->cancel;

No further case starts; the cases in play finish. Safe to call from a signal
handler and from L</on_event>.

=head2 cancelled

True once L</cancel> was called.

=head2 run_f

  my $report = await $batch->run_f;

Runs the batch; a L<Future> of the final L</report>. Runs once.

=head2 run

  my $report = $batch->run;

L</run_f>, waited for; runs the L<IO::Async::Loop> while requests are open.

=head2 report

  my $report = $batch->report;

The L<Langertha::Holmgang::Report> of the batch as it stands: one run per
target, variant and suite, the results taken over from L</resume> and those
played so far. Callable at any time, so a caller can write a checkpoint after
each result: a run still in play is C<aborted> there with the error
C<unfinished: ...>, which a later L</resume> continues. After L</run> it is
the final report, with C<finished_at>; with L</resume> its C<started_at> is
the earlier report's.

=head1 SEE ALSO

=over 4

=item * L<Langertha::Holmgang::Runner>

=item * L<Langertha::Holmgang::Target>

=item * L<Langertha::Holmgang::Report>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-holmgang/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
