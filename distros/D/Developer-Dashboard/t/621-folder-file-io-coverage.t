#!/usr/bin/env perl

use strict;
use warnings;

# The CORE::GLOBAL overrides must exist before the module under test is
# compiled. They fail only for exact paths registered in the %FAIL_* tables,
# so every I/O error branch runs deterministically for any uid (a chmod-based
# unreadable file does not fail for root).
our ( %FAIL_OPEN, %FAIL_OPENDIR, %FAIL_CHDIR, %FAIL_CHMOD, %FAIL_CLOSE, %CLOSE_HANDLE );

BEGIN {
    require Scalar::Util;
    require Symbol;
    *CORE::GLOBAL::open = sub (*;$@) {
        if ( @_ >= 3 && defined $_[2] && !ref $_[2] && $FAIL_OPEN{ $_[2] } ) {
            $! = 13;
            return 0;
        }
        my $ok = @_ == 2 ? CORE::open( $_[0], $_[1] ) : CORE::open( $_[0], $_[1], @_[ 2 .. $#_ ] );
        if ( $ok && @_ >= 3 && defined $_[2] && !ref $_[2] && $FAIL_CLOSE{ $_[2] } && ref $_[0] ) {
            $CLOSE_HANDLE{ Scalar::Util::refaddr( $_[0] ) } = 1;
        }
        return $ok;
    };
    *CORE::GLOBAL::close = sub (;*) {
        my $handle = @_ ? $_[0] : undef;
        return CORE::close() if !defined $handle;
        $handle = Symbol::qualify_to_ref( $handle, caller ) if !ref $handle;
        if ( $CLOSE_HANDLE{ Scalar::Util::refaddr($handle) } ) {
            delete $CLOSE_HANDLE{ Scalar::Util::refaddr($handle) };
            CORE::close($handle);
            $! = 5;
            return 0;
        }
        return CORE::close($handle);
    };
    *CORE::GLOBAL::opendir = sub (*$) {
        if ( defined $_[1] && $FAIL_OPENDIR{ $_[1] } ) {
            $! = 13;
            return 0;
        }
        return CORE::opendir( $_[0], $_[1] );
    };
    *CORE::GLOBAL::chdir = sub (;$) {
        if ( @_ && defined $_[0] && $FAIL_CHDIR{ $_[0] } ) {
            $! = 13;
            return 0;
        }
        return @_ ? CORE::chdir( $_[0] ) : CORE::chdir();
    };
    *CORE::GLOBAL::chmod = sub (@) {
        my ( $mode, @files ) = @_;
        return 0 if grep { defined $_ && $FAIL_CHMOD{$_} } @files;
        return CORE::chmod( $mode, @files );
    };
}

use Test::More;
use Cwd qw(getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::File;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::Folder;
use Developer::Dashboard::PathRegistry;

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME}                           = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
delete $ENV{DEVELOPER_DASHBOARD_CONFIG_DIRS};
chdir $home or die "Unable to chdir to $home: $!";
my $start = getcwd();

sub error_of { my ($code) = @_; return eval { $code->(); 1 } ? '' : $@ }
sub write_file {
    my ( $file, $text ) = @_;
    open my $fh, '>', $file or die "Unable to write $file: $!";
    print {$fh} $text;
    close $fh or die "Unable to close $file: $!";
    return $file;
}

# --- Folder ----------------------------------------------------------------
{
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
    Developer::Dashboard::Folder->configure( paths => $paths );
    my $postman = Developer::Dashboard::Folder->postman;
    ok( -d $postman, 'postman creates its directory when missing' );
    is( Developer::Dashboard::Folder->postman, $postman, 'postman is stable when the directory already exists' );

    my $dir = File::Spec->catdir( $home, 'folder-fixture' );
    make_path( File::Spec->catdir( $dir, 'zdir' ), File::Spec->catdir( $dir, 'adir' ) );
    write_file( File::Spec->catfile( $dir, 'b.txt' ), 'b' );
    write_file( File::Spec->catfile( $dir, 'a.txt' ), 'a' );
    my @items = Developer::Dashboard::Folder->ls($dir);
    is_deeply( [ map { $_->{NAME} } @items ], [qw(adir zdir a.txt b.txt)], 'ls sorts folders first then by name inside each type' );

    {
        local $FAIL_OPENDIR{$dir} = 1;
        is_deeply( [ Developer::Dashboard::Folder->ls($dir) ], [], 'ls returns nothing when the directory cannot be opened' );
    }
    {
        local $FAIL_CHDIR{$dir} = 1;
        my $ran = 0;
        is( Developer::Dashboard::Folder->cd( $dir, sub { $ran = 1 } ), undef, 'cd returns undef when chdir fails' );
        ok( !$ran, 'cd does not run the callback when chdir fails' );
    }
    is( Developer::Dashboard::Folder->cd( $dir, sub { 7 } ), 7, 'cd runs the callback when chdir succeeds' );
    chdir $start or die "chdir: $!";

    {
        local $ENV{DEVELOPER_DASHBOARD_PATH_S5EMPTY} = '';
        is( Developer::Dashboard::Folder->_resolve_path('s5empty'), undef, 'an empty path env override is ignored' );
        local $ENV{DEVELOPER_DASHBOARD_PATH_S5SET} = $home;
        is( Developer::Dashboard::Folder->_resolve_path('s5set'), $home, 'a set path env override resolves' );
    }

    # Lazily built default registry honours existing workspace roots.
    {
        no warnings 'once';
        local $Developer::Dashboard::Folder::PATHS;
        make_path( File::Spec->catdir( $home, 'projects' ) );
        my $built = Developer::Dashboard::Folder::_paths_obj();
        is_deeply( [ $built->workspace_roots ], [ File::Spec->catdir( $home, 'projects' ) ], 'default registry lists only existing workspace roots' );
    }
}

# --- File ------------------------------------------------------------------
{
    my $target = write_file( File::Spec->catfile( $home, 'file-fixture.txt' ), "content\n" );
    is( Developer::Dashboard::File->read($target), "content\n", 'read returns file content' );
    {
        local $FAIL_OPEN{$target} = 1;
        like( error_of( sub { Developer::Dashboard::File->read($target) } ), qr/Unable to read \Q$target\E/, 'read dies when the file cannot be opened' );
    }
    {
        local $FAIL_CLOSE{$target} = 1;
        like( error_of( sub { Developer::Dashboard::File->touch($target) } ), qr/Unable to close \Q$target\E/, 'touch dies when close fails' );
    }
    is( Developer::Dashboard::File->touch($target), $target, 'touch succeeds normally' );
}

# --- FileRegistry ----------------------------------------------------------
{
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
    my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
    $files->register_named_files( { '' => '/ignored', plain => 'plain-created.txt' } );
    ok( !exists $files->{named_files}{''}, 'register_named_files skips an empty alias name' );
    ok( exists $files->named_files->{plain}, 'named_files lists the registered alias' );

    # A lazy-create alias whose path has no directory part has no parent to create.
    $files->{named_files}{bare} = { path => 'bare-created.txt', create => 1 };
    is( $files->resolve_file('bare'), 'bare-created.txt', 'a create alias without a parent directory resolves without creating one' );

    my $target = write_file( File::Spec->catfile( $home, 'registry-fixture.txt' ), "registry\n" );
    is( $files->read($target), "registry\n", 'read returns file content' );
    {
        local $FAIL_OPEN{$target} = 1;
        like( error_of( sub { $files->read($target) } ), qr/Unable to read \Q$target\E/, 'read dies when the file cannot be opened' );
    }
}

done_testing;

__END__

=pod

=head1 NAME

t/621-folder-file-io-coverage.t - forces the I/O failure and guard branches of Developer::Dashboard::Folder, File and FileRegistry

=head1 PURPOSE

Test file in the Developer Dashboard codebase. forces the I/O failure and guard branches of Developer::Dashboard::Folder, File and FileRegistry

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate with zero uncoverable annotations needs the chdir, opendir, open and close failure branches of these modules exercised for any uid, including root.

=head1 WHEN TO USE

Use this file when you change the Folder, File or FileRegistry I/O handling, or when a coverage run reports one of those branches as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/621-folder-file-io-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/621-folder-file-io-coverage.t

Run this coverage-gap test by itself while editing the covered modules.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/621-folder-file-io-coverage.t

Confirm the targeted branches are reported as covered.

=cut
