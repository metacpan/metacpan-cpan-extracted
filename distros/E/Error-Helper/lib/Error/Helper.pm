package Error::Helper;

use warnings;
use strict;

=head1 NAME

Error::Helper - Provides some easy error related methods.

=head1 VERSION

Version 2.0.0

=cut

our $VERSION = '2.0.0';

=head1 SYNOPSIS

Below is a example script showing it's usage.

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

            # this will be fatal as it error flag derp is set to fatal
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

    # catches fatal errors
    eval{
        $foo_obj->foo( $ARGV[1] );
    };
    if ($@) {
    	# do something...
    	warn( '$foo_obj->foo( $ARGV[1] ) errored.... '.$@);
    	if ($foo_obj->errorFlag eq 'derp') {
	    	warn('error flag derp found... calling again with a value of default');
    		$foo_obj->foo( 'default' );
    	}
    } elsif ($foo->error) {
    	# do something...
       	warn( '$foo_obj->foo( $ARGV[1] ) errored');
    }

There are five required variables in the blessed hash object.

    - $self->{error} :: This contains the current error code.
        - Type :: int or undef

    - $self->{errorFilename} :: File from which $self->warn was called.
        - Type :: string or undef

    - $self->{errorLine} :: Line from which $self->warn was called.
        - Type :: int or undef

    - $self->{errorString} :: This contains a description of the current error.
        - Type :: string or undef

    - $self->{perror} :: This is set to true is a permanent error is present.
            If note, it needs set to false.
        - Type :: Perl boolean

The following are optional.

    - $self->{errorExtra} :: This is a hash reserved for any additional Error::Helper items.

    - $self->{errorExtra}{all_errors_fatal} :: If true, this will die when $self->warn is called instead of
            printing the error to STDERR. This is for if you want to use it eval for capturing errors and this
            module more for handling grabbing error specifics, such as dieing and additional code based on the
            return of $self->errorFlag.
        - Type :: Perl boolean
        - Default :: undef

    - $self->{errorExtra}{fatal_errors} :: This is a hash in which the keys are errors codes that are fatal. When
            $self->warn is called it will check if the error code is fatal or not. $self->{errorExtra}{fatal_errors}{33}=>1
            would be fatal, but $self->{errorExtra}{fatal_errors}{33}=>0 would now.

    - $self->{errorExtra}{flags} :: This hash contains error integer to flag mapping. The
            keys are the error integer and the value is the flag. For any unmatched error
            integers, 'other' is returned.

    - $self->{errorExtra}{fatal_flags} :: This is a hash in which the keys are error flags that are fatal. When
            $self->warn is called it will check if the flag for the error code is fatal or not. For the flag foo
            $self->{errorExtra}{fatal_flags}{foo}=>1 would be fatal, but
            $self->{errorExtra}{fatal_flags}{foo}=>0 would now.

    - $self->{errorExtra}{perror_not_fatal} :: Controls if $self->{perror} is fatal or not.
        - Type :: Perl boolean
        - Default :: undef

=head1 METHODS

=head2 error

Returns the current error code and true if there is an error.

If there is no error, undef is returned.

    if($self->error){
        # do something
    }

=cut

sub error {
	return $_[0]->{error};
}

=head2 errorblank

This blanks the error storage and is only meant for internal usage.

It does the following.

	$self->{error}         = undef;
	$self->{errorFilename} = undef;
	$self->{errorLine}     = undef;
	$self->{errorString}   = "";

If $self->{perror} is set, it will not be able to blank any current
errors.

=cut

sub errorblank {
	my $self = $_[0];

	if ( $self->{perror} ) {
		my ( $package, $filename, $line ) = caller;

		#get the calling sub
		my @called     = caller(1);
		my $subroutine = $called[3];
		$subroutine =~ s/.*\:\://g;

		$package =~ s/\:\:/\-/g;

		my $error
			= $package . ' '
			. $subroutine
			. ': Unable to blank, as a permanent error is set. '
			. 'error="'
			. $self->error
			. '" errorFilename="'
			. $self->errorFilename
			. '" errorLine="'
			. $self->errorLine
			. '" errorString="'
			. $self->errorString
			. '" file="'
			. $filename
			. ' line='
			. $line;

		if ( !$self->{errorExtra}{perror_not_fatal} ) {
			die($error);
		} else {
			print STDERR $error;
		}

		return undef;
	} ## end if ( $self->{perror} )

	$self->{error}         = undef;
	$self->{errorFilename} = undef;
	$self->{errorLine}     = undef;
	$self->{errorString}   = "";

	return 1;
} ## end sub errorblank

=head2 errorFilename

This returns the filename in which the error occured or other wise returns undef.

    if($self->error){
        print 'error happened in '.$self->errorFilename."\n";
    }

=cut

sub errorFilename {
	return $_[0]->{errorFilename};
}

