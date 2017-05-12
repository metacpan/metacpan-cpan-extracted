#!/usr/bin/perl

use warnings;
use strict;

use lib 'lib';
use Test::More tests => 7;

# The versions of the following packages are reported to help understanding
# the environment in which the tests are run.  This is certainly not a
# full list of all installed modules.
my @show_versions =
 qw/Test::More
    IO::Multiplex
    Net::CIDR
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

require_ok("HTTP::Server::Multiplex");
require_ok("HTTP::Server::VirtualHost");
require_ok("HTTP::Server::VirtualHost::LocalHost");
require_ok("HTTP::Server::Connection");
require_ok("HTTP::Server::Directory");
require_ok("HTTP::Server::Directory::UserDirs");
require_ok("HTTP::Server::Session");
