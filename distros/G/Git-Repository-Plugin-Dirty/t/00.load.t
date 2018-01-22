use strict;
use warnings;

use Test::More;
use Test::Trap;
use Test::Exception;
use Path::Tiny;
use Capture::Tiny qw(capture);

use File::Temp;
use Cwd;

use Git::Repository qw(Dirty);

BEGIN { sub _test_wrapper };    # for syntactic sugarness

my $gitbin = '/usr/bin/git';
if ( !-x $gitbin ) {
    plan skip_all => "$gitbin required for these tests";
}
else {
    plan tests => 71;
}

diag("Testing Git::Repository::Plugin::Dirty $Git::Repository::Plugin::Dirty::VERSION");
ok( exists $INC{'Git/Repository/Plugin/Dirty.pm'}, "Dirty loaded as plugin" );

my $starting_dir = cwd();

_test_wrapper "current_branch()" => sub {
    my ( $git, $dir, $name ) = @_;
    is( $git->current_branch(), "master", "current_branch() returns current branch of initiated object" );
    capture { $git->run( "checkout", "-b", "ohhai-$$" ) };
    is( $git->current_branch(), "ohhai-$$", "current_branch() returns current branch after changing branch" );
};

_test_wrapper "clean repo" => sub {
    my ( $git, $dir, $name ) = @_;

    ok( !$git->is_dirty(), "$name: is_dirty() returns false" );
    ok( !$git->is_dirty( untracked => 1 ), "$name: is_dirty(untracked => 1) returns false" );
    is_deeply( [ $git->has_untracked() ], [], "$name: has_untracked() returns empty list" );
    ok( !$git->has_unstaged_changes(), "$name: has_unstaged_changes() returns false" );
    ok( !$git->has_staged_changes(),   "$name: has_staged_changes() returns false" );
    is_deeply( [ $git->diff_unstaged() ], [], "$name: diff_unstaged() returns empty list" );
    is_deeply( [ $git->diff_staged() ],   [], "$name: diff_staged() returns empty list" );

    my @lines;
    $git->diff_unstaged( sub { my ( $git, $line ) = @_; push @lines, "$git$line" } );
    is_deeply( \@lines, [], "$name: diff_unstaged(\$handler) handler processes each line" );
    @lines = ();
    $git->diff_staged( sub { my ( $git, $line ) = @_; push @lines, "$git$line" } );
    is_deeply( \@lines, [], "$name: diff_staged(\$handler) handler processes each line" );
};

_test_wrapper "unstaged changes" => sub {
    my ( $git, $dir, $name ) = @_;
    path('baz/file')->spew("updated\nelated");

    ok( $git->is_dirty(), "$name: is_dirty() returns true" );
    ok( $git->is_dirty( untracked => 1 ), "$name: is_dirty(untracked => 1) returns true" );
    is_deeply( [ $git->has_untracked() ], [], "$name: has_untracked() returns empty list" );
    ok( $git->has_unstaged_changes(),        "$name: has_unstaged_changes() returns true" );
    ok( !$git->has_staged_changes(),         "$name: has_staged_changes() returns false" );
    ok( scalar( $git->diff_unstaged() ) > 0, "$name: diff_unstaged() returns diff lines as list" );
    is_deeply( [ $git->diff_staged() ], [], "$name: diff_staged() returns diff lines as list" );

    my @lines;
    $git->diff_unstaged( sub { my ( $git, $line ) = @_; push @lines, "$git$line" } );
    ok( scalar(@lines) > 0, "$name: diff_unstaged(\$handler) handler processes each line" );
    @lines = ();
    $git->diff_staged( sub { my ( $git, $line ) = @_; push @lines, "$git$line" } );
    is_deeply( \@lines, [], "$name: diff_staged(\$handler) handler processes each line" );
};

