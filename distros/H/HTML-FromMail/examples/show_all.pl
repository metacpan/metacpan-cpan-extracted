#!/usr/bin/perl
#
# Call    show_all [-v] filename  (file contains message without From line)
#   or    show_all [-v] <message  (message at stdin)

sub usage() { die "Usage: $0 [-v] [filename]" }

# example:
#     show_all -v <msg

use strict;
use warnings;

# Select the browser you use, to display the result
my $display = sub {
   "galeon -x $_[0]"
#  "mozilla -remote 'openFile($_[0])'"
#  "netscape -remote 'openFile($_[0])'"
};

my $verbose = @ARGV && $ARGV[0] eq '-v' ? shift @ARGV : 0;
usage unless @ARGV;

#my $template_system;     # use default = OODoc
my $template_system = 'HTML::FromMail::Format::Magic';
#my $template_system = 'HTML::FromMail::Format::OODoc';

# Relative directory with template files.  The template used is
# examples/magic1/message/index.html
my $templates = "templ_all";

# Only for my own home test environment
use lib qw(lib ../lib);
use lib '/home/markov/shared/perl/MailBox3/lib';   # Mail::Box
use lib '/home/markov/shared/perl/Template/lib';   # OODoc::Template

# Here the real work starts
use Mail::Message;
use HTML::FromMail;

use File::Temp 'tempdir';

#
# Get the message
#

my ($filename, $file);
if(@ARGV)
{   $filename = shift @ARGV;
    open $file, '<', $filename
      or die "Cannot read message from $file\n";
}
else
{   $filename = "stdin";
    $file = \*STDIN;
}

my $msg = Mail::Message->read($file);
die "No message read.\n" unless $msg;

$msg->printStructure if $verbose;

#
# Look for the templates to be used.  Usually this is simple, but in
# the case of this example script, I cannot hard-code the path.
#

$templates = File::Spec->catdir('examples', $templates)
   unless -d $templates;

die "Cannot find templates in $templates for the example. In which directory are you?\n"
   unless -d $templates;

print "Taking templates from $templates\n" if $verbose;

#
# Start the formatter
#

my $temp  = tempdir;
print "Producing output in $temp.\n" if $verbose;

my @template_system
  = defined $template_system ? (formatter => $template_system) : ();

my $fmt   = HTML::FromMail->new
 ( templates => $templates
 , @template_system
 );

my $start = $fmt->export($msg, output => $temp);

die "Failed to produce html.\n" unless defined $start;

#
# Force open browser to load the produced page
#

print "Displaying $start\n" if $verbose;

system($display->($start))==0
  or die "Couldn't send instruction to the browser.\n";

print "Ready!\n" if $verbose;
