#!perl -T

use strict;
use warnings;
use Test::More;

use Error::Helper;

{

	package Foo::Bar::Baz;
	use base 'Error::Helper';

	sub new {
		my $self = {
			perror        => 1,
			error         => undef,
			errorLine     => undef,
			errorFilename => undef,
			errorString   => '',
			errorExtra    => {
				flags            => { 1 => 'one' },
				perror_not_fatal => 1,
			},
		};
		bless $self;

		return $self;
	} ## end sub new

	sub explode {
		my $self = $_[0];

		$self->{error}       = 1;
		$self->{errorString} = 'exploded';
		$self->warn;

		return undef;
	}
}

# runs $code with STDERR redirected to a string, which is returned
sub capture_stderr {
	my $code = $_[0];

	my $stderr = '';
	open( my $fh, '>', \$stderr ) or die($!);
	{
		local *STDERR = $fh;
		$code->();
	}
	close($fh);

	return $stderr;
} ## end sub capture_stderr

my $object = Foo::Bar::Baz->new;
capture_stderr( sub { $object->explode } );

#
# the variables mapped to the per object ones
#
is( $Error::Helper::error,       1,          'error is set' );
is( $Error::Helper::errorString, 'exploded', 'errorString is set' );
is( $Error::Helper::errorFlag,   'one',      'errorFlag is set' );
is( $Error::Helper::perror,      1,          'perror is set' );
like( $Error::Helper::errorFilename, qr/03-shared-variables\.t$/, 'errorFilename is set' );
like( $Error::Helper::errorLine,     qr/^\d+$/,                   'errorLine is set' );

#
# the ones with no per object mapping
#
is( $Error::Helper::errorSub,          'Foo::Bar::Baz::explode', 'errorSub is the full sub name' );
is( $Error::Helper::errorSubShort,     'explode',                'errorSubShort is just the sub name' );
is( $Error::Helper::errorPackage,      'Foo::Bar::Baz',          'errorPackage is the full package name' );
is( $Error::Helper::errorPackageShort, 'Baz', 'errorPackageShort is the last item in the name space' );

#
# blanking clears all of them
#
$object->{perror} = undef;
is( $object->errorblank, 1, 'errorblank returns 1' );

is( $Error::Helper::error,             undef, 'errorblank clears error' );
is( $Error::Helper::perror,            undef, 'errorblank clears perror' );
is( $Error::Helper::errorString,       '',    'errorblank clears errorString' );
is( $Error::Helper::errorFlag,         undef, 'errorblank clears errorFlag' );
is( $Error::Helper::errorFilename,     undef, 'errorblank clears errorFilename' );
is( $Error::Helper::errorLine,         undef, 'errorblank clears errorLine' );
is( $Error::Helper::errorSub,          undef, 'errorblank clears errorSub' );
is( $Error::Helper::errorSubShort,     undef, 'errorblank clears errorSubShort' );
is( $Error::Helper::errorPackage,      undef, 'errorblank clears errorPackage' );
is( $Error::Helper::errorPackageShort, undef, 'errorblank clears errorPackageShort' );

done_testing();