_test_wrapper "staged changes" => sub {
    my ( $git, $dir, $name ) = @_;
    path('foo/file')->spew("created\nelated");
    $git->run( "add", 'foo/file' );

    ok( $git->is_dirty(), "$name: is_dirty() returns true" );
    ok( $git->is_dirty( untracked => 1 ), "$name: is_dirty(untracked => 1) returns true" );
    is_deeply( [ $git->has_untracked() ], [], "$name: has_untracked() returns empty list" );
    ok( !$git->has_unstaged_changes(), "$name: has_unstaged_changes() returns true" );
    ok( $git->has_staged_changes(),    "$name: has_staged_changes() returns false" );
    is_deeply( [ $git->diff_unstaged() ], [], "$name: diff_unstaged() returns empty list" );
    ok( scalar( $git->diff_staged() ) > 0, "$name: diff_staged() returns diff lines as list" );

    my @lines;
    $git->diff_unstaged( sub { my ( $git, $line ) = @_; push @lines, "$git$line" } );
    is_deeply( \@lines, [], "$name: diff_unstaged(\$handler) handler processes each line" );
    @lines = ();
    $git->diff_staged( sub { my ( $git, $line ) = @_; push @lines, "$git$line" } );
    ok( scalar(@lines) > 0, "$name: diff_staged(\$handler) handler processes each line" );
};

_test_wrapper "untracked files" => sub {
    my ( $git, $dir, $name ) = @_;
    path('foo/new')->spew("new file");

    ok( !$git->is_dirty(), "$name: is_dirty() returns false" );
    ok( $git->is_dirty( untracked => 1 ), "$name: is_dirty(untracked => 1) returns true" );
    is_deeply( [ $git->has_untracked() ], ['foo/new'], "$name: has_untracked() returns list" );
    ok( !$git->has_unstaged_changes(), "$name: has_unstaged_changes() returns false" );
    ok( !$git->has_staged_changes(),   "$name: has_staged_changes() returns false" );
    is_deeply( [ $git->diff_unstaged() ], [], "$name: diff_unstaged() returns empty list" );
    is_deeply( [ $git->diff_staged() ],   [], "$name: diff_staged() returns empty list" );

    my @lines;
    $git->diff_unstaged( sub { my ( $git, $line ) = @_; push @lines, "$git$line" } );
    is_deeply( \@lines, [], "$name: diff_unstaged(\$handler) handler processes each line" );
    @lines = ();
    $git->diff_staged( sub { my ( $git, $line ) = @_; push @lines, "$git$line" } );
    is_deeply( \@lines, [], "$name: diff_staged(\$handler) handler processes each line" );
};

_test_wrapper "unstaged changes && staged changes" => sub {
    my ( $git, $dir, $name ) = @_;
    path('baz/file')->spew("updated\nelated");
    path('foo/file')->spew("created\nelated");
    $git->run( "add", 'foo/file' );

    ok( $git->is_dirty(), "$name: is_dirty() returns true" );
    ok( $git->is_dirty( untracked => 1 ), "$name: is_dirty(untracked => 1) returns true" );
    is_deeply( [ $git->has_untracked() ], [], "$name: has_untracked() returns empty list" );
    ok( $git->has_unstaged_changes(),        "$name: has_unstaged_changes() returns true" );
    ok( $git->has_staged_changes(),          "$name: has_staged_changes() returns true" );
    ok( scalar( $git->diff_unstaged() ) > 0, "$name: diff_unstaged() returns diff lines as list" );
    ok( scalar( $git->diff_staged() ) > 0,   "$name: diff_staged() returns diff lines as list" );

    my @lines;
    $git->diff_unstaged( sub { my ( $git, $line ) = @_; push @lines, "$git$line" } );
    ok( scalar(@lines) > 0, "$name: diff_unstaged(\$handler) handler processes each line" );
    @lines = ();
    $git->diff_staged( sub { my ( $git, $line ) = @_; push @lines, "$git$line" } );
    ok( scalar(@lines) > 0, "$name: diff_staged(\$handler) handler processes each line" );
};

