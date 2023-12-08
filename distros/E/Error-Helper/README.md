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

- $self->{perror} :: This is set to true is a permanent error is
  present. If note, it needs set to false.
  - Type :: Perl boolean

The following are optional.

- $self->{errorExtra} :: This is a hash reserved for any additional Error::Helper items.

- $self->{errorExtra}{all_errors_fatal} :: If true, this will die when
            $self->warn is called instead of printing the error to
            STDERR. This is for if you want to use it eval for
            capturing errors and this module more for handling
            grabbing error specifics, such as dieing and additional
            code based on the return of $self->errorFlag.
		- Type :: Perl boolean
		- Default :: undef

- $self->{errorExtra}{fatal_errors} :: This is a hash in which the
            keys are errors codes that are fatal. When $self->warn is
            called it will check if the error code is fatal or
            not. $self->{errorExtra}{fatal_errors}{33}=>1 would be
            fatal, but $self->{errorExtra}{fatal_errors}{33}=>0 would
            now.

- $self->{errorExtra}{flags} :: This hash contains error integer to
            flag mapping. The keys are the error integer and the value
            is the flag. For any unmatched error integers, 'other' is returned.

- $self->{errorExtra}{fatal_flags} :: This is a hash in which the keys
            are error flags that are fatal. When $self->warn is called
            it will check if the flag for the error code is fatal or
            not. For the flag foo
            $self->{errorExtra}{fatal_flags}{foo}=>1 would be fatal,
            but $self->{errorExtra}{fatal_flags}{foo}=>0 would now.

- $self->{errorExtra}{perror_not_fatal} :: Controls if $self->{perror}
  is fatal or not.
  - Type :: Perl boolean
  - Default :: undef


Below is a example script showing it all being used.

```perl
#!/usr/bin/env perl
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
				},
				fatal_flags => {
					derp => 1,
				},
				perror_not_fatal => 0,
			},
		};
		bless $self;

		#error if $arg is set to "test"
		if ( defined($arg)
			&& $arg eq "test" )
		{
			$self->{perror}      = 1;
			$self->{error}       = 2;
			$self->{errorString} = 'A value of "test" has been set';
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

		if ( $a eq 'derp' ) {
			$self->{error}       = 3;
			$self->{errorString} = 'foo was called with a value of derp';
			$self->warn;
		}

		return 1;
	} ## end sub foo
}

my $foo_obj = Foo->new( $ARGV[0] );
if ( $foo_obj->error ) {
	warn( 'error:' . $foo_obj->error . ': ' . $foo_obj->errorString );
	exit $foo_obj->error;
}

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
	$foo_obj->warnString('non-fatal error when calling foo');
}
```
