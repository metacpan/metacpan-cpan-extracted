use warnings;
use strict;

{

	package Foo;
	use base 'Error::Helper';

	sub new {
		my $arg = $_[1];

		my $self = {
			perror        => undef,
			error         => undef,
			errorLine     => undef,
			errorFilename => undef,
			errorString   => "",
			errorExtra    => {
				all_errors_fatal => 0,
				flags            => {
					1 => 'UndefArg',
					2 => 'test',
					3 => 'derp',
					4 => 'test2',
				},
				fatal_flags => {
					derp => 1,
				},
				fatal_errors => {
					4 => 1,
				},
				perror_not_fatal => 0,
			},
		};
		bless $self;

		# error if $arg is set to "test"
		if ( defined($arg)
			&& $arg eq "test" )
		{
			$self->{perror}      = 1;
			$self->{error}       = 2;
			$self->{errorString} = 'A value of "test" has been set';
			$self->warn;
			return $self;
		}

		# error if $arg is set to "test2", error fatally
		if ( defined($arg)
			&& $arg eq "test2" )
		{
			$self->{perror}      = 1;
			$self->{error}       = 4;
			$self->{errorString} = 'A value of "test2" has been set';
			$self->warn;
			return $self;
		}

		return $self;
	} ## end sub new

	sub foo {
		my $self = $_[0];
		my $a    = $_[1];

		if ( !$self->errorblank ) {
			return undef;
		}

		if ( !defined($a) ) {
			$self->{error}       = 1;
			$self->{errorString} = 'No value specified';
			$self->warn;
			return undef;
		}

		# this will be fatal as it error flag derp is set to fatal
		if ( $a eq 'derp' ) {
			$self->{error}       = 3;
			$self->{errorString} = 'foo was called with a value of derp';
			$self->warn;
		}

		return 1;
	} ## end sub foo
}

my $foo_obj;
eval {
	$foo_obj = Foo->new( $ARGV[0] );
	# will never be evaulated as perrors are fatal
	if ( $foo_obj->error ) {
		warn( 'error:' . $foo_obj->error . ': ' . $foo_obj->errorString );
		exit $foo_obj->error;
	}
};
if ($@) {
	print 'Error: '
		. $Error::Helper::error
		. "\nError String: "
		. $Error::Helper::errorString
		. "\nError Flag: "
		. $Error::Helper::errorFlag
		. "\nError File: "
		. $Error::Helper::errorFilename
		. "\nError Line: "
		. $Error::Helper::errorLine
		. "\nError Sub: "
		. $Error::Helper::errorSub
		. "\nError Sub Short: "
		. $Error::Helper::errorSubShort
		. "\nError Package: "
		. $Error::Helper::errorPackage
		. "\nError PackageShort: "
		. $Error::Helper::errorPackageShort . "\n";

	exit $Error::Helper::error;
} ## end if ($@)

# catches fatal errors
eval { $foo_obj->foo( $ARGV[1] ); };
if ($@) {
	# do something...
	warn( '$foo_obj->foo( $ARGV[1] ) errored.... ' . $@ );
	if ( $foo_obj->errorFlag eq 'derp' ) {
		warn('error flag derp found... calling again with a value of default');
		$foo_obj->foo('default');
	}
} elsif ( $foo_obj->error ) {
	# do something...
	warn('$foo_obj->foo( $ARGV[1] ) errored');
}
