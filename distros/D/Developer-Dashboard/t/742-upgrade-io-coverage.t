#!/usr/bin/env perl

use strict;
use warnings;

# CORE::GLOBAL overrides must exist before the module under test compiles.
# close fails only for handles registered in %HANDLE_FAIL, and chmod fails
# only for paths matching @CHMOD_FAIL_RE, so both error branches run for any
# uid.
our ( %HANDLE_FAIL, @CHMOD_FAIL_RE );

BEGIN {
    require Scalar::Util;
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
    *CORE::GLOBAL::chmod = sub {
        if ( @_ == 2 && defined $_[1] && grep { $_[1] =~ $_ } @CHMOD_FAIL_RE ) {
            $! = 1;
            return 0;
        }
        return CORE::chmod(@_);
    };
}

use Test::More;
use File::Temp ();
use HTTP::Response;

use lib 'lib';

use Developer::Dashboard::CLI::Upgrade;

my $installer = "#!/bin/sh\n# Developer Dashboard install progress\ngit clone https://github.com/manif3station/developer-dashboard.git\n";

{
    package Test::Upgrade::UA;
    sub new { bless {}, shift }
    sub get {
        my $r = HTTP::Response->new( 200, 'OK' );
        $r->content($installer);
        return $r;
    }
}

# Default platform and default user agent resolution.
{
    my $out = '';
    open my $fh, '>', \$out or die;
    is( Developer::Dashboard::CLI::Upgrade::run_upgrade( args => ['--dry-run'], out => $fh ), 0, 'dry run without a forced platform succeeds' );
    like( $out, qr/Platform: (?:unix|windows)/, 'the detected platform is reported' );
}
{
    no warnings 'redefine';
    my $built = 0;
    local *Developer::Dashboard::CLI::Upgrade::_user_agent = sub { $built++; return Test::Upgrade::UA->new };
    my $ran;
    my $code = Developer::Dashboard::CLI::Upgrade::run_upgrade( args => [], platform => 'unix', runner => sub { $ran = shift; return 0 } );
    is( $code, 0, 'upgrade runs with the default user agent builder' );
    is( $built, 1, 'the default user agent builder was used' );
    is( $ran->[0], 'sh', 'the installer runs through sh' );
}

# close failure on the downloaded installer.
{
    no warnings 'redefine';
    local *Developer::Dashboard::CLI::Upgrade::tempfile = sub {
        my ( $fh, $path ) = File::Temp::tempfile(@_);
        $HANDLE_FAIL{ Scalar::Util::refaddr($fh) } = 1;
        return ( $fh, $path );
    };
    my $err = eval { Developer::Dashboard::CLI::Upgrade::run_upgrade( args => [], platform => 'unix', ua => Test::Upgrade::UA->new, runner => sub { 0 } ); 1 } ? '' : $@;
    like( $err, qr/Unable to close downloaded Developer Dashboard installer/, 'a close failure on the installer file is fatal' );
}

# chmod failure on the downloaded installer.
{
    local @CHMOD_FAIL_RE = ( qr/developer-dashboard-upgrade-/ );
    my $err = eval { Developer::Dashboard::CLI::Upgrade::run_upgrade( args => [], platform => 'unix', ua => Test::Upgrade::UA->new, runner => sub { 0 } ); 1 } ? '' : $@;
    like( $err, qr/Unable to secure downloaded Developer Dashboard installer/, 'a chmod failure on the installer file is fatal' );
}

done_testing;

__END__

=pod

=head1 NAME

t/742-upgrade-io-coverage.t - covers the default-resolution and file-error branches of Developer::Dashboard::CLI::Upgrade

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It drives the default platform and user agent resolution and forces close and chmod failures on the downloaded installer through CORE::GLOBAL overrides that work for any uid.

=head1 WHY IT EXISTS

It exists because lib/ must reach 100 percent Devel::Cover coverage with no uncoverable annotations.

=head1 WHEN TO USE

Use this file when you change run_upgrade, or when a coverage run reports one of those branches as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/742-upgrade-io-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification.

=head1 EXAMPLES

Example 1:

  prove -lv t/742-upgrade-io-coverage.t

Run this coverage-gap test by itself while editing the upgrade command.

=cut
