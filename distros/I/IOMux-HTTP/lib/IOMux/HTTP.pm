# Copyrights 2011 by Mark Overmeer.
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 1.07.
use warnings;
use strict;

package IOMux::HTTP;
use vars '$VERSION';
$VERSION = '0.11';

use base 'IOMux::Net::TCP';

use Log::Report      'iomux-http';
use Time::HiRes      qw(time);

use HTTP::Request    ();
use HTTP::Response   ();
use HTTP::Status;
use HTTP::Date       qw(time2str);

use constant
  { HTTP_0_9 => 'HTTP/0.9'
  , HTTP_1_0 => 'HTTP/1.0'
  , HTTP_1_1 => 'HTTP/1.1'
  };

# oops, dirty hack
sub HTTP::Message::id() { shift->{IMH_id} }


my $conn_id = 'C0000000';

sub init($)
{   my ($self, $args) = @_;
    $args->{name} ||= ++$conn_id;

    $self->SUPER::init($args);
    $self->{IMH_headers}   = $args->{add_headers} || [];

    $self->{IMH_requests}  = [];
    $self->{IMH_starttime} = time;
    $self->{IMH_msgcount}  = 0;  # something unique for logging
    $self;
}


sub startTime() {shift->{IMH_starttime}}

sub mux_input($)
{   my ($self, $refdata) = @_;

    while($$refdata)   # possibly more than one message in one TCP package
    {
        # Read header
        my $msg = $self->{IMH_incoming};
        unless($msg)
        {   if($self->{IMH_no_more})
            {   # ignore input for closing, connection can still be writing
                $$refdata = '';
                return;
            }

            $$refdata =~ s/^\s+//s;      # strip leading blanks, sloppy remote
            $$refdata =~ s/(.*?)\r?\n\r?\n//s
                or return;               # not whole header yet, wait for more

            $msg      = $self->{IMH_incoming} = $self->headerArrived($1);
            #trace "new header ".$msg->uri if $msg->isa('HTTP::Request');

            my $msgid = sprintf 'in-%s-%02d'
                , $self->name, $self->{IMH_msgcount}++;
            $msg->id($msgid);
        }

        my $headers = $msg->headers;
        my $proto   = $msg->protocol;

        $msg->protocol($proto = HTTP_0_9)
            unless $proto;

        $self->{IMH_no_more}++
            if $msg->protocol lt HTTP_1_1
            || lc($headers->header('Connection') || '') ne 'keep-alive';

        $self->{IMH_take_all}++
            if $proto lt HTTP_1_0;

        return   # simply wait until EOF
            if $self->{IMH_take_all};

        # Read body

        my $result = $self->bodyComponentArrived($msg, $refdata)
            or return;   # message not ready yet

        my $resp   = $result->isa('HTTP::Response') ? $result : undef;

        $self->shutdown(0)
            if $self->{IMH_no_more};

        delete $self->{IMH_incoming};
        $self->messageArrived($msg, $resp);
    }
}

sub mux_outputbuffer_empty()
{   my $more = shift->{IMH_more_output} or return;
    $more->();
}

sub mux_eof($)
{   my ($self, $refdata) = @_;

    my $msg = delete $self->{IMH_incoming};  # headers only

    if($msg && length($$refdata) && $self->{IMH_take_all})
    {   $msg->content_ref($refdata);
    }
    else
    {   trace "trailing ".length($$refdata)." bytes ignored"
            if $$refdata =~ m/\S/;
    }

    $self->messageArrived($msg)
        if $msg;

    $self->SUPER::mux_eof($refdata);
}

sub bodyComponentArrived($$)
{   my ($self, $msg, $refdata) = @_;

    my $headers = $msg->headers;
    if(my $cl = $headers->header('Content-Length'))
    {   return if length($$refdata) < $cl;   # wait for more
        $msg->content(substr $$refdata, 0, $cl, '');
        return $msg;
    }

    # No Content-Length for multiparts?
    my $ct = $headers->header('Content-Type') || '';
    if($ct =~ m/^multipart\/\w+\s*;.*boundary\s*=(["']?)\s*(\w+)\1/i)
    {   $$refdata =~ s/(.*?\r?\n--\Q$2\E--\r?\n)//
            or return;  # multipart terminator not received yet
        $msg->content($1);
        return $msg;
    }

    # No Content-Length and not multipart, then no body.
    $msg;
}

sub headerArrived($)  {panic}
sub messageArrived($) {panic}

#--------------

sub sendMessage($$)
{   my ($self, $msg, $callback) = @_;

    if($self->mux_output_waiting || $self->{IMH_more_output})
    {   # Arggg. Well, some message content still being written.
        # Do not flood the outbufs with stringified requests.
        # For instance, a number of large files to be sent back
        # or uploaded as chunked.
        push @{$self->{IMH_queued}}, [$msg, $callback];
        return;
    }

    # Write the message now, and after that, but do not forget to
    # handle messages which arrived during this sending after it.
    my $queue_cb;
    $queue_cb = sub
      { my $queued = shift @{$self->{IMH_queued}} or return;
        my ($next_msg, $user_cb) = @$queued;       # the next msg
        $self->writeMessage($next_msg, sub {$queue_cb->(); $user_cb->()});
      };

    $self->writeMessage($msg, $queue_cb);
}

sub writeMessage($$)
{   my ($self, $msg, $callback) = @_;

    my $header = $msg->headers;
    $header->push_header
      ( Date       => time2str(time)
      , Connection => ($self->{IMH_no_more} ? 'close' : 'keep-alive')
      , @{$self->{IMH_headers}}
      );

    my $content = $msg->content;
    if(ref $content eq 'CODE')
    {   # create chunked
        $header->push_header(Transfer_Encoding => 'chunked');
        my $size = 0;
        $self->{IMH_more_output} = sub
          { my $chunk = $content->();
            unless(defined $chunk)
            {  delete $self->{IMH_more_output};
               $self->write("0\r\n\r\n");  # end chunks and no footer
               $size += 5;
               info "sent CHUNKED msg ".$msg->id.' '.$msg->status." ${size}b";
               return $callback->();
            }
            length $chunk or return;
            my $hexlen = sprintf "%x", length $chunk;
            $size     += length($hexlen) + length($chunk) + 4;
            $self->write("$hexlen\r\n$chunk\r\n");
          };
        $self->write(\$header->as_string);
    }
    else
    {   # write message in one go.
        $header->push_header(Content_Length => length $content);
        $msg->content_ref(\$content);
        my $text = $msg->as_string;
        $self->write(\$text);
        info "sent msg ".length($text)."b "
.(ref $msg).' '.($msg->isa('HTTP::Request') ? $msg->uri : $msg->content);
        $callback->();
    }
}


sub closeConnection() { shift->{IMH_no_more} = 1 }

1;
