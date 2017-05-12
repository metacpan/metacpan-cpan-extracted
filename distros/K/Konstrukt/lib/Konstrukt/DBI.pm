=head1 NAME

Konstrukt::DBI - Database handle pool

=head1 SYNOPSIS

	#receive connection
	my $db_source = 'DBI:'.$db_type.':'.$db_base.':'.$db_host;
	my $dbh = $Konstrukt::DBI->get_connection($db_source, $db_user, $db_pass) or return undef;
	
	#receive connection with default settings
	my $dbh = $Konstrukt::DBI->get_connection() or return undef;
	
	#do some query
	$dbh->do_stuff("SELECT foo FROM bar WHERE baz = 23");

=head1 DESCRIPTION

This module provides a database handle pool for the current process.
If your plugin or website needs database connection it usually has to create
one via DBI.

This can lead into several DBI connections per process, if there is more than
one plugin used within this process. Each connection will consume resources and
connection time.

So it will be a good idea to create a connection with the same parameters only
once per process and share it over all plugins that need the connection.

This is what this module does: Provide a pool for DBI connections.

Your plugin only has to ask for a DB handle with the appropriate parameters.
This module will create a connection, if there is no cached connection.
Otherwise it will just pass the already existing handle.
It will return undef and bail out an error message, if the connection failed.

Take a look at the L</SYNOPSIS> for the usage of this module.

Additionally, this module will register a error handler, which will catch
the errors that may occur during the database queries. The errors will be logged
and put out on the website, if you use the L<error plugin|Konstrukt::Plugin::error>
on your website.

Note:	A further performance advantage may be achieved by using the module
L<Apache::DBI>, which not only caches the handles within a single request but
also over multiple requests.

=head1 CONFIGURATION

In the konstrukt.settings file:

	#this module may be disabled. it is enabled by default
	#dbi/use    0
	
	#default settings that will be used as defaults, if the specified settings are incomplete
	dbi/source dbi:mysql:database:host
	dbi/user   user
	dbi/pass   pass

As this will be the default settings for connection without an explicit definition
of the connection settings, all modules/plugin which use this module will use these
settings as default connection settings.

=cut

package Konstrukt::DBI;

use strict;
use warnings;

use Konstrukt::Debug;

=head1 METHODS

=head2 new

Constructor of this class

=cut
sub new {
	my ($class) = @_;
	return bless { pool => {}, use => 1 }, $class;
}
#= /new

=head2 init

Initialization of this class

=cut
sub init {
	my ($self) = @_;
	
	#set default settings
	$Konstrukt::Settings->default("dbi/use", 1);
	
	#$self->{pool} = {};
	$self->{use}  = $Konstrukt::Settings->get('dbi/use');
	
	#only proceed, if DBI pool should be used
	if ($self->{use}) {
		require DBI;
		
		#receive and cache defaults from konstrukt.settings
		my $db_source = $Konstrukt::Settings->get('dbi/source');
		my $db_user   = $Konstrukt::Settings->get('dbi/user');
		my $db_pass   = $Konstrukt::Settings->get('dbi/pass');
		
		$self->{defaults} = [$db_source, $db_user, $db_pass] if $db_source and $db_user and $db_pass;
		
		return 1;
	}
}
#= /init

=head2 get_connection

Creates a new DBI Connection if none has been created yet.
Returns the database handle or undef on error.

B<Parameters>:

=over

=item * $db_source - Database source in DBI-format

=item * $db_user - User

=item * $db_pass - Pass

=back

=cut
sub get_connection {
	my ($self, $db_source, $db_user, $db_pass) = @_;
	
	return unless $self->{use};
	
	#use defaults, if parameters incomplete
	if (not $db_source or not $db_user or not $db_pass) {
		if (exists $self->{defaults}) {
			($db_source, $db_user, $db_pass) = @{$self->{defaults}};
		} else {
			$Konstrukt::Debug->error_message("No DB source specified and also no defaults available. Cannot create database connection!", 1);
		}
	}
	
	my $key = "$db_source\n$db_user\n$db_pass";
	
	#create new connection if not yet done
	unless (exists($self->{pool}->{$key}) and defined($self->{pool}->{$key}) and $self->{pool}->{$key}->ping()) {
		if ($self->{pool}->{$key} = DBI->connect($db_source, $db_user, $db_pass, { PrintError => 0 })) {
			#success. add error handler
			$self->{pool}->{$key}->{RaiseError} = 1; 
			$self->{pool}->{$key}->{HandleError} = sub { $self->error_handler(@_) };
			$self->{pool}->{$key}->{ShowErrorStatement} = 1;
		} else {
			#connection error
			$Konstrukt::Debug->error_message("SQL-Error: Could not connect to SQL-server! Error $DBI::err ($DBI::errstr)", 1);
		}
	}
	
	#return database handle
	return $self->{pool}->{$key};
}
#= /get_connection

=head2 error_handler

Handles an error event. Will generate an error message.

B<Parameters>:

=over

=item * $message - The DBI error message

=item * $dbh - The DB handle, within that the error occured

=item * $rv - First value being returned by the method that failed (typically undef)

=back

=cut
sub error_handler {
	my ($self, $message, $dbh, $rv) = @_;
	
	return unless $self->{use};
	
	$Konstrukt::Debug->error_message("SQL-Error: $message") if Konstrukt::Debug::ERROR;
	return 1;
}
#= /error_handler

=head2 disconnect

Disconnects all cached connections

=cut
sub disconnect {
	my ($self) = @_;
	
	return unless $self->{use};
	
	foreach my $key (keys %{$self->{pool}}) {
		unless ($self->{pool}->{$key}->disconnect()) {
			$Konstrukt::Debug->error_message("Couldn't disconnect key $key! Error: $DBI::err ($DBI::errstr)") if Konstrukt::Debug::ERROR;
		}
		undef $self->{pool}->{$key};
		delete $self->{pool}->{$key};
	}
	
	return 1;
}
#= /disconnect

#create global object
sub BEGIN { $Konstrukt::DBI = __PACKAGE__->new() unless defined $Konstrukt::DBI; }

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt>

=cut
