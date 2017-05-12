# -*- perl -*-

use strict;
require 5.005;
use ExtUtils::MakeMaker ();
use Getopt::Long ();


sub Usage {
    print <<"EOF";
Usage: $0 <options>

Possible options are:

  --antivir-path=<p>    Set path of antivir binary; 'none' to disable
  --debug		Turn on debugging mode
  --facility=<f>	Set syslog facility
  --gzip-path=<p>       Set path of gzip binary; 'none' to disable
  --help		Print this message
  --lha-path=<p>        Set path of unarj binary; 'none' to disable
  --mail-user=<u>	Set UID under which sendmail executes external binaries
  --mail-group=<g>	Set GID under which sendmail executes external binaries
  --mail-host=<h>	Set host to use for delivering mails
  --my-mail=<a>		Set email address being used in reports
  --noprompt		Suppress prompting the user
  --pid-file=<p>        Set path of PID file
  --php-path=<p>        Set path of pgp binary; 'none' to disable
  --sendmail-path=<p>   Set path of sendmail binary; 'none' to disable
  --tar-path=<p>	Set path of tar binary; 'none' to disable
  --tmp-dir=<p>		Set path of spool directory
  --unarj-path=<p>      Set path of unarj binary; 'none' to disable
  --unix-sock=<p>       Set path of unix socket
  --domain=<d>          Set domain being added to unqualified email adresses
  --unzip-path=<p>      Set path of unzip binary; 'none' to disable
  --verbose		Turn on verbose mode

See "perldoc ExtUtils::MakeMaker" for generic options.
EOF
    exit 1;
}


use vars qw($debug $verbose $prompt);
$prompt = 1;
Getopt::Long::Configure('pass_through');
Getopt::Long::GetOptions('debug' => \$debug, 'verbose' => \$verbose,
			 'prompt!' => \$prompt, 'help' => \&Usage);


my %prereq =
    ( "IO::Scalar" => 1.113,
      "MIME::Tools" => 4.116,
      "IO::Tee" => 0.61
    );


use lib "lib";
# Create a config file. Make sure this is successfull, so that we
# get a Makefile anyways. This is required by the automatic CPAN
# installation.

my $cfg = eval {
    require Mail::IspMailGate::Install;
    $Mail::IspMailGate::Install::config = 1;
    Mail::IspMailGate::Install->Config();
};


my $unixSock = $cfg ? $cfg->{'unix_sock'} : '';


ExtUtils::MakeMaker::WriteMakefile
    ('NAME' => 'Mail::IspMailGate',
     'EXE_FILES' => ['ispMailGateD'],
     'VERSION_FROM' => 'lib/Mail/IspMailGate/Install.pm',
     'dist'         => { 'SUFFIX'       => ".gz",
			 'DIST_DEFAULT' => 'all tardist',
			 'COMPRESS'     => "gzip -9vf" },
     'clean'        => { 'FILES'        => 'output ispMailGate ispMailGateD' },
     'DEFINE'       => $unixSock ? q{-DPATH_UNIXSOCK=\"}.$unixSock.q{\"} : "",
     'INC'          => '-I$(PERL_INC)',
     'linkext'      => {'LINKTYPE'     => ''},
     'ABSTRACT'     => "A general purpose filtering MDA for sendmail",
     'AUTHOR'       => 'Jochen Wiedmann <joe@ispsoft.de>',
     'PREREQ_PM'    => \%prereq
    );


package MY;

sub postamble {
    qq{

all :: README\n\nREADME: ispMailGateD
\tperldoc -t ispMailGateD >README

install ::
\t\$(PERL) -I\$(PERL_ARCHLIB) -I\$(PERL_LIB) -MMail::IspMailGate::Install -e Install
};
}

sub libscan {
    my($self, $path) = @_;
    ($path =~ /\~$/) ? undef : $path;
}
