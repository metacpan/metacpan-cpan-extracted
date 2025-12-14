use warnings;
use strict;

use Test::More;

require_ok('Mail::Server::IMAP4::Fetch');
require_ok('Mail::Server::IMAP4::List');
require_ok('Mail::Server::IMAP4::Search');
require_ok('Mail::Server::IMAP4::User');
require_ok('Mail::Server::IMAP4');
require_ok('Mail::Transport::IMAP4');
require_ok('Mail::Box::IMAP4::Head');
require_ok('Mail::Box::IMAP4::Message');
require_ok('Mail::Box::IMAP4s');
require_ok('Mail::Box::IMAP4');

done_testing;
