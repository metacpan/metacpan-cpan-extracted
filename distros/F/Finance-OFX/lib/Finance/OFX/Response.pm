# Filename: Response.pm
#
# OFX response
# http://www.ofx.net/
# 
# Created February 16, 2008  Brandon Fosdick <bfoz@bfoz.net>
#
# Copyright 2008 Brandon Fosdick <bfoz@bfoz.net> (BSD License)
#
# $Id: Response.pm,v 1.2 2008/03/04 04:22:27 bfoz Exp $

package Finance::OFX::Response;

use strict;
use warnings;
use vars qw($VERSION);
use base qw(HTTP::Response);

our $VERSION = '2';

use Finance::OFX::Parse;

sub new
{
    my ($this, %options) = @_;
    my $class = ref($this) || $this;
    my $self = $class->SUPER::new(%options);
    bless $self, $class;
    return $self;
}

# Create a new OFX::Response from an HTTP::Response object
# NOTE: Re-blesses the passed reference
sub from_http_response
{
    my ($this, $self) = @_;
    my $class = ref($this) || $this;
    bless $self, $class;

    return $self unless $self->is_success;

    # Parse the HTTP response into an OFX tree
    $self->{tree} = Finance::OFX::Parse::parse($self->content);
    $self->{ofx} = $self->{tree}{ofx};
    $self->{ofxHeader} = $self->{tree}{header};

    return $self;
}

sub ofx
{
    my $s = shift;
    $s->{ofx} = shift if scalar @_;
    $s->{ofx};
}

sub ofx_header
{
    my $s = shift;
    $s->{ofxHeader} = shift if scalar @_;
    $s->{ofxHeader};
}

sub signonInstitution
{
    my $s = shift;
    return $s->{ofx}{signonmsgsrsv1}{sonrs}{fi};
}

sub signon_status_code
{
    my $s = shift;
    return $s->{ofx}{signonmsgsrsv1}{sonrs}{status}{code};
}

1;

__END__

=head1 NAME

Finance::OFX::Response - An OFX-specific subclass of L<HTTP::Response>.

=head1 SYNOPSIS

 use Finance::OFX::Response
 
 my $r = OFX::Response->from_http_response($response);

=head1 DESCRIPTION

C<Finance::OFX::Response> encapsulates information about an OFX Financial 
Institution. 

=head1 CONSTRUCTOR

=over

=item $r = Finance::OFX::Response->new( %options )

Constructs a new C<Finance::OFX::Response> object and returns it. This is merely 
a default constructor that does nothing in particular. Don't use it.

=item $r = Finance::OFX::Response->from_http_response( $response )

Converts the given L<HTTP::Response> object into an L<Finance::OFX::Response> 
object and uses L<Finance::OFX::Parse> to parse the response content.

=back

=head1 ATTRIBUTES

=over

=item $r->ofx

=item $r->ofx( $fid )

Get/Set the OFX branch of the parsed content tree.

=item $r->ofx_header

=item $r->ofx_header( $fi )

Get/Set the OFX header branch of the parsed content tree.

=item $r->signon_status_code( $fi )

Get the status code from the SONRS block.

=back

=head1 SEE ALSO

L<Finance::OFX::Parse>
L<HTTP::Response>
L<http://ofx.net>

=head1 WARNING

From C<Finance::Bank::LloydsTSB>:

This is code for B<online banking>, and that means B<your money>, and
that means B<BE CAREFUL>. You are encouraged, nay, expected, to audit
the source of this module yourself to reassure yourself that I am not
doing anything untoward with your banking data. This software is useful
to me, but is provided under B<NO GUARANTEE>, explicit or implied.

=head1 AUTHOR

Brandon Fosdick, E<lt>bfoz@bfoz.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Brandon Fosdick <bfoz@bfoz.net>

This software is provided under the terms of the BSD License.

=cut
