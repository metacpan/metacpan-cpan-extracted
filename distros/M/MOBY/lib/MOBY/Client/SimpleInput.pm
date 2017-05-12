package MOBY::Client::SimpleInput;
use strict;
use Carp;
use vars qw($AUTOLOAD @ISA);

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.5 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOBY::Client::SimpleInput - a small object describing a MOBY service

=head1 SYNOPSIS

=cut

=head1 DESCRIPTION

A module for describing the Simple inputs to a moby service

=cut

=head1 AUTHORS

Mark Wilkinson (markw at illuminae dot com)

=cut

=head1 METHODS


=head2 new

 Title     :	new
 Usage     :	my $IN = MOBY::Client::SimpleInput->new(%args)
 Function  :	create SimpleInput object
 Returns   :	MOBY::Client::SimpleInput object
 Args      :    articleName => $articleName (optional)
                objectType => $objectType (required)
                namespaces => \@namesapces (optional)
=cut

=head2 articleName

 Title     :	articleName
 Usage     :	$name = $IN->articleName([$name])
 Function  :	get/set articleName
 Returns   :	string

=cut

=head2 objectType

 Title     :	objectType
 Usage     :	$type = $IN->objectType([$type])
 Function  :	get/set name
 Returns   :	string

=cut

=head2 namespaces

 Title     :	namespaces
 Usage     :	$namespaces = $IN->namespaces([\@namespaces])
 Function  :	get/set namespaces for the objectType
 Returns   :	arrayref of namespace strings

=cut

=head2 addNamespace

 Title     :	addNamespace
 Usage     :	$namespaces = $IN->addNamespace($namespace)
 Function  :	add another namespace for the objectType
 Returns   :	arrayref of namespace strings

=cut

{

	# Encapsulated:
	# DATA
	#___________________________________________________________
	#ATTRIBUTES
	my %_attr_data =    #     				DEFAULT    	ACCESSIBILITY
	  (
		articleName => [ undef, 'read/write' ],
		objectType  => [ undef, 'read/write' ],
		namespaces => [ undef, 'read/write' ],
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

	sub addNamespace {
		my ( $self, $ns ) = @_;
		return $self->{namespaces} unless $ns;
		push @{ $self->{namespaces} }, $ns;
		return $self->{namespaces};
	}
}

sub new {
	my ( $caller, %args ) = @_;
	my $caller_is_obj = ref( $caller );
	return $caller if $caller_is_obj;
	my $class = $caller_is_obj || $caller;
	my $proxy;
	my $self = bless {}, $class;
	foreach my $attrname ( $self->_standard_keys ) {
		if ( exists $args{$attrname} ) {
			$self->{$attrname} = $args{$attrname};
		} elsif ( $caller_is_obj ) {
			$self->{$attrname} = $caller->{$attrname};
		} else {
			$self->{$attrname} = $self->_default_for( $attrname );
		}
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
