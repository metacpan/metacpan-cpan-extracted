#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 41;

# The versions of the following packages are reported to help understanding
# the environment in which the tests are run.  This is certainly not a
# full list of all installed modules.
my @show_versions =
 qw/Mail::Message
    Mail::Transport
    Mail::Box::IMAP4
    Mail::Box::POP3
   /;

foreach my $package (@show_versions)
{   eval "require $package";

    no strict 'refs';
    my $report
      = !$@    ? "version ". (${"$package\::VERSION"} || 'unknown')
      : $@ =~ m/^Can't locate/ ? "not installed"
      : "reports error";

    warn "$package $report\n";
}

require_ok('Mail::Box::Collection');
require_ok('Mail::Box::Dir::Message');
require_ok('Mail::Box::Dir');
require_ok('Mail::Box::File::Message');
require_ok('Mail::Box::File');
require_ok('Mail::Box::Identity');
require_ok('Mail::Box::Locker::DotLock');
require_ok('Mail::Box::Locker::Flock');
require_ok('Mail::Box::Locker::Multi');
require_ok('Mail::Box::Locker::Mutt');
require_ok('Mail::Box::Locker::NFS');
require_ok('Mail::Box::Locker');
require_ok('Mail::Box::Locker::POSIX');
require_ok('Mail::Box::Maildir::Message');
require_ok('Mail::Box::Maildir');
require_ok('Mail::Box::Manager');
require_ok('Mail::Box::Manage::User');
require_ok('Mail::Box::Mbox::Message');
require_ok('Mail::Box::Mbox');
require_ok('Mail::Box::Message::Destructed');
require_ok('Mail::Box::Message');
require_ok('Mail::Box::MH::Index');
require_ok('Mail::Box::MH::Labels');
require_ok('Mail::Box::MH::Message');
require_ok('Mail::Box::MH');
require_ok('Mail::Box::Net::Message');
require_ok('Mail::Box::Net');
require_ok('Mail::Box');
require_ok('Mail::Box::Search::Grep');
require_ok('Mail::Box::Search');
require_ok('Mail::Box::Test');
require_ok('Mail::Box::Thread::Manager');
require_ok('Mail::Box::Thread::Node');
require_ok('Mail::Box::Tie::ARRAY');
require_ok('Mail::Box::Tie::HASH');
require_ok('Mail::Box::Tie');
require_ok('Mail::Message::Body::Delayed');
require_ok('Mail::Message::Dummy');
require_ok('Mail::Message::Head::Delayed');
require_ok('Mail::Message::Head::Subset');
require_ok('Mail::Server');

# The following modules only compile when optional modules are installed
#require_ok('Mail::Box::Locker::FcntlLock');
#require_ok('Mail::Box::Search::SpamAssassin');
#require_ok('Mail::Message::Wrapper::SpamAssassin');
