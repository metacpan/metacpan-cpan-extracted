package Lingua::LO::NLP::Romanize;
use strict;
use warnings;
use 5.012000;
use utf8;
use version 0.77; our $VERSION = version->declare('v1.0.0');
use Carp;
use Scalar::Util 'blessed';
use Class::Accessor::Fast 'antlers';
use Lingua::LO::NLP::Syllabify;

=encoding utf8

=head1 NAME

Lingua::LO::NLP::Romanize - Romanize Lao syllables

=head1 FUNCTION

This is a factory class for C<Lingua::LO::NLP::Romanize::*>. Currently there
are the following romanization modules:

=over 4

=item L<Lingua::LO::NLP::Romanize::PCGN>

for the standard set by the
L<Permanent Committee on Geographical Names for British Official Use|https://www.gov.uk/government/uploads/system/uploads/attachment_data/file/533781/ROMANIZATION_SYSTEM_FOR_LAO.pdf>

=item L<Lingua::LO::NLP::Romanize::IPA>

for the International Phonetic Alphabet

=back

=head1 SYNOPSIS

    my $o = Lingua::LO::NLP::Romanize->new(
        variant => 'PCGN',
        hyphen => 1,
    );

=cut

=head1 METHODS

=head2 new

The constructor takes any number of hash-style named arguments. The following
ones are always recognized:

=over 4

=item C<variant>

Standard according to which to romanize; this determines the
L<Lingua::LO::NLP::Romanize> subclass to actually instantiate. This argument is mandatory.

=item C<hyphen>

Separate runs of Lao syllables with hyphens. Set this to the character you
would like to use as a hyphen - usually this will be the ASCII "hyphen minus"
(U+002D) but it can be the unambiguous Unicode hyphen ("‐", U+2010), a slash or
anything you like. As a special case, you can pass a 1 to use the ASCII
version. If this argument is missing, C<undef> or C<0>, blanks are used.
Syllables duplicated using "ໆ" are always joined with a hyphen: either the one
you specify or the ASCII one.

=item C<normalize>

Run text through tone mark order normalization; see
L<Lingua::LO::NLP::Data/normalize_tone_marks>. If your text looks fine but
syllables are not recognized, you may need this.

=back

Subclasses may specify additional arguments, such as
L<IPA|Lingua::LO::NLP::Romanize::IPA>'s C<tone> that controls the rendering of
IPA diacritics for tonal languages.

=cut

sub new {
    my ($class, %args) = @_;

    # Allow subclasses to omit a constructor
    return bless {}, $class if $class ne __PACKAGE__;

    # If we've been called on Lingua::LO::NLP::Romanize, require a variant
    my $variant = delete $args{variant} or croak("`variant' argument missing or undefined");
    my $hyphen = delete $args{hyphen};
    my $normalize = delete $args{normalize};

    my $subclass = __PACKAGE__ . "::$variant";
    (my $module = $subclass) =~ s!::!/!g;
    require "$module.pm";   ## no critic (BarewordIncludes)

    my $self = $subclass->new(%args);

    # Pass an explicit false if hyphen arg was unset
    $self->hyphen($hyphen // 0);
    $self->normalize($normalize);
    return $self;
}

=head2 romanize

    romanize( $text )

Return the romanization of C<$text> according to the standard passed to the
constructor. Text is split up by
L<Lingua::LO::NLP::Syllabify/get_fragments>; Lao syllables are processed
and everything else is passed through unchanged save for possible conversion of
combining characters to a canonically equivalent form by
L<Unicode::Normalize/NFC>.

=cut

sub romanize {
    my ($self, $text) = @_;
    my $result = '';

    my @frags = Lingua::LO::NLP::Syllabify->new( $text, normalize => $self->normalize )->get_fragments;
    while(@frags) {
        my @lao;
        push @lao, shift @frags while @frags and $frags[0]->{is_lao};
        $result .= join($self->{hyphen}, map { $self->romanize_syllable( $_->{text} ) } @lao);
        $result .= (shift @frags)->{text} while @frags and not $frags[0]->{is_lao};
    }
    return $result;
}

=head2 romanize_syllable

    romanize_syllable( $syllable )

Return the romanization of a single C<$syllable> according to the standard passed to the
constructor. This is a virtual method that must be implemented by subclasses.

=cut

sub romanize_syllable {
    my $self = shift;
    ref $self or die "romanize_syllable is not a class method";
    die blessed($self) . " must implement romanize_syllable()";
}

=head2 hyphen

  my $hyphen = $o->hyphen;
  $o->hyphen( '-' );    # Use ASCII hyphen
  $o->hyphen( 1 );      # Dito
  $o->hyphen( 0 );      # No hyphenation, separate syllables with spaces
  $o->hyphen( '‐' );    # Unicode hyphen U+2010

Accessor for the C<hyphen> attribute, see L</new>.

=cut

sub hyphen {
    my ($self, $hyphen) = @_;
    if(defined $hyphen) {
        if($hyphen eq '1') {
            $self->{hyphen} = '-';
        } elsif($hyphen eq '0') {
            $self->{hyphen} = ' ';
        } else {
            $self->{hyphen} = $hyphen;
        }
    }
    return $self->{hyphen};
}

=head2 normalize

  my $normalization = $o->normalize;
  $o->normalize( $bool );

Accessor for the C<normalize> attribute, see L</new>.

=cut

has normalize => (is => 'rw');

1;

