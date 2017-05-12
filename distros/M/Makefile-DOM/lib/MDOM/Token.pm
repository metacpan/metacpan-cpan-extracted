package MDOM::Token;

=pod

=head1 NAME

MDOM::Token - A single token of Makefile source code

=head1 INHERITANCE

  MDOM::Token
  isa MDOM::Element

=head1 DESCRIPTION

C<MDOM::Token> is the abstract base class for all Tokens. In MDOM terms, a "Token" is
a L<MDOM::Element> that directly represents bytes of source code.

The implementation and POD are borrowed directly from L<PPI::Token>.

=head1 METHODS

=cut

use strict;
use base 'MDOM::Element';
use Params::Util '_INSTANCE';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.008';
}

# We don't load the abstracts, they are loaded
# as part of the 'use base' statements.

# Load the token classes
use MDOM::Token::Whitespace            ();
use MDOM::Token::Comment               ();
use MDOM::Token::Separator             ();
use MDOM::Token::Continuation          ();
use MDOM::Token::Bare                  ();
use MDOM::Token::Interpolation         ();
use MDOM::Token::Modifier              ();

#####################################################################
# Constructor and Related

sub new {
	if ( @_ == 2 ) {
		# MDOM::Token->new( $content );
        my $class;
        if ($_[0] eq __PACKAGE__) {
		    $class = 'MDOM::Token::Bare';
            shift;
        } else {
            $class = shift;
        }
		return bless {
			content => (defined $_[0] ? "$_[0]" : ''),
                        lineno => $.,
			}, $class;
	} elsif ( @_ == 3 ) {
		# MDOM::Token->new( $class, $content );
		my $class = substr( $_[0], 0, 12 ) eq 'MDOM::Token::' ? $_[1] : "MDOM::Token::$_[1]";
		return bless {
			content => (defined $_[2] ? "$_[2]" : ''),
                        lineno => $.,
			},  $class;
	}

	# Invalid argument count
	undef;
}

=head2  set_class

Set a specific class for a token.

=cut

sub set_class {
	my $self  = shift; @_ or return undef;
	my $class = substr( $_[0], 0, 12 ) eq 'MDOM::Token::' ? shift : 'MDOM::Token::' . shift;

	# Find out if the current and new classes are complex
	my $old_quote = (ref($self) =~ /\b(?:Quote|Regex)\b/o) ? 1 : 0;
	my $new_quote = ($class =~ /\b(?:Quote|Regex)\b/o)     ? 1 : 0;

	# No matter what happens, we will have to rebless
	bless $self, $class;

	# If we are changing to or from a Quote style token, we
	# can't just rebless and need to do some extra thing
	# Otherwise, we have done enough
	return 1 if ($old_quote - $new_quote) == 0;

	# Make a new token from the old content, and overwrite the current
	# token's attributes with the new token's attributes.
	my $token = $class->new( $self->{content} ) or return undef;
	delete $self->{$_} foreach keys %$self;
	$self->{$_} = $token->{$_} foreach keys %$token;

	1;
}



#####################################################################
# MDOM::Token Methods

=pod

=head2 set_content $string

The C<set_content> method allows to set/change the string that the
C<MDOM::Token> object represents.

Returns the string you set the Token to

=cut

sub set_content {
	$_[0]->{content} = $_[1];
}

=pod

=head2 add_content $string

The C<add_content> method allows you to add additional bytes of code
to the end of the Token.

Returns the new full string after the bytes have been added.

=cut

sub add_content { $_[0]->{content} .= $_[1] }

=pod

=head2 length

The C<length> method returns the length of the string in a Token.

=cut

sub length { &CORE::length($_[0]->{content}) }





#####################################################################
# Overloaded MDOM::Element methods

sub content {
	$_[0]->{content};
}

# You can insert either a statement, or a non-significant token.
sub insert_before {
	my $self    = shift;
	my $Element = _INSTANCE(shift, 'MDOM::Element')  or return undef;
	if ( $Element->isa('MDOM::Structure') ) {
		return $self->__insert_before($Element);
	} elsif ( $Element->isa('MDOM::Token') ) {
		return $self->__insert_before($Element);
	}
	'';
}

# As above, you can insert a statement, or a non-significant token
sub insert_after {
	my $self    = shift;
	my $Element = _INSTANCE(shift, 'MDOM::Element') or return undef;
	if ( $Element->isa('MDOM::Structure') ) {
		return $self->__insert_after($Element);
	} elsif ( $Element->isa('MDOM::Token') ) {
		return $self->__insert_after($Element);
	}
	'';
}

=pod

=head2 source

Returns the makefile source for the current token

=cut

sub source {
    my $self = shift;
    return $self->content;
}

1;
