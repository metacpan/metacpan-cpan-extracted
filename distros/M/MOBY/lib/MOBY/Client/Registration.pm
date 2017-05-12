#$Id: Registration.pm,v 1.2 2008/09/02 13:11:40 kawas Exp $

=head1 NAME

MOBY::Client::Registration - an object to wrap the registration XML from MOBY Central

=cut

=head1 SYNOPSIS

 my $reg = $Central->registerService(%args);
 if ($reg->success){
	 print "registered successfully ",$reg->registration_id,"\n";
 } else {
	 print "registration failed ",$reg->message,"\n";
 }

=cut

=head1 DESCRIPTION

simply turns the registration XML into a hash

=head1 AUTHORS

Mark Wilkinson (markw@illuminae.com)

BioMOBY Project:  http://www.biomoby.org


=cut

=head1 METHODS

=head2 new

 Title     :	new
 Usage     :	my $MOBY = MOBY::Client::Registration->new(%args)
 Function  :
 Returns   :	MOBY::Client::Registration object
 Args      :    registration_id => $id
                message => $message
                success => $success

=cut

=head2 success

get/set the value

=head2 registration_id

get/set the value

=head2 id (same as registration_id)

get/set the value

=head2 message

get/set the value

=head2 RDF

get/set the value

=cut

package MOBY::Client::Registration;
use strict;
use Carp;
use vars qw($AUTOLOAD);

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

{

	#Encapsulated class data
	#___________________________________________________________
	#ATTRIBUTES
	my %_attr_data =    #     				DEFAULT    	ACCESSIBILITY
	  (
		success         => [ 0,     'read/write' ],
		message         => [ "OK",  'read/write' ],
		registration_id => [ undef, 'read/write' ],
		RDF             => [ undef, 'read/write' ],
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

sub id {
	my ( $self, $val ) = @_;
	$self->registration_id( $val ) if defined $val;
	return $self->registration_id;
}

sub new {
	my ( $caller, %args ) = @_;
	my $caller_is_obj = ref( $caller );
	my $class         = $caller_is_obj || $caller;
	my $self          = bless {}, $class;
	foreach my $attrname ( $self->_standard_keys ) {
		if ( exists $args{$attrname} && defined $args{$attrname} ) {
			$self->{$attrname} = $args{$attrname};
		} elsif ( $caller_is_obj ) {
			$self->{$attrname} = $caller->{$attrname};
		} else {
			$self->{$attrname} = $self->_default_for( $attrname );
		}
	}
	return $self;
}
sub DESTROY { }

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
1;
