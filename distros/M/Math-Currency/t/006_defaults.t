use Test::More tests => 6;
use POSIX qw(setlocale);

BEGIN { use_ok( Math::Currency ); }

# For subsequent testing, we need to make sure that format is default US
my $format = Math::Currency->format("USD");

my $floating = Math::Currency->new("12.34"); # default to dollars
is ( $floating, '$12.34', 'Individual currency object');
my $dollars = Math::Currency->new("12.34",'USD'); # force to dollars
is ( $dollars, '$12.34', 'Individual currency object');

SKIP: {
    skip 'en_GB locale is not available on this system', 3, unless have_locale('en_GB');
    $format = Math::Currency->format("GBP"); #change default currency
    ok ( $format->{INT_CURR_SYMBOL} =~ /GBP/, 'Default currency changed');

    is ( $dollars, '$12.34', 'Object did not change to new default currency');
    isnt ( $floating, '$12.34', 'Object changed to new default currency');
}

sub have_locale {
    my $wanted = shift;

    my $locale = setlocale(&POSIX::LC_ALL, $wanted) || '';

    return $locale eq $wanted;
}
