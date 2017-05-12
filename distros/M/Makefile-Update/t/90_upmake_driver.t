use strict;
use warnings;
use autodie;
use File::Temp ();
use Test::More;
use Test::Output;

BEGIN {
    use_ok('Makefile::Update');
    use_ok('Makefile::Update::Makefile');
}

my $vars_orig = {
    foo => [qw{
        a.cpp
        h.cpp
    }],
};

my $vars_new = {
    foo => [qw{
        a.cpp
        b.cpp
        h.cpp
    }],
};

my $tmp = File::Temp->new(UNLINK => 0);
print $tmp <<'EOF';
foo_sources = \
    a.cpp \
    h.cpp
EOF

my $fn = $tmp->filename;
undef $tmp;

my $upd = \&update_makefile;

stdout_is { upmake($fn, $upd, $vars_orig) }
    '',
    'no messages if nothing changed by default';

stdout_is { upmake({file => $fn}, $upd, $vars_orig) }
    '',
    'still quiet when using hash argument';

stdout_is { upmake({file => $fn, dryrun => 1}, $upd, $vars_orig) }
    qq{Wouldn't change the file "$fn".\n},
    'dry run unchanged message given';

stdout_is { upmake({file => $fn, verbose => 1}, $upd, $vars_orig) }
    qq{No changes in the file "$fn".\n},
    'verbose message about unchanged file given';

stdout_is { upmake({file => $fn, dryrun => 1}, $upd, $vars_new) }
    qq{Would update "$fn".\n},
    'dry run modified message given';

stdout_is { upmake($fn, $upd, $vars_new) }
    qq{File "$fn" successfully updated.\n},
    'default modified message given';

stdout_is { upmake({file => $fn, quiet => 1}, $upd, $vars_orig) }
    '',
    'no messages given with quiet option';


done_testing();

END {
    unlink $fn;
}
