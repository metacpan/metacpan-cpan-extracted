use Modern::Perl;

use File::ShareDir qw(dist_file dist_dir);
use File::Spec;
use IPC::Run3;

use Koha::QA::Tidy::TT;

BEGIN {
    # Check if prettier is available via node
    my ( $stdout, $stderr );
    my $available = Koha::QA::Tidy::TT->_has_prettier();
    unless ($available) {
        print "1..0 # skip prettier is not available\n";
        exit 0;
    }
}

use Test::NoWarnings qw(had_no_warnings);
use Test::More tests => 10;
use Test::Warn;
use File::Temp qw(tempfile);

sub check_tidy {
    my ( $content, $params ) = @_;
    $params ||= {};
    my $checker = Koha::QA::Tidy::TT->new( { content => $content, %$params } );
    $checker->check();
    return $checker->errors();
}

subtest 'File tidy should pass tidy check' => sub {
    plan tests => 1;

    my $input = <<'INPUT';
[% USE Koha %]
[% INCLUDE 'doc-head-open.inc' %]
<title>Koha</title>
[% INCLUDE 'doc-head-close.inc' %]
</head>
<body id="main_intranet-main" class="intranet-main">
<div id="container-main" class="container-fluid">
    <h1>The title</h1>
</div>
[% INCLUDE 'intranet-bottom.inc' %]
INPUT

    my @errors = check_tidy($input);
    is( scalar @errors, 0 );
};

subtest 'File not tidy should not pass tidy check' => sub {
    plan tests => 1;

    my $input = <<'INPUT';
[% USE Koha %]
[% INCLUDE 'doc-head-open.inc' %]
    <title>Koha</title>
[% INCLUDE 'doc-head-close.inc' %]
</head>
<body id="main_intranet-main" class="intranet-main">
    <div id="container-main" class="container-fluid">
        <h1>The title</h1>
    </div>
[% INCLUDE 'intranet-bottom.inc' %]
INPUT

    my @errors = check_tidy($input);
    is_deeply(
        \@errors,
        [
            {
                message => 'Template::Toolkit file is not tidy',
                error   => 'tidy_tt'
            }
        ]
    );
};

subtest 'Fix content' => sub {
    plan tests => 2;

    my $tidy_input = <<INPUT;
[% USE Koha %]
[% INCLUDE 'doc-head-open.inc' %]
<title>Koha</title>
[% INCLUDE 'doc-head-close.inc' %]
</head>
<body id="main_intranet-main" class="intranet-main">
<div id="container-main" class="container-fluid">
    <h1>The title</h1>
</div>
[% INCLUDE 'intranet-bottom.inc' %]
INPUT

    my $untidy_input = <<INPUT;
[% USE Koha %]
[% INCLUDE 'doc-head-open.inc' %]
    <title>Koha</title>
[% INCLUDE 'doc-head-close.inc' %]
</head>
<body id="main_intranet-main" class="intranet-main">
    <div id="container-main" class="container-fluid">
        <h1>The title</h1>
    </div>
[% INCLUDE 'intranet-bottom.inc' %]
INPUT

    subtest 'File is tidy' => sub {
        plan tests => 2;
        my $checker = Koha::QA::Tidy::TT->new( { content => $tidy_input } );
        $checker->check();
        is( $checker->fix, $tidy_input, "check called before fix" );

        $checker = Koha::QA::Tidy::TT->new( { content => $tidy_input } );
        is( $checker->fix, $tidy_input, "check not called before fix" );
    };

    subtest 'File is not tidy' => sub {
        plan tests => 2;
        my $checker = Koha::QA::Tidy::TT->new( { content => $untidy_input } );
        $checker->check();
        is( $checker->fix, $tidy_input, "check called before fix" );

        $checker = Koha::QA::Tidy::TT->new( { content => $untidy_input } );
        is( $checker->fix, $tidy_input, "check not called before fix" );
    };
};

subtest 'File passed via file parameter' => sub {
    plan tests => 2;

    my $tidy_input = <<INPUT;
[% USE Koha %]
[% INCLUDE 'doc-head-open.inc' %]
<title>Koha</title>
[% INCLUDE 'doc-head-close.inc' %]
</head>
<body id="main_intranet-main" class="intranet-main">
<div id="container-main" class="container-fluid">
    <h1>The title</h1>
</div>
[% INCLUDE 'intranet-bottom.inc' %]
INPUT

    my $untidy_input = <<INPUT;
[% USE Koha %]
[% INCLUDE 'doc-head-open.inc' %]
    <title>Koha</title>
[% INCLUDE 'doc-head-close.inc' %]
</head>
<body id="main_intranet-main" class="intranet-main">
    <div id="container-main" class="container-fluid">
        <h1>The title</h1>
    </div>
[% INCLUDE 'intranet-bottom.inc' %]
INPUT

    my ( $fh, $filename ) = tempfile( UNLINK => 0, TEMPDIR => 1, SUFFIX => '.tt' );
    print $fh $tidy_input;
    close $fh;

    my $checker = Koha::QA::Tidy::TT->new( { file => $filename } );
    my @errors  = $checker->errors() if $checker->check();
    is( scalar @errors, 0, 'Tidy file passed via file parameter should pass tidy check' );

    ( $fh, $filename ) = tempfile( UNLINK => 0, TEMPDIR => 1, SUFFIX => '.tt' );
    print $fh $untidy_input;
    close $fh;

    $checker = Koha::QA::Tidy::TT->new( { file => $filename } );
    $checker->check();
    is( $checker->fix, $tidy_input, 'Untidy file passed via file parameter should be fixed' );
};

