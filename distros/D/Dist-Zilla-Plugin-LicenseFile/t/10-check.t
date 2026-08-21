use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => "Dist::Zilla::Tester not installed"
        unless eval { require Dist::Zilla::Tester; 1 };
}

use Dist::Zilla::Tester;
use Path::Tiny;
use File::Temp qw(tempdir);
use Software::License::Perl_5;

# The text [LicenseFile] expects to find committed in the repository: the bare
# licence, without the copyright notice ->fulltext puts above it.
sub wanted_license {
    Software::License::Perl_5->new({
        holder => 'Test',
        year   => 2026,
    })->license;
}

sub build_dist {
    my (%arg) = @_;

    my $dist_dir = path(tempdir(CLEANUP => 1), 'dist');
    $dist_dir->mkpath;

    my $plugin_config = $arg{plugin_config} // '';
    $dist_dir->child('dist.ini')->spew_utf8(<<"DIST");
name = Test-Dist
version = 0.001
author = Test <test\@test.de>
license = Perl_5
copyright_holder = Test
copyright_year = 2026

[GatherDir]

[LicenseFile]
$plugin_config
DIST

    $dist_dir->child('lib')->mkpath;
    $dist_dir->child('lib', 'Test', 'Dist.pm')->parent->mkpath;
    $dist_dir->child('lib', 'Test', 'Dist.pm')->spew_utf8("package Test::Dist;\n# ABSTRACT: a test distribution\n1;\n");

    $dist_dir->child('LICENSE')->spew_utf8($arg{license}) if defined $arg{license};

    my $tzil = Dist::Zilla::Tester->from_config({ dist_root => "$dist_dir" });
    my $error;
    eval { $tzil->build; 1 } or $error = $@;

    return ($tzil, $error);
}

subtest 'a committed LICENSE matching the dist metadata builds' => sub {
    my ($tzil, $error) = build_dist(license => wanted_license());
    is($error, undef, 'build succeeded');
    my ($file) = grep { $_->name eq 'LICENSE' } @{ $tzil->files };
    ok($file, 'LICENSE is part of the distribution');
    is($file->content, wanted_license(), 'and it is the committed file, unmodified');
};

subtest 'a missing LICENSE aborts the build' => sub {
    my ($tzil, $error) = build_dist();
    ok($error, 'build aborted');
    like($error, qr/dzil genlicense/, 'and the message says how to fix it');
};

subtest 'a stale LICENSE aborts the build' => sub {
    my ($tzil, $error) = build_dist(license => "The Artistic License 2.0\n");
    ok($error, 'build aborted');
    like($error, qr/out of date/i, 'and the message says the file no longer matches');
    like($error, qr/dzil genlicense/, 'and how to fix it');
};

subtest 'required = 0 downgrades both checks to a warning' => sub {
    my ($tzil, $error) = build_dist(plugin_config => 'required = 0');
    is($error, undef, 'build succeeded without a LICENSE');
    ok(
        (grep { /LICENSE/ } @{ $tzil->log_messages }),
        'but the missing file was still reported',
    );
};

subtest 'trailing whitespace does not count as drift' => sub {
    my ($tzil, $error) = build_dist(license => wanted_license() . "\n\n");
    is($error, undef, 'build succeeded');
};

done_testing;
