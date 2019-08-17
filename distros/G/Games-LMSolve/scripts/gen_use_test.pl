#!/usr/bin/perl

use strict;
use warnings;

use autodie;

my @modules = (
    (
        map { "Games::LMSolve::$_" }
            qw(Numbers Base Plank::Base Plank::Hex Alice),
        qw(Tilt::Base Tilt::Single Tilt::Multi Tilt::RedBlue),
        qw(Input Registry)
    ),
    "Games::LMSolve"
);

my $num_modules = scalar(@modules);

open my $out_fh, ">", 't/00use.t';
print {$out_fh} <<"EOF" ;
#!/usr/bin/perl -w

use strict;

use Test::More tests => $num_modules;

BEGIN
{
EOF

foreach (@modules)
{
    print {$out_fh} "use_ok(\"$_\");\n";
}

print {$out_fh} "}\n";

close($out_fh);
