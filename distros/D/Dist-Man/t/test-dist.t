#!/usr/bin/perl

use strict;
use warnings;

# Should be 469
use Test::More tests => 469;

use Dist::Man;
use File::Spec;
use File::Path;
use Carp;

use lib './t/lib';

use TestParseFile;
# TEST:source "$^CURRENT_DIRNAME/lib/TestParseFile.pm";

package main;

{
    my $module_base_dir =
        File::Spec->catdir("t", "data", "MyModule-Test")
        ;

    Dist::Man->create_distro(
        distro  => 'MyModule-Test',
        modules => ['MyModule::Test', 'MyModule::Test::App'],
        dir     => $module_base_dir,
        builder => 'Module::Build',
        license => 'perl',
        author  => 'Baruch Spinoza',
        email   => 'spinoza@philosophers.tld',
        verbose => 0,
        force   => 0,
    );

    {
        my $readme = TestParseFile->new(
            {
                fn => File::Spec->catfile($module_base_dir, "README"),
            }
        );

        # TEST
        $readme->parse(qr{\AMyModule-Test\n\n}ms,
            "Starts with the package name",
        );

        # TEST
        $readme->parse(qr{\AThe README is used to introduce the module and provide instructions.*?\n\n}ms,
            "README used to introduce",
        );

        # TEST
        $readme->parse(
            qr{\AA README file is required for CPAN modules since CPAN extracts the.*?\n\n\n}ms,
            "A README file is required",
        );

        # TEST
        $readme->parse(qr{\A\n*INSTALLATION\n\nTo install this module, run the following commands:\n\n\s+\Qperl Build.PL\E\n\s+\Q./Build\E\n\s+\Q./Build test\E\n\s+\Q./Build install\E\n\n},
            "INSTALLATION section",
        );

        # TEST
        $readme->parse(qr{\ASUPPORT AND DOCUMENTATION\n\nAfter installing.*?^\s+perldoc MyModule::Test\n\n}ms,
            "Support and docs 1"
        );

        # TEST
        $readme->parse(qr{\AYou can also look for information at:\n\n\s+RT[^\n]+\n\s+\Qhttp://rt.cpan.org/NoAuth/Bugs.html?Dist=MyModule-Test\E\n\n}ms,
            "README - RT"
        );
    }

    {
        my $build_pl = TestParseFile->new(
            {
                fn => File::Spec->catfile($module_base_dir, "Build.PL"),
            }
        );

        # TEST
        $build_pl->parse(qr{\Ause strict;\nuse warnings;\nuse Module::Build;\n\n}ms,
            "Build.PL - Standard stuff at the beginning"
        );

        # TEST
        $build_pl->parse(qr{\A.*module_name *=> *'MyModule::Test',\n}ms,
            "Build.PL - module_name",
        );

        # TEST
        $build_pl->parse(qr{\A\s*license *=> *'perl',\n}ms,
            "Build.PL - license",
        );

        # TEST
        $build_pl->parse(qr{\A\s*dist_author *=> *\Qq{Baruch Spinoza <spinoza\E\@\Qphilosophers.tld>},\E\n}ms,
            "Build.PL - dist_author",
        );

        # TEST
        $build_pl->parse(qr{\A\s*dist_version_from *=> *\Q'lib/MyModule/Test.pm',\E\n}ms,
            "Build.PL - dist_version_from",
        );

        # TEST
        $build_pl->parse(
            qr/\A\s*build_requires => \{\n *\Q'Test::More' => 0\E,\n\s*\},\n/ms,
            "Build.PL - Build Requires",
        );

        # TEST
        $build_pl->parse(
            qr/\A\s*add_to_cleanup *=> \Q[ 'MyModule-Test-*' ],\E\n/ms,
            "Build.PL - add_to_cleanup",
        );

        # TEST
        $build_pl->parse(
            qr/\A\s*create_makefile_pl *=> \Q'traditional',\E\n/ms,
            "Build.PL - create_makefile_pl",
        );

    }

    {
        my $manifest = TestParseFile->new(
            {
                fn => File::Spec->catfile($module_base_dir, 'MANIFEST'),
            }
        );

        # TEST
        $manifest->consume(<<'EOF', 'MANIFEST - Contents');
Build.PL
Changes
MANIFEST
README
lib/MyModule/Test.pm
lib/MyModule/Test/App.pm
t/00-load.t
t/pod-coverage.t
t/pod.t
EOF

        # TEST
        $manifest->is_end("MANIFEST - that's all folks!");
    }

    {
        my $pod_t = TestParseFile->new(
            {
                fn => File::Spec->catfile($module_base_dir, 't', 'pod.t'),
            }
        );

        my $minimal_test_pod = "1.22";
        # TEST
        $pod_t->consume(<<"EOF", 'pod.t - contents');
#!perl -T

use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod
my \$min_tp = $minimal_test_pod;
eval "use Test::Pod \$min_tp";
plan skip_all => "Test::Pod \$min_tp required for testing POD" if \$\@;

all_pod_files_ok();
EOF

        # TEST
        $pod_t->is_end('pod.t - end.');
    }

    {
        my $pc_t = TestParseFile->new(
            {
                fn => File::Spec->catfile(
                    $module_base_dir, 't', 'pod-coverage.t'
                ),
            }
        );

        # TEST
        $pc_t->parse(
            qr/\Ause strict;\nuse warnings;\nuse Test::More;\n\n/ms,
            "pod-coverage.t - header",
        );

        my $l1 = q{eval "use Test::Pod::Coverage $min_tpc";};

        # TEST
        $pc_t->parse(
            qr/\A# Ensure a recent[^\n]+\nmy \$min_tpc = \d+\.\d+;\n\Q$l1\E\nplan skip_all[^\n]+\n *if \$\@;\n\n/ms,
            "pod-coverage.t - min_tpc block",
        );

        $l1 = q{eval "use Pod::Coverage $min_pc";};
        my $s1 = q{# Test::Pod::Coverage doesn't require a minimum };

        # TEST
        $pc_t->parse(
            qr/\A\Q$s1\E[^\n]+\n# [^\n]+\nmy \$min_pc = \d+\.\d+;\n\Q$l1\E\nplan skip_all[^\n]+\n *if \$\@;\n\n/ms,
            'pod-coverage.t - min_pod_coverage block',
        );

        # TEST
        $pc_t->parse(
            qr/all_pod_coverage_ok\(\);\n/,
            'pod-coverage.t - all_pod_coverage_ok',
        );

        # TEST
        $pc_t->is_end(
            'pod-coverage.t - EOF',
        );
    }

    {
        my $mod1 = TestParseModuleFile->new(
            {
                fn => File::Spec->catfile(
                    $module_base_dir, qw(lib MyModule Test.pm),
                ),
                perl_name   => 'MyModule::Test',
                dist_name   => 'MyModule-Test',
                author_name => 'Baruch Spinoza',
                license => 'perl',
            }
        );

        # TEST*$parse_module_start_num_tests
        $mod1->parse_module_start();

    }

    {
        my $mod2 = TestParseModuleFile->new(
            {
                fn => File::Spec->catfile(
                    $module_base_dir, qw(lib MyModule Test App.pm),
                ),
                perl_name   => 'MyModule::Test::App',
                dist_name   => 'MyModule-Test',
                author_name => 'Baruch Spinoza',
                license => 'perl',
            }
        );

        # TEST*$parse_module_start_num_tests
        $mod2->parse_module_start();

    }

    my $files_list;
    if (!$ENV{"DONT_DEL"})
    {
        rmtree ($module_base_dir, {result => \$files_list});
    }
}

{
    my $module_base_dir =
        File::Spec->catdir('t', 'data', 'Book-Park-Mansfield')
        ;

    Dist::Man->create_distro(
        distro  => 'Book-Park-Mansfield',
        modules => [
            'Book::Park::Mansfield',
            'Book::Park::Mansfield::Base',
            'Book::Park::Mansfield::FannyPrice',
            'JAUSTEN::Utils',
        ],
        dir     => $module_base_dir,
        builder => 'Module::Build',
        license => 'perl',
        author  => 'Jane Austen',
        email   => 'jane.austen@writers.tld',
        verbose => 0,
        force   => 0,
    );

    {
        my $readme = TestParseFile->new(
            {
                fn => File::Spec->catfile($module_base_dir, "README"),
            }
        );

        # TEST
        $readme->parse(qr{\ABook-Park-Mansfield\n\n}ms,
            'Starts with the package name',
        );

        # TEST
        $readme->parse(qr{\AThe README is used to introduce the module and provide instructions.*?\n\n}ms,
            'README used to introduce',
        );

        # TEST
        $readme->parse(
            qr{\AA README file is required for CPAN modules since CPAN extracts the.*?\n\n\n}ms,
            'A README file is required',
        );

        # TEST
        $readme->parse(qr{\A\n*INSTALLATION\n\nTo install this module, run the following commands:\n\n\s+\Qperl Build.PL\E\n\s+\Q./Build\E\n\s+\Q./Build test\E\n\s+\Q./Build install\E\n\n},
            'INSTALLATION section',
        );

        # TEST
        $readme->parse(qr{\ASUPPORT AND DOCUMENTATION\n\nAfter installing.*?^\s+perldoc Book::Park::Mansfield\n\n}ms,
            'Support and docs 1'
        );

        # TEST
        $readme->parse(qr{\AYou can also look for information at:\n\n\s+RT[^\n]+\n\s+\Qhttp://rt.cpan.org/NoAuth/Bugs.html?Dist=Book-Park-Mansfield\E\n\n}ms,
            'README - RT'
        );
    }

    {
        my $mod1 = TestParseModuleFile->new(
            {
                fn => File::Spec->catfile(
                    $module_base_dir, qw(lib Book Park Mansfield.pm),
                ),
                perl_name   => 'Book::Park::Mansfield',
                dist_name   => 'Book-Park-Mansfield',
                author_name => 'Jane Austen',
                license => 'perl',
            }
        );

        # TEST*$parse_module_start_num_tests
        $mod1->parse_module_start();

    }

    {
        my $jausten_mod = TestParseModuleFile->new(
            {
                fn => File::Spec->catfile(
                    $module_base_dir, qw(lib JAUSTEN Utils.pm),
                ),
                perl_name   => 'JAUSTEN::Utils',
                dist_name   => 'Book-Park-Mansfield',
                author_name => 'Jane Austen',
                license => 'perl',
            }
        );

        # TEST*$parse_module_start_num_tests
        $jausten_mod->parse_module_start();
    }

    {
        my $mod2 = TestParseModuleFile->new(
            {
                fn => File::Spec->catfile(
                    $module_base_dir, qw(lib Book Park Mansfield Base.pm),
                ),
                perl_name   => 'Book::Park::Mansfield::Base',
                dist_name   => 'Book-Park-Mansfield',
                author_name => 'Jane Austen',
                license => 'perl',
            }
        );

        # TEST*$parse_module_start_num_tests
        $mod2->parse_module_start();

    }

    my $files_list;
    if (!$ENV{'DONT_DEL_JANE'})
    {
        rmtree ($module_base_dir, {result => \$files_list});
    }
}

{
    my $module_base_dir =
        File::Spec->catdir("t", "data", "second-Book-Park-Mansfield")
        ;

    Dist::Man->create_distro(
        distro  => 'Book-Park-Mansfield',
        modules => [
            'Book::Park::Mansfield',
            'Book::Park::Mansfield::Base',
            'Book::Park::Mansfield::FannyPrice',
            'JAUSTEN::Utils',
        ],
        dir     => $module_base_dir,
        builder => 'ExtUtils::MakeMaker',
        license => 'perl',
        author  => 'Jane Austen',
        email   => 'jane.austen@writers.tld',
        verbose => 0,
        force   => 0,
    );

    {
        my $readme = TestParseFile->new(
            {
                fn => File::Spec->catfile($module_base_dir, "README"),
            }
        );

        # TEST
        $readme->parse(qr{\ABook-Park-Mansfield\n\n}ms,
            'Starts with the package name',
        );

        # TEST
        $readme->parse(qr{\AThe README is used to introduce the module and provide instructions.*?\n\n}ms,
            'README used to introduce',
        );

        # TEST
        $readme->parse(
            qr{\AA README file is required for CPAN modules since CPAN extracts the.*?\n\n\n}ms,
            'A README file is required',
        );

        # TEST
        $readme->parse(qr{\A\n*INSTALLATION\n\nTo install this module, run the following commands:\n\n\s+\Qperl Makefile.PL\E\n\s+\Qmake\E\n\s+\Qmake test\E\n\s+\Qmake install\E\n\n},
            'INSTALLATION section',
        );

        # TEST
        $readme->parse(qr{\ASUPPORT AND DOCUMENTATION\n\nAfter installing.*?^\s+perldoc Book::Park::Mansfield\n\n}ms,
            'Support and docs 1'
        );

        # TEST
        $readme->parse(qr{\AYou can also look for information at:\n\n\s+RT[^\n]+\n\s+\Qhttp://rt.cpan.org/NoAuth/Bugs.html?Dist=Book-Park-Mansfield\E\n\n}ms,
            'README - RT'
        );
    }

    {
        my $makefile_pl = TestParseFile->new(
            {
                fn => File::Spec->catfile($module_base_dir, "Makefile.PL"),
            }
        );

        # TEST
        $makefile_pl->parse(qr{\Ause strict;\nuse warnings;\nuse ExtUtils::MakeMaker;\n\n}ms,
            "Makefile.PL - Standard stuff at the beginning"
        );

        # TEST
        $makefile_pl->parse(qr{\A.*NAME *=> *'Book::Park::Mansfield',\n}ms,
            "Makefile.PL - NAME",
        );

        # TEST
        $makefile_pl->parse(qr{\A\s*AUTHOR *=> *\Qq{Jane Austen <jane.austen\E\@\Qwriters.tld>},\E\n}ms,
            "Makefile.PL - AUTHOR",
        );

        # TEST
        $makefile_pl->parse(qr{\A\s*VERSION_FROM *=> *\Q'lib/Book/Park/Mansfield.pm',\E\n}ms,
            "Makefile.PL - VERSION_FROM",
        );

        # TEST
        $makefile_pl->parse(qr{\A\s*ABSTRACT_FROM *=> *\Q'lib/Book/Park/Mansfield.pm',\E\n}ms,
            "Makefile.PL - ABSTRACT_FROM",
        );

        # TEST
        $makefile_pl->parse(qr{\A\s*\(\$ExtUtils::MakeMaker::VERSION \>= \d+\.\d+\n\s*\? \(\s*'LICENSE'\s*=>\s*'perl'\s*\)\n\s*:\s*\(\s*\)\)\s*,\n}ms,
            "Makefile.PL - LICENSE",
        );

        # TEST
        $makefile_pl->parse(qr{\A\s*PL_FILES *=> *\{\},\n}ms,
            "Makefile.PL - PL_FILES",
        );

        # TEST
        $makefile_pl->parse(qr{\A\s*PREREQ_PM *=> *\{\n\s*'Test::More' *=> *0,\n\s*\},\n}ms,
            "Makefile.PL - PREREQ_PM",
        );

    }

    {
        my $manifest = TestParseFile->new(
            {
                fn => File::Spec->catfile($module_base_dir, 'MANIFEST'),
            }
        );

        my $contents = <<'EOF';
Changes
MANIFEST
Makefile.PL
README
lib/Book/Park/Mansfield.pm
lib/Book/Park/Mansfield/Base.pm
lib/Book/Park/Mansfield/FannyPrice.pm
lib/JAUSTEN/Utils.pm
t/00-load.t
t/pod-coverage.t
t/pod.t
EOF

        # TEST
        $manifest->consume(
            $contents,
            "MANIFEST for Makefile.PL'ed Module",
        );

        # TEST
        $manifest->is_end("MANIFEST - that's all folks!");
    }

    {
        my $mod1 = TestParseModuleFile->new(
            {
                fn => File::Spec->catfile(
                    $module_base_dir, qw(lib Book Park Mansfield.pm),
                ),
                perl_name   => 'Book::Park::Mansfield',
                dist_name   => 'Book-Park-Mansfield',
                author_name => 'Jane Austen',
                license => 'perl',
            }
        );

        # TEST*$parse_module_start_num_tests
        $mod1->parse_module_start();

    }

    {
        my $jausten_mod = TestParseModuleFile->new(
            {
                fn => File::Spec->catfile(
                    $module_base_dir, qw(lib JAUSTEN Utils.pm),
                ),
                perl_name   => 'JAUSTEN::Utils',
                dist_name   => 'Book-Park-Mansfield',
                author_name => 'Jane Austen',
                license => 'perl',
            }
        );

        # TEST*$parse_module_start_num_tests
        $jausten_mod->parse_module_start();
    }

    {
        my $mod2 = TestParseModuleFile->new(
            {
                fn => File::Spec->catfile(
                    $module_base_dir, qw(lib Book Park Mansfield Base.pm),
                ),
                perl_name   => 'Book::Park::Mansfield::Base',
                dist_name   => 'Book-Park-Mansfield',
                author_name => 'Jane Austen',
                license => 'perl',
            }
        );

        # TEST*$parse_module_start_num_tests
        $mod2->parse_module_start();

    }

    my $files_list;
    if (!$ENV{'DONT_DEL_JANE2'}) {
        rmtree ($module_base_dir, {result => \$files_list});
    }
}

{
    my $module_base_dir =
        File::Spec->catdir("t", "data", "x11l-Book-Park-Mansfield")
        ;

    Dist::Man->create_distro(
        distro  => 'Book-Park-Mansfield',
        modules => [
            'Book::Park::Mansfield',
            'Book::Park::Mansfield::Base',
            'Book::Park::Mansfield::FannyPrice',
            'JAUSTEN::Utils',
        ],
        dir     => $module_base_dir,
        builder => 'ExtUtils::MakeMaker',
        license => 'mit',
        author  => 'Jane Austen',
        email   => 'jane.austen@writers.tld',
        verbose => 0,
        force   => 0,
    );

    {
        my $readme = TestParseFile->new(
            {
                fn => File::Spec->catfile($module_base_dir, "README"),
            }
        );

        # TEST
        $readme->parse(qr{\ABook-Park-Mansfield\n\n}ms,
            'Starts with the package name',
        );

        # TEST
        $readme->parse(qr{\AThe README is used to introduce the module and provide instructions.*?\n\n}ms,
            'README used to introduce',
        );

        # TEST
        $readme->parse(
            qr{\AA README file is required for CPAN modules since CPAN extracts the.*?\n\n\n}ms,
            'A README file is required',
        );

        # TEST
        $readme->parse(qr{\A\n*INSTALLATION\n\nTo install this module, run the following commands:\n\n\s+\Qperl Makefile.PL\E\n\s+\Qmake\E\n\s+\Qmake test\E\n\s+\Qmake install\E\n\n},
            'INSTALLATION section',
        );

        # TEST
        $readme->parse(qr{\ASUPPORT AND DOCUMENTATION\n\nAfter installing.*?^\s+perldoc Book::Park::Mansfield\n\n}ms,
            'Support and docs 1'
        );

        # TEST
        $readme->parse(qr{\AYou can also look for information at:\n\n\s+RT[^\n]+\n\s+\Qhttp://rt.cpan.org/NoAuth/Bugs.html?Dist=Book-Park-Mansfield\E\n\n}ms,
            'README - RT'
        );
    }

    {
        my $makefile_pl = TestParseFile->new(
            {
                fn => File::Spec->catfile($module_base_dir, "Makefile.PL"),
            }
        );

        # TEST
        $makefile_pl->parse(qr{\Ause strict;\nuse warnings;\nuse ExtUtils::MakeMaker;\n\n}ms,
            "Makefile.PL - Standard stuff at the beginning"
        );

        # TEST
        $makefile_pl->parse(qr{\A.*NAME *=> *'Book::Park::Mansfield',\n}ms,
            "Makefile.PL - NAME",
        );

        # TEST
        $makefile_pl->parse(qr{\A\s*AUTHOR *=> *\Qq{Jane Austen <jane.austen\E\@\Qwriters.tld>},\E\n}ms,
            "Makefile.PL - AUTHOR",
        );

        # TEST
        $makefile_pl->parse(qr{\A\s*VERSION_FROM *=> *\Q'lib/Book/Park/Mansfield.pm',\E\n}ms,
            "Makefile.PL - VERSION_FROM",
        );

        # TEST
        $makefile_pl->parse(qr{\A\s*ABSTRACT_FROM *=> *\Q'lib/Book/Park/Mansfield.pm',\E\n}ms,
            "Makefile.PL - ABSTRACT_FROM",
        );

        # TEST
        $makefile_pl->parse(qr{\A\s*\(\$ExtUtils::MakeMaker::VERSION \>= \d+\.\d+\n\s*\? \(\s*'LICENSE'\s*=>\s*'mit'\s*\)\n\s*:\s*\(\s*\)\)\s*,\n}ms,
            "Makefile.PL - LICENSE",
        );

        # TEST
        $makefile_pl->parse(qr{\A\s*PL_FILES *=> *\{\},\n}ms,
            "Makefile.PL - PL_FILES",
        );

        # TEST
        $makefile_pl->parse(qr{\A\s*PREREQ_PM *=> *\{\n\s*'Test::More' *=> *0,\n\s*\},\n}ms,
            "Makefile.PL - PREREQ_PM",
        );

    }

    {
        my $manifest = TestParseFile->new(
            {
                fn => File::Spec->catfile($module_base_dir, 'MANIFEST'),
            }
        );

        my $contents = <<'EOF';
Changes
MANIFEST
Makefile.PL
README
lib/Book/Park/Mansfield.pm
lib/Book/Park/Mansfield/Base.pm
lib/Book/Park/Mansfield/FannyPrice.pm
lib/JAUSTEN/Utils.pm
t/00-load.t
t/pod-coverage.t
t/pod.t
EOF

        # TEST
        $manifest->consume(
            $contents,
            "MANIFEST for Makefile.PL'ed Module",
        );

        # TEST
        $manifest->is_end("MANIFEST - that's all folks!");
    }

    {
        my $mod1 = TestParseModuleFile->new(
            {
                fn => File::Spec->catfile(
                    $module_base_dir, qw(lib Book Park Mansfield.pm),
                ),
                perl_name   => 'Book::Park::Mansfield',
                dist_name   => 'Book-Park-Mansfield',
                author_name => 'Jane Austen',
                license => 'mit',
            }
        );

        # TEST*$parse_module_start_num_tests
        $mod1->parse_module_start();

    }

    {
        my $jausten_mod = TestParseModuleFile->new(
            {
                fn => File::Spec->catfile(
                    $module_base_dir, qw(lib JAUSTEN Utils.pm),
                ),
                perl_name   => 'JAUSTEN::Utils',
                dist_name   => 'Book-Park-Mansfield',
                author_name => 'Jane Austen',
                license => 'mit',
            }
        );

        # TEST*$parse_module_start_num_tests
        $jausten_mod->parse_module_start();
    }

    {
        my $mod2 = TestParseModuleFile->new(
            {
                fn => File::Spec->catfile(
                    $module_base_dir, qw(lib Book Park Mansfield Base.pm),
                ),
                perl_name   => 'Book::Park::Mansfield::Base',
                dist_name   => 'Book-Park-Mansfield',
                author_name => 'Jane Austen',
                license => 'mit',
            }
        );

        # TEST*$parse_module_start_num_tests
        $mod2->parse_module_start();

    }

    my $files_list;
    if (!$ENV{'DONT_DEL_X11L'}) {
        rmtree ($module_base_dir, {result => \$files_list});
    }
}

{
    my $module_base_dir =
        File::Spec->catdir("t", "data", "bsdl-Book-Park-Mansfield")
        ;

    Dist::Man->create_distro(
        distro  => 'Book-Park-Mansfield',
        modules => [
            'Book::Park::Mansfield',
            'Book::Park::Mansfield::Base',
            'Book::Park::Mansfield::FannyPrice',
            'JAUSTEN::Utils',
        ],
        dir     => $module_base_dir,
        builder => 'ExtUtils::MakeMaker',
        license => 'bsd',
        author  => 'Jane Austen',
        email   => 'jane.austen@writers.tld',
        verbose => 0,
        force   => 0,
    );

    {
        my $readme = TestParseFile->new(
            {
                fn => File::Spec->catfile($module_base_dir, "README"),
            }
        );

        # TEST
        $readme->parse(qr{\ABook-Park-Mansfield\n\n}ms,
            'Starts with the package name',
        );

        # TEST
        $readme->parse(qr{\AThe README is used to introduce the module and provide instructions.*?\n\n}ms,
            'README used to introduce',
        );

        # TEST
        $readme->parse(
            qr{\AA README file is required for CPAN modules since CPAN extracts the.*?\n\n\n}ms,
            'A README file is required',
        );

        # TEST
        $readme->parse(qr{\A\n*INSTALLATION\n\nTo install this module, run the following commands:\n\n\s+\Qperl Makefile.PL\E\n\s+\Qmake\E\n\s+\Qmake test\E\n\s+\Qmake install\E\n\n},
            'INSTALLATION section',
        );

        # TEST
        $readme->parse(qr{\ASUPPORT AND DOCUMENTATION\n\nAfter installing.*?^\s+perldoc Book::Park::Mansfield\n\n}ms,
            'Support and docs 1'
        );

        # TEST
        $readme->parse(qr{\AYou can also look for information at:\n\n\s+RT[^\n]+\n\s+\Qhttp://rt.cpan.org/NoAuth/Bugs.html?Dist=Book-Park-Mansfield\E\n\n}ms,
            'README - RT'
        );
    }

    {
        my $makefile_pl = TestParseFile->new(
            {
                fn => File::Spec->catfile($module_base_dir, "Makefile.PL"),
            }
        );

        # TEST
        $makefile_pl->parse(qr{\Ause strict;\nuse warnings;\nuse ExtUtils::MakeMaker;\n\n}ms,
            "Makefile.PL - Standard stuff at the beginning"
        );

        # TEST
        $makefile_pl->parse(qr{\A.*NAME *=> *'Book::Park::Mansfield',\n}ms,
            "Makefile.PL - NAME",
        );

        # TEST
        $makefile_pl->parse(qr{\A\s*AUTHOR *=> *\Qq{Jane Austen <jane.austen\E\@\Qwriters.tld>},\E\n}ms,
            "Makefile.PL - AUTHOR",
        );

        # TEST
        $makefile_pl->parse(qr{\A\s*VERSION_FROM *=> *\Q'lib/Book/Park/Mansfield.pm',\E\n}ms,
            "Makefile.PL - VERSION_FROM",
        );

        # TEST
        $makefile_pl->parse(qr{\A\s*ABSTRACT_FROM *=> *\Q'lib/Book/Park/Mansfield.pm',\E\n}ms,
            "Makefile.PL - ABSTRACT_FROM",
        );

        # TEST
        $makefile_pl->parse(qr{\A\s*\(\$ExtUtils::MakeMaker::VERSION \>= \d+\.\d+\n\s*\? \(\s*'LICENSE'\s*=>\s*'bsd'\s*\)\n\s*:\s*\(\s*\)\)\s*,\n}ms,
            "Makefile.PL - LICENSE",
        );

        # TEST
        $makefile_pl->parse(qr{\A\s*PL_FILES *=> *\{\},\n}ms,
            "Makefile.PL - PL_FILES",
        );

        # TEST
        $makefile_pl->parse(qr{\A\s*PREREQ_PM *=> *\{\n\s*'Test::More' *=> *0,\n\s*\},\n}ms,
            "Makefile.PL - PREREQ_PM",
        );

    }

    {
        my $manifest = TestParseFile->new(
            {
                fn => File::Spec->catfile($module_base_dir, 'MANIFEST'),
            }
        );

        my $contents = <<'EOF';
Changes
MANIFEST
Makefile.PL
README
lib/Book/Park/Mansfield.pm
lib/Book/Park/Mansfield/Base.pm
lib/Book/Park/Mansfield/FannyPrice.pm
lib/JAUSTEN/Utils.pm
t/00-load.t
t/pod-coverage.t
t/pod.t
EOF

        # TEST
        $manifest->consume(
            $contents,
            "MANIFEST for Makefile.PL'ed Module",
        );

        # TEST
        $manifest->is_end("MANIFEST - that's all folks!");
    }

    {
        my $mod1 = TestParseModuleFile->new(
            {
                fn => File::Spec->catfile(
                    $module_base_dir, qw(lib Book Park Mansfield.pm),
                ),
                perl_name   => 'Book::Park::Mansfield',
                dist_name   => 'Book-Park-Mansfield',
                author_name => 'Jane Austen',
                license => 'bsd',
            }
        );

        # TEST*$parse_module_start_num_tests
        $mod1->parse_module_start();

    }

    {
        my $jausten_mod = TestParseModuleFile->new(
            {
                fn => File::Spec->catfile(
                    $module_base_dir, qw(lib JAUSTEN Utils.pm),
                ),
                perl_name   => 'JAUSTEN::Utils',
                dist_name   => 'Book-Park-Mansfield',
                author_name => 'Jane Austen',
                license => 'bsd',
            }
        );

        # TEST*$parse_module_start_num_tests
        $jausten_mod->parse_module_start();
    }

    {
        my $mod2 = TestParseModuleFile->new(
            {
                fn => File::Spec->catfile(
                    $module_base_dir, qw(lib Book Park Mansfield Base.pm),
                ),
                perl_name   => 'Book::Park::Mansfield::Base',
                dist_name   => 'Book-Park-Mansfield',
                author_name => 'Jane Austen',
                license => 'bsd',
            }
        );

        # TEST*$parse_module_start_num_tests
        $mod2->parse_module_start();

    }

    my $files_list;
    if (!$ENV{'DONT_DEL_BSDL'}) {
        rmtree ($module_base_dir, {result => \$files_list});
    }
}

{
    my $module_base_dir =
        File::Spec->catdir('t', 'data', 'gpl-Book-Park-Mansfield')
        ;

    Dist::Man->create_distro(
        distro  => 'Book-Park-Mansfield',
        modules => [
            'Book::Park::Mansfield',
            'Book::Park::Mansfield::Base',
            'Book::Park::Mansfield::FannyPrice',
            'JAUSTEN::Utils',
        ],
        dir     => $module_base_dir,
        builder => 'Module::Build',
        license => 'gpl',
        author  => 'Jane Austen',
        email   => 'jane.austen@writers.tld',
        verbose => 0,
        force   => 0,
    );

    {
        my $readme = TestParseFile->new(
            {
                fn => File::Spec->catfile($module_base_dir, "README"),
            }
        );

        # TEST
        $readme->parse(qr{\ABook-Park-Mansfield\n\n}ms,
            'Starts with the package name',
        );

        # TEST
        $readme->parse(qr{\AThe README is used to introduce the module and provide instructions.*?\n\n}ms,
            'README used to introduce',
        );

        # TEST
        $readme->parse(
            qr{\AA README file is required for CPAN modules since CPAN extracts the.*?\n\n\n}ms,
            'A README file is required',
        );

        # TEST
        $readme->parse(qr{\A\n*INSTALLATION\n\nTo install this module, run the following commands:\n\n\s+\Qperl Build.PL\E\n\s+\Q./Build\E\n\s+\Q./Build test\E\n\s+\Q./Build install\E\n\n},
            'INSTALLATION section',
        );

        # TEST
        $readme->parse(qr{\ASUPPORT AND DOCUMENTATION\n\nAfter installing.*?^\s+perldoc Book::Park::Mansfield\n\n}ms,
            'Support and docs 1'
        );

        # TEST
        $readme->parse(qr{\AYou can also look for information at:\n\n\s+RT[^\n]+\n\s+\Qhttp://rt.cpan.org/NoAuth/Bugs.html?Dist=Book-Park-Mansfield\E\n\n}ms,
            'README - RT'
        );
    }

    {
        my $mod1 = TestParseModuleFile->new(
            {
                fn => File::Spec->catfile(
                    $module_base_dir, qw(lib Book Park Mansfield.pm),
                ),
                perl_name   => 'Book::Park::Mansfield',
                dist_name   => 'Book-Park-Mansfield',
                author_name => 'Jane Austen',
                license => 'gpl',
            }
        );

        # TEST*$parse_module_start_num_tests
        $mod1->parse_module_start();

    }

    {
        my $jausten_mod = TestParseModuleFile->new(
            {
                fn => File::Spec->catfile(
                    $module_base_dir, qw(lib JAUSTEN Utils.pm),
                ),
                perl_name   => 'JAUSTEN::Utils',
                dist_name   => 'Book-Park-Mansfield',
                author_name => 'Jane Austen',
                license => 'gpl',
            }
        );

        # TEST*$parse_module_start_num_tests
        $jausten_mod->parse_module_start();
    }

    {
        my $mod2 = TestParseModuleFile->new(
            {
                fn => File::Spec->catfile(
                    $module_base_dir, qw(lib Book Park Mansfield Base.pm),
                ),
                perl_name   => 'Book::Park::Mansfield::Base',
                dist_name   => 'Book-Park-Mansfield',
                author_name => 'Jane Austen',
                license => 'gpl',
            }
        );

        # TEST*$parse_module_start_num_tests
        $mod2->parse_module_start();

    }

    my $files_list;
    if (!$ENV{'DONT_DEL_GPL'})
    {
        rmtree ($module_base_dir, {result => \$files_list});
    }
}

{
    my $module_base_dir =
        File::Spec->catdir('t', 'data', 'lgpl-Book-Park-Mansfield')
        ;

    Dist::Man->create_distro(
        distro  => 'Book-Park-Mansfield',
        modules => [
            'Book::Park::Mansfield',
            'Book::Park::Mansfield::Base',
            'Book::Park::Mansfield::FannyPrice',
            'JAUSTEN::Utils',
        ],
        dir     => $module_base_dir,
        builder => 'Module::Build',
        license => 'lgpl',
        author  => 'Jane Austen',
        email   => 'jane.austen@writers.tld',
        verbose => 0,
        force   => 0,
    );

    {
        my $readme = TestParseFile->new(
            {
                fn => File::Spec->catfile($module_base_dir, "README"),
            }
        );

        # TEST
        $readme->parse(qr{\ABook-Park-Mansfield\n\n}ms,
            'Starts with the package name',
        );

        # TEST
        $readme->parse(qr{\AThe README is used to introduce the module and provide instructions.*?\n\n}ms,
            'README used to introduce',
        );

        # TEST
        $readme->parse(
            qr{\AA README file is required for CPAN modules since CPAN extracts the.*?\n\n\n}ms,
            'A README file is required',
        );

        # TEST
        $readme->parse(qr{\A\n*INSTALLATION\n\nTo install this module, run the following commands:\n\n\s+\Qperl Build.PL\E\n\s+\Q./Build\E\n\s+\Q./Build test\E\n\s+\Q./Build install\E\n\n},
            'INSTALLATION section',
        );

        # TEST
        $readme->parse(qr{\ASUPPORT AND DOCUMENTATION\n\nAfter installing.*?^\s+perldoc Book::Park::Mansfield\n\n}ms,
            'Support and docs 1'
        );

        # TEST
        $readme->parse(qr{\AYou can also look for information at:\n\n\s+RT[^\n]+\n\s+\Qhttp://rt.cpan.org/NoAuth/Bugs.html?Dist=Book-Park-Mansfield\E\n\n}ms,
            'README - RT'
        );
    }

    {
        my $mod1 = TestParseModuleFile->new(
            {
                fn => File::Spec->catfile(
                    $module_base_dir, qw(lib Book Park Mansfield.pm),
                ),
                perl_name   => 'Book::Park::Mansfield',
                dist_name   => 'Book-Park-Mansfield',
                author_name => 'Jane Austen',
                license => 'lgpl',
            }
        );

        # TEST*$parse_module_start_num_tests
        $mod1->parse_module_start();

    }

    {
        my $jausten_mod = TestParseModuleFile->new(
            {
                fn => File::Spec->catfile(
                    $module_base_dir, qw(lib JAUSTEN Utils.pm),
                ),
                perl_name   => 'JAUSTEN::Utils',
                dist_name   => 'Book-Park-Mansfield',
                author_name => 'Jane Austen',
                license => 'lgpl',
            }
        );

        # TEST*$parse_module_start_num_tests
        $jausten_mod->parse_module_start();
    }

    {
        my $mod2 = TestParseModuleFile->new(
            {
                fn => File::Spec->catfile(
                    $module_base_dir, qw(lib Book Park Mansfield Base.pm),
                ),
                perl_name   => 'Book::Park::Mansfield::Base',
                dist_name   => 'Book-Park-Mansfield',
                author_name => 'Jane Austen',
                license => 'lgpl',
            }
        );

        # TEST*$parse_module_start_num_tests
        $mod2->parse_module_start();

    }

    my $files_list;
    if (!$ENV{'DONT_DEL_LGPL'})
    {
        rmtree ($module_base_dir, {result => \$files_list});
    }
}


=head1 NAME

t/test-dist.t - test the integrity of prepared distributions.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>

=head1 COPYRIGHT AND LICENSE

Copyright by Shlomi Fish, 2009. This file is available under the MIT/X11 
License:

L<http://www.opensource.org/licenses/mit-license.php>
