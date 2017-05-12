use Test;
BEGIN { plan tests => 8 }

use Geography::Country::Utils qw(Name Code iso2fips fips2iso);

ok(defined &Name);
ok(defined &Code);
ok(defined &iso2fips);
ok(defined &fips2iso);

ok(Name('SW'), 'Sweden');

my $l2 = eval { require Net::Country; 1 };

skip(
    ($l2 ? 0 : "Skipping test on this platform"),
    eval { iso2fips('IS') }, 'IC'
);

skip(
    ($l2 ? 0 : "Skipping test on this platform"),
    eval { fips2iso('DA') }, 'DK'
);

ok(Code('Greenland'), 'GL');