subtest 'Non-existing prettierrc file passed' => sub {
    plan tests => 2;

    my $input = <<INPUT;
File does not exist
INPUT

    my $nonexistent_prettierrc = q{.this-should-not-exist};
    my $checker = Koha::QA::Tidy::TT->new( { content => $input, prettierrc => $nonexistent_prettierrc } );
    $checker->check();
    is_deeply(
        [ $checker->errors ],
        [
            {
                error   => 'no_prettierrc',
                message => 'prettierrc file not found: ' . File::Spec->rel2abs($nonexistent_prettierrc)
            }
        ]
    );
    is( $checker->fix, undef, 'fix() returns undef rather than silently truncating the file' );
};

subtest 'Relative prettierrc is resolved against the real working directory' => sub {
    plan tests => 2;

    # _prettier_cmd() cd's into the share dir so Node can resolve the plugin, a relative
    # prettierrc must still be resolved against the caller's cwd, not that share dir
    my ( $fh, $abs_prettierrc ) = tempfile( SUFFIX => '.js', UNLINK => 0, TEMPDIR => 1 );
    print $fh <<'PRETTIERRC';
module.exports = {
    overrides: [
        {
            files: ["*.tt", "*.inc"],
            options: {
                parser: "template-toolkit",
                plugins: ["@koha-community/prettier-plugin-template-toolkit"],
            },
        },
    ],
};
PRETTIERRC
    close $fh;
    my $relative_prettierrc = File::Spec->abs2rel($abs_prettierrc);

    my $input = <<'INPUT';
[% USE Koha %]
INPUT

    my @errors;
    warning_is { @errors = check_tidy( $input, { prettierrc => $relative_prettierrc } ) } undef,
        'prettier was invoked with the config resolved against the real cwd, without a "module not found" warning';

    is( scalar @errors, 0, 'relative prettierrc resolves correctly instead of "module not found"' );
};

subtest 'Empty file is valid' => sub {
    plan tests => 3;

    # An already-empty file stays empty: that must not be confused with prettier
    # failing to produce output for non-empty content (see Tidy::Perl/Tidy::JS)
    my @errors = check_tidy(q{});
    is_deeply( \@errors, [], 'check() reports no error for an empty file' );

    my $checker  = Koha::QA::Tidy::TT->new( { content => q{} } );
    my $is_valid = $checker->check;
    is( $is_valid,     1,   'check() returns a true scalar, not the leftover list' );
    is( $checker->fix, q{}, 'fix() returns the empty content rather than undef' );
};

subtest 'Parsing failure should fail the check' => sub {
    plan tests => 3;

    my $input = <<'INPUT';
<html>
  <head></head>
  <body>
    <select name="foo">
      [% FOREACH bar IN bar_loop %]
        [% IF bar.selected %]
        <option>bar</option>
      [% END %]
    </select>
  </body>
</html>
INPUT

    my $checker = Koha::QA::Tidy::TT->new( { content => $input } );
    my $is_valid;

    warning_like { $is_valid = $checker->check } qr/SyntaxError/, "check() warns with prettier's parse error";

    ok( !$is_valid, 'check() reports the file as not tidy when prettier fails to parse it' );
    is_deeply(
        [ $checker->errors ],
        [
            {
                message => 'prettier failed to process the file, the original content was kept',
                error   => 'tidy_tt_prettier_failed'
            }
        ],
        'the parse failure is reported distinctly instead of being folded into ordinary untidiness'
    );
};

subtest 'Broken prettierrc fails the check' => sub {
    plan tests => 3;

    my ( $fh, $broken_prettierrc ) = tempfile( SUFFIX => '.js', UNLINK => 1, TEMPDIR => 1 );
    print $fh "this is not valid javascript {{{\n";
    close $fh;

    my $input = <<'INPUT';
[% USE Koha %]
INPUT

    my $checker = Koha::QA::Tidy::TT->new( { content => $input, prettierrc => $broken_prettierrc } );
    my $is_valid;

    warning_like { $is_valid = $checker->check } qr/\[error\]/, "check() warns with prettier's config error";

    ok( !$is_valid, 'check() reports failure for a broken prettierrc' );
    is_deeply(
        [ $checker->errors ],
        [
            {
                message => 'prettier failed to process the file, the original content was kept',
                error   => 'tidy_tt_prettier_failed'
            }
        ],
        'check() reports the prettier-failed error, not "not tidy"'
    );
};

had_no_warnings();
