#!perl -T

use strict;
use warnings;
use Test::More;

use Error::Helper;

{

	package TestOutside;
	use base 'Error::Helper';

	sub new {
		my $self = {
			perror        => undef,
			error         => undef,
			errorLine     => undef,
			errorFilename => undef,
			errorString   => '',
			errorExtra    => { perror_not_fatal => 1 },
		};
		bless $self;

		return $self;
	} ## end sub new
}

#
# warn and errorblank are called at file scope below on purpose, as caller(1) is
# empty there, which previously resulted in undef warnings
#

my $object = TestOutside->new;
$object->{error}       = 1;
$object->{errorString} = 'called at file scope';

my @warnings;
my $stderr = '';
{
	open( my $fh, '>', \$stderr ) or die($!);
	local *STDERR = $fh;
	local $SIG{__WARN__} = sub { push( @warnings, $_[0] ); };

	$object->warn;

	close($fh);
}

is_deeply( \@warnings, [], 'warn outside of a sub does not warn about undef' );
like(
	$stderr,
	qr/^main:1:other: called at file scope at line \d+ in /,
	'warn outside of a sub omits the sub name from the message'
);
is( $Error::Helper::errorSub,          undef,  'errorSub is undef when called outside of a sub' );
is( $Error::Helper::errorSubShort,     undef,  'errorSubShort is undef when called outside of a sub' );
is( $Error::Helper::errorPackage,      'main', 'errorPackage is still set' );
is( $Error::Helper::errorPackageShort, 'main', 'errorPackageShort is still set' );

#
# same for errorblank, which needs a perror set to reach the message
#
$object->{perror} = 1;

my @blank_warnings;
my $blank_stderr = '';
my $returned;
{
	open( my $fh, '>', \$blank_stderr ) or die($!);
	local *STDERR = $fh;
	local $SIG{__WARN__} = sub { push( @blank_warnings, $_[0] ); };

	$returned = $object->errorblank;

	close($fh);
}

is_deeply( \@blank_warnings, [], 'errorblank outside of a sub does not warn about undef' );
like(
	$blank_stderr,
	qr/^main: Unable to blank, as a permanent error is set\./,
	'errorblank outside of a sub omits the sub name from the message'
);
is( $returned, undef, 'errorblank returns undef when a perror is set' );

done_testing();
