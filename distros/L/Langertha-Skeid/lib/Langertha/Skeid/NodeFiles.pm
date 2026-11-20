package Langertha::Skeid::NodeFiles;
our $VERSION = '0.005';
# ABSTRACT: Nodes from a second, less trusted file, under the constraints the main config sets
use strict;
use warnings;
use Carp qw(croak);
use Mojo::URL;
use YAML::PP;
use Scalar::Util qw(blessed refaddr);
use Langertha::Skeid::Protocol::Documents;
use Langertha::Skeid::Protocol::Rerank;
# The node vocabulary (trust) is the control plane's; it loads this module too, so no import.
use Langertha::Skeid ();


# The fields a node from a node file may carry. `capacity` is left out: a probe makes Skeid poll
# a URL of the node's choosing, and a custom probe names code.
my %FIELD = map { $_ => 1 } qw(
  id url model engine weight max_conns healthy tags metadata
  api_key_env api_key_ref api_key_header kind rerank_format trust
);


sub normalize_config {
  my ($class, $list) = @_;
  croak 'node_files must be a list' unless ref($list) eq 'ARRAY';
  my (@entries, %seen);
  for my $i (0 .. $#$list) {
    my $raw = $list->[$i];
    my $at  = "node_files[$i]";
    croak "$at must be a mapping" unless ref($raw) eq 'HASH';
    my $path = $raw->{path};
    croak "$at: path required" unless defined($path) && !ref($path) && length($path);
    croak "$at: path $path is listed twice" if $seen{$path}++;

    my $env_re;
    if (defined(my $re = $raw->{allow_api_key_env})) {
      croak "$at: allow_api_key_env must be a regular expression" if ref $re;
      $env_re = eval { qr/$re/ } or croak "$at: allow_api_key_env is not a valid regular expression";
    }

    my $hosts = $raw->{allow_url_hosts};
    croak "$at: allow_url_hosts must list at least one host pattern"
      unless ref($hosts) eq 'ARRAY' && @$hosts;
    my @host_res;
    for my $pattern (@$hosts) {
      croak "$at: allow_url_hosts holds a pattern that is no host name"
        unless defined($pattern) && !ref($pattern) && $pattern =~ /\A[A-Za-z0-9*][A-Za-z0-9*.\-]*\z/;
      my $re = join '\.', map { $_ eq '*' ? '[^.]+' : quotemeta($_) } split /\./, lc $pattern, -1;
      push @host_res, qr/\A$re\z/;
    }

    my $kinds = exists($raw->{allow_kinds}) ? $raw->{allow_kinds} : ['chat'];
    croak "$at: allow_kinds must be a list" unless ref($kinds) eq 'ARRAY';
    my %kinds;
    for my $kind (@$kinds) {
      my $norm = (defined($kind) && lc($kind) eq 'chat') ? ''
        : eval { Langertha::Skeid::Protocol::Documents->normalize_kind($kind) };
      croak "$at: allow_kinds names an unknown kind" unless defined $norm;
      $kinds{$norm} = 1;
    }

    my $trust = eval { Langertha::Skeid->normalize_trust($raw->{trust}) }
      // croak "$at: trust must be internal or external";

    push @entries, {
      path              => "$path",
      trust             => $trust,
      allow_api_key_env => $env_re,
      allow_api_key_ref => ($raw->{allow_api_key_ref} ? 1 : 0),
      allow_url_hosts   => \@host_res,
      allow_kinds       => \%kinds,
    };
  }
  return \@entries;
}


# A node file is a list of a few hundred nodes at most. Its writer is less trusted, so what it
# may cost to read is bounded: the bytes, the nesting, and no YAML alias -- an alias shares a
# structure, and a few hundred bytes of nested aliases expand to more than any walk of it can
# afford (the config digest walks every node on the event loop).
my $MAX_BYTES = 1024 * 1024;
my $MAX_DEPTH = 16;

sub read_file {
  my ($class, $path) = @_;
  my $size = -s $path;
  die "node file $path is larger than $MAX_BYTES bytes\n" if defined($size) && $size > $MAX_BYTES;
  my $data;
  unless (eval { $data = YAML::PP->new->load_file($path); 1 }) {
    my ($line) = ($@ =~ /line:?\s*(\d+)/i);
    die "node file $path is not valid YAML" . (defined $line ? " (line $line)" : '') . "\n";
  }
  return [] unless defined $data;
  my $problem = _shape_problem($data);
  die "node file $path $problem\n" if $problem;
  if (ref($data) eq 'HASH') {
    die "node file $path may hold only nodes\n" if grep { $_ ne 'nodes' } keys %$data;
    $data = $data->{nodes} // [];
  }
  die "node file $path must be a list of nodes\n" unless ref($data) eq 'ARRAY';
  return $data;
}

# Why a loaded structure is not acceptable from a less trusted writer, or undef: a structure
# reached twice (a YAML alias), or nesting deeper than $MAX_DEPTH.
sub _shape_problem {
  my ($data) = @_;
  my %seen;
  my @todo = ([ $data, 0 ]);
  while (my $item = pop @todo) {
    my ($node, $depth) = @$item;
    next unless ref $node;
    next if blessed($node);
    return 'uses a YAML alias or anchor' if $seen{refaddr $node}++;
    return "nests deeper than $MAX_DEPTH levels" if $depth > $MAX_DEPTH;
    my @children = ref($node) eq 'HASH' ? values %$node : ref($node) eq 'ARRAY' ? @$node : ();
    push @todo, map { [ $_, $depth + 1 ] } @children;
  }
  return undef;
}


