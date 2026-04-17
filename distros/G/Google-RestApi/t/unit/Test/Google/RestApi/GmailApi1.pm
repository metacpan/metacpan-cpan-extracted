package Test::Google::RestApi::GmailApi1;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::GmailApi1';
use aliased 'Google::RestApi::GmailApi1::Message';
use aliased 'Google::RestApi::GmailApi1::Thread';
use aliased 'Google::RestApi::GmailApi1::Draft';
use aliased 'Google::RestApi::GmailApi1::Label';

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
    subject => 'Test Message for GmailApi1 Unit Tests',
    body    => 'This is a test message for GmailApi1 unit tests.',
  );
  $self->{_setup_msg} = $msg;
  return;
}

sub shutdown : Tests(shutdown) {
  my $self = shift;
  $self->{_setup_msg}->trash() if $self->{_setup_msg};
  $self->SUPER::shutdown(@_);
  return;
}

sub _constructor : Tests(4) {
  my $self = shift;

  throws_ok sub { GmailApi1->new() },
    qr/api/i,
    'Constructor without api should throw';

  ok my $gmail = GmailApi1->new(api => mock_rest_api()), 'Constructor should succeed';
  isa_ok $gmail, GmailApi1, 'Constructor returns';
  can_ok $gmail, qw(api message thread draft label
                    profile messages threads labels
                    send_message batch_modify_messages batch_delete_messages);

  return;
}

sub message_factory : Tests(2) {
  my $self = shift;

  my $gmail = mock_gmail_api();
  ok my $msg = $gmail->message(id => 'msg123'), 'Message factory should succeed';
  isa_ok $msg, Message, 'Message factory returns';

  return;
}

sub thread_factory : Tests(2) {
  my $self = shift;

  my $gmail = mock_gmail_api();
  ok my $thread = $gmail->thread(id => 'thread123'), 'Thread factory should succeed';
  isa_ok $thread, Thread, 'Thread factory returns';

  return;
}

sub draft_factory : Tests(2) {
  my $self = shift;

  my $gmail = mock_gmail_api();
  ok my $draft = $gmail->draft(id => 'draft123'), 'Draft factory should succeed';
  isa_ok $draft, Draft, 'Draft factory returns';

  return;
}

sub label_factory : Tests(2) {
  my $self = shift;

  my $gmail = mock_gmail_api();
  ok my $label = $gmail->label(id => 'Label_1'), 'Label factory should succeed';
  isa_ok $label, Label, 'Label factory returns';

  return;
}

sub profile : Tests(2) {
  my $self = shift;

  my $gmail = mock_gmail_api();
  my $profile = $gmail->profile();
  ok $profile, 'Profile returns data';
  ok $profile->{emailAddress}, 'Profile has email address';

  return;
}

sub list_labels : Tests(2) {
  my $self = shift;

  my $gmail = mock_gmail_api();
  my @labels = $gmail->labels();
  ok scalar(@labels) >= 1, 'List should return at least one label';
  ok $labels[0]->{id}, 'Label has an ID';

  return;
}

sub list_messages : Tests(2) {
  my $self = shift;

  my $gmail = mock_gmail_api();
  my @messages = $gmail->messages();
  ok scalar(@messages) >= 1, 'List should return at least one message';
  ok $messages[0]->{id}, 'Message has an ID';

  return;
}

sub messages_max_pages : Tests(2) {
  my $self = shift;

  my $gmail = mock_gmail_api();
  my @messages = $gmail->messages(max_pages => 1);
  ok scalar(@messages) >= 1, 'Messages with max_pages=1 returns results';
  ok $messages[0]->{id}, 'Message has an ID';

  return;
}

sub threads_max_pages : Tests(1) {
  my $self = shift;

  my $gmail = mock_gmail_api();
  my @threads = $gmail->threads(max_pages => 1);
  ok defined(\@threads), 'Threads with max_pages accepts param';

  return;
}

1;
