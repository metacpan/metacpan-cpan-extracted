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
use Test::More tests => 5;
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

subtest 'Non-existing prettierrc file passed' => sub {
    plan tests => 1;

    my $input = <<INPUT;
File does not exist
INPUT

    my $nonexistent_prettierrc = q{.this-should-not-exist};
    my @errors                 = check_tidy( $input, { prettierrc => $nonexistent_prettierrc } );
    is_deeply(
        \@errors,
        [ { error => 'no_prettierrc', message => qq{prettierrc file not found: $nonexistent_prettierrc} } ]
    );
};

had_no_warnings();
