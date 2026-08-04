#!perl -T

use strict;
use warnings;
use Test::More;

use Error::Helper;

{

	package TestBasic;
	use base 'Error::Helper';

	sub new {
		my $self = {
			perror        => undef,
			error         => undef,
			errorLine     => undef,
			errorFilename => undef,
			errorString   => '',
			errorExtra    => {
				flags => {
					1 => 'UndefArg',
					2 => 'test',
				},
			},
		};
		bless $self;

		return $self;
	} ## end sub new

	sub mapped_error {
		my $self = $_[0];

		$self->{error}       = 1;
		$self->{errorString} = 'no arg specified';
		$self->warn;

		return undef;
	}

	sub unmapped_error {
		my $self = $_[0];

		$self->{error}       = 42;
		$self->{errorString} = 'an error with no flag';
		$self->warn;

		return undef;
	}

	sub bare_error {
		my $self = $_[0];

		$self->warn;

		return undef;
	}

	sub free_form {
		my $self = $_[0];

		$self->warnString('a freeform message');

		return 1;
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

my $object = TestBasic->new;
isa_ok( $object, 'TestBasic', 'the test object' );

#
# nothing has errored yet
#
is( $object->error,         undef, 'error is undef prior to any error' );
is( $object->errorString,   '',    'errorString is blank prior to any error' );
is( $object->errorFilename, undef, 'errorFilename is undef prior to any error' );
is( $object->errorLine,     undef, 'errorLine is undef prior to any error' );
is( $object->errorFlag,     undef, 'errorFlag is undef prior to any error' );
ok( !$object->perror, 'perror is false prior to any error' );

#
# a error with a flag mapped to it
#
my $stderr = capture_stderr( sub { $object->mapped_error } );
like(
	$stderr,
	qr/^TestBasic mapped_error:1:UndefArg: no arg specified at line \d+ in /,
	'warn prints the expected message to STDERR'
);
is( $object->error,       1,                  'error is set to the error code' );
is( $object->errorString, 'no arg specified', 'errorString is set' );
is( $object->errorFlag,   'UndefArg',         'errorFlag returns the mapped flag' );
like( $object->errorFilename, qr/01-basics\.t$/, 'errorFilename is the file warn was called from' );
like( $object->errorLine,     qr/^\d+$/,         'errorLine is the line warn was called from' );

#
# blanking it
#
is( $object->errorblank,    1,     'errorblank returns 1' );
is( $object->error,         undef, 'errorblank clears error' );
is( $object->errorString,   '',    'errorblank clears errorString' );
is( $object->errorFilename, undef, 'errorblank clears errorFilename' );
is( $object->errorLine,     undef, 'errorblank clears errorLine' );
is( $object->errorFlag,     undef, 'errorFlag is undef once blanked' );

#
# a error with no flag mapped to it
#
capture_stderr( sub { $object->unmapped_error } );
is( $object->error,     42,      'the unmapped error code is set' );
is( $object->errorFlag, 'other', q{errorFlag returns 'other' for a unmapped error code} );
$object->errorblank;

#
# warn with neither error nor errorString set
#
# errorString is only defaulted when it is undef, which is the state of a fresh
# object, as errorblank sets it to a empty string
#
$object->{errorString} = undef;
capture_stderr( sub { $object->bare_error } );
is( $object->error,       3060, 'warn defaults to error 3060 when no error code is set' );
is( $object->errorString, 'unknown... warn called without errorString being set', 'warn sets a default errorString' );
$object->errorblank;

#
# warnString
#
my $free_form = capture_stderr( sub { $object->free_form } );
like(
	$free_form,
	qr/^TestBasic free_form: a freeform message in .*01-basics\.t at line \d+$/m,
	'warnString prints the expected message to STDERR'
);
is( $object->error,       undef, 'warnString does not set error' );
is( $object->errorString, '',    'warnString does not set errorString' );

done_testing();
