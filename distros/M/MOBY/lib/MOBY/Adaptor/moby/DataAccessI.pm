#$Id: DataAccessI.pm,v 1.3 2008/09/02 13:09:30 kawas Exp $
# Write generic AUTOLOAD routines
package MOBY::Adaptor::moby::DataAccessI;
use strict;
use Carp;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOBY::Adaptor::moby::DataAccessI - This file may need to be renamed and may not make sense as
an interface.

=cut

=head1 SYNOPSIS

 use MOBY::Adaptor::moby::queryapi::mysql  # implements this interface def
 my $m = MOBY::Adaptor::moby::queryapi::mysql->new(
    username => 'user',
    password => 'pass',
    dbname => 'mobycentral',
    port => '3306',
    sourcetype => 'DBD::mysql');

=cut

=head1 DESCRIPTION

The BioMOBY registry data access interface

=head1 AUTHORS

Mark Wilkinson markw_at_ illuminae dot com
Dennis Wang oikisai _at_ hotmail dot com
BioMOBY Project:  http://www.biomoby.org


=cut

=head1 METHODS


=head2 new

 Usage     :	my $MOBY = MOBY::Client::Central->new(Registries => \%regrefs)
 Function  :	connect to one or more MOBY-Central
                registries for searching
 Returns   :	MOBY::Client::Central object
 Args      :    Registries - optional.
 Notes     :    Each registry must have a different


=cut

sub new {
	my ( $caller, %args ) = @_;
	my $caller_is_obj = ref($caller);
	my $class         = $caller_is_obj || $caller;

	my $self = bless {}, $class;

	foreach my $attrname ( $self->_standard_keys_a ) {
		if ( exists $args{$attrname} && defined $args{$attrname} ) {
			$self->{$attrname} = $args{$attrname};
		}
		elsif ($caller_is_obj) {
			$self->{$attrname} = $caller->{$attrname};
		}
		else {
			$self->{$attrname} = $self->_default_for($attrname);
		}
	}
	return $self;
}

# Modified by Dennis

{

	#Encapsulated class data

	#___________________________________________________________
	#ATTRIBUTES
	my %_attr_data =    #     				DEFAULT    	ACCESSIBILITY
	  (
		username => [ undef, 'read/write' ],
		password => [ undef, 'read/write' ],
		dbname   => [ undef, 'read/write' ],
		port     => [ undef, 'read/write' ],
		proxy    => [ undef, 'read/write' ],
		url      => [ undef, 'read/write' ],
		driver   => [ undef, 'read/write' ],
	  );

	#_____________________________________________________________

	# METHODS, to operate on encapsulated class data

	# Is a specified object attribute accessible in a given mode
	sub _accessible {
		my ( $self, $attr, $mode ) = @_;
		$_attr_data{$attr}[1] =~ /$mode/;
	}

	# Classwide default value for a specified object attribute
	sub _default_for {
		my ( $self, $attr ) = @_;
		$_attr_data{$attr}[0];
	}

	# List of names of all specified object attributes
	sub _standard_keys_a {
		keys %_attr_data;
	}

=head2 username

 Usage     :	my $un = $API->username($arg)
 Function  :	get/set username (if required)
 Returns   :	String (username)
 Args      :    String (username) - optional.

=cut

	sub username {
		my ( $self, $arg ) = @_;
		$self->{username} = $arg if defined $arg;
		return $self->{username};
	}

=head2 password

 Usage     :	my $un = $API->password($arg)
 Function  :	get/set password (if required)
 Returns   :	String (password)
 Args      :    String (password) - optional.

=cut

	sub password {
		my ( $self, $arg ) = @_;
		$self->{password} = $arg if defined $arg;
		return $self->{password};
	}

=head2 dbname

 Usage     :	my $un = $API->dbname($arg)
 Function  :	get/set dbname (if required)
 Returns   :	String (dbname)
 Args      :    String (dbname) - optional.

=cut

	sub dbname {
		my ( $self, $arg ) = @_;
		$self->{dbname} = $arg if defined $arg;
		return $self->{dbname};
	}

=head2 port

 Usage     :	my $un = $API->port($arg)
 Function  :	get/set port (if required)
 Returns   :	String (port)
 Args      :    String (port) - optional.

=cut

	sub port {
		my ( $self, $arg ) = @_;
		$self->{port} = $arg if defined $arg;
		return $self->{port};
	}

=head2 proxy

 Usage     :	my $un = $API->proxy($arg)
 Function  :	get/set proxy (if required)
 Returns   :	String (proxy)
 Args      :    String (proxy) - optional.

=cut

	sub proxy {
		my ( $self, $arg ) = @_;
		$self->{proxy} = $arg if defined $arg;
		return $self->{proxy};
	}

=head2 sourcetype

 Usage     :	my $un = $API->sourcetype($arg)
 Function  :	get/set string name of sourcetype (e.g. mySQL)
 Returns   :	String (sourcetype)
 Args      :    String (sourcetype) - optional.

=cut

	sub sourcetype {
		my ( $self, $arg ) = @_;
		$self->{sourcetype} = $arg if defined $arg;
		return $self->{sourcetype};
	}

=head2 driver

 Usage     :	my $un = $API->driver($arg)
 Function  :	get/set string name of driver module (e.g. DBD::mySQL)
 Returns   :	String (driver)
 Args      :    String (driver) - optional.

=cut

	sub driver {
		my ( $self, $arg ) = @_;
		$self->{driver} = $arg if defined $arg;
		return $self->{driver};
	}

=head2 url

 Usage     :	my $un = $API->url($arg)
 Function  :	get/set url (if required)
 Returns   :	String (url)
 Args      :    String (url) - optional.

=cut

	sub url {
		my ( $self, $arg ) = @_;
		$self->{url} = $arg if defined $arg;
		return $self->{url};
	}

	sub _implementation {
		my ( $self, $arg ) = @_;
		$self->{'_implementation'} = $arg if defined $arg;
		return $self->{'_implementation'};
	}

=head2 dbh

 Usage     :	my $un = $API->dbh($arg)
 Function  :	get/set database handle (if required)
 Returns   :	Database handle in whatever object is appropriate for sourcetype
 Args      :    Database handle in whatever object is appropriate for sourcetype

=cut

	sub dbh {
		my ( $self, $arg ) = @_;
		$self->{dbh} = $arg if defined $arg;
		return $self->{dbh};
	}

}

sub DESTROY { }

1;
