use strict;
use warnings;
use autodie;
use Test::More;

BEGIN { use_ok('Makefile::Update::Makefile'); }

my $vars = {
    foo => [qw{
        foo_a.cpp
        foo_z.cpp
    }],
    bar => [qw{
        bar_a.cpp
        bar_z.cpp
        bar_b.cpp
    }],
};

open my $in, '<', \<<'EOF';
foo_SOURCES = \
    foo_z.cpp \
    foo_a.cpp

bar_SOURCES = \
    bar_a.cpp \
    bar_z.cpp

EOF

open my $out, '>', \my $outstr;
update_makefile($in, $out, $vars);

is($outstr, <<'EOF', 'new files inserted into the right place');
foo_SOURCES = \
    foo_z.cpp \
    foo_a.cpp

bar_SOURCES = \
    bar_a.cpp \
    bar_b.cpp \
    bar_z.cpp

EOF

done_testing()
