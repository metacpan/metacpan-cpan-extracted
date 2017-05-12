package Lingua::Stem::Snowball;
use strict;
use warnings;
use 5.006002;

use Carp;
use Exporter;
use vars qw(
    $VERSION
    @ISA
    @EXPORT_OK
    $AUTOLOAD
    %EXPORT_TAGS
    $stemmifier
    %instance_vars
);

$VERSION = '0.952';

@ISA         = qw( Exporter DynaLoader );
%EXPORT_TAGS = ( 'all' => [qw( stemmers stem )] );
@EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );

require DynaLoader;
__PACKAGE__->bootstrap($VERSION);

# Ensure that C symbols are exported so that other shared libaries (e.g.
# KinoSearch) can use them.  See Dynaloader docs.
sub dl_load_flags {0x01}

# A shared home for the actual struct sb_stemmer C modules.
$stemmifier = Lingua::Stem::Snowball::Stemmifier->new;

%instance_vars = (
    lang              => '',
    encoding          => undef,
    locale            => undef,
    stemmer_id        => -1,
    strip_apostrophes => 0,
);

sub new {
    my $class = shift;
    my $self = bless { %instance_vars, @_ }, ref($class) || $class;

    # Validate lang, validate/guess encoding, and get an sb_stemmer.
    $self->lang( $self->{lang} );
    if ( !defined $self->{encoding} ) {
        $self->{encoding}
            = $self->{lang} eq 'ru' ? 'KOI8-R'
            : $self->{lang} eq 'ro' ? 'ISO-8859-2'
            : $self->{lang} eq 'tr' ? 'UTF-8'
            :                         'ISO-8859-1';
    }
    $self->_derive_stemmer;

    return $self;
}

sub stem {
    my ( $self, $lang, $words, $locale, $is_stemmed );

    # Support lots of DWIMmery.
    if ( UNIVERSAL::isa( $_[0], 'HASH' ) ) {
        ( $self, $words, $is_stemmed ) = @_;
    }
    else {
        ( $lang, $words, $locale, $is_stemmed ) = @_;
        $self = __PACKAGE__->new( lang => $lang );
    }

    # Bail if we don't have a valid lang.
    return undef unless $self->{lang};

    # Bail if there's no input.
    return undef unless ( ref($words) or length($words) );

    # Duplicate the input array and transform it into an array of stems.
    $words = ref($words) ? $words : [$words];
    my @stems = map {lc} @$words;
    $self->stem_in_place( \@stems );

    # Determine whether any stemming took place, if requested.
    if ( ref($is_stemmed) ) {
        $$is_stemmed = 0;
        if ( $self->{stemmer_id} == -1 ) {
            $$is_stemmed = 1;
        }
        else {
            for ( 0 .. $#stems ) {
                next if $stems[$_] eq $words->[$_];
                $$is_stemmed = 1;
                last;
            }
        }
    }

    return wantarray ? @stems : $stems[0];
}

sub lang {
    my ( $self, $lang ) = @_;
    if ( defined $lang ) {
        $lang = lc($lang);
        $lang = $lang eq 'dk' ? 'nl' : $lang;    # backwards compat
        if ( _validate_language($lang) ) {
            $self->{lang} = $lang;
            # Force stemmer_id regen at next call to stem_in_place().
            $self->{stemmer_id} = -1;
        }
        else {
            $@ = "Language '$lang' does not exist";
        }
    }
    return $self->{lang};
}

sub encoding {
    my ( $self, $encoding ) = @_;
    if ( defined $encoding ) {
        croak("Invalid value for encoding: '$encoding'")
            unless $encoding =~ /^(?:UTF-8|KOI8-R|ISO-8859-[12])$/;
        $self->{encoding} = $encoding;
        # Force stemmer_id regen at next call to stem_in_place().
        $self->{stemmer_id} = -1;
    }
    return $self->{encoding};
}

# Deprecated, has no effect on stemming behavior.
sub strip_apostrophes {
    my ( $self, $boolean ) = @_;
    if ( defined $boolean ) {
        $self->{strip_apostrophes} eq $boolean ? 1 : 0;
    }
    return $self->{strip_apostrophes};
}

# Deprecated, has no effect on stemming behavior.
sub locale {
    my ( $self, $locale ) = @_;
    if ($locale) {
        $self->{locale} = $locale;
    }
    return $self->{locale};
}

1;

__END__

=head1 NAME

Lingua::Stem::Snowball - Perl interface to Snowball stemmers. 

=head1 SYNOPSIS

    my @words = qw( horse hooves );

    # OO interface:
    my $stemmer = Lingua::Stem::Snowball->new( lang => 'en' );
    $stemmer->stem_in_place( \@words ); # qw( hors hoov )

    # Functional interface:
    my @stems = stem( 'en', \@words );

=head1 DESCRIPTION

Stemming reduces related words to a common root form -- for instance, "horse",
"horses", and "horsing" all become "hors".  Most commonly, stemming is
deployed as part of a search application, allowing searches for a given term
to match documents which contain other forms of that term.