sub check {
  my ($class, $skeid, $entry, $node) = @_;
  return 'entry' unless ref($node) eq 'HASH';
  return 'field' if grep { !$FIELD{$_} } keys %$node;
  return 'id'    unless defined($node->{id})  && !ref($node->{id})  && length($node->{id});
  return 'url'   unless defined($node->{url}) && !ref($node->{url}) && length($node->{url});

  my $url = Mojo::URL->new($node->{url});
  my $scheme = lc($url->scheme // '');
  my $host   = lc($url->host // '');
  return 'url_host' unless ($scheme eq 'http' || $scheme eq 'https') && length($host)
    && !defined($url->userinfo)
    && grep { $host =~ $_ } @{$entry->{allow_url_hosts}};

  if (defined($node->{api_key_env}) && length($node->{api_key_env})) {
    my $re = $entry->{allow_api_key_env};
    return 'api_key_env' if ref($node->{api_key_env}) || !$re || $node->{api_key_env} !~ /\A(?:$re)\z/;
  }
  return 'api_key_ref'
    if defined($node->{api_key_ref}) && length($node->{api_key_ref}) && !$entry->{allow_api_key_ref};

  # The zone is the main config's to grant (ADR 0032): a node may repeat its entry's trust, and
  # anything else -- a wider zone, a narrower one, a value that is none -- rejects it. An
  # external node without a key of its own is what the main config refuses to load; here it is
  # this node that is left out, not the load that fails.
  my $trust = $entry->{trust} // 'external';
  if (exists $node->{trust}) {
    my $named = eval { $skeid->normalize_trust($node->{trust}) };
    return 'trust' unless defined($named) && $named eq $trust;
  }
  return 'key_required' if $trust eq 'external' && !$skeid->node_has_key_source($node);

  my $kind = eval { Langertha::Skeid::Protocol::Documents->normalize_kind($node->{kind}) };
  return 'invalid' unless defined $kind;
  return 'kind' unless $entry->{allow_kinds}{$kind};

  return 'invalid' unless eval {
    $skeid->normalize_engine_id((defined($node->{engine}) && length($node->{engine})) ? $node->{engine} : 'OpenAIBase');
    $skeid->normalize_tags($node->{tags});
    Langertha::Skeid::Protocol::Rerank->normalize_format($node->{rerank_format});
    Langertha::Skeid::Protocol::Documents->normalize_key_header($node->{api_key_header});
    1;
  };
  return undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::NodeFiles - Nodes from a second, less trusted file, under the constraints the main config sets

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  node_files:
    - path: /etc/skeid/gpm/nodes.yaml
      allow_api_key_env: '^SKEID_NODE_GPM_[A-Z0-9_]+_API_KEY$'
      allow_api_key_ref: false
      allow_url_hosts: [ '*.cai-gpm.svc' ]
      allow_kinds: [ documents, chat ]
      trust: internal                    # default external (ADR 0032)

=head1 DESCRIPTION

A node file is a list of nodes that someone other than the author of the main config writes -- a
GPU manager publishing where its models run. Whoever can write that file must not be able to
make Skeid send an environment variable or a broker secret of its choosing, as a node key, to a
URL of its choosing (ADR 0031). So the main config names each such file together with what a
node from it may say, and this module holds the checks; L<Langertha::Skeid> reads the files and
merges what passes into the C<nodes> section.

A node from a node file is checked field by field. Any failing check rejects that node, and only
that node: the rest of the file still loads. The rule that failed is reported by name with the
node's position in the file, never with the value that broke it.

=head2 normalize_config

  my $entries = Langertha::Skeid::NodeFiles->normalize_config($cfg->{node_files});

The C<node_files> section, checked and filled with its defaults. It belongs to the main config,
so a malformed section fails the load like any other:

=over 4

=item * C<path> -- required, a file path; each path once.

=item * C<allow_api_key_env> -- a regular expression an C<api_key_env> must match whole. Absent:
no node of this file may name a variable.

=item * C<allow_api_key_ref> -- default false: no node of this file may name a broker reference.

=item * C<allow_url_hosts> -- required, at least one host pattern. A node's C<url> must be
C<http> or C<https> to a host one of them matches, case-insensitively. C<*> stands for exactly
one DNS label: C<*.cai-gpm.svc> matches C<gpu-1.cai-gpm.svc>, not C<cai-gpm.svc> and not
C<a.b.cai-gpm.svc>.

=item * C<allow_kinds> -- default C<[chat]>: the node kinds this file may add (C<chat>,
C<documents>).

=item * C<trust> -- default C<external>: the trust zone of every node of this file, C<internal>
or C<external> (ADR 0032). The file's writer cannot change it; see L</check>.

=back

=head2 read_file

  my $nodes = Langertha::Skeid::NodeFiles->read_file($path);   # dies when it cannot

The node list of one node file: a YAML list of nodes, or a mapping whose only key is C<nodes>.
A file that does not parse, says anything but nodes, is larger than 1 MiB, nests deeper than 16
levels or uses a YAML alias dies -- the caller keeps that file's last good list. The message
names the file and the line, never its content.

=head2 check

  my $rule = Langertha::Skeid::NodeFiles->check($skeid, $entry, $node);
  # undef: the node may load; else the name of the rule it broke

Checks one node of a node file against its entry from L</normalize_config>. The rules, in the
order they are checked: C<entry> (not a mapping), C<field> (a field a node file may not set:
C<capacity> or an unknown one), C<id>, C<url> (missing), C<url_host> (not C<http(s)> to an allowed
host, or credentials in the URL), C<api_key_env>, C<api_key_ref>, C<trust> (the node names a
C<trust> other than its entry's), C<key_required> (the entry is external and the node names no
C<api_key_env> or C<api_key_ref>), C<kind>, C<invalid> (a value
the main config would refuse too -- an unknown engine or rerank format, a header that is no
token), so that a broken node of a less trusted file cannot fail the load of the main config.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-skeid/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
