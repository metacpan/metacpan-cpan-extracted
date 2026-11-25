use strict;
use warnings;

use Test::More;
use FindBin qw($RealBin);
use File::Spec;

use lib 'lib';

require Developer::Dashboard::HtmlEscape;
require Developer::Dashboard::Crypto::PBKDF2;
require Developer::Dashboard::IndicatorStore::Watch;

my @xs_contracts = (
    [ 'Developer::Dashboard::Crypto::PBKDF2', '_xs_pbkdf2_sha256', 'PBKDF2 XS entry point is available in the existing module namespace' ],
    [ 'Developer::Dashboard::IndicatorStore::Watch', '_xs_inotify_init', 'Linux inotify XS entry point is available in the existing module namespace' ],
    [ 'Developer::Dashboard::IndicatorStore::Watch', '_xs_inotify_add_watch', 'Linux inotify watch XS entry point is available in the existing module namespace' ],
    [ 'Developer::Dashboard::IndicatorStore::Watch', '_xs_win32_find_first_change', 'Windows notification XS entry point is available in the existing module namespace' ],
    [ 'Developer::Dashboard::IndicatorStore::Watch', '_xs_win32_wait', 'Windows notification wait XS entry point is available in the existing module namespace' ],
    [ 'Developer::Dashboard::IndicatorStore::Watch', '_xs_win32_next_change', 'Windows notification rearm XS entry point is available in the existing module namespace' ],
    [ 'Developer::Dashboard::IndicatorStore::Watch', '_xs_win32_close_change', 'Windows notification close XS entry point is available in the existing module namespace' ],
);

for my $contract (@xs_contracts) {
    my ( $package, $method, $description ) = @{$contract};
    ok( $package->can($method), $description );
}

my $root = File::Spec->catdir( $RealBin, File::Spec->updir );
my $makefile = _slurp( File::Spec->catfile( $root, 'Makefile.PL' ) );
my $escape_xs = _slurp( File::Spec->catfile( $root, 'HtmlEscape.xs' ) );
my $native_header = _slurp( File::Spec->catfile( $root, 'Native.h' ) );
like( $makefile, qr/HtmlEscape\.xs/, 'Makefile.PL builds the shared XS extension source' );
like( $escape_xs, qr/^INCLUDE:\s+Native\.xs\s*$/m, 'shared XS extension includes the native API definitions' );
like(
    $native_header,
    qr/LoadLibraryExA\(\s*names\[index\],\s*NULL,\s*LOAD_LIBRARY_SEARCH_DEFAULT_DIRS\)/,
    'Windows OpenSSL loading excludes the unsafe current-directory search path'
);

{
    no strict 'refs';
    no warnings 'once';
    local $Developer::Dashboard::HtmlEscape::XS_LOADED = 1;
    local *{'Developer::Dashboard::IndicatorStore::Watch::can'} = sub {
        my ( $class, $name ) = @_;
        return undef if $name eq '_xs_inotify_init';
        return sub { };
    };
    is(
        Developer::Dashboard::IndicatorStore::Watch::_native_xs_available(),
        0,
        'native watcher availability rejects a missing first XS symbol',
    );
}

{
    no strict 'refs';
    no warnings 'once';
    local $Developer::Dashboard::HtmlEscape::XS_LOADED = 1;
    local *{'Developer::Dashboard::IndicatorStore::Watch::can'} = sub {
        my ( $class, $name ) = @_;
        return sub { } if $name eq '_xs_inotify_init';
        return undef if $name eq '_xs_win32_find_first_change';
        return;
    };
    is(
        Developer::Dashboard::IndicatorStore::Watch::_native_xs_available(),
        0,
        'native watcher availability rejects a missing second XS symbol',
    );
}

done_testing;

# _slurp($path)
# Reads a text file for source-level API contract assertions.
# Input: a filesystem path.
# Output: the file contents; dies with the operating-system error on failure.
sub _slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    local $/;
    return <$fh>;
}

__END__

=head1 NAME

t/677-native-xs-api.t - verify the native XS API contract

=head1 PURPOSE

This test proves that the crypto and filesystem-watcher adapters expose native
entry points from the distribution's existing XS extension without relying on
FFI::Platypus.

=head1 WHY IT EXISTS

The project replaces FFI bindings used for PBKDF2 and operating-system file
notifications with XS. A regression could leave Perl code calling missing
symbols, put the symbols under a new incompatible namespace, or omit the new
translation unit from MakeMaker. These checks make those integration
requirements explicit.

=head1 WHEN TO USE

Run this test after changing the XS source, its MakeMaker mapping, or either
Perl adapter. It is part of the Docker-only native-extension test suite.

=head1 HOW TO USE

  d2 docker compose exec dev prove -Iblib/arch -Iblib/lib -Ilib -lv t/677-native-xs-api.t

The extension must first be built in the same development container with the
normal MakeMaker build steps.

=head1 WHAT USES IT

The native XS adapters in Developer::Dashboard::Crypto::PBKDF2 and
Developer::Dashboard::IndicatorStore::Watch are checked here. Their callers
continue to use the existing public Perl module names.

=head1 EXAMPLES

Example 1: run the focused contract test after building the extension.

  prove -Iblib/arch -Iblib/lib -Ilib -lv t/677-native-xs-api.t

Example 2: run the focused test through the required Docker development
container.

  d2 docker compose exec dev prove -Iblib/arch -Iblib/lib -Ilib -lv t/677-native-xs-api.t

=cut
