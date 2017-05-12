
use strict;
use Test::More tests => 26;

use_ok('Mail::Builder::Simple');

my $mail = Mail::Builder::Simple->new;

can_ok($mail, 'new');
can_ok($mail, '_add_args');
can_ok($mail, '_add_arg');
can_ok($mail, '_process_array');
can_ok($mail, '_process_item');
can_ok($mail, '_process_template');
can_ok($mail, '_set_or_add');
can_ok($mail, '_check_email_valid');
can_ok($mail, 'sendmail');
can_ok($mail, 'send');
can_ok($mail, '_add_custom_headers');
can_ok($mail, '_load_mailer');
can_ok($mail, '_mailer_args');
can_ok($mail, '_asure_compatibility');
can_ok($mail, '_different_email_addresses');

ok($mail->_check_email_valid('from', 'teddy@cpan.org'), 'Email OK');
ok($mail->_check_email_valid('subject', 'teddy@cpan.org'), 'Field OK');

is($mail->_load_mailer({mailer => 'SMTP'}),
'Email::Sender::Transport::SMTP', 'Mailer OK');

is($mail->_load_mailer({mailer => 'Email::Sender::Transport::SMTP'}),
'Email::Sender::Transport::SMTP', 'Mailer OK');

ok(eq_hash($mail->_mailer_args({mailer_args => [host => 'foo']}),
{host => 'foo'}), 'mailer_args ok');


ok(eq_hash($mail->_asure_compatibility({Host => 'foo'}),
{host => 'foo'}), 'Compatibility host ok');

ok(eq_hash($mail->_asure_compatibility({username => 'foo'}),
{username => 'foo', sasl_username => 'foo'}), 'Compatibility username OK');


ok(eq_hash($mail->_asure_compatibility({password => 'foo'}),
{password => 'foo', sasl_password => 'foo'}), 'Compatibility password OK');

ok(eq_hash($mail->_asure_compatibility({host => 'foo:1234'}),
{host => 'foo', port => 1234}), 'Compatibility port OK');


ok(eq_hash($mail->_different_email_addresses({from => 'm@m.ro', to => 't@t.ro', cc => 'c@c.ro'}),
{from => 'm@m.ro', to => 't@t.ro', cc => 'c@c.ro'}), 'Different addresses OK');

