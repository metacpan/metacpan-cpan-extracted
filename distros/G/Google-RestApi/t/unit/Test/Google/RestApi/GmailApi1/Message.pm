package Test::Google::RestApi::GmailApi1::Message;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::GmailApi1::Message';
use aliased 'Google::RestApi::GmailApi1::Attachment';

use parent 'Test::Unit::TestBase';

init_logger;

sub dont_create_mock_spreadsheets { 1; }

sub startup : Tests(startup) {
  my $self = shift;
  $self->SUPER::startup(@_);
  my $gmail = mock_gmail_api();
  my $profile = $gmail->profile();
  my $msg = $gmail->send_message(
    to      => $profile->{emailAddress},
    subject => 'Test Message for Unit Tests',
    body    => 'This is a test message body.',
  );
  $self->{_live_msg} = $msg;
  return;
}

sub shutdown : Tests(shutdown) {
  my $self = shift;
  $self->{_live_msg}->trash() if $self->{_live_msg};
  $self->SUPER::shutdown(@_);
  return;
}

sub _msg_id {
  my $self = shift;
  return $self->{_live_msg}->message_id();
}

sub _constructor : Tests(3) {
  my $self = shift;

  my $gmail = mock_gmail_api();

  ok my $msg = Message->new(gmail_api => $gmail),
    'Constructor without id should succeed';
  isa_ok $msg, Message, 'Constructor returns';

  ok Message->new(gmail_api => $gmail, id => 'msg123'),
    'Constructor with id should succeed';

  return;
}

sub requires_id : Tests(5) {
  my $self = shift;

  my $gmail = mock_gmail_api();
  my $msg = Message->new(gmail_api => $gmail);

  throws_ok sub { $msg->get() },
    qr/Message ID required/i,
    'get() without ID should throw';

  throws_ok sub { $msg->modify(add_label_ids => ['STARRED']) },
    qr/Message ID required/i,
    'modify() without ID should throw';

  throws_ok sub { $msg->trash() },
    qr/Message ID required/i,
    'trash() without ID should throw';

  throws_ok sub { $msg->untrash() },
    qr/Message ID required/i,
    'untrash() without ID should throw';

  throws_ok sub { $msg->delete() },
    qr/Message ID required/i,
    'delete() without ID should throw';

  return;
}

sub get_and_modify : Tests(2) {
  my $self = shift;

  my $gmail = mock_gmail_api();

  my $msg = $gmail->message(id => $self->_msg_id());
  my $details = $msg->get();
  ok $details, 'Get returns message details';

  lives_ok sub {
    $msg->modify(
      add_label_ids    => ['STARRED'],
      remove_label_ids => ['UNREAD'],
    );
  }, 'Modify message lives';

  return;
}

sub trash_and_untrash : Tests(2) {
  my $self = shift;

  my $gmail = mock_gmail_api();
  my $msg = $gmail->message(id => $self->_msg_id());

  lives_ok sub { $msg->trash() }, 'Trash message lives';
  lives_ok sub { $msg->untrash() }, 'Untrash message lives';

  return;
}

sub attachment_factory : Tests(2) {
  my $self = shift;

  my $gmail = mock_gmail_api();
  my $msg = $gmail->message(id => $self->_msg_id());

  ok my $att = $msg->attachment(id => 'att_001'), 'Attachment factory should succeed';
  isa_ok $att, Attachment, 'Attachment factory returns';

  return;
}

1;
