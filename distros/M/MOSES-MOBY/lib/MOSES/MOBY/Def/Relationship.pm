#-----------------------------------------------------------------
# MOSES::MOBY::Def::Relationship
# Author: Edward Kawas <edward.kawas@gmail.com>,
#         Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see below.
#
# $Id: Relationship.pm,v 1.4 2008/04/29 19:41:31 kawas Exp $
#-----------------------------------------------------------------

package MOSES::MOBY::Def::Relationship;
use base qw( MOSES::MOBY::Base Exporter );
use strict;
use vars qw( @EXPORT %ALLOWED_TYPES );

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/;

# relationship types
use constant ISA  => 'ISA';
use constant HASA => 'HASA';
use constant HAS  => 'HAS';

BEGIN {
    @EXPORT = qw(
		 ISA
		 HASA
		 HAS);
}

=head1 NAME

MOSES::MOBY::Def::Relationship - a definition of relationships between Moby data types

=head1 SYNOPSIS

 use MOSES::MOBY::Def::Relationship;
 # create a new relationship
 my $relationship = new MOSES::MOBY::Def::Relationship
   ( memberName   => 'myArticleName',
     datatype     => 'DNASequence',
     raletionship => HASA
   );
	
 # get the article name of the datatype in this relationship
 print $relationship->memberName;
	
 # set the article name of the datatype in this relationship
 $relationship->memberName ('myNewArticleName');

=cut

=head1 DESCRIPTION

A container representing a relationship of a BioMoby data type.

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

=item B<memberName>

A name how this relationship is known (an I<article name> in the
BioMoby speak).

=item B<datatype>

A name of a data type that is related by this relationship.

=item B<relationship>

A type of this relationship. Can be C<HAS>, C<HASA> or C<ISA>.

=back

=cut

{
    my %_allowed =
	(
	 memberName   => { type => MOSES::MOBY::Base->STRING,
			   post => sub {
			       my ($self) = shift;
			       $self->{original_memberName} = $self->{memberName};
			       $self->{memberName} = $self->escape_name ($self->{original_memberName})
			       } },
	 datatype     => { type => MOSES::MOBY::Base->STRING,
			   post => sub {
			       my ($self) = shift;
			       $self->{module_datatype} =
				   $self->datatype2module ($self->{datatype}) } },
	 relationship => { type => MOSES::MOBY::Base->STRING,
			   post => \&_check_relationship },

	 # used internally (but cannot start with underscore - Template would ignore it)
	 module_datatype => undef,
	 original_memberName => undef,
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
# Checking relationship type.
#-----------------------------------------------------------------
sub _check_relationship {
    my ($self, $attr) = @_;
    $self->throw ('Invalid relationship type: ' . $self->relationship)
	unless exists $ALLOWED_TYPES{$self->relationship};
}

%ALLOWED_TYPES = (HAS => 1, HASA => 1, ISA => 1);

#-----------------------------------------------------------------
# init
#-----------------------------------------------------------------
sub init {
    my ($self) = shift;
    $self->SUPER::init();
    $self->relationship (HASA);
}

1;
__END__
