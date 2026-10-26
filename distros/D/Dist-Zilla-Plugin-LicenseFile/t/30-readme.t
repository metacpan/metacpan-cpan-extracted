use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

# README.md lives in the repository only; the built dist ships a README
# generated from POD instead.
my $readme_md = "$Bin/../README.md";

BEGIN {
    plan skip_all => "Dist::Zilla::Tester not installed"
        unless eval { require Dist::Zilla::Tester; 1 };
}
plan skip_all => "README.md is not part of the built distribution"
    unless -f $readme_md;

use Dist::Zilla::Tester;
use Path::Tiny;
use File::Temp qw(tempdir);

# README.md quotes the out-of-date failure verbatim. The quote is hand
# maintained, so this is the only thing that notices when it drifts from what
# munge_files really emits.

sub squash {
    my ($text) = @_;
    $text =~ s{\s+}{ }g;
    $text =~ s{\A }{};
    $text =~ s{ \z}{};
    return $text;
}

my $dist_dir = path(tempdir(CLEANUP => 1), 'dist');
$dist_dir->mkpath;
$dist_dir->child('dist.ini')->spew_utf8(<<'DIST');
name = Test-Dist
version = 0.001
author = Test <test@test.de>
license = Perl_5
copyright_holder = Test
copyright_year = 2026

[GatherDir]

[LicenseFile]
DIST
$dist_dir->child('lib', 'Test')->mkpath;
$dist_dir->child('lib', 'Test', 'Dist.pm')->spew_utf8("package Test::Dist;\n# ABSTRACT: a test distribution\n1;\n");
$dist_dir->child('LICENSE')->spew_utf8("The Artistic License 2.0\n");

my $tzil = Dist::Zilla::Tester->from_config({ dist_root => "$dist_dir" });
my $error;
eval { $tzil->build; 1 } or $error = $@;
ok($error, 'a stale LICENSE aborts the build');

my ($message) = squash("$error") =~ m{(\[LicenseFile\] .*?commit the file)};
ok($message, 'the failure carries the [LicenseFile] message') or diag $error;

my $readme = path($readme_md)->slurp_utf8;
my ($quote) = $readme =~ m{^```\n(\[LicenseFile\] .*?)\n```}ms;
ok($quote, 'README.md quotes a [LicenseFile] failure') or diag $readme;

is(squash($quote // ''), $message // '', 'and the quote is the message the plugin emits');

done_testing;
