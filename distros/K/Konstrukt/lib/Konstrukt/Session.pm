#TODO: Test if, the DBI-pool really gets used
#TODO: session TableName parameter seems to be unsupported
#FEATURE: SID tracking through GET/POST
# PHP: url_rewriter.tags "a=href,area=href,frame=src,form=,fieldset="

=head1 NAME

Konstrukt::Session - Session management (Cookies/Session)

=head1 SYNOPSIS

The user will automatically get a session and you (as a plugin developer) can
access the session object easily like this:
	
	$Konstrukt::Session->method();

The following methods are available:
	
	$Konstrukt::Session->activated();             #returns true if the session management is activated
	$sid = $Konstrukt::Session->session_id($key); #get session id
	$Konstrukt::Session->set($key => $value);       #set value
	$boolean = $Konstrukt::Session->exists($key); #does this key exist?
	$value = $Konstrukt::Session->get($key);      #get value
	@keys = $Konstrukt::Session->keys();          #get all keys
	$Konstrukt::Session->delete($key);            #delete specified key
	$Konstrukt::Session->clear();                 #clear all keys

That's currently exactly what the CPAN-module Session offers, since Session
currently is the only method of handling sessions internally. As L<Session> uses
L<Apache::Session> and L<Apache::Session::Flex> internally, you might also want to take
a look at those.

Currently only the MySQL backend has been tested so the settings may not be
apropriate to cover all backends offered by L<Apache::Session>.

=head1 DESCRIPTION

This module provides easy session management for your plugins/websites.

=head1 CONFIGURATION

