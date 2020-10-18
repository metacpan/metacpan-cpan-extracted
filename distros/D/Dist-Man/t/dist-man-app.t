#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

use Dist::Man::App;
use File::Spec;
use File::Path;
use Carp;

use lib './t/lib';
use TestParseFile;

my $module_base_dir =
    File::Spec->catdir("t", "data", "mymodule-dir")
    ;

{
    local @ARGV = (qw(setup --mb --module=MyModule::Test),
        "--dir=$module_base_dir",
        qw(--distro=MyModule-Test --author=ShlomiFish
        --email=shlomif@cpan.org --license=mit --verbose
        ),
    );

    Dist::Man::App->run();
}

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

if (!$ENV{"DONT_DEL"})
{
    rmtree ($module_base_dir);
}

=head1 NAME

t/test-dist.t - test the integrity of prepared distributions.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>

=head1 COPYRIGHT AND LICENSE

Copyright by Shlomi Fish, 2009. This file is available under the MIT/X11
License:

L<http://www.opensource.org/licenses/mit-license.php>
