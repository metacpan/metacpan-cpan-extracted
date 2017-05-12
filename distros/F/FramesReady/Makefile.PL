# This -*- perl -*- script writes the Makefile for FramesReady
# $Id: Makefile.PL,v 1.19 2010/03/31 09:10:00 aederhaag Exp $

require 5.005;
use strict;
use ExtUtils::MakeMaker;
use Config;

#--- End Configuration - You should not have to change anything below this line


# Allow us to suppress all program installation with the -n (library only)
# option.  This is for those that don't want to mess with the configuration
# section of this file.
use Getopt::Std;
use vars qw($opt_n);
unless (getopts("n")) {
    die "Usage: $0 [-n]\n";
}

# Check if we have an internet connection
require IO::Socket;
my $s = IO::Socket::INET->new(PeerAddr => "www.google.com:80",
			      Timeout  => 10,
			      );
if ($s) {
  # XXX could try to send a GET to it???
  close($s);

  print <<EOT;

    You appear to be directly connected to the Internet.  I have some
	tests that try to access some sites on the net to verify
	that the new HTTP/1.1 support works as it should.

EOT

  if (prompt("Do you want to enable these tests?", "y") =~ /^y/i) {
    open(ENABLED, ">t/live/ENABLED") || die "Can't enable: $!";
    close(ENABLED);

  } else {
    unlink("t/live/ENABLED");
  }
}

# Check for non-standard modules that are used by this library.
$| = 1;
my $missing_modules = 0;

print "\nChecking for URI...........";
eval {
    require URI;
    URI->VERSION(1.10);
};
if ($@) {
    print " failed\n";
    $missing_modules++;
    print <<EOT;
$@
The URI module must be installed.  Non-absolute frame names will not
work without it :-(

EOT
    sleep(2);  # Don't hurry too much
} else {
    print " ok\n";
}
print "Checking for HTML::Parser..";
eval {
    require HTML::HeadParser;
    HTML::Parser->VERSION(2.20);
};
if ($@) {
    print " failed\n";
    $missing_modules++;
    print <<EOT;
$@
The HTML::Parser is needed to extract correct base URI information from
HTML so that we can resolve relative links correctly.  The HTML::Form
module also needs HTML::TokeParser to work.

EOT
    sleep(2);  # Don't hurry too much
} else {
    print " ok\n";
}

print "Checking for MIME::Base64..";
eval {
    require MIME::Base64;
    #MIME::Base64->VERSION('2.00');
};
if ($@) {
    print " failed\n";
    $missing_modules++;
    print <<EOT;
$@
The Base64 encoding is used in authentication headers in HTTP.

EOT
    sleep(2);  # Don't hurry too much
} else {
    print " ok\n";
}

print <<EOT if $missing_modules;
The missing modules can be obtained from CPAN.  Visit
<URL:http://www.perl.com/CPAN/> to find a CPAN site near you.

EOT

print "\n";

# Ok, now it is time to really generate the Makefile

WriteMakefile(
	      NAME          => 'FramesReady',
	      VERSION_FROM  => 'lib/LWP/UserAgent/FramesReady.pm',
	      PREREQ_PM     => {
                  'URI'			=> "1.10",
                  'HTML::HeadParser'	=> '0', # or a minimum working version
                  'MIME::Base64'	=> '2.1', # or a minimum working version
                  'LWP::UserAgent'	=> '0', # or a minimum working version
                  'HTML::Form'		=> '0', # or a minimum working version
                  'HTTP::Daemon'	=> '0', # or a minimum working version
                  'Net::HTTP'		=> '0', # or a minimum working version
                  'Net::FTP'		=> "2.58",
                  'TAP::Formatter::File' => "3.21",
                  'Digest::MD5'		=> 0,},
              'dist'        => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    );


package MY;

# What happens when we say 'make test'
sub test
{
    q(
      TEST_VERBOSE=0

test: all
	$(FULLPERL) t/TEST $(TEST_VERBOSE)

    );
}


# Determine things that should *not* be installed
sub libscan
{
    my($self, $path) = @_;
    return '' if $path =~ m/.(pl|dtd|sgml)$/;
    return '' if $path =~ m:\bCVS/:;
    return '' if $path =~ m/~$/;
    $path;
}

# Pass libwww-perl version number to pod2man
sub manifypods
{
    my $self = shift;
    my $ver = $self->{VERSION} || "";
    local($_) = $self->SUPER::manifypods(@_);
    s/pod2man\s*$/pod2man --release FramesReady-$ver/m;
    $_;
}
