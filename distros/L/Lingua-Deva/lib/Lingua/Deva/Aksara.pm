package Lingua::Deva::Aksara;

use v5.12.1;
use strict;
use warnings;
use utf8;

use Lingua::Deva::Maps qw( %Vowels %Consonants %Finals );

=encoding UTF-8

=head1 NAME

Lingua::Deva::Aksara - Object representation of a Devanagari "syllable"

=head1 SYNOPSIS

    use v5.12.1;
    use strict;
    use charnames ':full';
    use Lingua::Deva::Aksara;

    my $a = Lingua::Deva::Aksara->new(
        onset => ['dh', 'r'],
        vowel => 'au',
        final => "h\N{COMBINING DOT BELOW}",
    );
    $a->vowel( 'ai' );
    say 'valid' if $a->is_valid();
    say @{ $a->get_rhyme() }; # prints 'aiḥ'

=head1 DESCRIPTION

I<Akṣara> is the Sanskrit term for the basic unit above the character level in
the Devanagari script.  A C<Lingua::Deva::Aksara> object is a Perl
representation of such a unit.

C<Lingua::Deva::Aksara> objects serve as an intermediate format for the
conversion facilities in L<Lingua::Deva>.  Onset, vowel, and final tokens are
stored in separate fields.  I<Tokens> are in Latin script; if the Aksara in
question was created through the L<l_to_aksaras()|Lingua::Deva/l_to_aksaras>
or L<d_to_aksaras()|Lingua::Deva/d_to_aksaras> method of a C<Lingua::Deva>
object, then the tokens are in the transliteration format associated with that
object.

=head2 Methods

=over 4

=item new()

Constructor.  Can take optional initial data as its argument.

    use Lingua::Deva::Aksara;
    Lingua::Deva::Aksara->new( onset => ['gh', 'r'] );

=cut

sub new {
    my $class = shift;
    my $self = { @_ };
    return bless $self, $class;
}

=item onset()

Accessor method for the array of onset tokens of this Aksara.

    my $a = Lingua::Deva::Aksara->new();
    $a->onset( ['d', 'r'] ); # sets onset tokens to ['d', 'r']
    $a->onset(); # returns a reference to ['d', 'r']

Returns undefined when there is no onset.

=cut

sub onset {
    my $self = shift;
    $self->{onset} = shift if @_;
    return $self->{onset};
}

=item vowel()

Accessor method for the vowel token of this Aksara.  Returns undefined when
there is no vowel.

=cut

sub vowel {
    my $self = shift;
    $self->{vowel} = shift if @_;
    return $self->{vowel};
}

=item final()

Accessor method for the final token of this Aksara.  Returns undefined when
there is no final.

=cut

sub final {
    my $self = shift;
    $self->{final} = shift if @_;
    return $self->{final};
}

=item get_rhyme()

Returns the rhyme of this Aksara.  This is a reference to an array consisting
of vowel and final.  Undefined if there is no rhyme.

The Aksara is assumed to be well-formed.

=cut

sub get_rhyme {
    my $self = shift;
    if ($self->{final}) { return [ $self->{vowel}, $self->{final} ] }
    if ($self->{vowel}) { return [ $self->{vowel} ] }
    return;
}

=item is_valid()

Checks the formal validity of this Aksara.  This method first checks if the
Aksara conforms to the structure C<(C+(VF?)?)|(VF?)>, where the letters
represent onset consonants, vowel, and final.  Then it checks whether the
onset, vowel, and final fields contain only appropriate tokens.

In order to do validation against a different transliteration scheme than the
default one, a reference to a customized C<Lingua::Deva> instance can be
passed along.

    $d; # Lingua::Deva object with custom transliteration
    say $a->is_valid($d);

An Aksara constructed through L<Lingua::Deva>'s public interface is already
well-formed (ie. in accordance with the particular transliteration used) and
no validity check is necessary.

=cut

sub is_valid {
    my ($self, $deva) = @_;

    my ($C, $V, $F) = ref($deva) eq 'Lingua::Deva'
                    ? ($deva->{C}, $deva->{V}, $deva->{F})
                    : (\%Consonants, \%Vowels, \%Finals);

    # Check Aksara structure
    my $s = @{ $self->{onset} // [] } ? 'C' : '';
    $s   .=    $self->{vowel}         ? 'V' : '';
    $s   .=    $self->{final}         ? 'F' : '';
    return 0 if $s =~ m/^(C?F|)$/;

    # After this point empty strings and arrays have been rejected

    # Check Aksara tokens
    if (defined $self->{onset}) {
        for my $o (@{ $self->{onset} }) {
            return 0 if not defined $C->{$o};
        }
    }
    if (defined $self->{vowel}) {
        return 0 if not defined $V->{ $self->{vowel} };
    }
    if (defined $self->{final}) {
        return 0 if not defined $F->{ $self->{final} };
    }

    return 1;
}

=back

=cut

1;
