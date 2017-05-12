package My::Test::Util;

# Test helper functions.

use strict;
use warnings;
use base 'Exporter';
use Test::More;

our @EXPORT = qw(plan_locale);

sub plan_locale {
    my ($wanted, $tests) = @_;

    $tests += 1; # add 1 for the "Re-initialized" test pass

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $locale = POSIX::setlocale( &POSIX::LC_ALL, $wanted ) || '';
    if ($locale ne $wanted) {
        plan skip_all => "locale $locale is not available on this system";
    }
    elsif (! Math::Currency->localize()) {
        plan skip_all => 'No locale support';
    }
    else {
        plan tests => $tests;

        pass "Re-initalized locale with $wanted";
    }
}


1;
