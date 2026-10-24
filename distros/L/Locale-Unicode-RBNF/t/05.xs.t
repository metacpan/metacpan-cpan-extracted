#!perl
##----------------------------------------------------------------------------
## Unicode CLDR Rule-Based Number Format - t/05.xs.t
##
## The C parsing engine must give exactly the same results as the pure Perl
## one.
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use File::Spec;
    use Test::More;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;
use utf8;

BEGIN
{
    use_ok( 'Locale::Unicode::RBNF' ) || BAIL_OUT( 'Unable to load Locale::Unicode::RBNF' );
};

if( do{ no warnings 'once'; $Locale::Unicode::RBNF::IsPurePerl } )
{
    diag( 'The C parsing engine is not in use; nothing to compare.' );
    done_testing();
    exit(0);
}
# Loading the pure Perl implementation while the XS layer is in use only installs the
# parsing methods, so both engines can be compared in the same process.
require_ok( 'Locale::Unicode::RBNF::PP' );
my $xs_parse = \&Locale::Unicode::RBNF::_parse_text;
my $pp_parse = \&Locale::Unicode::RBNF::PP::rbnf_parse_text;
isnt( $xs_parse, $pp_parse, 'the C engine is still in use after loading the pure Perl one' );
my $cldr = File::Spec->catdir( 't', 'cldr' );
my @extra = (
    'n importe quoi',
    'Deux Mille Vingt Six',
    'QUATRE VINGT ONZE',
    "soixante\x{2011}et\x{2011}onze",
    'One Thousand, Two Hundred and Thirty Four',
    'İKİ',
    'BİR',
    '参百万',
    'mcmxciv',
    '1 234',
    '12,5',
    ''
);
foreach my $def (
    [ fr   => 'spellout' ],
    [ fr   => 'ordinal' ],
    [ en   => 'spellout' ],
    [ en   => 'ordinal' ],
    [ ja   => 'spellout' ],
    [ 'tr' => 'spellout' ],
    [ root => 'numbering_system' ] )
{
    my( $loc, $type ) = @$def;
    my $fmt = Locale::Unicode::RBNF->new( locale => $loc, type => $type, cldr => $cldr ) || BAIL_OUT( Locale::Unicode::RBNF->error );
    my %texts = map{ $_ => 1 } @extra;
    foreach my $rs ( @{$fmt->rule_set_names} )
    {
        $texts{ $fmt->format( $_, $rs ) // '' } = 1 for( 0, 1, 2, 7, 11, 21, 42, 71, 80, 99, 100, 101, 999, 1000, 1234, 2026, 12345, 1000000, 1234567, -5, 3.25 );
    }
    foreach my $lenient ( 0, 1 )
    {
        $fmt->lenient( $lenient );
        my $diff = 0;
        foreach my $text ( sort( keys( %texts ) ) )
        {
            my @xs = $fmt->parse( $text );
            my @pp;
            {
                no warnings 'redefine';
                local *Locale::Unicode::RBNF::_parse_text = $pp_parse;
                @pp = $fmt->parse( $text );
            }
            $_ //= 'undef' for( @xs, @pp );
            if( "@xs" ne "@pp" )
            {
                $diff++;
                diag( "$loc $type lenient=$lenient '$text': XS @xs, Perl @pp" );
            }
        }
        is( $diff, 0, "$loc $type lenient=$lenient: " . scalar( keys( %texts ) ) . ' texts parsed identically' );
    }
}

done_testing();

__END__
