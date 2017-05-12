#!/usr/bin/perl
#
# Call    demo.pl [-v] folder [directory]
#        -v        = verbose
#        folder    = any kind of folder
#        directory = where the output will be

sub usage() { die "Usage: $0 [-v] folder\n" }

# example:
#     demo.pl -v $MAIL

use strict;
use warnings;
use File::Spec::Functions;

# Select the browser you use, to display the result
my $display = sub {
   "galeon -x $_[0]"
#  "mozilla -remote 'openFile($_[0])'"
#  "netscape -remote 'openFile($_[0])'"
};

my $verbose = @ARGV && $ARGV[0] eq '-v' ? shift @ARGV : 0;
usage unless @ARGV;

#my $template_system;     # use default = OODoc
#my $template_system  = 'HTML::FromMail::Format::Magic';
my $template_system = 'HTML::FromMail::Format::OODoc';

# Relative directory with template files.  The template used is
# examples/magic1/message/index.html
my $templates = "templ_demo";

# Only for my own home test environment
use lib qw(lib ../lib);
use lib '/home/markov/shared/perl/MailBox3/lib';   # Mail::Box
use lib '/home/markov/shared/perl/Template/lib';   # OODoc::Template

# Here the real work starts
use Mail::Box::Manager;
use HTML::FromMail;

use File::Temp 'tempdir';

#
# Get the folder
#

if(@ARGV < 1)
{   warn "ERROR: No folder name specified\n";
    die;
}
my $filename = shift;

my $temp = @ARGV ? shift : tempdir;
if(@ARGV)
{   warn "ERROR: too many command-line arguments\n";
    usage;
}

#
# Open the folder to take first message
#

my $mgr      = Mail::Box::Manager->new;
my $folder   = $mgr->open($filename)
   or die "ERROR: Cannot open folder $filename\n";

my $msg      = $folder->message(0)
  or die "The folder is empty... one message is required\n";

$msg->printStructure if $verbose;

#
# Look for the templates to be used.  Usually this is simple, but in
# the case of this example script, I cannot hard-code the path.
#

$templates = catdir 'examples', $templates
   unless -d $templates;

die "Cannot find templates in $templates for the example. In which directory are you?\n"
   unless -d $templates;

print "Taking templates from $templates\n" if $verbose;

#
# Start the formatter
#

print "Producing output in $temp.\n" if $verbose;

# Translate a message into its location
sub message_directory($)
{   my $message = shift;
}

# Compose settings, in this case, for each page the same so only one
# formatter object is needed.

my %message_settings = 
 ( message_directory => \&message_directory
 );

my %field_settings =
 ( address => 'MAILTO'
 );

my %settings =
 ( message => \%message_settings
 , field   => \%field_settings
 );

my @template_system
  = defined $template_system ? (formatter => $template_system) : ();

my $fmt   = HTML::FromMail->new
 ( @template_system
 , templates => $templates
 , settings  => \%settings
 );

$fmt->export
  ( $msg
  , use      => [ 'message/index.html', 'message/details.html' ]
  , output   => $temp
  );

my $reply = $msg->reply
  ( include     => 'INLINE'
  , group_reply => 1
  );

$fmt->export
  ( $reply
  , use      => 'message/reply.html'
  , output   => $temp
  );

#
# Force open browser to load the produced page
#

my $start = catfile $temp, 'index.html';
print "Displaying $start\n" if $verbose;

system($display->($start))==0
  or die "Couldn't send instruction to the browser.\n";

print "Ready!\n" if $verbose;
