#!/usr/bin/perl -w
package MOBY::mysql;
use strict;
use Carp;
use vars qw($AUTOLOAD @ISA);

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOBY::mysql - makes a MYSQL database connection.

=head1 SYNOPSIS

 use MOBY::simple_output;
 my $dbh = MOBY::central_db_connection->new(
        db_connect_object => "MOBY::mysql",
        username => "myusername"
        password => "mypassword",
        dbname => "dbname",
        host => "dbhost",
 )

 $sth = $dbh->prepare("select * from tablename");


=cut

=head1 DESCRIPTION

makes a mysql conneciton to the database.  Should be created via
a central_db_connection object only!

=head1 AUTHORS

Mark Wilkinson (mwilkinson@gene.pbi.nrc.ca)


=cut

{

	# Encapsulated:
	# DATA
	#___________________________________________________________
	#ATTRIBUTES
	my %_attr_data =    #     				DEFAULT    	ACCESSIBILITY
	  ();

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
	sub _standard_keys {
		keys %_attr_data;
	}
}

sub new {
	my ( $caller, $dbname, $username, $password, $host, $port ) = @_;
	my $debug         = 0;
	my $caller_is_obj = ref($caller);
	return $caller if $caller_is_obj;
	my $class = $caller_is_obj || $caller;
	my $proxy;
	my $self = bless {}, $class;
	my ($dsn) = "DBI:mysql:$dbname:$host:$port";
	$debug
	  && &_LOG("connecting to db with params $dbname, $username, $password\n");
	my $dbh = DBI->connect( $dsn, $username, $password, { RaiseError => 1 } )
	  or die "can't connect to database";
	$debug && &_LOG("CONNECTED!\n");
	$self->databasehandle($dbh);
	return $self;
}

sub AUTOLOAD {
	no strict "refs";
	my ( $self, $newval ) = @_;
	$AUTOLOAD =~ /.*::(\w+)/;
	my $attr = $1;
	if ( $self->_accessible( $attr, 'write' ) ) {
		*{$AUTOLOAD} = sub {
			if ( defined $_[1] ) { $_[0]->{$attr} = $_[1] }
			return $_[0]->{$attr};
		};    ### end of created subroutine
###  this is called first time only
		if ( defined $newval ) {
			$self->{$attr} = $newval;
		}
		return $self->{$attr};
	} elsif ( $self->_accessible( $attr, 'read' ) ) {
		*{$AUTOLOAD} = sub {
			return $_[0]->{$attr};
		};    ### end of created subroutine
		return $self->{$attr};
	}

	# Must have been a mistake then...
	croak "No such method: $AUTOLOAD";
}
sub DESTROY { }
1;
