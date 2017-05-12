use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use Test::MinimumVersion;
use Perl::PrereqScanner 1.016; # don't skip "lib"
use Module::CoreList 2.77;
use version;
use File::pushd 'pushd';

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MakeMaker => ],
                [ ExecDir => ],
                [ 'Test::Compile' => {  # use ALL the features!
                    fake_home => 1,
                    needs_display => 1,
                    fail_on_warning => 'all',
                    bail_out_on_fail => 1,
                } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            path(qw(source bin foo)) => "#!/usr/bin/perl\nprint qq{hello!\n}\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child(qw(t 00-compile.t));
ok( -e $file, 'test created');

# here we perform a static analysis of the file generated:
# - check minimum perl version
# - check prereqs required by this file - analyse for core (against latest perl)

my $minimum_perl = version->parse('5.006002');  # minimum perl for any version of the prereq
my $in_core_perl = version->parse('5.012000');  # minimum perl to contain the version we use

minimum_version_ok($file->stringify, $minimum_perl) or diag `perlver --blame $file`;

my $scanner = Perl::PrereqScanner->new();
my $file_req = $scanner->scan_string(scalar $file->slurp_utf8);

my $req_hash = $file_req->as_string_hash;

# TODO: this code should really be pulled out into its own dist.

foreach my $prereq (keys %$req_hash)
{
    next if $prereq eq 'perl';
    my $added_in = Module::CoreList->first_release($prereq);

    # this code is borrowed ethusiastically from [OnlyCorePrereqs]
    ok(defined($added_in), "$prereq is available in core") or next;

    ok(
        version->parse($added_in) <= $minimum_perl,
        "$prereq was available in perl $minimum_perl",
    ) or note("$prereq was not added until $added_in"), next;

    # get the version that was in core for our minimum
    my $has = $Module::CoreList::version{$in_core_perl->numify}{$prereq};
    $has = version->parse($has);    # version.pm XS hates tie() - RT#87983

    # see if our req is satisfied
    ok(
        $file_req->accepts_module($prereq => $has),
        "perl $in_core_perl has $prereq $req_hash->{$prereq}",
    ) or note('detected a dependency on '
        . $prereq . ' ' . $req_hash->{$prereq} . ': perl ' . $in_core_perl
        . ' only has ' . $has), next;


    my $deprecated_in = Module::CoreList->deprecated_in($prereq);
    ok(!$deprecated_in, "$prereq has not been ejected from core")
        or note 'detected a dependency that was deprecated from core in '
            . $deprecated_in . ': '. $prereq;
}

subtest 'run the generated test' => sub
{
    my $wd = pushd $build_dir;
    $tzil->plugin_named('MakeMaker')->build;

    # let tests run, rather than skip_all
    local $ENV{DISPLAY} = 'something';

    do $file;
    note 'ran tests successfully' if not $@;
    fail($@) if $@;
};

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
