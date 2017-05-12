#$Id: DataAdapterI.pm,v 1.2 2008/09/02 13:09:30 kawas Exp $
package MOBY::Adaptor::moby::DataAdapterI;
use strict;
use Carp;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOBY::Adaptor::moby::DataAdapterI - An interface definition for MOBY Central underlying data-stores

=cut

=head1 SYNOPSIS

 use MOBY::Adaptor::moby::queryapi::mysql  # implements this interface def

=cut

=head1 DESCRIPTION

This is an interface definition. There is NO implementation in this module
with the exception that certain calls to required parameters have get/setter
functions in this module (that can be overridden)

=head1 AUTHORS

Mark Wilkinson markw_at_ illuminae dot com
Dennis Wang oikisai _at_ hotmail dot com
BioMOBY Project:  http://www.biomoby.org


=cut

=head1 METHODS

=head2 create

 Title     :	create
 Usage     :	my $un = $API->create(%args)
 Function  :	create an Object and register it into mobycentral
 Args      :    				
 Returns   :    1 if creation was successful
 				0 otherwise
=cut
sub create{
	die "create not implemented in the DataAdapterI Interface file.\n";	
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
	die "delete not implemented in the DataAdapterI Interface file.\n";	
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
	die "update not implemented in the DataAdapterI Interface file.\n";	
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
	die "query not implemented in the DataAdapterI Interface file.\n";	
}

1;