=head2 errorFlag

This returns the error flag for the current error.

If none is set, undef is returned.

This may be used in a similar manner as the error method.

    if ( $self->errorFlag ){
        if ( $self->errorFlag eq 'foo' ){
            # do something
        }else{
            die('error flag '.$self->errorFlag.' can not be handled');
        }
    }

=cut

sub errorFlag {
	if ( !$_[0]->{error} ) {
		return undef;
	}

	if (  !defined( $_[0]->{errorExtra} )
		|| ref( $_[0]->{errorExtra} ) ne 'HASH'
		|| ( !defined( $_[0]->{errorExtra}{flags} ) )
		|| ref( $_[0]->{errorExtra}{flags} ) ne 'HASH'
		|| !defined( $_[0]->{errorExtra}{flags}{ $_[0]->{error} } ) )
	{
		return 'other';
	}

	return $_[0]->{errorExtra}{flags}{ $_[0]->{error} };
} ## end sub errorFlag

=head2 errorLine

This returns the filename in which the error occured or other wise returns undef.

    if($self->error){
        print 'error happened at line '.$self->errorLine."\n";
    }

=cut

sub errorLine {
	return $_[0]->{errorLine};
}

=head2 errorString

Returns the error string if there is one. If there is not,
it will return ''.

    if($self->error){
        warn('error: '.$self->error.":".$self->errorString);
    }

=cut

sub errorString {
	return $_[0]->{errorString};
}

=head2 perror

This returns a Perl boolean for if there is a permanent
error or not.

    if($self->perror){
                warn('A permanent error is set');
    }

=cut

sub perror {
	return $_[0]->{perror};
}

=head2 warn

Throws a warn like error message based using the contents of $self->errorString

    $self->warn;

=cut

sub warn {
	my $self = $_[0];

	my ( $package, $filename, $line ) = caller;

	$self->{errorFilename} = $filename;
	$self->{errorLine}     = $line;

	#get the calling sub
	my @called     = caller(1);
	my $subroutine = $called[3];
	$subroutine =~ s/.*\:\://g;

	$package =~ s/\:\:/\-/g;

	my $error
		= $package . ' '
		. $subroutine . ':'
		. $self->error . ':'
		. $self->errorFlag . ': '
		. $self->errorString
		. ' at line '
		. $line . ' in '
		. $filename . "\n";

	if (
		$self->{errorExtra}{all_fatal}
		|| (
			$self->perror
			&& !(
				   defined( $self->{errorExtra} )
				&& ref( $self->{errorExtra} ) eq 'HASH'
				&& $self->{errorExtra}{perror_not_fatal}
			)
		)
		|| (   defined( $self->{errorExtra} )
			&& ref( $self->{errorExtra} ) eq 'HASH'
			&& defined( $self->{errorExtra}{fatal_errors} )
			&& ref( $self->{errorExtra}{fatal_errors} ) eq 'HASH'
			&& $self->{errorExtra}{fatal_errors}{ $self->{error} } )
		|| (   defined( $self->{errorExtra} )
			&& ref( $self->{errorExtra} ) eq 'HASH'
			&& defined( $self->{errorExtra}{fatal_flags} )
			&& ref( $self->{errorExtra}{fatal_flags} ) eq 'HASH'
			&& $self->{errorExtra}{fatal_flags}{ $self->errorFlag } )
		)
	{
		die($error);
	} ## end if ( $self->{errorExtra}{all_fatal} || ( $self...))

	print STDERR $error;
} ## end sub warn

=head2 warnString

Throws a warn like error in the same for mate as warn, but with a freeform message.

This will not trigger any of the fatality checks. It will also not set any of the error values.

    $self->warnString('some error');

=cut

sub warnString {
	my $self   = $_[0];
	my $string = $_[1];

	if ( !defined($string) ) {
		$string = 'undef';
	}

	my ( $package, $filename, $line ) = caller;

	#get the calling sub
	my @called     = caller(1);
	my $subroutine = $called[3];
	if (defined($subroutine)) {
		$subroutine =~ s/.*\:\://g;
		$package =~ s/\:\:/\-/g;
		print STDERR $package . ' ' . $subroutine . ': ' . $string . ' in ' . $filename . ' at line ' . $line . "\n";
	}else {
		print STDERR $package . ': ' . $string . ' in ' . $filename . ' at line ' . $line . "\n";
	}
} ## end sub warnString

=head1 ERROR FLAGS

Error flags are meant to be short non-spaced strings that are easier to remember than a specific error integer.

'other' is the generic error flag for when one is not defined.

An error flag should never evaluate to false if an error is present.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-error-helper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Error-Helper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Error::Helper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Error-Helper>

=item * Search CPAN

<https://metacpan.org/dist/Error-Helper>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2023 Zane C. Bowers-Hadley.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Error::Helper