This module is very similar to L<Lingua::Stem> -- however, Lingua::Stem is
pure Perl, while Lingua::Stem::Snowball is an XS module which provides a Perl
interface to the C version of the Snowball stemmers.
(L<http://snowball.tartarus.org>).  

=head2 Supported Languages

The following stemmers are available (as of Lingua::Stem::Snowball 0.95):

    |-----------------------------------------------------------|
    | Language   | ISO code | default encoding | also available |
    |-----------------------------------------------------------|
    | Danish     | da       | ISO-8859-1       | UTF-8          | 
    | Dutch      | nl       | ISO-8859-1       | UTF-8          | 
    | English    | en       | ISO-8859-1       | UTF-8          |
    | Finnish    | fi       | ISO-8859-1       | UTF-8          | 
    | French     | fr       | ISO-8859-1       | UTF-8          |
    | German     | de       | ISO-8859-1       | UTF-8          | 
    | Hungarian  | hu       | ISO-8859-1       | UTF-8          | 
    | Italian    | it       | ISO-8859-1       | UTF-8          | 
    | Norwegian  | no       | ISO-8859-1       | UTF-8          | 
    | Portuguese | pt       | ISO-8859-1       | UTF-8          | 
    | Romanian   | ro       | ISO-8859-2       | UTF-8          | 
    | Russian    | ru       | KOI8-R           | UTF-8          | 
    | Spanish    | es       | ISO-8859-1       | UTF-8          | 
    | Swedish    | sv       | ISO-8859-1       | UTF-8          | 
    | Turkish    | tr       | UTF-8            |                | 
    |-----------------------------------------------------------|

=head2 Benchmarks

Here is a comparison of Lingua::Stem::Snowball and Lingua::Stem, using The
Works of Edgar Allen Poe, volumes 1-5 (via Project Gutenberg) as source
material.  It was produced on a 3.2GHz Pentium 4 running FreeBSD 5.3 and Perl
5.8.7.  (The benchmarking script is included in this distribution:
devel/benchmark_stemmers.plx.)

    |--------------------------------------------------------------------|
    | total words: 454285 | unique words: 22748                          |
    |--------------------------------------------------------------------|
    | module                        | config        | avg secs | rate    |
    |--------------------------------------------------------------------|
    | Lingua::Stem 0.81             | no cache      | 2.029    | 223881  |
    | Lingua::Stem 0.81             | cache level 2 | 1.280    | 355025  |
    | Lingua::Stem::Snowball 0.94   | stem          | 1.426    | 318636  |
    | Lingua::Stem::Snowball 0.94   | stem_in_place | 0.641    | 708495  |
    |--------------------------------------------------------------------|

=head1 METHODS / FUNCTIONS

=head2 new

    my $stemmer = Lingua::Stem::Snowball->new(
        lang     => 'es', 
        encoding => 'UTF-8',
    );
    die $@ if $@;

Create a Lingua::Stem::Snowball object.  new() accepts the following hash
style parameters:

=over

=item *

B<lang>: An ISO code taken from the table of supported languages, above.

=item *

B<encoding>: A supported character encoding.

=back

Be careful with the values you supply to new(). If C<lang> is invalid,
Lingua::Stem::Snowball does not throw an exception, but instead sets $@.
Also, if you supply an invalid combination of values for C<lang> and
C<encoding>, Lingua::Stem::Snowball will not warn you, but the behavior will
change: stem() will always return undef, and stem_in_place() will be a no-op.

=head2 stem

    @stemmed = $stemmer->stem( WORDS, [IS_STEMMED] );
    @stemmed = stem( ISO_CODE, WORDS, [LOCALE], [IS_STEMMED] );

Return lowercased and stemmed output.  WORDS may be either an array of words
or a single scalar word.  

In a scalar context, stem() returns the first item in the array of stems:

    $stem       = $stemmer->stem($word);
    $first_stem = $stemmer->stem(\@words); # probably wrong

LOCALE has no effect; it is only there as a placeholder for backwards
compatibility (see Changes).  IS_STEMMED must be a reference to a scalar; if
it is supplied, it will be set to 1 if the output differs from the input in
some way, 0 otherwise.

=head2 stem_in_place
 
    $stemmer->stem_in_place(\@words);

This is a high-performance, streamlined version of stem() (in fact, stem()
calls stem_in_place() internally). It has no return value, instead modifying
each item in an existing array of words.  The words must already be in lower
case.

=head2 lang
    
    my $lang = $stemmer->lang;
    $stemmer->lang($iso_language_code);

Accessor/mutator for the lang parameter. If there is no stemmer for the
supplied ISO code, the language is not changed (but $@ is set).

=head2 encoding 

    my $encoding = $stemmer->encoding;
    $stemmer->encoding($encoding);

Accessor/mutator for the encoding parameter.

=head2 stemmers

    my @iso_codes = stemmers();
    my @iso_codes = $stemmer->stemmers();

Returns a list of all valid language codes.

=begin deprecated

=head2 strip_apostrophes locale

=end deprecated

=head1 REQUESTS & BUGS

Please report any requests, suggestions or bugs via the RT bug-tracking system
at http://rt.cpan.org/ or email to bug-Lingua-Stem-Snowball@rt.cpan.org. 

http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-Stem-Snowball is the RT queue
for Lingua::Stem::Snowball.  Please check to see if your bug has already been
reported. 

=head1 AUTHORS

Lingua::Stem::Snowball was originally developed to provide
access to stemming algorithms for the OpenFTS (full text search engine) 
project (L<http://openfts.sourceforge.net>), by Oleg Bartunov, E<lt>oleg at
sai dot msu dot suE<gt> and Teodor Sigaev, E<lt>teodor at stack dot netE<gt>.

Currently maintained by Marvin Humphrey E<lt>marvin at rectangular dot
comE<gt>.  Previously maintained by Fabien Potencier E<lt>fabpot at cpan dot
orgE<gt>.  

=head1 COPYRIGHT AND LICENSE

Perl bindings copyright 2004-2008 by Marvin Humphrey, Fabien Potencier, Oleg
Bartunov and Teodor Sigaev.

This software may be freely copied and distributed under the same
terms and conditions as Perl.

Snowball files and stemmers are covered by the BSD license.

=head1 SEE ALSO

L<http://snowball.tartarus.org>, L<Lingua::Stem|Lingua::Stem>.

=cut
