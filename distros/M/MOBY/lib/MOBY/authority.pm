#!/usr/bin/perl -w
package MOBY::authority;
use strict;
use Carp;
use MOBY::Config;
use vars qw($AUTOLOAD @ISA);

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOBY::authority - a lightweight connection to the
authority table in the database

=head1 SYNOPSIS

 use MOBY::authority;
 my $Instance = MOBY::authority->new(
       authority_common_name => "genbank",
       authority_uri => "ncbi.nlm.nih.gov",
       contact_email => "mr.BIG@ncbi.nlm.nih.gov",

 );
 print $Instance->authority_id;


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
		authority_common_name => [ undef, 'read/write' ],
		authority_uri         => [ undef, 'read/write' ],
		contact_email         => [ undef, 'read/write' ],
		dbh                   => [ undef, 'read/write' ],
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
	sub authority_id {
		die "AUTHORITY_ID is deprecated.  fix your code!\n";
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
	my $dbh = $self->dbh;
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobycentral' );

	my $result = $adaptor->query_authority(authority_uri => $self->authority_uri);
	my $row = shift(@$result);
	unless ($row) {
		my $insertid = $adaptor->insert_authority(
							authority_common_name => $self->authority_common_name, 
							authority_uri => $self->authority_uri,
							contact_email => $self->contact_email);
	} else {
		$self->authority_common_name($row->{authority_common_name});
		$self->authority_uri($row->{authority_uri});
		$self->contact_email($row->{contact_email});		
	}
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
