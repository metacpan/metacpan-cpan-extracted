#!/usr/bin/env perl
use warnings;
use strict;

use Test::More tests => 11;

# The versions of the following packages are reported to help understanding
# the environment in which the tests are run.  This is certainly not a
# full list of all installed modules.
my @show_versions =
 qw/
    Log::Dispatch
    Log::Log4perl
    Mojolicious
    Plack::Test
    POSIX
    PPI
    String::Print
    Sys::Syslog
    Test::Pod
	XML::LibXML
   /;

#   Log::Report::Optional
#   Log::Report::Lexicon
warn "Perl $]\n";
foreach my $package (sort @show_versions)
{   eval "require $package";

    my $report
      = !$@                    ? "version ". ($package->VERSION || 'unknown')
      : $@ =~ m/^Can't locate/ ? "not installed"
      : "reports error";

    warn "$package $report\n";
}

use_ok('Log::Report');
use_ok('Log::Report::Die');
use_ok('Log::Report::Dispatcher');
use_ok('Log::Report::Dispatcher::File');
use_ok('Log::Report::Dispatcher::Try');
use_ok('Log::Report::Dispatcher::Perl');
use_ok('Log::Report::Dispatcher::Callback');
use_ok('Log::Report::Domain');
use_ok('Log::Report::Exception');
use_ok('Log::Report::Message');
use_ok('Log::Report::Translator');

# Log::Report::Dispatcher::Syslog       requires optional Sys::Syslog
# Log::Report::Dispatcher::LogDispatch  requires optional Log::Dispatch
# Log::Report::Dispatcher::Log4perl     requires optional Log::Log4perl
