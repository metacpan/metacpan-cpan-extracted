use strict;
use warnings;

package HTTP::Async::Polite;
use base 'HTTP::Async';

our $VERSION = '0.33';

use Carp;
use Data::Dumper;
use Time::HiRes qw( time sleep );
use URI;

=head1 NAME

HTTP::Async::Polite - politely process multiple HTTP requests

=head1 SYNOPSIS

See L<HTTP::Async> - the usage is unchanged.

=head1 DESCRIPTION

This L<HTTP::Async> module allows you to have many requests going on at once.
This can be very rude if you are fetching several pages from the same domain.
This module add limits to the number of simultaneous requests to a given
domain and adds an interval between the requests.

In all other ways it is identical in use to the original L<HTTP::Async>.

=head1 NEW METHODS

=head2 send_interval

Getter and setter for the C<send_interval> - the time in seconds to leave
between each request for a given domain. By default this is set to 5 seconds.

=cut

sub send_interval {
    my $self = shift;
    return scalar @_
      ? $self->_set_opt( 'send_interval', @_ )
      : $self->_get_opt('send_interval');
}

=head1 OVERLOADED METHODS

These methods are overloaded but otherwise work exactly as the original
methods did. The docs here just describe what they do differently.

=head2 new

Sets the C<send_interval> value to the default of 5 seconds.

=cut

sub new {
    my $class = shift;

    my $self = $class->SUPER::new;

    # Set the interval between sends.
    $self->{opts}{send_interval} = 5;    # seconds
    $class->_add_get_set_key('send_interval');

    $self->_init(@_);

    return $self;
}

=head2 add_with_opts

Adds the request to the correct queue depending on the domain.

=cut

sub add_with_opts {
    my $self = shift;
    my $req  = shift;
    my $opts = shift;
    my $id   = $self->_next_id;

    # Instead of putting this request and opts directly onto the to_send array
    # instead get the domain and add it to the domain's queue. Store this
    # domain with the opts so that it is easy to get at.
    my $uri    = URI->new( $req->uri );
    my $host   = $uri->host;
    my $port   = $uri->port;
    my $domain = "$host:$port";
    $opts->{_domain} = $domain;

    # Get the domain array - create it if needed.
    my $domain_arrayref = $self->{domain_stats}{$domain}{to_send} ||= [];

    push @{$domain_arrayref}, [ $req, $id ];
    $self->{id_opts}{$id} = $opts;

    $self->poke;

    return $id;
}

=head2 to_send_count

Returns the number of requests waiting to be sent. This is the number in the
actual queue plus the number in each domain specific queue.

=cut

sub to_send_count {
    my $self = shift;
    $self->poke;

    my $count = scalar @{ $$self{to_send} };

    $count += scalar @{ $self->{domain_stats}{$_}{to_send} }
      for keys %{ $self->{domain_stats} };

    return $count;
}

sub _process_to_send {
    my $self = shift;

    # Go through the domain specific queues and add all requests that we can
    # to the real queue.
    foreach my $domain ( keys %{ $self->{domain_stats} } ) {

        my $domain_stats = $self->{domain_stats}{$domain};
        next unless scalar @{ $domain_stats->{to_send} };

        # warn "TRYING TO ADD REQUEST FOR $domain";
        # warn        sleep 5;

        # Check that this request is good to go.
        next if $domain_stats->{count};
        next unless time > ( $domain_stats->{next_send} || 0 );

        # We can add this request.
        $domain_stats->{count}++;
        push @{ $self->{to_send} }, shift @{ $domain_stats->{to_send} };
    }

    # Use the original to send the requests on the queue.
    return $self->SUPER::_process_to_send;
}

sub _add_to_return_queue {
    my $self       = shift;
    my $req_and_id = shift;

    # decrement the count for this domain so that another request can start.
    # Also set the interval so that we don't scrape too fast.
    my $id          = $req_and_id->[1];
    my $domain      = $self->{id_opts}{$id}{_domain};
    my $domain_stat = $self->{domain_stats}{$domain};
    my $interval    = $self->_get_opt( 'send_interval', $id );

    $domain_stat->{count}--;
    $domain_stat->{next_send} = time + $interval;

    return $self->SUPER::_add_to_return_queue($req_and_id);
}

=head1 SEE ALSO

L<HTTP::Async> - the module that this one is based on.

=head1 AUTHOR

Edmund von der Burg C<< <evdb@ecclestoad.co.uk> >>. 

L<http://www.ecclestoad.co.uk/>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Edmund von der Burg C<< <evdb@ecclestoad.co.uk> >>.
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut

1;

