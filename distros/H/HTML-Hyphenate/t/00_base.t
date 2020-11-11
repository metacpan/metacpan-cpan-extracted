use strict;
use warnings;
use utf8;

use Test::More;
use Test::Compile;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

BEGIN {
    @MAIN::methods =
      qw(html style min_length min_pre min_post default_lang default_included classes_included classes_excluded hyphenated);
    @MAIN::scripts = qw(bin/hyphenate_html);
    plan tests => ( 4 + @MAIN::methods ) + 1 + 2;
    ok(1);
    use_ok('HTML::Hyphenate');
}
diag("Testing HTML::Hyphenate $HTML::Hyphenate::VERSION");
my $hyphen = new_ok('HTML::Hyphenate');

@HTML::Hyphenate::Sub::ISA = qw(HTML::Hyphenate);
my $hyphen_sub = new_ok('HTML::Hyphenate::Sub');

foreach my $method (@MAIN::methods) {
    can_ok( 'HTML::Hyphenate', $method );
}

my $test = Test::Compile->new();
$test->all_files_ok();
$test->pl_file_compiles($_) for @MAIN::scripts;

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
$test->done_testing();
