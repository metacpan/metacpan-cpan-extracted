#!/usr/bin/perl

#==============================================================================
# Ham::Fldigi
# v0.002
# (c) 2012 Andy Smith, M0VKG
#==============================================================================
# DESCRIPTION
# Perl extensions for managing Fldigi instances
#==============================================================================
# SYNOPSIS
# use Ham::Fldigi;
# my $f = new Ham::Fldigi('LogLevel' => 4,
#                         'LogFile' => './debug.log',
#                         'LogPrint' => 1,
#                         'LogWrite' => 1);
# my $client = $f->client('Hostname' => 'localhost',
#                         'Port' => '7362',
#                         'Name' => 'default');
# $client->modem("BPSK125");
# $client->send("CQ CQ CQ DE M0VKG M0VKG M0VKG KN");
#==============================================================================

# Perl documentation is provided inline in pod format.
# To view, run:-
# perldoc Ham::Fldigi

=head1 NAME

Ham::Fldigi - Perl extensions for managing Fldigi instances

=head1 SYNOPSIS

	use Ham::Fldigi;

=head1 DESCRIPTION

This module itself doesn't do much - see C<Ham::Fldigi::Client> for details.

=head2 EXPORT

None by default.
=cut

package Ham::Fldigi;

use 5.012004;
use strict;
use warnings;

our $VERSION = '0.002';

use Moose;
use Ham::Fldigi::Client;
use Ham::Fldigi::Shell;
use base qw(Ham::Fldigi::Debug);

has 'clients' => (is => 'ro', isa => 'HashRef[Ham::Fldigi::Client');

=head1 CONSTRUCTORS

=head2 Fldigi->new([I<LogLevel> => n, ] [I<LogFile> => filename, ] [I<LogPrint> => (0|1), ] [I<LogWrite> => (0|1)]) 

Creates a new B<Ham::Fldigi> object with the specified options.

=item * 

I<LogLevel> is an integer between 0 and 4, with 0 being no logging at all, 1 for errors, 2 for warnings, 3 for notices and 4 for debugging. This defaults to B<2>, which will display and log errors and warnings.

=item *

I<LogFile> is the path to the logfile that will be written to.

=item *

I<LogPrint> is whether to print log messages to screen or not.

=item *

I<LogWrite> is whether to log messages to the logfile or not.

=cut

sub new {
	
	# Get the class name
	my($class) = shift;
	my(%params) = @_;

	my $self = {
		'version' => $VERSION,
	};

	if(defined($params{'LogLevel'})) {
		$Ham::Fldigi::Debug::debug_level = $params{'LogLevel'};
	}
	if(defined($params{'LogFile'})) {
		$Ham::Fldigi::Debug::debug_file = $params{'LogFile'};
	}
	if(defined($params{'LogPrint'})) {
		$Ham::Fldigi::Debug::debug_print = $params{'LogPrint'};
	}
	if(defined($params{'LogWrite'})) {
		$Ham::Fldigi::Debug::debug_write = $params{'LogWrite'};
	}

	bless $self, $class;

	$self->debug("Constructor called. Version is ".$VERSION.".");
	$self->debug("Returning...");
	return $self;
}

=head1 METHODS

=head2 Fldigi->client('Hostname' => I<hostname>, 'Port' => I<port>, 'Name' => I<name>)

Creates a new B<Ham::Fldigi::Client> object with the specified arguments. See C<Ham::Fldigi::Client> for more details.

=cut

sub client {

	my ($self, %params) = @_;

	# Create a new Ham::Fldigi::Client object
	my $c = Ham::Fldigi::Client->new(%params);
	if(!defined $c) {
		# We didn't get a Ham::Fldigi::Client object back
		$self->error("Error creating Ham::Fldigi::Client object!");
		return undef;
	} else {
		# Add the client to the 'clients' hash
		$self->{clients}{$c->name} = $c;
	}

	# Return the previously returned Ham::Fldigi::Client object
	return $c;
}

=head2 Fldigi->shell()

Creates an Fldigi shell object.

This is an attempt to create a more featured replacement for Fldigi's bundled 'fldigi-shell'. This is still under development and shouldn't be used yet.

=cut

sub shell {

	my ($self, %params) = @_;

	$params{'Parent'} = $self;

	my $s = Ham::Fldigi::Shell->new(%params);

	return $s;

}

1;
__END__

=head1 SEE ALSO

The source code for this module is hosted on Github at L<https://github.com/m0vkg/Perl-Ham-Fldigi>.

=head1 AUTHOR

Andy Smith M0VKG, E<lt>andy@m0vkg.org.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Andy Smith

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

