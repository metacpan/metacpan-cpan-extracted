use strict;
use ExtUtils::MakeMaker;
# most of this has been taken from Crypt-SSLeay


my $GOTSSL = "";
my($SEP, $SSL_LIB, $SSL_INC, $LIBS);

# FIND POSSIBLE SSL INSTALLATIONS
my @POSSIBLE_SSL_DIRS = qw(/usr/local/openssl /usr/local/ssl /local/ssl /opt/ssl /usr/local /local /usr);
my $open_ssl = 0;


# if they want to build with ssl then they will have set this env variable
if (exists $ENV{'GOTSSL'} && $ENV{'GOTSSL'} eq 'yes'){

  use File::Basename qw(dirname basename);
  use Getopt::Long;
  use vars qw($opt_default);

  &GetOptions("default", \$opt_default);

  $opt_default ||= $ENV{CRYPT_SSLEAY_DEFAULT};
  my $currdir = dirname($0) || '.';
  chdir($currdir) || die("can't change to $currdir: $!");
  if($^O eq 'MSWin32') {
      unshift(@POSSIBLE_SSL_DIRS, 'c:/openssl');
  }

  my @CANDIDATE;
  my $dir;
  for $dir (@POSSIBLE_SSL_DIRS) {
      next unless -d $dir;
      my $candidate = Candidate($dir);
      next unless $candidate;
  
      push(@CANDIDATE, $candidate);
  }

  if (@CANDIDATE == 1) {
      my($dir, $inc_dir, $ver) = @{$CANDIDATE[0]};
      print "Found OpenSSL (version $ver) installed at $dir\n";
  } elsif (@CANDIDATE > 1) {
      print "Found the following OpenSSL installations:\n";
      for (@CANDIDATE) {
  	my($dir, $inc_dir, $ver) = @$_;
  	print "\t$ver\t$dir\n";
      }
  }

  my $SSL_DIR;
  if($opt_default && (@CANDIDATE == 1) && $CANDIDATE[0][0]) {
      $SSL_DIR = $CANDIDATE[0][0];
      print "Using --default OpenSSL candidate found at $SSL_DIR\n";
  } else {
      if($ARGV[0] =~ /^[a-z]\:|^\//i) {
  	$SSL_DIR = shift;
      } else {
  	unless($CANDIDATE[0][0]) {
  	    print "No OpenSSL installation found, usually in $POSSIBLE_SSL_DIRS[0]\n";
  	}
  	$SSL_DIR = prompt "Which OpenSSL build path do you want to link against?", $CANDIDATE[0][0];
      }
  }

  my $candidate = &Candidate($SSL_DIR);
  unless($candidate) {
      warn "Apparently no SSLeay installation at '$SSL_DIR'\nAre you sure you got it correct????\n"
        unless -f "$SSL_DIR/include/ssl.h";
  }
  $candidate ||= ["$SSL_DIR", "$SSL_DIR/include"];
  
  $SSL_INC = "$SSL_DIR/include";
  
  if($^O =~ /Win32/) {
      unless($SSL_DIR =~ /^[a-zA-Z]\:/) {
  	# default drive c
  	$SSL_DIR = "c:".$SSL_DIR;
      }
      unless($SSL_INC =~ /^[a-zA-Z]\:/) {
  	# default drive c
  	$SSL_INC = "c:".$SSL_INC;
      }
      $SSL_INC .= " -I".$SSL_DIR."/inc32";
      $SSL_DIR =~ s|/|\\|g;
      $SSL_INC =~ s|/|\\|g;
  
      # patch from Ben Laurie
      if(-d "$SSL_DIR/lib") {
    	$SSL_LIB = "-L$SSL_DIR/lib";
      } elsif(-d "$SSL_DIR/out32dll") {
  	$SSL_LIB = "-L$SSL_DIR\\out32dll";	
      }else {
  	# Allow developers to point at OpenSSL source...
  	$SSL_LIB = "-L$SSL_DIR";
      }

      $SEP = "\\";
      $LIBS = "-lssleay32 -llibeay32";
  } else {
      $SSL_LIB = "-L".$SSL_DIR."/lib";
      $SEP = "/";
      $LIBS = "-lssl -lcrypto ".($^O ne 'linux' ? " -lgcc" : "");
  
      # ccc on alpha support
      if ($^O eq 'linux' && `uname -m` =~ /alpha/ &&
  	!(system("nm $SSL_DIR/lib/libssl.a|grep -q 'U _Ots'")>>8)) {
  	$LIBS .= ' -lots'; 
      }
  }

  # write include file that determing ssl support
  my $ssl_header_prefix = '';
  my $candidate_info = join('; ', @$candidate);
  if($candidate->[1] =~ /openssl/i) {
      $ssl_header_prefix = "openssl/";
  }
  
  print <<INFO;

================================================
BUILD INFORMATION
================================================

ssl dir:	$SSL_DIR
libraries:      $LIBS
include dir:	$SSL_INC
ssl header:     @{[$ssl_header_prefix]}ssl.h
ssl candidate:  $candidate_info

================================================

INFO
  ;

# end of Crypt-SSLeay

  $GOTSSL = ' -DOPENSSL_NO_KRB5 -DGOTSSL ';
}

