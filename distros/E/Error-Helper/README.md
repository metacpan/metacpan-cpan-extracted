# Error::Helper Synopsis

This module allows one to use it as a base for adding various error
handling methods to their module. Error checking can be done in two
methods, either calling one of error checking functions and seeing if
it is present or setting that error code/flag to be fatal and
collecting failures via eval and then when processing $@, then check
the error code/flag.

There are five required variables in the blessed hash object.

- $self->{error} :: This contains the current error code.
  - Type :: int or undef

- $self->{errorFilename} :: File from which $self->warn was called.
  - Type :: string or undef

- $self->{errorLine} :: Line from which $self->warn was called.
  - Type :: int or undef

- $self->{errorString} :: This contains a description of the current error.
  - Type :: string or undef

- $self->{perror} :: This is set to true if a permanent error is
  present. If not, it needs to be set to false.
  - Type :: Perl boolean

The following are optional.

- $self->{errorExtra} :: This is a hash reserved for any additional Error::Helper items.

- $self->{errorExtra}{all_errors_fatal} :: If true, this will die when
  $self->warn is called instead of printing the error to STDERR. This
  is for if you want to use it eval for capturing errors and this
  module more for handling grabbing error specifics, such as dying and
  additional code based on the return of $self->errorFlag.
  - Type :: Perl boolean
  - Default :: undef
  - Alias :: all_fatal, which is what 2.0.0 and 2.1.0 checked for and
    is still honored.

- $self->{errorExtra}{fatal_errors} :: This is a hash in which the
  keys are error codes that are fatal. When $self->warn is called it
  will check if the error code is fatal or not. Setting
  $self->{errorExtra}{fatal_errors}{33}=1 would make error 33 fatal,
  but $self->{errorExtra}{fatal_errors}{33}=0 would not.
  - Type :: hash

- $self->{errorExtra}{flags} :: This hash contains error integer to
  flag mapping. The keys are the error integer and the value is the
  flag. For any unmatched error integers, 'other' is returned.
  - Type :: hash

- $self->{errorExtra}{fatal_flags} :: This is a hash in which the keys
  are error flags that are fatal. When $self->warn is called it will
  check if the flag for the error code is fatal or not. For the flag
  foo, setting $self->{errorExtra}{fatal_flags}{foo}=1 would make it
  fatal, but $self->{errorExtra}{fatal_flags}{foo}=0 would not.
  - Type :: hash

- $self->{errorExtra}{perror_not_fatal} :: Controls if $self->{perror}
  is fatal or not.
  - Type :: Perl boolean
  - Default :: undef

This module also sets several other variables as well for when
something like a new method is called and dies, before something
blessed can be returned. These allow examining the error that resulted
in it dying.

The following are mapped to the ones above.

    $Error::Helper::perror
    $Error::Helper::error
    $Error::Helper::errorString
    $Error::Helper::errorFlag
    $Error::Helper::errorFilename
    $Error::Helper::errorLine

The following don't have mappings above.

- $Error::Helper::errorSub :: The sub that warn was called from.

- $Error::Helper::errorSubShort :: Same as errorSub, but everything
  prior to the subname is removed. So Foo::bar would become bar.

- $Error::Helper::errorPackage :: The package that warn was called from.

- $Error::Helper::errorPackageShort :: Same as errorPackage, but
  everything prior to the last item in the name space is removed. So
  Foo::Foo::Bar would just become Bar.

Below is an example script showing it all being used.

```perl
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
		my $self  = $_[0];
		my $value = $_[1];

		if ( !$self->errorblank ) {
			return undef;
		}

		if ( !defined($value) ) {
			$self->{error}       = 1;
			$self->{errorString} = 'No value specified';
			$self->warn;
			return undef;
		}

		# this will be fatal as the error flag derp is set to fatal
		if ( $value eq 'derp' ) {
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
	# not reached when a perror is set, as perrors are fatal by default
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
```
