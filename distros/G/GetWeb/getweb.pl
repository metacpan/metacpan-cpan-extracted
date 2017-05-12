#!/usr/bin/perl
#-
#-getweb.pl:  sends formatted web pages via e-mail.
#-
#-Usage:
#-         $0 [-hvD] [-r root]
#-            [(-c | -f spool | -i [-s subject] [-b body])] 
#-            [file ...]
#-
#-Where:
#-          -i : interactive mode (read in command, send result to STDOUT)
#-  -s subject : specify subject on command-line
#-     -b body : specify message body on command-line
#-     -r root : system root, default is /usr/local/getweb
#-
#-    file ... : files containing mail messages or input (default is STDIN)
#-          -c : CGI Web-interface mode
#-    -f spool : read from mail spoolfile 'spool' (example: /var/spool/mail/me)
#-
#-          -h : print this help message and exit
#-          -v : print the version number and exit
#-          -D : print debugging information
#-
#
#   Version:  1.1 release
#   Author: Rolf Nelson
#

my $DEFAULT_ROOT = "/usr/local/getweb";

BEGIN {
    push(@INC,".");
}

$ENV{PATH} = "/bin";

use Getopt::Std;
use MailBot::Config;
use GetWeb::GetWeb;
use strict;

# untaint @ARGV to get around libwww-perl bug
grep {/((.|\n)*)/ and $_ = $1} @ARGV;
&procOpts();

my $root = $::opt_r || $DEFAULT_ROOT;
MailBot::Config -> setRoot($root);
my $mailBotConfig = MailBot::Config::current();

if ($::opt_i)
{
    $mailBotConfig -> setInteractive();

    (defined $::opt_s) and
	$mailBotConfig -> setSubject($::opt_s);

    (defined $::opt_b) and
	$mailBotConfig -> setBody($::opt_b);
}

if (defined $::opt_f)
{
    $mailBotConfig -> setMailSpool($::opt_f);
}
elsif ($::opt_c)
{
    $mailBotConfig -> setCGI();
}

my $in = shift @ARGV;
if (defined $in)
{
    open(STDIN,$in) or die "could not open $in for input: $!";
}

my $getweb = new GetWeb::GetWeb;

$getweb -> run;

0;

#----------------------------------------------------------------
# procOpts:  process command-line options
#----------------------------------------------------------------
sub procOpts
{
    ($::opt_v, $::opt_c, $::opt_h, $::opt_D,
     $::opt_i, $::opt_r) = ();  #avoid warning message
    getopts('b:cf:ir:s:hvD') || &showUsage("bad command switches");
    &d();
    $::opt_h && &showUsage();
    $::opt_v && &showVersion();
}   

#----------------------------------------------------------------
# showUsage : display a usage string, then exit.
#----------------------------------------------------------------
sub showUsage
{
    my $errMsg = shift;
    if ($errMsg ne "")
	{
	print STDERR "Usage error: $errMsg\n\n";
	}

    seek(DATA,0,0);
    while (<DATA>)
	{
	if (s/^\#\-//)
	    {
		s/\$0/$0/;
		print STDERR $_ unless /^\-/;
	    }
	}

    exit ($errMsg ne "");
}

#----------------------------------------------------------------
# showVersion : print Version and exit.
#----------------------------------------------------------------
sub showVersion
{
    seek(DATA,0,0);
    while (<DATA>)
	{
	print STDERR $_ if /\s+Version:/;
	}

    exit(0);
}

#----------------------------------------------------------------
# d : print debugging message if -D verbose flag is on.
#----------------------------------------------------------------
sub d
{
    return unless $::opt_D;
    my $msg = shift;
    if ($msg eq "")
	{					       
	print STDERR "found -D flag; running $0 in verbose DEBUG mode.\n";
	}
    else
	{
	print STDERR $msg, "\n";
	}
}

__END__
