# Never modify Config.PPM, always Config.PL
# (Whenever you generate a distribution Config.PPM is overwriten by Config.PL)

use strict;
use warnings;
use Cwd;
use IO::Handle ();
use Socket;

{
    # just to tell 'make' that we are done with configuration
    open my $cfg, '>', 'Config';
    $cfg->print("\n");
}

if ($ENV{PERL_MM_USE_DEFAULT} || !-t STDIN) { exit(); }

my $stderr = IO::Handle->new();
unless ($stderr->fdopen(fileno(STDERR),"w")) {
    die("Can't print to STDERR");
}
$stderr->autoflush(1);
my $stdin = IO::Handle->new();
unless ($stdin->fdopen(fileno(STDIN),"r")) {
    die("Can't open STDIN");
}

# global variables
my %default;
my $smtp;
my $configfile;
my $new = '';

$stderr->print("\n\n
################# Default new object settings for Mail::Sender #################
\n");

sub called_directly {
    if (-d 'blib/lib/Mail') {
        foreach my $dir (@INC) {
            if (-e $dir.'/Mail/Sender.config') {
                $stderr->print(
                    "You have already specified some defaults for Mail::Sender,\n",
                    "They are saved in $dir/Mail/Sender.config.\n",
                    "If you go on you will OVERWRITE the whole file!\n",
                    "You'd better edit the file by hand.\n"
                );
                $new = ' new and OVERWRITE old';
                last;
            }
        }
        return;
    }
    die (
        "Do not execute this script directly, run:\n".
        "\tperl Makefile.PL\n\tmake\n\tmake test\n\tmake install\n".
        "If you are using ActivePerl under Windows use 'nmake' instead of 'make'.\n".
        "nmake.exe may be found at ftp://ftp.microsoft.com/Softlib/MSLFILES/nmake15.exe\n"
    );
}

sub from_ppm {
    print "Running from PPM...\n\n";
    chdir '..';

    # find Mail/Sender.pm
    foreach my $dir (@INC) {
        if (-e $dir.'/Mail/Sender.pm') {
            $configfile = $dir.'/Mail/Sender.config';
            last;
        }
    }
    unless ($configfile) {
        $stderr->print("The module Sender.pm is not found. Are you realy running the script via PPM install ???\n");
        $stdin->getline();
        exit(1);
    }
    if (-e $configfile) {
        $stderr->print("You have already specified some defaults for Mail::Sender,
    They are saved in $configfile.
    If you go on you will OVERWRITE the whole file!
    You'd better edit the file by hand.\n");
        $new = ' new and OVERWRITE old';
    }
}

sub get_smtp {
    while (1) {
        $stderr->print("\nDefault SMTP server (hostname or IP address)\n\n\t: ");
        $smtp = trim($stdin->getline());
        last unless $smtp;

        $stderr->print("\n\t...Trying $smtp...");

        my $proto = (getprotobyname('tcp'))[2];
        my $port  = getservbyname('smtp', 'tcp');

        my $smtpaddr = inet_aton($smtp);
        unless ($smtpaddr) {
            $stderr->print("FAILED\n\t...cannot find server '$smtp' !!!\n");
            last if ignore();
            next;
        }

        socket(my $s, AF_INET, SOCK_STREAM, $proto) or die(
            "Call to socket() failed. You either do not have enough permissions\n".
            "or something really strange happened. Until you fix this neither Mail::Sender\n".
            "nor any other network related module will work. :-(\n"
        );

        unless (connect($s, sockaddr_in($port, $smtpaddr))) {
            $stderr->print("FAILED\n\t...the server is either down or doesn't accept connections\n\ton port $port.");
            last if ignore();
            next;
        }
        $s->autoflush();

        my $line = $s->getline();
        chomp $line;
        if ($line =~ /^[45]\d*\s*(.*)$/) {
            $s->close;
            $stderr->print("FAILED\n\t...the server replied '$1'.\n");
            last if ignore();
            next;
        }

        $s->print("helo localhost\r\n");
        $line = $s->getline();
        chomp $line;
        if ($line =~ /^[45]\d*\s*(.*)$/) {
            $stderr->print(
                "To my greeting the server replied '$1'.\n",
                "It probably meens that you will have to specify the client name\n",
                "when connecting to this server. You should specify the default\n",
                "client name later during this configuration, otherwise you will have\n",
                "to include parameter client=> in every \"Mail::Sender->new\" call.\n"
            );
            last if ignore();
            next;
        }
        $s->print("quit\r\n");
        $stderr->print("successful :-)\n");
        last;
    }
    $default{smtp} = "'$smtp'";
}

sub ignore {
    $stderr->print("\nDo you want to change the setting or use this one in spite of the errors?\n\t(C)hange / (U)se : ");
    while (my $line = $stdin->getline()) {
        chomp $line;
        return 1 if $line =~ /^[uU]/;
        return if $line =~ /^[cC]/;
        $stderr->print("\t(C)hange / (U)se : ");
    }
    exit;
}

sub quote_address {
    my $input = shift;
    if ($input && $input =~ /^[\w\d.-]+@(?:[\w\d-]+\.)*[\w\d]+$/) {
        return "'$input'";
    }
    return $input;
}

sub trim {
    return '' unless defined($_[0]) && length($_[0]);
    my $input = shift;
    $input =~ s/^\s*//;
    $input =~ s/\s*\z//;
    return $input;
}

if ($0 =~ /\.PPM$/i) {
    from_ppm();
}
else { # called directly
    called_directly();
}

$stderr->print("\nSpecify$new defaults for Mail::Sender? (y/N) ");
my $res = $stdin->getline();
chomp $res;
exit unless $res =~ /^[yY]/;

if ($configfile) {
    $stderr->print("\n\t... will be saved to $configfile\n");
}
else {
    $stderr->print("\n\t... will be saved to .../lib/Mail/Sender.config\n");
    $configfile = 'blib/lib/Mail/Sender.config';
}

get_smtp();

$stderr->print(<<'END');

*********************************************************************
**** ALL of the following Defaults are interpreted as perl code *****
*********************************************************************

*********************************************************************
Default FROM value (must be perl code / ENTER for none):

    Examples:
        *   'user\@yourdomain.com'
        *   getlogin() . '\@yourdomain.com'
        *   'Your Name <yourname\@yourdomain.com>'

END
$stderr->print("\t: ");
$default{from} = quote_address(trim($stdin->getline()));
delete $default{from} unless $default{from};

$stderr->print("\n*********************************************************************\n");
$stderr->print("Default for REPLY-TO field (must be perl code / ENTER for none):\n\n\t: ");
$default{replyto} = quote_address(trim($stdin->getline()));
delete $default{replyto} unless $default{replyto};

$stderr->print("\n*********************************************************************\n");
$stderr->print("Default for CC field (must be perl code / ENTER for none):\n\n\t: ");
$default{cc} = quote_address(trim($stdin->getline()));
delete $default{cc} unless $default{cc};

$stderr->print("\n*********************************************************************\n");
$stderr->print("Default for BCC field (must be perl code / ENTER for none):\n\n\t: ");
$default{bcc} = quote_address(trim($stdin->getline()));
delete $default{bcc} unless $default{bcc};

$stderr->print("\n*********************************************************************\n");
$stderr->print("Default name of the client MACHINE used when connecting\nto the SMTP server (must be perl code / ENTER for none):\n\n\t: ");
$default{client}=<STDIN>;
chomp $default{client};delete $default{client} unless $default{client};

$stderr->print("\n*********************************************************************\n");
$stderr->print("Default additional headers (must be perl code / ENTER for none):\n\n\t: ");
$default{headers}=<STDIN>;
chomp $default{headers};delete $default{headers} unless $default{headers};

$stderr->print("\n*********************************************************************\n");
$stderr->print("Default encoding of message bodies (N)one, (Q)uoted-printable, (B)ase64:\n\n\t: ");
while (my $line = $stdin->getline()) {
    chomp $line;
    next unless $line;
    if ($line =~ /^[qQ]/) {
        $default{encoding} = "'Quoted-printable'";
        last;
    } elsif ($line =~ /^[bB]/) {
        $default{encoding} = "'Base64'";
        last;
    } elsif ($line =~ /^[nN]/) {
        last;
    }
}

$stderr->print("\n*********************************************************************\n");
$stderr->print("Default charset of message bodies (must be perl code / ENTER for none):\n\n\t: ");
$default{charset} = $stdin->getline();
chomp $default{charset};
if ($default{charset} =~ /^[\w\d_-]+$/) {
    $default{charset} = "'$default{charset}'";
}
delete $default{charset} unless $default{charset};

$stderr->print("\n*********************************************************************\n");
$stderr->print("*********************************************************************\n");

open my $cfg, '>', $configfile;
$cfg->print("### Config file for Mail::Sender\n### generated by Config.PL (".scalar(localtime).")\n\n");
$cfg->print("%default = (\n");

foreach my $key (keys %default) {
    $cfg->print("\t$key => $default{$key},\n");
}

$cfg->print(");\n\n");
$cfg->print(<<'END');
# The contents of this variable will be inserted into the headers of every
# mail message sent by Mail::Sender.
#
#  $Mail::Sender::SITE_HEADERS = "X-Sender: ".getlogin()."\@mysite.com";


# This function will be evaluated for every mail message before contacting the server.
# You may change all the options of the message and even cancel the message.
#
# sub SiteHook {
# }


1;

END

$stderr->print("The defaults were saved into $configfile
Please review the code in there if 'make test' or
every 'use Mail::Sender;' command fails.");
