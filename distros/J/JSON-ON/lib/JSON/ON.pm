package JSON::ON;
$VERSION = v0.0.3;

use warnings;
use strict;
use Carp;

=head1 NAME

JSON::ON - javascript object notation object notator

=head1 SYNOPSIS

This module serializes and deserializes blessed references with JSON.

  use JSON::ON;

  my $stuff = {whatever => What::Ever->new};
  my $j = JSON::ON->new;
  my $enc = $j->encode($stuff);

  # elsewhere...
  my $j = JSON::ON->new;
  my $dec = $j->decode($enc);
  $dec->{whatever}->amethod;

=head2 Making Sausage

The encode() method installs a local UNIVERSAL::TO_JSON() which simply
un-blesses HASH, ARRAY, and SCALAR references.  Similarly, the decoding
has a hook which simply blesses them back into their class.  This leaves
edge cases for inside-out objects and code references, but ...

=head2 Implementation

A special token is embedded in the JSON whenever an object appears (it is ugly, but highly unlikely to appear in a regular JSON document.)

This is intended more as an opaque transport mechanism than as
human-readable JSON.

=cut

use Class::Accessor::Classy;
with 'new';
ro 'j';
ro 'module_handler';
no  Class::Accessor::Classy;

use Scalar::Util qw(reftype);

use constant JSON_CLASS =>
  eval {require JSON::XS; 'JSON::XS'} ||
  do   {require JSON; 'JSON'};

use constant _json_marker =>
  "i = sqrt(-1); " . "\b"x14 .
  "# object =>;#<";

=head1 Constructor

=head2 new

  my $j = JSON::ON->new(%args);

=over

=item j

Optional.  The JSON object.

=item module_handler

Optional.  A callback for handling modules found in decode().  The
default is to warn if a module has no VERSION method (which is a good
indicator that it is not loaded.)  Setting this to undef() will ignore
all modules.

  module_handler => sub {
    foreach my $module (@_) {
      unless($module->can("VERSION")) {
        (my $pm = $module) =~ s{::}{/}g;
        eval {require "$pm.pm"};
        die $@ if($@ and $@ !~ m/^Can't locate $pm in \@INC /);
      }
    }
  },

=back

=cut

sub new {
  my $self = shift->SUPER::new(@_);
  my $j = $self->{j} ||=
    JSON_CLASS()->new
    ->convert_blessed(1)
    ->filter_json_single_key_object(_json_marker(), sub {
      if(my $m = $self->{_modules}) {($m->{$_[0]->[1]} ||= 0)++}
      return bless($_[0]->[2] eq 'SCALAR' ?
        \ ($_[0]->[0]) : $_[0]->[0], $_[0]->[1]);
    });
  $self->{module_handler} = sub {
    foreach my $mod (@_) {
      carp("$mod is not loaded") unless $mod->can('VERSION');
    }
  } unless exists $self->{module_handler};
  $self;
} # new ################################################################

# unbless simple reference types
sub _obj_to_hash {
  my $rt = reftype($_[0]);
  my $ref = ref($_[0]);
  my $obj = $rt eq 'HASH'
    ? {%{$_[0]}} : $rt eq 'ARRAY'
      ? [@{$_[0]}] : ${$_[0]};
  return {_json_marker() => [$obj, $ref, $rt]};
} # _obj_to_hash #######################################################

=head1 Methods

=head2 encoder

  $j->encoder->($data);

=cut

sub encoder {
  my $self = shift;

  my $j = $self->{j};
  my $encode = $j->can('encode') or die;
  # suppress 'once'
  local *UNIVERSAL::TO_JSON = \&_obj_to_hash;
  return sub {
    local *UNIVERSAL::TO_JSON = \&_obj_to_hash;
    # TODO would goto be faster?
    my $x = eval {$encode->($j, $_[0])};
    $@ and croak($@);
    return($x);
  };
}

=head2 decoder

  $j->decoder->($data);

=cut

sub decoder {
  my $self = shift;

  my $j = $self->{j};
  my $decode = $j->can('decode') or die;
  my $hook = $self->module_handler;
  return $hook ? sub {
    my $mod = local $self->{_modules} = {};
    my $res = $decode->($j, $_[0]);
    $hook->(keys %$mod) if(%$mod);
    return $res;
  }
  : sub { return $decode->($j, $_[0]); };
}

=head2 subs

Convenience method.  Returns $j->decoder, $j->encoder subrefs.

  my ($dec, $enc) = $j->subs;

=cut

sub subs {
  my $self = shift;
  return($self->decoder, $self->encoder);
} # subs ###############################################################

=head2 encode

  my $enc = $j->encode($stuff);

=cut

sub encode {
  my ($self, $what) = @_;

  my $e = $self->{_encoder} ||= $self->encoder;
  return $e->($what);
} # encode #############################################################

=head2 decode

  my $dec = $j->decode($enc);

=cut

sub decode {
  my ($self, $what) = @_;

  my $d = $self->{_decoder} ||= $self->decoder;
  return $d->($what);
} # decode #############################################################

=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2010-2013 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
