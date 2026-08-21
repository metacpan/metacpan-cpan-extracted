use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => "Dist::Zilla::App::Tester not installed"
        unless eval { require Dist::Zilla::App::Tester; 1 };
}

use Dist::Zilla::App::Tester;
use Dist::Zilla::Tester;
use Path::Tiny;
use File::Temp qw(tempdir);
use Software::License::Perl_5;

sub wanted_license {
    Software::License::Perl_5->new({
        holder => 'Test',
        year   => 2026,
    })->license;
}

# A source tree for test_dzil() to copy. $with_plugin decides whether the dist
# also runs the [LicenseFile] check on build.
sub source_dist {
    my (%arg) = @_;

    my $dist_dir = path(tempdir(CLEANUP => 1), 'dist');
    $dist_dir->mkpath;

    my $check = $arg{with_plugin} ? "\n[LicenseFile]\n" : '';
    $dist_dir->child('dist.ini')->spew_utf8(<<"DIST");
name = Test-Dist
version = 0.001
author = Test <test\@test.de>
license = Perl_5
copyright_holder = Test
copyright_year = 2026

[GatherDir]
$check
DIST

    $dist_dir->child('lib', 'Test', 'Dist.pm')->parent->mkpath;
    $dist_dir->child('lib', 'Test', 'Dist.pm')
        ->spew_utf8("package Test::Dist;\n# ABSTRACT: a test distribution\n1;\n");

    $dist_dir->child('LICENSE')->spew_utf8($arg{license}) if defined $arg{license};

    return "$dist_dir";
}

sub written_license {
    my ($result) = @_;
    return path($result->tempdir, 'source', 'LICENSE')->slurp_utf8;
}

subtest 'writes LICENSE from the dist metadata' => sub {
    my $result = test_dzil(source_dist(), ['genlicense']);
    is($result->exit_code, 0, 'exit code 0')
        or diag $result->error // $result->output;
    like($result->output, qr/wrote LICENSE/, 'says it wrote the file');
    is(written_license($result), wanted_license(), 'and the text is the bare licence');
};

subtest 'is idempotent' => sub {
    my $result = test_dzil(source_dist(license => wanted_license()), ['genlicense']);
    is($result->exit_code, 0, 'exit code 0');
    like($result->output, qr/LICENSE is up to date/, 'reports no change');
    is(written_license($result), wanted_license(), 'file untouched');
};

subtest 'overwrites a stale LICENSE' => sub {
    my $result = test_dzil(source_dist(license => "something else entirely\n"), ['genlicense']);
    is($result->exit_code, 0, 'exit code 0');
    like($result->output, qr/wrote LICENSE/, 'says it wrote the file');
    is(written_license($result), wanted_license(), 'stale text replaced');
};

subtest 'what it writes is what the plugin accepts' => sub {
    my $source = source_dist(with_plugin => 1);

    my $result = test_dzil($source, ['genlicense']);
    is($result->exit_code, 0, 'genlicense ran')
        or diag $result->error // $result->output;

    # Feed the file it just wrote back into a build guarded by [LicenseFile].
    path($source, 'LICENSE')->spew_utf8(written_license($result));

    my $tzil = Dist::Zilla::Tester->from_config({ dist_root => $source });
    my $error;
    eval { $tzil->build; 1 } or $error = $@;
    is($error, undef, 'the guarded build passes with it');
};

done_testing;
