#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

sub not_in_file_ok {
    my ($filename, %regex) = @_;
    open( my $fh, '<', $filename )
        or die "couldn't open $filename for reading: $!";

    my %violated;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }

    for my $test (keys %regex) {
        ok !$violated{$test}, $test or diag "$test appears on lines @{$violated{$test}}";
    }
}

sub module_boilerplate_ok {
    my ($module) = @_;
    subtest $module => sub {
        not_in_file_ok($module =>
            'the great new $MODULENAME' => qr/ - The great new /,
            'boilerplate description'   => qr/Quick summary of what the module/,
            'stub function definition'  => qr/function[12]/,
            'module description'        => qr/One-line description of module/,
            'description'               => qr/A full description of the module/,
            'subs / methods'            => qr/section listing the public components/,
            'diagnostics'               => qr/A list of every error and warning message/,
            'config and environment'    => qr/A full explanation of any configuration/,
            'dependencies'              => qr/A list of all of the other modules that this module relies upon/,
            'incompatible'              => qr/any modules that this module cannot be used/,
            'bugs and limitations'      => qr/A list of known problems/,
            'contact details'           => qr/<contact address>/,
        );
    };
}

subtest 'README' => sub {
    not_in_file_ok(('README.md') =>
        "The README is used..."       => qr/The README is used/,
        "'version information here'"  => qr/to provide version information/,
    );
};

subtest 'Changes' => sub {
    not_in_file_ok(Changes =>
        "placeholder date/time"       => qr(Date/time)
    );
};

module_boilerplate_ok('bin/group-git');
module_boilerplate_ok('lib/Group/Git.pm');
module_boilerplate_ok('lib/Group/Git/Bitbucket.pm');
module_boilerplate_ok('lib/Group/Git/Cmd/Branch.pm');
module_boilerplate_ok('lib/Group/Git/Cmd/Grep.pm');
module_boilerplate_ok('lib/Group/Git/Cmd/Help.pm');
module_boilerplate_ok('lib/Group/Git/Cmd/List.pm');
module_boilerplate_ok('lib/Group/Git/Cmd/Pull.pm');
module_boilerplate_ok('lib/Group/Git/Cmd/Sh.pm');
module_boilerplate_ok('lib/Group/Git/Cmd/State.pm');
module_boilerplate_ok('lib/Group/Git/Cmd/Status.pm');
module_boilerplate_ok('lib/Group/Git/Cmd/TagList.pm');
module_boilerplate_ok('lib/Group/Git/Cmd/Watch.pm');
module_boilerplate_ok('lib/Group/Git/Examples.pod');
module_boilerplate_ok('lib/Group/Git/Github.pm');
module_boilerplate_ok('lib/Group/Git/Gitosis.pm');
module_boilerplate_ok('lib/Group/Git/Repo.pm');
module_boilerplate_ok('lib/Group/Git/Stash.pm');
module_boilerplate_ok('lib/Group/Git/Taggers.pm');
module_boilerplate_ok('lib/Group/Git/Taggers/Local.pm');
module_boilerplate_ok('lib/Group/Git/Taggers/Remote.pm');
done_testing();