WriteMakefile(
    clean => { 'FILES'	=> '*~ *.inl core test*.txt *.tar.gz _Inline ' },
    dist => { 'TARFLAGS'	=> 'cvf',
              'COMPRESS'        => 'gzip -9f',
    		'SUFFIX'	=> '.tgz'},
    'NAME'	=> 'HTTP::MHTTP',
    'VERSION_FROM' => 'MHTTP.pm',
    'MYEXTLIB' => 'mhttp/libmhttp$(LIB_EXT)',
    'DEFINE'	=> $GOTSSL,
    'LIBS'      => [($GOTSSL ? "$SSL_LIB $LIBS" : "")],
    'INC'	=> "-Imhttp ".($GOTSSL ? "-I".$SSL_INC : ""),
);

sub MY::postamble {
'
$(MYEXTLIB): mhttp/Makefile
	cd mhttp && $(MAKE) $(PASSTHRU)
';
}


# this next bit is taken from Crypt-SSLeay
## HELPERS

sub Candidate {
    my $dir = shift;
    my $version_file;
    my $inc_dir;

    for (
	 "$dir/crypto/opensslv.h", # cygwin32 builds
	 "$dir/inc32/openssl/opensslv.h", # win32 builds
	 "$dir/include/openssl/opensslv.h", 
	 "$dir/include/opensslv.h", 
	 "$dir/include/crypto.h"
	) 
      {
	  if(-e $_) {
	      $version_file = $_;
	  } 
      }
    return unless defined $version_file;

    $open_ssl = ($version_file =~ /openssl/) ? 1 : 0;
    my $dirname = $inc_dir = dirname($version_file);
    return unless (-e "$dirname/ssl.h");

    open(VERSION_FILE, $version_file) or return;
    my $version_match = $open_ssl ? "OPENSSL_VERSION_NUMBER" : "SSLEAY_VERSION_NUMBER";
    my $version;
    while (<VERSION_FILE>) {
	if (/^\#define\s+$version_match\s+0x0+(\d\d\d)/) {
	    $version = $1;
	    $version =~ s/(\d)0(\d)/$1$2/;	    
	    my $type = ($version > 92) ? "OpenSSL" : "SSLeay";
	    $version = "$type ".join('.', split(//, "0$version"));
	    last;
	}
    }
    close(VERSION_FILE);

    # Silly test to look for the library files
    my $foundlib = 0;
    my $libd = (-d "$dir/out32dll") ? 'out32dll' : 'lib';
    if (opendir(LIBDIR, "$dir/$libd")) {
	while (defined($_ = readdir(LIBDIR))) {
	    $foundlib++ if /^libssl/;
	    $foundlib++ if /^libcrypto/;
	    $foundlib++ if /^ssleay32/;
	    $foundlib++ if /^libeay32/;
	}
	closedir(LIBDIR);
    }
    warn "$dir/lib does not seem to contain the SSLeay library files\n"
	unless $foundlib;

    [$dir, $inc_dir, $version];
}


# end of more Crypt-SSLeay

