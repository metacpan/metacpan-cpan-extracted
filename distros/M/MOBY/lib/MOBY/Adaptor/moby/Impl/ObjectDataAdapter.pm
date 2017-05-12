#$Id: ObjectDataAdapter.pm,v 1.3 2008/09/02 13:09:01 kawas Exp $
package MOBY::Adaptor::moby::Impl::ObjectDataAdapter;
use strict;
use Carp;
use vars qw(@ISA);
@ISA = qw{MOBY::Adaptor::moby::DataAdapterI}; # implements the interface

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOBY::Adaptor::moby::Impl::ObjectDataAdapter - An interface definition for MOBY Central underlying data-stores

=cut

=head1 SYNOPSIS

 use MOBY::Adaptor::moby::DataAdapterI  # implements this interface def


=cut

=head1 DESCRIPTION

Description here.

=head1 AUTHORS

Mark Wilkinson markw_at_ illuminae dot com
Dennis Wang oikisai _at_ hotmail dot com
BioMOBY Project:  http://www.biomoby.org


=cut

=head1 METHODS

=head2 new

 Title     :	new
 Usage     :	
 Function  :	

 Returns   :	
 Args      :    
 Notes     :    


=cut

sub new {
	my ($caller, %args) = @_;
	my $caller_is_obj = ref($caller);

    return my $self;    
}
=head2 create

 Title     :	create
 Usage     :	my $un = $API->create(%args)
 Function  :	create an Object and register it into mobycentral
 Args      :    				
 Returns   :    1 if creation was successful
 				0 otherwise
=cut
sub create{
}

=cut

=head2 delete

 Title     :	delete
 Usage     :	my $un = $API->delete(%args)
 Function  :	delete an Object from mobycentral
 Args      :    				
 Returns   :    1 if deletion was successful
 				0 otherwise
=cut
sub delete{
}

=head2 update

 Title     :	update
 Usage     :	my $un = $API->update(%args)
 Function  :	update an Object in mobycentral
 Args      :    				
 Returns   :    1 if the update was successful
 				0 otherwise
=cut
sub update{
	die "update not applicable with this registry.\n";	
}

=head2 query

 Title     :	query
 Usage     :	my $un = $API->query(%args)
 Function  :	retrieve an Object from mobycentral
 Args      :    				
 Returns   :    1 if deletion was successful
 				0 otherwise
=cut
sub query{
}

##########PRIVATE MEMBER VARIABLES#############
{

};

1;
