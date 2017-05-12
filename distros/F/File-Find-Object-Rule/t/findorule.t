#!perl

use strict;
use warnings;

use lib './t/lib';

use Test::More tests => 5;
use File::Spec;

use File::Path;
use File::Find::Object::TreeCreate;

my $tree_creator = File::Find::Object::TreeCreate->new();

{
    my $tree =
    {
        'name' => "findorule-t-copy-to/",
        'subs' =>
        [
            {
                'name' => "File-Find-Rule.t",
                'contents' => $tree_creator->cat(
                    "./t/sample-data/to-copy-from/File-Find-Rule.t"
                ),
            },
            {
                'name' => "findorule.t",
                'contents' => $tree_creator->cat(
                    "./t/sample-data/to-copy-from/findorule.t"
                ),
            },
            {
                'name' => "foobar",
                'contents' => $tree_creator->cat(
                    "./t/sample-data/to-copy-from/foobar"
                ),

            },
            {
                'name' => "lib/",
                'subs' =>
                [
                    {
                        'name' => "File/",
                        'subs' =>
                        [
                            {
                                name => "Find/",
                                subs =>
                                [
                                    {
                                        name => "Object/",
                                        subs =>
                                        [
                                            {
                                                name => "Rule/",
                                                subs =>
                                                [
                                                    {
                                                        name => "Test/",
                                                        subs =>
                                                        [
                                                        {
                                                            name => "ATeam.pm",
content => $tree_creator->cat(
    "./t/sample-data/to-copy-from/lib/File/Find/Object/Rule/Test/ATeam.pm"

),
}
                                                        ],
                                                    },
                                                ],
                                            }
                                        ],
                                    },
                                ],
                            },
                        ],
                    },
                ],
            },
        ],
    };

    $tree_creator->create_tree("./t/sample-data/", $tree);
}

# extra tests for findorule.  these are more for testing the parsing code.

sub run ($) {
    my $expr = shift;
    my $script = File::Spec->catfile(
        File::Spec->curdir(), "scripts", "findorule"
    );

    [ sort split /\n/, `$^X -Mblib $script $expr` ];
}

my $copy_fn = $tree_creator->get_path(
    "./t/sample-data/findorule-t-copy-to/"
);

my $FFR_t = $tree_creator->get_path(
    "./t/sample-data/findorule-t-copy-to/File-Find-Rule.t"
);
my $findorule_t = $tree_creator->get_path(
    "./t/sample-data/findorule-t-copy-to/findorule.t"
);
my $foobar_fn = $tree_creator->get_path(
    "./t/sample-data/findorule-t-copy-to/foobar"
);

# TEST
is_deeply(run $copy_fn . ' -file -name foobar', [ $foobar_fn ],
          '-file -name foobar');

# TEST
is_deeply(run $copy_fn . ' -maxdepth 0 -directory',
          [ $copy_fn ], 'last clause has no args');


{
    local $TODO = "Win32 cmd.exe hurts my brane"
      if ($^O =~ m/Win32/ || $^O eq 'dos');

    # TEST
    is_deeply(run $copy_fn . ' -file -name \( foobar \*.t \)',
              [ $FFR_t, $findorule_t, $foobar_fn ],
              'grouping ()');

    # TEST
    is_deeply(run $copy_fn . ' -name \( -foo foobar \)',
              [ $foobar_fn ], 'grouping ( -literal )');
}

# Remming out due to capturing STDERR using unixisms. In the future, we
# may implement this using Test::Trap.
# is_deeply(run $copy_fn . ' -file -name foobar baz',
#          [ "unknown option 'baz'" ], 'no implicit grouping');

# TEST
is_deeply(run $copy_fn . ' -maxdepth 0 -name -file',
          [], 'terminate at next -');

rmtree($copy_fn);
