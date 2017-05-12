package HTTP::MobileAgent::Plugin::ID;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.2');
use HTTP::MobileAgent::Plugin::XHTML;

##########################################
# Base Module

package # hide from PAUSE 
       HTTP::MobileAgent;

sub id {
    my $self = shift;
    $self->{__id} = $_[0] if (defined($_[0]));
    $self->{__id} = $self->__id unless (defined($self->{__id}));
    $self->{__id};
}

sub __id{  }

sub support_id { 0 }

##########################################
# DoCoMo Module

package # hide from PAUSE
       HTTP::MobileAgent::DoCoMo;

sub __id { $_[0]->card_id || $_[0]->serial_number }

sub support_id { $_[0]->html_version ? $_[0]->html_version > 2.0 ? 1 : 0 : 1 }

##########################################
# EZWeb Module

package # hide from PAUSE
       HTTP::MobileAgent::EZweb;

sub __id { $_[0]->get_header('x-up-subno') }

sub support_id { 1 }

##########################################
# SoftBank Module

package # hide from PAUSE
       HTTP::MobileAgent::Vodafone;

sub __id {
    if ($_[0]->is_type_c) {
        return $_[0]->serial_number;
    } else {
        my $juid = $_[0]->get_header('x-jphone-uid');
        if ($juid && $juid ne "") {
            $juid =~ s/^.(.+)$/0$1/;
            return $juid;
        } else {
            return;
        }
    }
}

sub support_id { 1 }

1; # Magic true value required at end of module
__END__

=head1 NAME

HTTP::MobileAgent::Plugin::ID - Add ID fuctions to HTTP::MobileAgent


=head1 VERSION

This document describes HTTP::MobileAgent::Plugin::ID version 0.0.2


=head1 SYNOPSIS

  use HTTP::MobileAgent::Plugin::ID;
  
  my $ma = HTTP::MobileAgent->new;

  # Supporting ID or not
  
  if ($ma->support) {
    
    unless ($ma->id) {
      # Include two cases: DoCoMo or Not
      
      unless ($ma->is_docomo) {
        
        warn "User must turn User-ID functon on.";
      } else {
        # If ID from cache exists, you can set it.
        
        $ma->id($cache->param("id")) or warn "Set utn link and ask ID to user.";
      }
    }
    
    if ($ma->id) {
      # Do something...
    }
  } else {
    # Not support ID
    
    warn "User can't access this service.";
  }


=head1 DEPENDENCIES

=over

=item L<HTTP::MobileAgent::Plugin::XHTML>

=back


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to C<nene@kokogiko.net>.


=head1 AUTHOR

OHTSUKA Ko-hei  C<< <nene@kokogiko.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, OHTSUKA Ko-hei C<< <nene@kokogiko.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
