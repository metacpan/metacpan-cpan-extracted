#!/usr/bin/perl -w
my $users = <<EOF;
use CDB_File 0.86; # there are serious bugs in previous versions
use CDB_File::BiIndex;
use CDB_File::BiIndex::Generator;
use CDB_File::Generator;
use CGI::Carp;
use CGI::Form;
use CGI::Request;
use CGI::Response;
use Cwd;
use Data::Dumper;
use DB_File;
use DB_File; #for temporary database
use English;
use Fcntl;
use File::Copy;
use File::Find;
use FileHandle;
use File::Path;
use Getopt::Function; #don't need yet qw(maketrue makevalue);
use Getopt::Mixed 1.006, 'nextOption';
use HTML::LinkExtor;
use HTML::Stream;
use HTTP::Cookies;
use HTTP::Date qw(time2str);
use HTTP::Headers;
use HTTP::Message;
use HTTP::Request;
use HTTP::Response;
use HTTP::Status ();
use IO::File;
use LWP::Debug;
use LWP::Debug ();
#use LWP::FastRobot;
use LWP::MediaTypes;
#use LWP::NoStopRobot;
use LWP::RobotUA;
use LWP::UserAgent;
use MLDBM qw(DB_File);
use Net::Telnet;
use Schedule::SoftTime;
use Socket;
use Symbol;
use URI;
#use URI::URL;
use WWW::Link;
#use WWW::Link_Controller::ReadConf;
#use WWW::Link_Controller::ReadConf::utils;
use WWW::Link::Repair;
use WWW::Link::Repair::Substitutor;
use WWW::Link::Reporter;
use WWW::Link::Reporter::Compile;
use WWW::Link::Reporter::HTML;
use WWW::Link::Reporter::LongList;
use WWW::Link::Reporter::RepairForm;
use WWW::Link::Reporter::Text;
use WWW::Link::Selector;
#use WWW::Link::Test;
use WWW::Link::Tester;
use WWW::Link::Tester::Adaptive;
use WWW::Link::Tester::Complex;
use WWW::Link::Tester::Simple;
use WWW::RobotRules::AnyDBM_File; #we must cache the robots file
#these must be at the end since we trash the Carp namespace and that
#upsets other perl modules (and can crash perl!)
use Exporter;
use Carp;
EOF
@users = split /\n/, $users;


use Symbol;

$sym=undef;

$file=shift;
die "call with one or no arguments" if shift;

if ( $file ) {
  $sym = gensym;
  open($sym, ">" . $file);
}

#we don't want warnings to come out here since we are using a large
#bunch of modules which aren't always expected to work together and
#don't work well in practice..

#to do this, we have to be very very determined since the packages
#seem to feel free to override our own opinion about warnings.

#finally, we have to delete the Carp namespace becuase Exporter and
#Carp are particularly determined to give warnings.  However, after
#we've done this, some other modules will fail because they expect
#an undisturbed carp namespace..  so we have to make sure that we
#only do this near the end.

no warnings;
foreach (@users){
  $SIG{__WARN__}=sub {1};
  Symbol::delete_package('Carp') if m/Exporter/;
  eval "$_";
  do { print STDERR ("Statement $_ failed: $@\n"); print STDERR "\n" ;
       print $sym "Failed: $_ reason $@\n" if defined $sym;
     } if $@;
}
