package Locale::MakePhrase::Language;
our $VERSION = 0.2;

=head1 NAME

Locale::MakePhrase::Language - base class for language-specific
handling.

=head1 DESCRIPTION

This is a base-class for language-specific implementation modules.

You only need to implement custom language objects, if there is
something you cant do with a language rule, such as:

=over 2

=item *

handling keyboard input in a language specific way

=item *

display of formula's

=back

=head1 API

The following methods are available:

=cut

use strict;
use warnings;
use utf8;
use base qw();

#--------------------------------------------------------------------------

=head2 new()

Construct an instance of this module; all arguments passed to the
init() method.

=cut

# Generic constructor
sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = bless {}, $class;
  return $self->init(@_);
}

=head2 $self init([...])

Allow sub-classes a chance to control construction.

=cut

sub init { shift }

=head2 $string language()

Returns the language tag of this modules' language.

=cut

sub language {
  my $lang = shift;
  $lang =~ s/.*::([a-z_]+)$/$1/;
  return $lang;
}

=head2 boolean y_or_n($keypress)

This methods is simply a stub which declares the signature.  It is
up the language specific module to implement the correct handling
of the keypress'ed value.

For example, the L<Locale::MakePhrase::Language::en> module implements
a test for the B<y> character; if B<y> is pressed, a value of true is
returned; any other key returns false.

=cut

# stub
sub y_or_n {
  die "Must be implemented in a language specific sub-class";
}

1;
__END__
#--------------------------------------------------------------------------

