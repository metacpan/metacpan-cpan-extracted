#!/usr/bin/env perl

use strict;
use warnings;

# These CORE::GLOBAL overrides must exist before the module under test is
# compiled. They fail only for exact registered paths (open/unlink) or for
# handles that were opened on a registered path pattern (close), so every
# error branch runs deterministically even as root, where chmod-based
# fixtures cannot fail.
our ( %OPEN_FAIL, %UNLINK_FAIL, @CLOSE_FAIL_RE, %HANDLE_FAIL );

BEGIN {
    require Scalar::Util;
    *CORE::GLOBAL::open = sub (*;$@) {
        if ( @_ >= 3 && defined $_[2] && !ref $_[2] && $OPEN_FAIL{ $_[2] } ) {
            $! = 13;
            return 0;
        }
        my $ok;
        if ( @_ == 2 ) { $ok = CORE::open( $_[0], $_[1] ) }
        else           { $ok = CORE::open( $_[0], $_[1], @_[ 2 .. $#_ ] ) }
        # A freed handle's address can be handed to a later, unrelated handle, so
        # every successful open resets that slot before it is (re)registered.
        delete $HANDLE_FAIL{ Scalar::Util::refaddr( $_[0] ) } if $ok && ref $_[0];
        if ( $ok && @_ >= 3 && defined $_[2] && !ref $_[2] && grep { $_[2] =~ $_ } @CLOSE_FAIL_RE ) {
            $HANDLE_FAIL{ Scalar::Util::refaddr( $_[0] ) } = 1;
        }
        return $ok;
    };
    *CORE::GLOBAL::close = sub (;*) {
        return CORE::close() if !@_;
        my $fail = ref $_[0] && delete $HANDLE_FAIL{ Scalar::Util::refaddr( $_[0] ) };
        my $ok = CORE::close( $_[0] );
        if ($fail) {
            $! = 5;
            return 0;
        }
        return $ok;
    };
    *CORE::GLOBAL::unlink = sub {
        if ( @_ == 1 && defined $_[0] && $UNLINK_FAIL{ $_[0] } ) {
            $! = 13;
            return 0;
        }
        return CORE::unlink(@_);
    };
}

use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::InternalCLI;

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $PKG = 'Developer::Dashboard::InternalCLI';
sub call { no strict 'refs'; return &{"${PKG}::$_[0]"}( @_[ 1 .. $#_ ] ) }

my $n = 0;
sub fresh {
    my $dir = File::Spec->catdir( $home, 'r' . ++$n );
    make_path($dir);
    return Developer::Dashboard::PathRegistry->new( home => $dir );
}

sub wf {
    my ( $path, $content ) = @_;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh or die "Unable to close $path: $!";
    return $path;
}

# helper_content: unsupported name, open failure, close failure.
like( eval { call( 'helper_content', 'bogus-helper' ); 1 } ? '' : $@, qr/Unsupported helper command/, 'helper_content rejects unknown helper names' );
my $asset = call( '_helper_asset_path', 'jq' );
{
    local $OPEN_FAIL{$asset} = 1;
    like( eval { call( 'helper_content', 'jq' ); 1 } ? '' : $@, qr/Unable to read \Q$asset\E/, 'helper_content dies when the asset cannot be opened' );
}
{
    local @CLOSE_FAIL_RE = ( qr/\Q$asset\E\z/ );
    like( eval { call( 'helper_content', 'jq' ); 1 } ? '' : $@, qr/Unable to close \Q$asset\E/, 'helper_content dies when the asset cannot be closed' );
}
ok( length call( 'helper_content', 'jq' ), 'helper_content still reads normally' );

# ensure_helper on windows: existing core-backed helper target is read.
{
    my $paths  = fresh();
    my $target = call( 'helper_path', paths => $paths, name => 'ask' );
    make_path( File::Spec->catdir( call( '_helper_install_root', $paths ) ) );
    wf( $target, "user owned\n" );
    no warnings 'redefine';
    local *Developer::Dashboard::InternalCLI::is_windows = sub { 1 };
    {
        local $OPEN_FAIL{$target} = 1;
        like( eval { call( 'ensure_helper', paths => $paths, name => 'ask' ); 1 } ? '' : $@, qr/Unable to read \Q$target\E/, 'ensure_helper dies on windows when the existing helper cannot be opened' );
    }
    {
        local @CLOSE_FAIL_RE = ( qr/\Q$target\E\z/ );
        like( eval { call( 'ensure_helper', paths => $paths, name => 'ask' ); 1 } ? '' : $@, qr/Unable to close \Q$target\E/, 'ensure_helper dies on windows when the existing helper cannot be closed' );
    }
}

# _stage_managed_helper: existing non-empty target is read.
{
    my $paths  = fresh();
    my $target = File::Spec->catfile( $home, "stage-$n.txt" );
    wf( $target, "user owned\n" );
    {
        local $OPEN_FAIL{$target} = 1;
        like( eval { call( '_stage_managed_helper', paths => $paths, name => 'jq', target => $target ); 1 } ? '' : $@, qr/Unable to read/, 'staging dies when the existing target cannot be opened' );
    }
    {
        local @CLOSE_FAIL_RE = ( qr/\Q$target\E\z/ );
        like( eval { call( '_stage_managed_helper', paths => $paths, name => 'jq', target => $target ); 1 } ? '' : $@, qr/Unable to close/, 'staging dies when the existing target cannot be closed' );
    }
}

# _write_helper_atomically: temp file close failure.
{
    my $target = File::Spec->catfile( $home, "atomic-$n.txt" );
    local @CLOSE_FAIL_RE = ( qr/\.tmp\.\d+\.\d+\z/ );
    like( eval { call( '_write_helper_atomically', $target, "body\n" ); 1 } ? '' : $@, qr/Unable to close .*\.tmp\./, 'atomic write dies when the temp file cannot be closed' );
}

# _remove_retired_managed_helper.
{
    my $paths  = fresh();
    my $root   = call( '_helper_install_root', $paths );
    make_path($root);
    my $target = File::Spec->catfile( $root, 'skill' );
    wf( $target, "#!/usr/bin/env perl\n" . call( '_managed_helper_marker', 'skill' ) . "\nbody\n" );
    {
        local $OPEN_FAIL{$target} = 1;
        like( eval { call( '_remove_retired_managed_helper', paths => $paths, name => 'skill' ); 1 } ? '' : $@, qr/Unable to read/, 'retired helper removal dies on open failure' );
    }
    {
        local @CLOSE_FAIL_RE = ( qr/\Q$target\E\z/ );
        like( eval { call( '_remove_retired_managed_helper', paths => $paths, name => 'skill' ); 1 } ? '' : $@, qr/Unable to close/, 'retired helper removal dies on close failure' );
    }
    {
        local $UNLINK_FAIL{$target} = 1;
        like( eval { call( '_remove_retired_managed_helper', paths => $paths, name => 'skill' ); 1 } ? '' : $@, qr/Unable to remove retired helper/, 'retired helper removal dies on unlink failure' );
    }
}

# _remove_legacy_managed_flat_helpers.
{
    my $paths  = fresh();
    my $parent = call( '_helper_parent_root', $paths );
    make_path($parent);
    my $target = File::Spec->catfile( $parent, 'jq' );
    wf( $target, "#!/usr/bin/env perl\n" . call( '_managed_helper_marker', 'jq' ) . "\nbody\n" );
    {
        local $OPEN_FAIL{$target} = 1;
        like( eval { call( '_remove_legacy_managed_flat_helpers', paths => $paths ); 1 } ? '' : $@, qr/Unable to read/, 'legacy removal dies on open failure' );
    }
    {
        local @CLOSE_FAIL_RE = ( qr/\Q$target\E\z/ );
        like( eval { call( '_remove_legacy_managed_flat_helpers', paths => $paths ); 1 } ? '' : $@, qr/Unable to close/, 'legacy removal dies on close failure' );
    }
    {
        local $UNLINK_FAIL{$target} = 1;
        like( eval { call( '_remove_legacy_managed_flat_helpers', paths => $paths ); 1 } ? '' : $@, qr/Unable to remove legacy managed helper/, 'legacy removal dies on unlink failure' );
    }
}

# _managed_helper_file_current.
{
    my $target = wf( File::Spec->catfile( $home, "cur-$n.txt" ), "x\n" );
    {
        local $OPEN_FAIL{$target} = 1;
        like( eval { call( '_managed_helper_file_current', $target, 'jq' ); 1 } ? '' : $@, qr/Unable to read/, 'currency check dies on open failure' );
    }
    {
        local @CLOSE_FAIL_RE = ( qr/\Q$target\E\z/ );
        like( eval { call( '_managed_helper_file_current', $target, 'jq' ); 1 } ? '' : $@, qr/Unable to close/, 'currency check dies on close failure' );
    }
}

# _module_source_path recomputes when the cache is empty.
{
    local $Developer::Dashboard::InternalCLI::MODULE_SOURCE_PATH = '';
    like( call('_module_source_path'), qr/InternalCLI\.pm\z/, 'module source path is recomputed when the cache is empty' );
}

# _abs_existing_path falls back to the input when abs_path yields nothing.
{
    no warnings 'redefine';
    local *Developer::Dashboard::InternalCLI::abs_path = sub { '' };
    is( call( '_abs_existing_path', $home ), $home, 'abs_path failure falls back to the original path' );
}

# _looks_like_private_cli_root: wrong trailing segment.
is( call( '_looks_like_private_cli_root', File::Spec->catdir( $home, 'elsewhere' ) ), 0, 'a non private-cli directory is rejected' );

done_testing;

__END__

=pod

=head1 NAME

t/740-internalcli-io-coverage.t - covers the I/O failure branches of Developer::Dashboard::InternalCLI

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It uses BEGIN-time CORE::GLOBAL open, close and unlink overrides that fail only for registered paths, so every read, close and remove error branch in InternalCLI runs even when the suite is root.

=head1 WHY IT EXISTS

It exists because lib/ must reach 100 percent Devel::Cover coverage with no uncoverable annotations, and chmod-based fixtures cannot fail for root.

=head1 WHEN TO USE

Use this file when you change the helper staging, retirement or currency-check code in InternalCLI, or when a coverage run reports one of those error branches as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/740-internalcli-io-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification.

=head1 EXAMPLES

Example 1:

  prove -lv t/740-internalcli-io-coverage.t

Run this coverage-gap test by itself while editing InternalCLI.

=cut
