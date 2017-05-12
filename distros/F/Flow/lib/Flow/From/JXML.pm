#===============================================================================
#
#  DESCRIPTION:  Deserialize to mixied XML and JSON
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================

=head1 NAME

Flow::From::JXML - deserialize flow from JSON+XML

=head1 SYNOPSIS

    my $f2   = create_flow(
        FromJXML => \$str2,
        Split    => {
            Flow1 => create_flow( sub { push @fset1, @_ } ),
            Flow2 => create_flow( sub { push @fset2, @_ } ),
        },
    );
    $f2->run();
    
=head1 DESCRIPTION

Flow::To::JXML - serialize flow to JSON+XML

=cut

package Flow::From::JXML;
use strict;
use warnings;
use JSON;
use Flow::To::XML;
use Data::Dumper;
use base 'Flow::From::XML';
our $VERSION = '0.1';

sub begin {
    our $self = shift;
    $self->put_begin(@_);
    my $xfl  = $self->{_xml_flow};
    my %tags = (
        flow => sub { shift;
        #clear UTF-X bit
        utf8::encode($_[0]) if utf8::is_utf8($_[0]);
        $self->put_flow( @{ decode_json( shift @_ ) } ) },
        ctl_flow =>
          sub { shift; 
          #clear UTF-X bit
          utf8::encode($_[0]) if utf8::is_utf8($_[0]);
          $self->put_ctl_flow( @{ decode_json( shift @_ ) } ) }
    );
    $xfl->read( \%tags );
    $xfl->close;
    return;
}

#sub flow { };
1;

