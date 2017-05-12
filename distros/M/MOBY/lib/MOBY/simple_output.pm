#!/usr/bin/perl -w
package MOBY::simple_output;
use strict;
use Carp;
use MOBY::Config;
use vars qw($AUTOLOAD @ISA);

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOBY::simple_output - a lightweight connection to the
simple_output table in the database

=head1 SYNOPSIS

 #NON FUNCTIONAL AT THIS TIME
 
 use MOBY::simple_output;
 my $Instance = MOBY::simple_output->new(
          object_type => "Sequence",
          namespaces => ["genbank/gi", "genbank/Acc"],
          article_name => "InputSequenceThingy",
 );
 print $Instance->simple_output_id;
 print $Instance->service_instance_id;


=cut

=head1 DESCRIPTION

representation of the simple_output table.  Can write to the database

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
		simple_output_id     => [ undef, 'read/write' ],
		object_type_uri      => [ undef, 'read/write' ],
		namespace_type_uris  => [ undef, 'read/write' ],
		article_name         => [ undef, 'read/write' ],
		service_instance_id  => [ undef, 'read/write' ],
		service_instance_lsid  => [ undef, 'read/write' ],
		collection_output_id => [ undef, 'read/write' ],
		dbh                  => [ undef, 'read/write' ],
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
	my $id = $self->WRITE;
	$self->simple_output_id($id) if defined $id;
	return $self;
}

sub WRITE {
	my ($self) = @_;
	$CONFIG ||= MOBY::Config->new;    # exported by Config.pm
	my $adaptor = $CONFIG->getDataAdaptor( datasource => 'mobycentral' );
	my $id = $adaptor->insert_simple_output(
		object_type_uri      => $self->object_type_uri,
		namespace_type_uris  => $self->namespace_type_uris,
		article_name         => $self->article_name,
		service_instance_lsid  => $self->service_instance_lsid,
		collection_output_id => $self->collection_output_id
		);
	return $id;
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
