package Google::Chat::WebHooks;
use strict;
use warnings;
use LWP::UserAgent;
use subs 'timeout';
use Class::Tiny qw(room_webhook_url _ua timeout);
use Carp;
use JSON;
use Try::Tiny;
use Data::Validate::URI qw(is_uri);

BEGIN {
    our $VERSION     = '0.02';
}
my $DIAG = 1;

sub BUILD
{	
	my ($self, $args) = @_;
	
	$self->_ua(LWP::UserAgent->new);
	$self->_ua->timeout(10);
	$self->_ua->env_proxy;
	
	croak "parameter 'room_webhook_url' must be supplied to new" unless $self->room_webhook_url;
	croak "Room URL is malformed" unless is_uri($self->room_webhook_url);
}

sub timeout
{
	my $self = shift;
    if (@_) {
		$self->_ua->timeout(shift);
    }
	return $self->_ua->timeout;
}

sub simple_message($)
{
	my $self = shift;
	my $msg = shift;

	my $msg_json = "{\"text\": \"$msg\"}";
	my $req = HTTP::Request->new('POST', $self->room_webhook_url);
	$req->header('Content-Type' => 'application/json');
	$req->content($msg_json);
	my $response = $self->_ua->request($req);
	if($response->is_error)
	{
		my $content = $response->decoded_content();
		my $json;
		try
		{
			$json = decode_json($content);
		};
		my $error_message = $response->code." ".$response->message;
		return { result => 0, message => $error_message, detail => $response->decoded_content};
	}
	return { result => 1, message => "success"};
}

#################### main pod documentation begin ###################

=head1 SYNOPSIS

  use Google::Chat::WebHooks;

  my $room = Google::Chat::WebHooks->new(room_webhook_url => 'https://chat.googleapis.com/v1/spaces/someid/messages?key=something&token=something');
  my $result = $room->simple_text("This is a message");
  $result = $room->simple_text("Message with some *bold*");

=head1 DESCRIPTION

Google::Chat::WebHooks - Send notifications to Google Chat Rooms as provided by G-Suite. Does not work with Google Hangouts as used with your free Google account. Cannot receive messages - for that you need a bot. I'm sure I'll write that module some day. 

=head1 USAGE

Just create an object, passing the webhook URL of the room to which you want to send notifications. Then fire away. If you need help setting up a webhook for your room, see L<https://developers.google.com/hangouts/chat/how-tos/webhooks>.

=over 3
=item new(room_webhook_url => value)
=item new(room_webhook_url => value, timeout => integer)

Create a new instance of this class, passing in the webhook URL to send messages to. This argument is mandatory. Failure to set it upon creation will result in the method croaking.

Optionally also set the connect timeout in seconds. Default value is 10.  

=item simple_message(string)

   my $result = $room->simple_text("This is a message");
   $result->{'result'}; # 1 if success, 0 if not
   $result->{'message'}; # "success" if result was 1, error message if not

Send a message to the room. L<Basic formatting is available|https://developers.google.com/hangouts/chat/how-tos/webhooks>. Returns a hash ref.

=item room_webhook_url(), room_webhook_url(value)

Get/set the URL of the room. 

=back

=head1 BUGS & SUPPORT

Please log them L<on GitHub|https://github.com/realflash/perl-google-chat-webhoooks/issues>.

=head1 AUTHOR

    I Gibbs
    CPAN ID: IGIBBS
    igibbs@cpan.org
    https://github.com/realflash/perl-google-chat-webhoooks

=head1 COPYRIGHT

This program is free software licensed under the...

	The General Public License (GPL)
	Version 3

The full text of the license can be found in the
LICENSE file included with this module.

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

