#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 8;

# The versions of the following packages are reported to help understanding
# the environment in which the tests are run.  This is certainly not a
# full list of all installed modules.
my @show_versions =
 qw/Mail::Box
    Mail::Box::Manager
    Mail::Message
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

require_ok('Mail::Transport');
require_ok('Mail::Transport::Exim');
require_ok('Mail::Transport::Mailx');
require_ok('Mail::Transport::Qmail');
require_ok('Mail::Transport::Receive');
require_ok('Mail::Transport::Sendmail');
require_ok('Mail::Transport::Send');
require_ok('Mail::Transport::SMTP');
