package Mail::Decency::LogParser::Core::PostfixParser;

use Moose::Role;

use version 0.74; our $VERSION = qv( "v0.1.6" );

use Data::Dumper;

=head1 NAME

Mail::Decency::LogParser::Core::LogParser

=head1 DESCRIPTION

Parse logs in postfix style. Also can be used as background for another log parser module

=cut

our $RX_HOST_AND_IP = qr/([^\]]*?)\[([^\]]+?)\]/;

=head1 METHODS

=cut

=head2 parse_line

Parses a single line and returns a parsed hashref which will passed to the handling modules.

Returns parsed line as hashref:

    {
        # wheter mail was rejected
        reject => [0|1],
        
        # wheter the log processing of this mail delivery is finished
        final  => [0|1],
        
        # the hostname sending/injecting the mail
        host   => [string],
        
        # the ip sending/injecting the mail
        ip     => [ipv4 or ipv6 string],
        
        # the reverse hostname of the sending/injecting mails seerver
        rdns   => [ipv4 or ipv6 string],
        
        # the helo name of the sending/injecting mail server
        helo => [string],
        
        # the senders/recipients address or domain
        (from|to)_(address|domain) => [string]
        
        
        #
        # REJECTED
        #
        
        # final deliver/reject code (200, 554, ..)
        code   => [string],
        
        # for rejections: the reason why the mail is rejected
        message => [string],
        
        #
        # NOT REJECTED
        #
        
        # wheter the mail has been queued (rejected mails will not)
        queued  => [0|1],
        
        # the current queue id in the log
        queue_id => [string],
        
        # depending on the MTA, sub division which handled thisi particula log line
        prog   => [string, eg "bounce" for postfix..],
        
        # the relay target (hostname, ip), if any
        relay_(host|ip) => [string],
        
        # the size of the mail in bytes
        size => [integer],
        
        # wheter the mail has been removed (can be happen before final)
        removed => [0|1],
        
        # what the final handling/delivery was
        (bounced|sent|deferred) => [0|1],
        
        # the next queue id, eg if the mail is to be bounced
        next_id => [string],
        
        # the previous queue id, eg if this is a bounce mail
        prev_id => [string],
        
        # wheter the current mail is a bounce (eg this is the bounce mail or the mail to be bounced)
        is_bounce => [0|1],
        
        # the original from (a bounce mail will be delivered from "")
        orig_from => [string],
    }

=cut

sub parse_line {
    my ( $self, $line ) = @_;
    
    #$self->logger->debug3( "Got line '$line'" );
    return if index( $line, 'postfix/' ) == -1 || index( $line, ' warning:' ) > -1;
    
    return if $line =~ / (dis)?connect from/;
    
    my $ref = {};
    my $queue_id;
    
    # found REJECT
    if ( index( $line, ' NOQUEUE:' ) > -1 ) {
        if ( $line =~ / reject: RCPT from $RX_HOST_AND_IP: (\d\d\d) [^:]+?: ([^;]*?);/ ) {
            $ref->{ reject }++;
            $ref->{ final }++;
            $ref->{ host }    = $1;
            $ref->{ ip }      = $2;
            $ref->{ code }    = $3;
            $ref->{ message } = $4;
        }
        else {
            return;
        }
    }
    
    # found QUEUED message
    else {
        
        # parse ..
        my ( $prog, $id, $msg ) = $line =~ /
            postfix \/ ([^\[]+)   # cleanup, bounce, ..
            \[\d+\]:\s+           # some process id
            ([A-Z0-9]+):\s+       # the queue id
            (.+)                  # rest of the message
        /x;
        
        # mark as queued
        $ref->{ queued } ++;
        
        # remember id and prog
        $queue_id = $ref->{ id } = $id;
        $ref->{ prog } = $prog;
    }
    
    # got sender or recupuent
    my $found_from = 0;
    while ( $line =~ /\b(from|to)=<([^>]*)/g ) {
        my ( $type, $value ) = ( $1, $2 );
        $ref->{ "${type}_address" } = $value;
        if ( $value =~ /^[^@]+@(.+?)$/ ) {
            $ref->{ "${type}_domain" } = $1;
        }
        $found_from ++ if $type eq 'from';
    }
    
    # got helo
    if ( $line =~ /helo=<([^>]*)/ ) {
        $ref->{ helo } = $1;
    }
    
    # got sender
    if ( $line =~ /client=$RX_HOST_AND_IP/ ) {
        $ref->{ rdns } = $1;
        $ref->{ ip }   = $2;
    }
    
    # workign on queue id (not no-queue)
    if ( $queue_id ) {
        
        # got relay target
        if ( $line =~ /\brelay=([^\[,]*)(?:\[([^\]]*)\])?/ ) {
            $ref->{ relay_host } = $1;
            $ref->{ relay_ip }   = $2 || '';
        }
        
        # got suze
        if ( $line =~ /\bsize=(\d+)/ ) {
            $ref->{ size } = $1;
        }
        
        # got final status
        if ( $line =~ /\bstatus=(bounced|sent|deferred)\b/ ) {
            $ref->{ $1 }++;
            $ref->{ final }++;
        }
        
        # got final remove
        elsif ( $line =~ / removed$/ ) {
            $ref->{ removed }++;
        }
        
        # try read current from cache
        my $cached = $self->cache->get( "QUEUE-$queue_id" );
        if ( $cached ) {
            
            # not final if has next
            if ( $cached->{ next_id } ) {
                delete $ref->{ final };
            }
            
            # update self
            $ref = { %$cached, %$ref };
            delete $ref->{ final } if $found_from;
            delete $ref->{ deferred } if $ref->{ sent };
        }
        
        
        # non delivery
        if ( $line =~ /sender non-delivery notification: ([A-Z0-9]+)/ ) {
            my $next_id = $1;
            
            # create new cache entry
            my %next = %$ref;
            push @{ $next{ prev } ||= [] }, $ref;
            $next{ orig_from } = $ref->{ from } if $ref->{ from };
            $next{ prev_id }   = $queue_id;
            $next{ queue_id }  = $next_id;
            $next{ is_bounce } = 1;
            delete $next{ next_id };
            
            # save next instance to cache
            $self->cache->set( "QUEUE-$next_id", \%next, time() + 600 );
            
            # current is not final anymore
            $ref->{ next_id } = $next_id;
            delete $ref->{ final };
        }
        
        # update current to cache
        $self->cache->set( "QUEUE-$queue_id", $ref, time() + 600 );
    }
    
    $queue_id ||= "NOQUEUE";
    $self->logger->debug3( Dumper( {
        $queue_id => $ref,
        LINE      => $line
    } ) ) if 0;
    
    return $ref;
}

=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut

1;
