#-----------------------------------------------------------------
# MOSES::MOBY::Def::Data
# Author: Edward Kawas <edward.kawas@gmail.com>,
#         Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see below.
#
# $Id: Data.pm,v 1.4 2008/04/29 19:41:09 kawas Exp $
#-----------------------------------------------------------------

#-----------------------------------------------------------------
#
# MOSES::MOBY::Def::Data
#
#-----------------------------------------------------------------
package MOSES::MOBY::Def::Data;
use base qw( MOSES::MOBY::Base );
use XML::LibXML;
use strict;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOSES::MOBY::Def::Data - a BioMoby definition of a service input/output

=head1 SYNOPSIS

=cut

=head1 DESCRIPTION

Each definition of a BioMoby service includes definition of data that
the service expects and tha data that the service produces. These
definitions are kept in modules in this file.

=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)
 Martin Senger (martin.senger [at] gmail [dot] com)

=cut

#-----------------------------------------------------------------
# A list of allowed attribute names. See MOSES::MOBY::Base for details.
#-----------------------------------------------------------------

=head1 ACCESSIBLE ATTRIBUTES

Details are in L<MOSES::MOBY::Base>. Here just a list of them:

=over

=item B<name>

=item B<primary>

A boolean attribute. Must have true value for primary inputs and
outputs.

=back

=cut

{
    my %_allowed =
	(
	 name         => { type => MOSES::MOBY::Base->STRING,
			   post => sub {
			       my ($self) = shift;
			       $self->{original_name} = $self->{name};
			       $self->{name} = $self->escape_name ($self->{original_name})
			       } },
	 primary      => { type => MOSES::MOBY::Base->BOOLEAN },

	 # used internally  (but cannot start with underscore - Template would ignore them)
	 original_name => undef,
	 );
	 
    sub _accessible {
	my ($self, $attr) = @_;
	exists $_allowed{$attr} or $self->SUPER::_accessible ($attr);
    }
    sub _attr_prop {
	my ($self, $attr_name, $prop_name) = @_;
	my $attr = $_allowed {$attr_name};
	return ref ($attr) ? $attr->{$prop_name} : $attr if $attr;
	return $self->SUPER::_attr_prop ($attr_name, $prop_name);
    }
}

#-----------------------------------------------------------------
# init
#-----------------------------------------------------------------
#sub init {
#    my ($self) = shift;
#    $self->SUPER::init();
#}

#-----------------------------------------------------------------
# toXML
#-----------------------------------------------------------------
sub toXML{
    my $self = shift;
    $self->throw( "toXML not implemented in the ". ref($self) ." module.\n");	
}

#-----------------------------------------------------------------
#
# MOSES::MOBY::Def::PrimaryData
#
#-----------------------------------------------------------------
package MOSES::MOBY::Def::PrimaryData;
use base qw( MOSES::MOBY::Def::Data );
use strict;

#-----------------------------------------------------------------
# A list of allowed attribute names. See MOSES::MOBY::Base for details.
#-----------------------------------------------------------------

=head1 ACCESSIBLE ATTRIBUTES

Details are in L<MOSES::MOBY::Base>. Here just a list of them:

=over

=item B<datatype>

=back

=cut

{
    my %_allowed =
	(
	 );
	 
    sub _accessible {
	my ($self, $attr) = @_;
	exists $_allowed{$attr} or $self->SUPER::_accessible ($attr);
    }
    sub _attr_prop {
	my ($self, $attr_name, $prop_name) = @_;
	my $attr = $_allowed {$attr_name};
	return ref ($attr) ? $attr->{$prop_name} : $attr if $attr;
	return $self->SUPER::_attr_prop ($attr_name, $prop_name);
    }
}

#-----------------------------------------------------------------
# init
#-----------------------------------------------------------------
sub init {
    my ($self) = shift;
    $self->SUPER::init();
    $self->primary (1);
}

#-----------------------------------------------------------------
#
# MOSES::MOBY::Def::PrimaryDataSimple
#
#-----------------------------------------------------------------
package MOSES::MOBY::Def::PrimaryDataSimple;
use base qw( MOSES::MOBY::Def::PrimaryData );
use strict;

#-----------------------------------------------------------------
# A list of allowed attribute names. See MOSES::MOBY::Base for details.
#-----------------------------------------------------------------

=head1 ACCESSIBLE ATTRIBUTES

Details are in L<MOSES::MOBY::Base>. Here just a list of them:

=over

=item B<namespaces>

=back

=cut

{
    my %_allowed =
	(
	 namespaces   => {type => 'MOSES::MOBY::Def::Namespace', is_array => 1},
	 datatype   => { type => 'MOSES::MOBY::Def::DataType' },
	 );
	 
    sub _accessible {
	my ($self, $attr) = @_;
	exists $_allowed{$attr} or $self->SUPER::_accessible ($attr);
    }
    sub _attr_prop {
	my ($self, $attr_name, $prop_name) = @_;
	my $attr = $_allowed {$attr_name};
	return ref ($attr) ? $attr->{$prop_name} : $attr if $attr;
	return $self->SUPER::_attr_prop ($attr_name, $prop_name);
    }
}

#-----------------------------------------------------------------

=head1 SUBROUTINES

=cut

#-----------------------------------------------------------------
# init
#-----------------------------------------------------------------
sub init {
    my ($self) = shift;
    $self->SUPER::init();
    $self->datatype (new MOSES::MOBY::Def::DataType ( name => 'Object'));
    $self->namespaces ([]);
}

