
package Email::Blaster::MailSender;

use strict;
use warnings 'all';
use MIME::Base64;
use Mail::Sendmail;


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  $class = ref($class) ? ref($class) : $class;
  
  return bless \%args, $class;
}# end new()


#==============================================================================
sub send_message
{
  my ($s, %args) = @_;
  
  my $to = $args{blaster}->config->is_testing ?
             $args{blaster}->config->test_email_address : $args{sendlog}->email;
  
  sendmail(
    To          => $to,
    From        => '"' . $args{transmission}->from_name . '" <' . $args{transmission}->from_address . '>',
    'reply-to'  => $args{transmission}->reply_to,
    Subject     => $args{subject},
    Message     => encode_base64( $args{content} ),
    'content-type' => $args{transmission}->content_type,
    'content-transfer-encoding' => 'base64',
  );
  
  my ($queued_as) = $Mail::Sendmail::log =~ m/\s+queued as\s+(.*)/;
  return $queued_as;
}# end send_message()

1;# return true:

