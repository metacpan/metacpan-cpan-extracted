package Lingua::Stem::Snowball::Lt;
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

$VERSION = '0.03';

@ISA         = qw( Exporter DynaLoader );
%EXPORT_TAGS = ( 'all' => [qw( stem )] );
@EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );

require DynaLoader;
__PACKAGE__->bootstrap($VERSION);

# Ensure that C symbols are exported so that other shared libaries (e.g.
# KinoSearch) can use them.  See Dynaloader docs.
sub dl_load_flags {0x01}

# A shared home for the actual struct sb_stemmer C modules.
$stemmifier = Lingua::Stem::Snowball::Lt::Stemmifier->new;

%instance_vars = (
    lang              => 'lt',
    encoding          => 'UTF-8',
    locale            => undef,
    stemmer_id        => -1,
    strip_apostrophes => 0,
);

sub new {
    my $class = shift;
    my $self = bless { %instance_vars, @_ }, ref($class) || $class;

    # Get an sb_stemmer.
    $self->_derive_stemmer;

    return $self;
}

sub stem {
    my ( $self, $words, $locale, $is_stemmed );

    # Support lots of DWIMmery.
    if ( UNIVERSAL::isa( $_[0], 'HASH' ) ) {
        ( $self, $words, $is_stemmed ) = @_;
    }
    else {
        ( $words, $locale, $is_stemmed ) = @_;
        $self = __PACKAGE__->new( );
    }

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

1;

__END__

=head1 NAME

Lingua::Stem::Snowball::Lt - Perl interface to Snowball stemmer for the Lithuanian language.

=head1 SYNOPSIS

    my @words = qw( niekada myliu );

    # OO interface:
    my $stemmer = Lingua::Stem::Snowball::Lt->new( );
    $stemmer->stem_in_place( \@words ); # qw( niekad myl )

    # Functional interface:
    my @stems = stem( \@words );

=head1 DESCRIPTION

Stemming reduces related words to a common root form -- for instance, "horse",
"horses", and "horsing" all become "hors".  Most commonly, stemming is
deployed as part of a search application, allowing searches for a given term
to match documents which contain other forms of that term.

This module is very similar to L<Lingua::Stem> -- however, Lingua::Stem is
pure Perl, while Lingua::Stem::Snowball::Lt is an XS module which provides a Perl
interface to the C version of the Lithuanian stemmer based on Snowball.
(L<http://snowball.tartarus.org>).  

=head1 METHODS / FUNCTIONS

=head2 new

    my $stemmer = Lingua::Stem::Snowball::Lt->new( );
    die $@ if $@;

Create a Lingua::Stem::Snowball::Lt object.

=head2 stem

    @stemmed = $stemmer->stem( WORDS, [IS_STEMMED] );
    @stemmed = stem( WORDS, [LOCALE], [IS_STEMMED] );

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

=head1 AUTHORS

Lingua::Stem::Snowball was originally developed to provide
access to stemming algorithms for the OpenFTS (full text search engine) 
project (L<http://openfts.sourceforge.net>), by Oleg Bartunov, E<lt>oleg at
sai dot msu dot suE<gt> and Teodor Sigaev, E<lt>teodor at stack dot netE<gt>.

Lingua::Stem::Snowball is currently maintained by Marvin Humphrey
E<lt>marvin at rectangular dot comE<gt>.  Previously maintained by Fabien
Potencier E<lt>fabpot at cpan dot orgE<gt>.  

Lithuanian language adaptation (Lingua::Stem::Snowball::Lt) was done by
Linas Valiukas.  Lithuanian stemmer for Snowball was created by Z. Medelis,
M. Petkevicius and T. Krilavicius.

=head1 COPYRIGHT AND LICENSE

Perl bindings copyright 2004-2008 by Marvin Humphrey, Fabien Potencier, Oleg
Bartunov and Teodor Sigaev.

Lithuanian language adaptation (Lingua::Stem::Snowball::Lt) copyright 2013
by Linas Valiukas.

This software may be freely copied and distributed under the same
terms and conditions as Perl.

Snowball files and stemmers are covered by the BSD license.

Lithuanian stemmer (by Z. Medelis, M. Petkevicius, T. Krilavicius) is covered
by the Academic Free License (AFL).

=head1 SEE ALSO

L<http://snowball.tartarus.org>, L<Lingua::Stem::Snowball|Lingua::Stem::Snowball>, L<Lingua::Stem|Lingua::Stem>.

=cut