To use the session management it must be activated in your konstrukt.settings
(it's deactivated by default).

	#Session management
	session/use           1 #default: 0
	#backend module. probably all Apache::Session backends possible, but not tested
	session/store         MySQL
	#dbi source. will default to your Konstrukt::DBI settings, when not specified
	session/source        dbi:mysql:database:host
	session/user          user
	session/pass          pass
	session/timeout       60      #default: delete sessions that haven't been used for 60 minutes
	#session/table        session #currently unsupported
	#only for backend store "File". Note: The path does _not_ relate to your document root!
	session/directory     /tmp/sessions #default: save sessions in dir /tmp/sessions. you have to create that dir!
	#only for backend store "DB_file". Note: The path does _not_ relate to your document root!
	session/file          /tmp/sessions #default: save sessions in file /tmp/sessions
	#show error message, if session could not be loaded or silently create a new one
	session/show_error    1

=cut

package Konstrukt::Session;

use strict;
use warnings;

#which mod_perl are we using? will be 0, 1 or 2
#use constant MODPERL => $ENV{MOD_PERL} ? ( ( exists $ENV{MOD_PERL_API_VERSION} and $ENV{MOD_PERL_API_VERSION} >= 2 ) ? 2 : 1 ) : 0;

use DBI;
use Session;

use Konstrukt::Debug;

=head1 METHODS

=head2 new

Constructor of this class

=cut
sub new {
	my ($class) = @_;
	return bless {}, $class;
}
# /new

=head2 init

Initialization of this class

B<Parameters>: none

=cut
sub init {
	my ($self) = @_;
	
	#Will check for a SID cookie and fetch the stored SID.
	#If no SID could be determined, create one and set the cookie.
	
	#only proceed, if sessions should be used
	if ($Konstrukt::Settings->get('session/use')) {
		#set default settings
		$Konstrukt::Settings->default("session/store"      => "MySQL");
		$Konstrukt::Settings->default("session/timeout"    => 60);
		$Konstrukt::Settings->default("session/directory"  => "/tmp/sessions");
		$Konstrukt::Settings->default("session/file"       => "/tmp/sessions");
		$Konstrukt::Settings->default("session/show_error" => 1);
		
		#get session settings
		my $backend_store  = $Konstrukt::Settings->get('session/store');
		my $db_source      = $Konstrukt::Settings->get('session/source');
		my $db_user        = $Konstrukt::Settings->get('session/user');
		my $db_pass        = $Konstrukt::Settings->get('session/pass');
		#my $db_table       = $Konstrukt::Settings->get('session/table');
		
		#determine backend type
		my ($backend_type, $dbh);
		if ($backend_store =~ /(informix|mysql|oracle|postgres|sybase)/i) {
			#get database handle from pool
			$backend_type = 'db';
			$dbh = $Konstrukt::DBI->get_connection($db_source, $db_user, $db_pass);
		} elsif (lc $backend_store eq 'db_file') {
			$backend_type = 'db_file'
		} elsif (lc $backend_store eq 'file') {
			$backend_type = 'file';
		} else {
			$Konstrukt::Debug->error_message("Unknown Session backend '$backend_type'! Check your 'session/store' setting.") if Konstrukt::Debug::ERROR;
			return;
		}
		$self->{backend_type} = $backend_type;
		
		#build session config
 		$self->{session_config} = {
			Store     => $backend_store,
			Lock      => 'Null',
			Generate  => 'MD5',
			Serialize => 'Storable',
			#database backend?
			(
				$backend_type eq 'db'
				?
				(
					DataSource => $db_source,
					UserName   => $db_user,
					Password   => $db_pass,
					#TableName  => $db_table, #doesn't seem to work
				)
				:
				()
			),
			#got a db handle?
			(
				defined $dbh
				? (Handle => $dbh)
				: ()
			),
			#file backend?
			(
				$backend_type eq 'file'
				? (Directory => $Konstrukt::Settings->get('session/directory'))
				: ()
			),
			#db_file backend?
			(
				$backend_type eq 'db_file'
				? (FileName => $Konstrukt::Settings->get('session/file'))
				: ()
			),
 		};

		#do auto-init here
		$self->install();
		
		#delete old sessions
		$self->session_cleanup();
		
		my $session = undef;
		if (exists $Konstrukt::Handler->{cookies}->{SID} and $Konstrukt::Handler->{cookies}->{SID}->value()) {
			#SID cookie found
			my $SID = $Konstrukt::Handler->{cookies}->{SID}->value();
			#recover session
			$session = Session->new($SID, %{$self->{session_config}});
			#error check
			if (not defined $session) {
				#no valid session
				$Konstrukt::Debug->error_message('Could not recover session! ' . Session->error() . ' Your session probably timed out!')
					if Konstrukt::Debug::ERROR and $Konstrukt::Settings->get('session/show_error');
				#try to create new session
				$session = $self->create_session();
			} else {
				#session successfully recovered
				if (($session->get('remote-ip') || '') ne $Konstrukt::Handler->{ENV}->{REMOTE_ADDR}) {
					#client ip doesn't match the session
					$Konstrukt::Debug->error_message('Your client\'s IP (' . $Konstrukt::Handler->{ENV}->{REMOTE_ADDR} . ') doesn\'t match the one stored in the session (' . ($session->get('remote-ip') || '<no ip set>') . ')!') if Konstrukt::Debug::ERROR;
					#create new, valid session
					$session = $self->create_session();
				} else {
					#hopefully we have a valid session here.
					$self->set_session($session);
				}
			}
		} else {
			#no valid cookie found
			$session = $self->create_session();
		}
		
		return defined $self->{session};
	} else {
		$Konstrukt::Debug->error_message("Session management not activated!") if Konstrukt::Debug::ERROR;
	}
}
# /init

=head2 install

Initializes the backend according the settings (e.g. create tables).

B<Parameters:>

none

=cut
sub install {
	my ($self) = @_;
	return unless $Konstrukt::Settings->get('autoinstall');
	
	if ($self->{backend_type} eq 'db') {
		return $Konstrukt::Lib->plugin_dbi_install_helper($self->{session_config}->{Handle});
	} elsif ($self->{backend_type} eq 'file') {
		#create directory
		my $dir = $Konstrukt::Settings->get('session/directory');
		unless (-d $dir) {
			unless (mkdir $dir) {
				$Konstrukt::Debug->error_message("Couldn't create directory '$dir' (Error: $!)! Check the file permissions or your iblock.settings.") if Konstrukt::Debug::ERROR;
			}
		}
	} elsif ($self->{backend_type} eq 'db_file') {
		#nothing to do here...	
	} else {
		$Konstrukt::Debug->error_message("Unknown backend store '$self->{backend_type}'! Check your 'session/store' setting.") if Konstrukt::Debug::ERROR;
	}
}
# /install

=head2 activated

Returns true if the session management is activated and ready to use.

=cut
sub activated {
	my ($self) = @_;
	return defined $self->{session};
}
# /activated

=head2 create_session

Creates a new session and sets an SID-cookie

B<Parameters>:

none

=cut
sub create_session {
	my ($self) = @_;
	
	unless ($Konstrukt::Settings->get('session/use')) {
		$Konstrukt::Debug->error_message('Session management deactivated! Check session/use in the konstrukt.settings file!') if Konstrukt::Debug::ERROR;
		return undef;
	}
	
	#create session
	my $session = Session->new(undef, %{$self->{session_config}});
	unless ($session) {
		$Konstrukt::Debug->error_message('Could not create session! ' . (Session->error()) . ' Check the setting in the konstrukt.settings file!') if Konstrukt::Debug::ERROR;
		return undef;
	}
	#set ip adress as a little session hijackig-prevention
	$session->set('remote-ip' => $Konstrukt::Handler->{ENV}->{REMOTE_ADDR});
	#create SID cookie
	my $cookie = CGI::Cookie->new(-name => 'SID', -value => $session->session_id());
	#put this cookie into our cookies collection
	$Konstrukt::Handler->{cookies}->{SID} = $cookie;
	
	#session creation done. set session
	$self->set_session($session);
	
	return $session;
}
# /create_session

=head2 set_session

Sets a timestamp for the session and sets it as an attribute of this object

B<Parameters>:

=over

=item * $session - The session object

=back

=cut
sub set_session {
	my ($self, $session) = @_;

	if (not $Konstrukt::Settings->get('session/use')) {
		$Konstrukt::Debug->error_message('Session management deactivated! Check session/use in the konstrukt.settings file!') if Konstrukt::Debug::ERROR;
		return undef;
	}
	
	#update timestamp. this will allow us to purge old session later on
	$session->set('timestamp', time());
	#set as attribute of myself
	$self->{session} = $session;
	
	return 1;
}
# /set_session

=head2 session_cleanup

Deletes old sessions from the database

B<Parameters>:

none

=cut
sub session_cleanup {
	my ($self) = @_;
	
	#only do clean up in db backends
	#TODO: also cleanup file and db_file storage?
	return unless $self->{backend_type} eq 'db';
	
	if (not $Konstrukt::Settings->get('session/use')) {
		$Konstrukt::Debug->error_message('Session management deactivated! Check session/use in the konstrukt.settings file!') if Konstrukt::Debug::ERROR;
		return undef;
	}
	
	my $session_timeout = $Konstrukt::Settings->get('session/timeout');
	#delete old sessions
	my $dbh = $self->{session_config}->{Handle};
	my $query = "DELETE FROM sessions WHERE timestamp < SUBDATE(NOW(), INTERVAL " . $dbh->quote($session_timeout) . " MINUTE)";
	return $dbh->do($query);
}
# /session_cleanup

=head2 session wrapper methods

Wrapper methods for the usual methods of the session backend.
For more indormation take a look at e.g. L<Session>.

(Implemented using AUTOLOAD.)

Methods

=over

=item * set('key', 'value') - Set a value

=item * get('key') - Retrieve a value

=item * remove('key') - Delete a key

=item * clear() - Delete all keys

=item * session_id() - Returns the current session id

=item * exists('key') - Returns true if the key exists

=item * keys() - Returns an array with the keys within the session

=item * delete() - Delete the session

=item * release() - Release the session

=back

=cut
sub AUTOLOAD {
	our $AUTOLOAD;
	my $method = substr($AUTOLOAD, (length __PACKAGE__) + 2);
	if ($method =~ /^(set|get|remove|clear|session_id|exists|keys|delete|release)$/) {
		my $self = shift;
		
		if (not $Konstrukt::Settings->get('session/use')) {
			$Konstrukt::Debug->error_message("Session management deactivated! Check session/use in the konstrukt.settings file!") if Konstrukt::Debug::ERROR;
			return;
		}
		
		unless (exists $self->{session}) {
			#no valid session present
			$Konstrukt::Debug->error_message("No session present!") if Konstrukt::Debug::ERROR;
			return;
		} else {
			return $self->{session}->$method(@_);
		}
	}
}
# /Session wrapper functions

#create global object
sub BEGIN { $Konstrukt::Session = __PACKAGE__->new() unless defined $Konstrukt::Session; }

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Session>, L<Apache::Session>, L<Apache::Session::Flex>, L<Konstrukt>

=cut

__DATA__

-- 8< -- dbi: create -- >8 --

CREATE TABLE IF NOT EXISTS sessions
(
	id          CHAR(32) NOT NULL,
	a_session   TEXT,
	timestamp   TIMESTAMP(14) NOT NULL,
	
	PRIMARY KEY(id),
	INDEX(timestamp)
);