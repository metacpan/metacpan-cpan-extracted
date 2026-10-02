package Devel::ebug::Wire;

use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(blessed reftype refaddr);

# ABSTRACT: Serialization for the Devel::ebug wire protocol
our $VERSION = '0.68'; # VERSION


our $JSON;

# Tried in order; the first that loads wins.  The XS module is much faster,
# and the protocol is chatty enough that it shows.
our @JSON_CLASSES = qw( Cpanel::JSON::XS JSON::PP );

# The two formats cannot be confused: a hex packed YAML line is made up
# entirely of [0-9a-f], and a JSON object always opens with a brace.  That
# lets the backend answer each request in the format it arrived in, which
# in turn means a frontend can choose freely without arranging anything
# with the backend beforehand.
sub detect {
  my($line) = @_;
  return 'yaml' unless defined $line;
  $line =~ s/^\s+//;
  return substr($line, 0, 1) eq '{' ? 'json' : 'yaml';
}

sub _json {
  return $JSON if $JSON;
  my $class;
  foreach my $try (@JSON_CLASSES) {
    (my $pm = "$try.pm") =~ s{::}{/}g;
    if (eval { require $pm; 1 }) {
      $class = $try;
      last;
    }
  }
  croak "the json serializer needs one of @{[ join ' or ', @JSON_CLASSES ]}, none of which could be loaded"
    unless $class;
  # canonical keeps the output stable, which makes the protocol diffable
  # and the tests repeatable; allow_nonref so a bare scalar is legal.
  $JSON = $class->new->utf8->canonical->allow_nonref;
  return $JSON;
}

# Walk a structure into something JSON can hold, tagging what it cannot.
sub _deflate {
  my($data, $seen) = @_;

  my $type = reftype $data;
  return $data unless defined $type;

  # Cycles have no JSON representation.  YAML would emit an anchor; here the
  # best that can be done is to break the loop visibly rather than recurse
  # until the stack gives out.
  $seen ||= {};
  my $addr = refaddr $data;
  return '*CYCLE*' if $seen->{$addr};
  local $seen->{$addr} = 1;

  my $class = blessed $data;
  my $out;

  if ($type eq 'HASH') {
    $out = { map { $_ => _deflate($data->{$_}, $seen) } keys %$data };
  } elsif ($type eq 'ARRAY') {
    $out = [ map { _deflate($_, $seen) } @$data ];
  } elsif ($type eq 'SCALAR' || $type eq 'REF') {
    $out = { __scalarref__ => _deflate($$data, $seen) };
  } else {
    # CODE, GLOB, IO and anything else: a name is better than a failure.
    return "$data";
  }

  return $class ? { __bless__ => $class, __value__ => $out } : $out;
}

# The reverse: put the classes back on.
sub _inflate {
  my($data) = @_;

  my $ref = ref $data;
  return $data unless $ref;

  # Current JSON::PP and Cpanel::JSON::XS both decode true and false into
  # JSON::PP::Boolean; accept Cpanel's own boolean class too, to be safe.
  if (blessed $data && ($data->isa('JSON::PP::Boolean') || $data->isa('Cpanel::JSON::XS::Boolean'))) {
    return $data ? 1 : 0;
  }

  if ($ref eq 'ARRAY') {
    return [ map { _inflate($_) } @$data ];
  }

  if ($ref eq 'HASH') {
    if (exists $data->{__bless__} && exists $data->{__value__}) {
      return bless _inflate($data->{__value__}), $data->{__bless__};
    }
    if (keys %$data == 1 && exists $data->{__scalarref__}) {
      my $value = _inflate($data->{__scalarref__});
      return \$value;
    }
    return { map { $_ => _inflate($data->{$_}) } keys %$data };
  }

  return $data;
}


sub encode {
  my($format, $data) = @_;

  if ($format eq 'json') {
    # No pretty printing, so the result never contains a raw newline and
    # stays one line on the wire.
    return _json()->encode(_deflate($data));
  }

  require YAML;
  return unpack('h*', YAML::Dump($data));
}

sub decode {
  my($format, $line) = @_;
  return undef unless defined $line;

  if ($format eq 'json') {
    return _inflate(_json()->decode($line));
  }

  require YAML;
  local $YAML::LoadBlessed = 1;
  return YAML::Load(pack('h*', $line));
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::ebug::Wire - Serialization for the Devel::ebug wire protocol

=head1 VERSION

version 0.68

=head1 SYNOPSIS

 use Devel::ebug::Wire;

 my $line = Devel::ebug::Wire::encode('json', { command => 'step' });
 my $req  = Devel::ebug::Wire::decode(Devel::ebug::Wire::detect($line), $line);

=head1 DESCRIPTION

The frontend and the backend exchange Perl data structures as single
newline terminated lines over a socket.  This module is the one place that
knows how those lines are written and read.

Two formats are understood:

=over 4

=item C<yaml>

The original format: L<YAML> C<Dump> output, hex packed so that it occupies
a single line.  This is the default, and what every existing client speaks.

=item C<json>

Plain JSON, one object per line.  Chosen with the C<serializer> attribute of
L<Devel::ebug>, or by setting C<DEVEL_EBUG_SERIALIZER> in the environment.

JSON is the format to pick when the other end of the socket is not Perl.
Hex packed YAML asks a client to implement YAML, object deserialization and
a hex decoder before it can say hello; a JSON line can be read by anything.

=back

The JSON encoder is only loaded when JSON is actually used, so it is not
needed to run the debugger, and neither is L<YAML> when JSON is in use.
L<Cpanel::JSON::XS> is used if it is installed, otherwise L<JSON::PP>.

=head2 Blessed references

YAML carries blessed references itself, and the protocol relies on it:
C<stack_trace> returns L<Devel::StackTrace::Frame> objects that the frontend
calls methods on.  JSON has no equivalent, so a blessed reference is written
as

 { "__bless__": "Some::Class", "__value__": { ... } }

and blessed back into its class on the way out.  Scalar references get the
same treatment through C<__scalarref__>.

References JSON cannot represent at all - code, globs, regular expressions,
filehandles - are replaced by their stringified form.  These only ever turn
up in values sampled from the program being debugged, such as the arguments
in a stack frame, where a readable placeholder is the best that can be done
and is what the reader wanted anyway.

=head1 FUNCTIONS

=head2 detect

 my $format = Devel::ebug::Wire::detect($line);

Works out which format a line arrived in.

=head2 encode

 my $line = Devel::ebug::Wire::encode($format, $data);

Serializes a data structure to a single line, without the terminating
newline.

=head2 decode

 my $data = Devel::ebug::Wire::decode($format, $line);

The inverse of C<encode>.

=head1 SEE ALSO

L<Devel::ebug>

=head1 AUTHOR

Original author: Leon Brocard E<lt>acme@astray.comE<gt>

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Brock Wilcox E<lt>awwaiid@thelackthereof.orgE<gt>

Taisuke Yamada

Richard Leach (HYDAHY)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005-2026 by Leon Brocard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
