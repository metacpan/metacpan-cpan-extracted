#!perl -T

use strict;
use warnings;
use Test::More;

use Error::Helper;

{

	package TestFatal;
	use base 'Error::Helper';

	sub new {
		my $errorExtra = $_[1];

		my $self = {
			perror        => $_[2],
			error         => undef,
			errorLine     => undef,
			errorFilename => undef,
			errorString   => '',
			errorExtra    => $errorExtra,
		};
		bless $self;

		return $self;
	} ## end sub new

	sub boom {
		my $self = $_[0];

		$self->{error}       = 3;
		$self->{errorString} = 'boom';
		$self->warn;

		return 1;
	}
}

# returns 'died' or 'warned' for a object built with the passed errorExtra and perror
sub fatality_of {
	my $errorExtra = $_[0];
	my $perror     = $_[1];

	my $object = TestFatal->new( $errorExtra, $perror );

	my $stderr = '';
	open( my $fh, '>', \$stderr ) or die($!);
	my $lived;
	{
		local *STDERR = $fh;
		$lived = eval { $object->boom; 1; };
	}
	close($fh);

	return $lived ? 'warned' : 'died';
} ## end sub fatality_of

my $flags = { 3 => 'derp' };

#
# nothing marked as fatal
#
is( fatality_of( {} ), 'warned', 'a error is not fatal by default' );
is( fatality_of( { flags            => $flags } ),     'warned', 'a flagged error is not fatal by default' );
is( fatality_of( { all_errors_fatal => 0 } ),          'warned', 'all_errors_fatal=0 is not fatal' );
is( fatality_of( { all_fatal        => 0 } ),          'warned', 'all_fatal=0 is not fatal' );
is( fatality_of( { fatal_errors     => { 3 => 0 } } ), 'warned', 'fatal_errors=0 for the error code is not fatal' );
is( fatality_of( { fatal_errors     => { 4 => 1 } } ), 'warned', 'fatal_errors for a other error code is not fatal' );
is( fatality_of( { flags            => $flags, fatal_flags => { derp => 0 } } ),
	'warned', 'fatal_flags=0 for the error flag is not fatal' );
is( fatality_of( { flags => $flags, fatal_flags => { other => 1 } } ),
	'warned', 'fatal_flags for a other error flag is not fatal' );

#
# marked as fatal
#
is( fatality_of( { all_errors_fatal => 1 } ), 'died', 'all_errors_fatal=1 is fatal' );
is( fatality_of( { all_fatal        => 1 } ), 'died', 'all_fatal=1 is still honored for backwards compatibility' );
is( fatality_of( { all_errors_fatal => 1, all_fatal => 1 } ), 'died', 'both fatal keys set is fatal' );
is( fatality_of( { fatal_errors     => { 3 => 1 } } ),        'died', 'fatal_errors=1 for the error code is fatal' );
is( fatality_of( { flags            => $flags, fatal_flags => { derp => 1 } } ),
	'died', 'fatal_flags=1 for the error flag is fatal' );
is( fatality_of( { fatal_flags => { other => 1 } } ),
	'died', q{fatal_flags=1 for 'other' is fatal for a unmapped error code} );

#
# perror
#
is( fatality_of( {},                        1 ), 'died',   'a perror is fatal by default' );
is( fatality_of( { perror_not_fatal => 1 }, 1 ), 'warned', 'perror_not_fatal=1 makes a perror non fatal' );

#
# errorblank can not blank a perror
#
# the error values are set to what warn would have left behind
my $blocked = TestFatal->new( {}, 1 );
$blocked->{error}         = 3;
$blocked->{errorString}   = 'boom';
$blocked->{errorFilename} = __FILE__;
$blocked->{errorLine}     = __LINE__;
ok( !eval { $blocked->errorblank; 1; }, 'errorblank dies when a perror is set' );
like( $@, qr/Unable to blank, as a permanent error is set/, 'errorblank dies with the expected message' );

my $noisy = TestFatal->new( { perror_not_fatal => 1 }, 1 );
$noisy->{error}         = 3;
$noisy->{errorString}   = 'boom';
$noisy->{errorFilename} = __FILE__;
$noisy->{errorLine}     = __LINE__;

my $stderr = '';
open( my $fh, '>', \$stderr ) or die($!);
my $returned;
{
	local *STDERR = $fh;
	$returned = $noisy->errorblank;
}
close($fh);

is( $returned, undef, 'errorblank returns undef when a perror is set and perror_not_fatal is true' );
like( $stderr, qr/Unable to blank, as a permanent error is set/, 'errorblank prints to STDERR instead of dying' );
like( $stderr, qr/file="[^"]+" line="\d+"$/,                     'the errorblank message quotes file and line' );
is( $noisy->error, 3, 'the error is left in place when it can not be blanked' );

done_testing();
