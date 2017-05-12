package MOBY::central_db_connection;
use strict;
use Carp;
use vars qw($AUTOLOAD @ISA);
use MOBY::Config;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOBY::central_db_connection - container object for a specific DB connection

=head1 SYNOPSIS

 use MOBY::simple_output;
 my $dbh = MOBY::central_db_connection->new(
        db_connect_object => "MOBY::mysql",
        username => "myusername"
        password => "mypassword",
        dbname => "dbname",
        host => "dbhost",
        port => "3306",
 )

 $sth = $dbh->prepare("select * from tablename");


=cut

=head1 DESCRIPTION

representation of the authority table.  Can write to the database

=head1 AUTHORS

Mark Wilkinson (mwilkinson@gene.pbi.nrc.ca)


=cut

{

	# Encapsulated:
	# DATA
	#___________________________________________________________
	#ATTRIBUTES
	my %_attr_data =    #     				DEFAULT    	ACCESSIBILITY
	  (
		db_connect_object => [ "MOBY::mysql", 'read/write' ],
		datasource        => [ 'mobycentral', 'read/write' ],

		#username => ["mobycentral",         'read/write'],
		#password => ["mobycentral",         'read/write'],
		#dbname => ["mobycentral",       'read/write'],
		#host => ["localhost",         'read/write'],
		#port => [3306,         'read/write'],
		dbh => [ undef, 'read/write' ],
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
	sub _standard_keys {
		keys %_attr_data;
	}

	sub db_connect_object {
		my ( $self, $attr ) = @_;
		$self->{db_connect_object} = $attr if defined $attr;
		return $self->{db_connect_object};
	}

	sub dbh {
		my ( $self, $attr ) = @_;
		$self->{dbh} = $attr if defined $attr;
		return $self->{dbh};
	}
}

sub new {
	my ( $caller, %args ) = @_;
	my $caller_is_obj = ref($caller);
	return $caller if $caller_is_obj;
	my $class = $caller_is_obj || $caller;
	my $proxy;
	my $self = bless {}, $class;
	foreach my $attrname ( $self->_standard_keys ) {
		if ( exists $args{$attrname} ) {
			$self->{$attrname} = $args{$attrname};
		} elsif ($caller_is_obj) {
			$self->{$attrname} = $caller->{$attrname};
		} else {
			$self->{$attrname} = $self->_default_for($attrname);
		}
	}
	$CONFIG ||= MOBY::Config->new;

	# getting the dbh is bad bad bad!!!
	my $dbh = $CONFIG->getDataAdaptor( datasource => 'mobycentral' )->dbh;
	$self->dbh($dbh);
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
