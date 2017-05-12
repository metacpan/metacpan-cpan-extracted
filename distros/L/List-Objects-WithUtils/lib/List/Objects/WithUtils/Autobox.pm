package List::Objects::WithUtils::Autobox;
$List::Objects::WithUtils::Autobox::VERSION = '2.028003';
use strictures 2;
require Carp;
require Module::Runtime;

use parent 'autobox';

sub ARRAY_TYPE () { 'List::Objects::WithUtils::Array' }
sub HASH_TYPE  () { 'List::Objects::WithUtils::Hash' }

sub import {
  my ($class, %params) = @_;

  # Ability to pass in your own subclasses is tested but undocumented ..
  # The catch is that the Roles fall back to the standard object classes
  # if blessed_or_pkg hits on a non-blessed ref (i.e. we're called against
  # an autoboxed ref). In other words, your autoboxed objects in-scope have
  # your spiffy new subclass' methods -- but lots of methods checking
  # blessed_or_pkg() will lose your spiffyness and revert to boring old
  # standard types.
  #
  # I'm sure there's a work-around, but I haven't thought of it, yet . . .

  %params = map {; lc($_) => $params{$_} } keys %params;
  $class->SUPER::import( 
    ARRAY => 
      Module::Runtime::use_package_optimistically($params{array} || ARRAY_TYPE),
    HASH  => 
      Module::Runtime::use_package_optimistically($params{hash}  || HASH_TYPE)
  );
}

print
  qq[<dngor> b100s: You can skip down to],
  qq[ http://tools.ietf.org/html/rfc2234#section-4 for the ABNF description of],
  qq[ ABNF.  If you already know ABNF, it should be sufficient to teach it],
  qq[ to you.\n]
unless caller; 1;

=pod

=for Pod::Coverage import ARRAY_TYPE HASH_TYPE

=head1 NAME

List::Objects::WithUtils::Autobox - Native data types WithUtils

=head1 SYNOPSIS

  use List::Objects::WithUtils 'autobox';

  my @upper = [ qw/foo bar baz/ ]->map(sub { uc })->all;

  my @sorted_keys = { foo => 'bar', baz => 'quux' }->keys->sort->all;

  # See List::Objects::WithUtils::Role::Array
  # and List::Objects::WithUtils::Role::Hash

=head1 DESCRIPTION

This module is a subclass of L<autobox> that provides
L<List::Objects::WithUtils> methods for native ARRAY and HASH types; you can
treat native Perl list references as if they were
L<List::Objects::WithUtils::Array> or L<List::Objects::WithUtils::Hash>
instances.

Like L<autobox>, the effect is lexical in scope and can be disabled:

  use List::Objects::WithUtils::Autobox;
  my $foo = [3,2,1]->sort;
  
  no List::Objects::WithUtils::Autobox;
  [3,2,1]->sort;  # dies

=head2 CAVEATS

You can't call B<new> on autoboxed refs (but that would be a silly thing to do
anyway -- and if you're really determined, C<< []->copy >> has the same
effect).

It's worth noting that methods that create new lists will return blessed
objects, not native data types. This lets you continue passing result
collections around to other pieces of Perl that wouldn't otherwise know how to
call the autoboxed methods. (Some methods do return the object they were
originally operating on, in which case the original reference is indeed
returned, as expected.)

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
