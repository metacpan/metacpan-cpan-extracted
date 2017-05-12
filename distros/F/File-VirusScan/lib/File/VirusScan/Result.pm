package File::VirusScan::Result;
use strict;
use warnings;
use Carp;

my @STATES = qw( clean error virus suspicious );
__PACKAGE__->_make_accessors(@STATES);

sub new
{
	my ($class, $args) = @_;
	my $self = {
		state => $args->{state} || 'clean',
		data  => $args->{data},
	};
	return bless $self, $class;
}

sub error
{
	my ($class, $err) = @_;
	return $class->new(
		{
			state => 'error',
			data  => $err,
		}
	);
}

sub virus
{
	my ($class, $vname) = @_;
	return $class->new(
		{
			state => 'virus',
			data  => $vname,
		}
	);
}

sub suspicious
{
	my ($class, $what) = @_;
	return $class->new(
		{
			state => 'suspicious',
			data  => $what,
		}
	);
}

sub clean
{
	my ($class) = @_;
	return $class->new({ state => 'clean', });
}

sub get_state
{
	my ($self) = @_;
	return $self->{state};
}

sub get_data
{
	my ($self) = @_;
	return $self->{data};
}


# Generate is_XXX accessors for all valid states
sub _make_accessors
{
	my ($class, @methods) = @_;
	no strict 'refs';  ## no critic (ProhibitNoStrict)
	foreach my $name (@methods) {
		my $wrappername = "${class}::is_${name}";
		if(!defined &{$wrappername}) {
			*{$wrappername} = sub {
				my ($self) = @_;
				return ($self->{state} eq $name);
			};
		}
	}

	use strict 'refs';
}


1;
__END__

=head1 NAME

File::VirusScan::Result - Results from a single virus scanner

=head1 SYNOPSIS

    use File::VirusScan::Result;

    # It's good
    return File::VirusScan::Result->clean();

    # It's bad
    return File::VirusScan::Result->virus( 'MyDoom' );

    # It's ugly (er, an error)
    return File::VirusScan::Result->error( "Could not execute virus scanner: $!" );

    # And, in the caller....
    if( $result->is_error() ) {
	...
    } elsif ( $result->is_virus() ) {
	...
    }

=head1 DESCRIPTION

Encapsulate all return data from a virus scan.  Currently, just holds
clean/virus/error status, along with a virus name or error message.

=head1 CLASS METHODS

=head2 clean ( )

Create a new object, with no flags set and no data.

=head2 error ( $error_message )

Create a new object with state set to 'error' and data set to
$error_message.

=head2 virus ( $virusname )

Create a new object with state set to 'virus', and data set to $virusname.

=head2 suspicious ( $what )

Create a new object with state set to 'suspicious', and data set to $what.

=head2 new ( \%data )

Main constructor.

=head1 INSTANCE METHODS

=head2 get_state ( )

Return the state of this result object.  Valid states are:

=over 4

=item clean

=item error

=item virus

=item suspicious

=back

=head2 is_clean ( )

Returns true if state is set to 'clean'

=head2 is_error ( )

Returns true if state is set to 'error'

=head2 is_virus ( )

Returns true if state is set to 'virus'

=head2 is_suspicious ( )

Returns true if state is set to 'suspicious'

=head2 get_data ( )

Return data value.

=head1 AUTHOR

Dave O'Neill (dmo@roaringpenguin.com)

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007 Roaring Penguin Software, Inc.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License, version 2, or
(at your option) any later version.