#-----------------------------------------------------------------
# toXML
#-----------------------------------------------------------------
sub toXML {
    my $caller         = shift;
    my $useArticleName = 1;
    if (@_) {
	my $var = shift;
	if ( $var == 0 ) {
	    $useArticleName = 0;
	}
    }
    my $root = $caller->createXMLElement ('Simple');
    
    #set the articlename
    $caller->setXMLAttribute( $root, 'articleName', $caller->original_name ||'' ) if $useArticleName;
    
    # set the objectType
    my $node = $caller->createXMLElement("objectType");
    $node->appendTextNode( $caller->datatype->name || "");
    $root->addChild($node);
    
    # add any namespaces
    foreach my $ns ( @{$caller->namespaces} ) {
	$node = $caller->createXMLElement("Namespace");
	$node->appendTextNode( $ns->name ) if $ns->name;
	$root->addChild($node);
    }
    
    return $root;
}

#-----------------------------------------------------------------
#
# MOSES::MOBY::Def::PrimaryDataSet
#
#-----------------------------------------------------------------
package MOSES::MOBY::Def::PrimaryDataSet;
use base qw( MOSES::MOBY::Def::PrimaryData );
use strict;

{
    my %_allowed =
	(
	 elements => {type => 'MOSES::MOBY::Def::PrimaryDataSimple', is_array => 1},
	 );
	 
    sub _accessible {
	my ($self, $attr) = @_;
	exists $_allowed{$attr} or $self->SUPER::_accessible ($attr);
    }
    sub _attr_prop {
	my ($self, $attr_name, $prop_name) = @_;
	my $attr = $_allowed {$attr_name};
	return ref ($attr) ? $attr->{$prop_name} : $attr if $attr;
	return $self->SUPER::_attr_prop ($attr_name, $prop_name);
    }
}

#-----------------------------------------------------------------

=head1 SUBROUTINES

=cut

#-----------------------------------------------------------------
# init
#-----------------------------------------------------------------
sub init {
    my ($self) = shift;
    $self->SUPER::init();
    $self->elements ([]);
}

#-----------------------------------------------------------------
# toXML
#-----------------------------------------------------------------
sub toXML{
    my $caller   = shift;
    my $root = $caller->createXMLElement ('Collection');
	
    #set the articlename
    $caller->setXMLAttribute($root, 'articleName' , $caller->original_name ||'');
    # add any datatypes
    foreach my $dt (@{$caller->elements}) {
	$root->addChild($dt->toXML(0));
    }
    return $root;
}

#-----------------------------------------------------------------
#
# MOSES::MOBY::Def::SecondaryData
#
#-----------------------------------------------------------------
package MOSES::MOBY::Def::SecondaryData;
use base qw( MOSES::MOBY::Def::Data );
use strict;

{
    my %_allowed =
	(
	 max         => { type => MOSES::MOBY::Base->STRING },
	 min         => { type => MOSES::MOBY::Base->STRING },
	 default     => undef,
	 description => { type => MOSES::MOBY::Base->STRING},
 	 datatype    => { type => MOSES::MOBY::Base->STRING},
	 allowables  => {is_array => 1},
	 );
	 
    sub _accessible {
	my ($self, $attr) = @_;
	exists $_allowed{$attr} or $self->SUPER::_accessible ($attr);
    }
    sub _attr_prop {
	my ($self, $attr_name, $prop_name) = @_;
	my $attr = $_allowed {$attr_name};
	return ref ($attr) ? $attr->{$prop_name} : $attr if $attr;
	return $self->SUPER::_attr_prop ($attr_name, $prop_name);
    }
}

#-----------------------------------------------------------------
# init
#-----------------------------------------------------------------
sub init {
    my ($self) = shift;
    $self->SUPER::init();
    $self->allowables ([]);
    $self->datatype (new MOSES::MOBY::Def::DataType ( name => 'String'));
}
#sub _verify_datatype_ {
#	my ($self, $attr) = @_;
#    $self->throw ("Datatype not set - valid types are: Integer|Float|String|DateTime and not " . $self->datatype)
#	unless $self->datatype =~ /Integer|Float|String|DateTime/ ;
#}

#sub _verify_max_ {
#    my ($self, $attr) = @_;
#    $self->throw ("max value must be a digit")
#	unless $self->max =~ m/^[+-]?\ *(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?$/ ;
#}

#sub _verify_min_ {
#	my ($self, $attr) = @_;
#    $self->throw ("min value must be a digit")
#	unless $self->min =~ m/^[+-]?\ *(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?$/ ;
#}

sub toXML {
    my $caller   = shift;
    my $rootName = "Parameter";
    if (@_) {
	$rootName = shift || "Parameter";
    }
    
    my $root = $caller->createXMLElement("$rootName");
    
    #set the articlename
    $root->setAttribute( 'articleName', $caller->original_name || '' );
    
    # set the datatype
    my $node = $caller->createXMLElement("datatype");
    $node->appendTextNode( $caller->datatype ) if $caller->datatype;
    $root->addChild($node);
    
    if ( $caller->max ) {
	$node = $caller->createXMLElement("max");
	$node->appendTextNode( $caller->max ) if $caller->max;
	$root->addChild($node);
    }
    if ( $caller->min ) {
	$node = $caller->createXMLElement("min");
	$node->appendTextNode( $caller->min ) if $caller->min;
	$root->addChild($node);
    }
    if ( $caller->default ) {
	$node = $caller->createXMLElement("default");
	$node->appendTextNode( $caller->default ) if $caller->default;
	$root->addChild($node);
    }
    
    # add any allowables
    foreach my $ns ( @{$caller->allowables} ) {
	$node = $caller->createXMLElement("enum");
	$node->appendTextNode($ns);
	$root->addChild($node);
    }
    
    return $root;
}

1;
__END__