_test_wrapper "unstaged changes && staged changes && untracked files" => sub {
    my ( $git, $dir, $name ) = @_;
    path('baz/file')->spew("updated\nelated");
    path('foo/file')->spew("created\nelated");
    $git->run( "add", 'foo/file' );
    path('foo/new')->spew("new file");

    ok( $git->is_dirty(), "$name: is_dirty() returns true" );
    ok( $git->is_dirty( untracked => 1 ), "$name: is_dirty(untracked => 1) returns true" );
    is_deeply( [ $git->has_untracked() ], ['foo/new'], "$name: has_untracked() returns list" );
    ok( $git->has_unstaged_changes(),        "$name: has_unstaged_changes() returns true" );
    ok( $git->has_staged_changes(),          "$name: has_staged_changes() returns true" );
    ok( scalar( $git->diff_unstaged() ) > 0, "$name: diff_unstaged() returns diff lines as list" );
    ok( scalar( $git->diff_staged() ) > 0,   "$name: diff_staged() returns diff lines as list" );

    my @lines;
    $git->diff_unstaged( sub { my ( $git, $line ) = @_; push @lines, "$git$line" } );
    ok( scalar(@lines) > 0, "$name: diff_unstaged(\$handler) handler processes each line" );
    @lines = ();
    $git->diff_staged( sub { my ( $git, $line ) = @_; push @lines, "$git$line" } );
    ok( scalar(@lines) > 0, "$name: diff_staged(\$handler) handler processes each line" );
};

#### misc ##
_test_wrapper "has_*_changes() re-throw from git obj" => sub {
    my ( $git, $dir, $name ) = @_;

    no warnings 'redefine';
    my $exit = 0;
    local *Git::Repository::run = sub { $? = $exit; die "You have failed me for the last time!\n" };

    for my $meth (qw(has_staged_changes has_unstaged_changes)) {
        $exit = 0;
        lives_ok { $git->$meth() } "$name: $meth() does not when exit is 0";

        $exit = 256;
        lives_ok { $git->$meth() } "$name: $meth() does not when exit is 256";

        $exit = 128;
        throws_ok { $git->$meth() } qr/You have failed me for the last time/, "$name: $meth() does when exit is 128";

        $exit = 129;
        throws_ok { $git->$meth() } qr/You have failed me for the last time/, "$name: $meth() does when exit is 129";
    }
};

_test_wrapper "diff_*() handlers returning false" => sub {
    my ( $git, $dir, $name ) = @_;
    path('baz/file')->spew("updated\nelated");
    path('foo/file')->spew("created\nelated");
    $git->run( "add", 'foo/file' );

    for my $meth (qw(diff_unstaged diff_staged)) {
        my $count = 0;
        $git->$meth(
            sub {
                my ( $git, $line ) = @_;
                isa_ok( $git, 'Git::Repository', "$name: $meth() first arg is git object" );
                ok( length $line, "$name: $meth() first arg is line" );
                $count++;
                return;
            }
        );
        is( $count, 1, "$name: $meth() stopped after return false" );
    }
};

###############
#### helpers ##
###############

sub _test_wrapper {
    my ( $note, $code ) = @_;

    note $note;

    my $dir = _setup_clean_repo();
    my $git = Git::Repository->new( { fatal => ["!0"] } );

    $code->( $git, $dir, $note );

    chdir $starting_dir || die "could not chdir back to starting dir ($starting_dir): $!\n";

    return;
}

sub _setup_clean_repo {
    my $dir = File::Temp->newdir;
    chdir $dir || die "could not chdir to temp dir ($dir): $!\n";

    for my $pth (qw(foo foo/bar baz baz/wop)) {
        mkdir $pth || die "Could not mkdir $pth: $!\n";
        path("$pth/file")->spew("$$: $pth/file");
    }

    capture {
        trap {
            system( $gitbin, "init", "." ) && die "Could not init: $?\n";
            system( $gitbin, "add",  "." ) && die "Could not add: $?\n";
            system( $gitbin, "commit", "-m", "init" ) && die "Could not commit: $?\n";
        };
        die( $trap->die ) if $trap->die;
    };

    return $dir;
}
