#===============================================================================
#
#  DESCRIPTION:  Import events from XML
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
package Flow::From::XML;
use Flow;
use base 'Flow';
use XML::Flow;
use strict;
use warnings;
our $VERSION = '0.1';

=head2 new  src
    
    new Flow::From::XML:: \$str

=cut

sub new {
    my $class = shift;
    my $dst   = shift;
    my $xflow = ( new XML::Flow:: $dst );
    return $class->SUPER::new( @_, _xml_flow => $xflow, );
}

sub begin {
    our $self = shift;
    $self->put_begin(@_);
    my $xfl  = $self->{_xml_flow};
    my %tags = (
        flow     => sub { shift; $self->put_flow( @{ shift @_ } ) },
        ctl_flow => sub { shift; $self->put_ctl_flow( @{ shift(@_) } ) }
    );
    $xfl->read( \%tags );
    $xfl->close;
    return;
}
1;

