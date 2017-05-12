use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

###########################################################
##          if built from a parent directory,             #
##      at install, the parent Makefile must execute      #
##                                                        #
##  @cd SpamCannibal && $(MAKE) install_daemon $(PASTHRU) #
##  @cd SpamCannibal && $(MAKE) clean_CTest $(PASTHRU)    #
##                                                        #
###########################################################

use Config;
use vars qw($CONFIG);
use Cwd qw(abs_path);

unless ($Config{osname} =~ /linux/i) {
  print STDERR "unsupported operating system $Config{osname}\n";
  exit 0;
}
unless (require IPTables::IPv4::DBTarpit) {
  print STDERR "Missing OS dependent module IPTables::IPv4::DBTarpit\n";
  exit 0;
}
require IPTables::IPv4::DBTarpit::Inst;
import IPTables::IPv4::DBTarpit::Inst qw(:all);

my $conf = 'config.db';
my $home = abs_path('./');
my $localconf = $home .'/'. $conf;

my $configtxt;

if ((caller)[1]) {
  hard_fail("Do not MAKE ". __PACKAGE__ ." as a sibling process
it contains directory sensitive components.");
}

my $pv = sprintf "%vd", $^V;
unless ($pv lt '5.8.0' || $pv gt '5.8.5') {
  print
"
################################################################
######################### WARNING ##############################
#                                                              #
# Early versions of perl 5.8.x contain bugs that cause certain #
# \@_ operations to fail. Please upgrade to at least perl 5.8.6 #
#                                                              #
################################################################

press ENTER:";
  readline *STDIN;
  print "\n";
}

$configtxt = do 'inst/dialog.pl';
$CONFIG = do 'config.db';

my($uid,$gid) = (getpwnam($CONFIG->{SPAMCANNIBAL_USER}))[2,3];

hard_fail('Can not find password file entry for user '. $CONFIG->{SPAMCANNIBAL_USER} .'
You must create the user and directory structure
before running this installation procedure.
') unless $CONFIG->{SPAMCANNIBAL_USER} && $uid && $gid;

# pull in pod pages for external support modules
my %xmodules = (
  'Geo::IP::PurePerl'			=> 'Geo-IP-PurePerl',
  'Geo::CountryFlags'			=> 'Geo-CountryFlags',
  'Data::Password::Manager'		=> 'Data-Password-Manager',
  'File::SafeDO'			=> 'File-SafeDO',
  'IPTables::IPv4::DBTarpit'		=> 'IPTables-IPv4-DBTarpit',
  'IPTables::IPv4::DBTarpit::Tools'	=> 'IPTables-IPv4-DBTarpit-Tools',
  'IPTables::IPv4::DBTarpit::Inst'	=> 'IPTables-IPv4-DBTarpit-Inst',
  'IPTables::IPv4::DBTarpit::SiteConfig'=> 'IPTables-IPv4-DBTarpit-SiteConfig',
  'LaBrea::Tarpit'			=> 'LaBrea-Tarpit',
  'LaBrea::Tarpit::Report'		=> 'LaBrea-Tarpit-Report',
  'Net::DNS::Codes'			=> 'Net-DNS-Codes',
  'Net::DNS::ToolKit'			=> 'Net-DNS-ToolKit',
  'Net::DNS::ToolKit::RR'		=> 'Net-DNS-ToolKit-RR',
  'Net::DNS::ToolKit::RR::Template'	=> 'Net-DNS-ToolKit-RR-Template',
  'Net::DNS::ToolKit::Question'		=> 'Net-DNS-ToolKit-Question',
  'Net::DNS::ToolKit::Utilities'	=> 'Net-DNS-ToolKit-Utilities',
  'Net::DNSBL::MultiDaemon'		=> 'Net-DNSBL-MultiDaemon',
  'Net::DNSBL::Utilities'		=> 'Net-DNSBL-Utilities',
  'Net::SMTP'				=> 'Net-SMTP',
  'Net::Whois::IP'			=> 'Net-Whois-IP',
  'NetAddr::IP::Lite'			=> 'NetAddr-IP-Lite',
  'Proc::PidUtil'			=> 'Proc-PidUtil',
  'Sys::Hostname::FQDN'			=> 'Sys-Hostname-FQDN',
);

my %xpmfiles;
foreach(keys %xmodules) {
  next unless eval "require $_";
  (my $pmf = $_) =~ s|::|/|g;
  $pmf .= '.pm';
  $xpmfiles{"$INC{$pmf}"} = 'docs/'. $xmodules{$_} . '.html';
}

my %makeparms = (
   'EXTRA_META'	  => q|configure_requires:
    IPTables::IPv4::DBTarpit::Inst: 0
|,
   'NAME'         => 'Mail::SpamCannibal',
   'VERSION_FROM' => 'SpamCannibal.pm',		# finds $VERSION
   'PREREQ_PM'	  => {
			'IPTables::IPv4::DBTarpit' => '0.43',
			'Geo::IP::PurePerl'	=> '1.10',
			'File::SafeDO'		=> '0.12',
			'Data::Password::Manager'  => '0.01',
			'Sys::Hostname::FQDN'	=> '0.06',
			'Net::DNS::Codes'	=> '0.09',
			'Net::DNS::ToolKit'	=> '0.41',
			'NetAddr::IP::Lite'	=> '0.02',
			'Net::DNSBL::MultiDaemon' => '0.26',
			'Net::SMTP'		=> '2.10',
			'Net::Whois::IP'	=> '0.35',
			'MIME::Base64'		=> '2.00',
			'Digest::MD5'		=> '2.00',
			'Test::Harness'		=> '2.01',
			'Test::Simple'		=> '0.42',
			'Unix::Syslog'		=> '0.97',
			'Proc::PidUtil'		=> '0.06',
		  },
   'PM'		  => {  'SpamCannibal.pm' => '$(INST_LIBDIR)/SpamCannibal.pm',
			'SiteConfig.pm' => '$(INST_LIB)/Mail/SpamCannibal/SiteConfig.pm',
			'lib/Mail/SpamCannibal/GoodPrivacy.pm'
				=> '$(INST_LIB)/Mail/SpamCannibal/GoodPrivacy.pm',
			'lib/Mail/SpamCannibal/ParseMessage.pm'
				=> '$(INST_LIB)/Mail/SpamCannibal/ParseMessage.pm',
			'lib/Mail/SpamCannibal/SMTPsend.pm'
				=> '$(INST_LIB)/Mail/SpamCannibal/SMTPsend.pm',
			'lib/Mail/SpamCannibal/ScriptSupport.pm'
				=> '$(INST_LIB)/Mail/SpamCannibal/ScriptSupport.pm',
			'lib/Mail/SpamCannibal/WebService.pm'
				=> '$(INST_LIB)/Mail/SpamCannibal/WebService.pm',
			'lib/Mail/SpamCannibal/WhoisIP.pm'
				=> '$(INST_LIB)/Mail/SpamCannibal/WhoisIP.pm',
			'lib/Mail/SpamCannibal/Password.pm'
				=> '$(INST_LIB)/Mail/SpamCannibal/Password.pm',
			'lib/Mail/SpamCannibal/Session.pm'
				=> '$(INST_LIB)/Mail/SpamCannibal/Session.pm',
			'lib/Mail/SpamCannibal/PidUtil.pm'
				=> '$(INST_LIB)/Mail/SpamCannibal/PidUtil.pm',
			'lib/Mail/SpamCannibal/LaBreaDaemon.pm'
				=> '$(INST_LIB)/Mail/SpamCannibal/LaBreaDaemon.pm',
			'lib/Mail/SpamCannibal/IP2ccFlag.pm'
				=> '$(INST_LIB)/Mail/SpamCannibal/IP2ccFlag.pm',
		  },
   'MAN3PODS'	  => {	'SpamCannibal.pm' => '$(INST_MAN3DIR)/Mail::SpamCannibal.$(MAN3EXT)',
			'SiteConfig.pm' => '$(INST_MAN3DIR)/Mail::SpamCannibal::SiteConfig.$(MAN3EXT)',
			'lib/Mail/SpamCannibal/GoodPrivacy.pm'
				=> '$(INST_MAN3DIR)/Mail::SpamCannibal::GoodPrivacy.$(MAN3EXT)',
			'lib/Mail/SpamCannibal/ParseMessage.pm'
				=> '$(INST_MAN3DIR)/Mail::SpamCannibal::ParseMessage.$(MAN3EXT)',
			'lib/Mail/SpamCannibal/SMTPsend.pm'
				=> '$(INST_MAN3DIR)/Mail::SpamCannibal::SMTPsend.$(MAN3EXT)',
			'lib/Mail/SpamCannibal/ScriptSupport.pm'
				=> '$(INST_MAN3DIR)/Mail::SpamCannibal::ScriptSupport.$(MAN3EXT)',
			'lib/Mail/SpamCannibal/WebService.pm'
				=> '$(INST_MAN3DIR)/Mail::SpamCannibal::WebService.$(MAN3EXT)',
			'lib/Mail/SpamCannibal/WhoisIP.pm'
				=> '$(INST_MAN3DIR)/Mail::SpamCannibal::WhoisIP.$(MAN3EXT)',
			'lib/Mail/SpamCannibal/Password.pm'
				=> '$(INST_MAN3DIR)/Mail::SpamCannibal::Password.$(MAN3EXT)',
			'lib/Mail/SpamCannibal/Session.pm'
				=> '$(INST_MAN3DIR)/Mail::SpamCannibal::Session.$(MAN3EXT)',
			'lib/Mail/SpamCannibal/PidUtil.pm'
				=> '$(INST_MAN3DIR)/Mail::SpamCannibal::PidUtil.$(MAN3EXT)',
			'lib/Mail/SpamCannibal/LaBreaDaemon.pm'
				=> '$(INST_MAN3DIR)/Mail::SpamCannibal::LaBreaDaemon.$(MAN3EXT)',
			'lib/Mail/SpamCannibal/IP2ccFlag.pm'
				=> '$(INST_MAN3DIR)/Mail::SpamCannibal::IP2ccFlag.$(MAN3EXT)',
		  },
   'INST_HTMLLIBDIR'		=> 'docs',
   'INSTALLHTMLSITELIBDIR'	=> $CONFIG->{SPAMCANNIBAL_HOME} .'/public_html/docs',
   'HTMLLIBPODS'	=> { (%xpmfiles),	# include foreign pm's for doc tree
		(	'pods/scripts.pod'		=> 'docs/scripts.html',
			'pods/index.pod'		=> 'docs/index.html',
			'pods/INSTALL.pod'		=> 'docs/install.html',
			'pods/quick_install.pod'	=> 'docs/quick_install.html',
			'pods/recover.pod'		=> 'docs/recover.html',
			'pods/howitworks.pod'		=> 'docs/howitworks.html',
			'pods/howtouse.pod'		=> 'docs/howtouse.html',
			'DNSBLserver/dnsbls.pod'	=> 'docs/Mail-SpamCannibal-DNSBLserver.html',
			'BDBaccess/bdbaccess.pod'	=> 'docs/Mail-SpamCannibal-BDBaccess.html',
			'SpamCannibal.pm'		=> 'docs/Mail-SpamCannibal.html',
			'SiteConfig.pm'			=> 'docs/Mail-SpamCannibal-SiteConfig.html',
			'BDBaccess/lib/Mail/SpamCannibal/BDBclient.pm' => 'docs/Mail-SpamCannibal-BDBclient.html',
			'lib/Mail/SpamCannibal/GoodPrivacy.pm'	 => 'docs/Mail-SpamCannibal-GoodPrivacy.html',
			'lib/Mail/SpamCannibal/ScriptSupport.pm' => 'docs/Mail-SpamCannibal-ScriptSupport.html',
			'lib/Mail/SpamCannibal/ParseMessage.pm'	 => 'docs/Mail-SpamCannibal-ParseMessage.html',
			'lib/Mail/SpamCannibal/SMTPsend.pm'	 => 'docs/Mail-SpamCannibal-SMTPsend.html',
			'lib/Mail/SpamCannibal/WebService.pm'	 => 'docs/Mail-SpamCannibal-WebService.html',
			'lib/Mail/SpamCannibal/Password.pm'	 => 'docs/Mail-SpamCannibal-Password.html',
			'lib/Mail/SpamCannibal/WhoisIP.pm'	 => 'docs/Mail-SpamCannibal-WhoisIP.html',
			'lib/Mail/SpamCannibal/Session.pm'	 => 'docs/Mail-SpamCannibal-Session.html',
			'lib/Mail/SpamCannibal/PidUtil.pm'	 => 'docs/Mail-SpamCannibal-PidUtil.html',
			'lib/Mail/SpamCannibal/LaBreaDaemon.pm'	 => 'docs/Mail-SpamCannibal-LaBreaDaemon.html',
			'lib/Mail/SpamCannibal/IP2ccFlag.pm'	 => 'docs/Mail-SpamCannibal-IP2ccFlag.html',
		),},
   'HTMLSCRIPTPODS'	=> {	'rc.sc_dbwatch'		=> 'docs/rc.sc_dbwatch.html',
				'rc.sc_lbdaemon.sample'	=> 'docs/rc.sc_lbdaemon.html',
				'DNSBLserver/rc.dnsbls' => 'docs/rc.dnsbls.html',
				'BDBaccess/rc.bdbaccess' => 'docs/rc.bdbaccess.html',
				'contrib/update_sc.sh'	=> 'docs/update_sc.sh.html',
		  },
   'clean'	  => { FILES	=> "*~ tmp* docs* script/sc_sesswrap"},
   'dist'         => { COMPRESS	=> 'gzip', SUFFIX => 'gz'},
);

# if html conversion has been removed in this perl version then work around here
#
require './fixup/perl2html.pl';
my $workaround = pf_html_check(\%makeparms);

sub MY::post_constants {
  my $post_constants = $Config{scriptdirexp} .'/pod2text';
  if (-e $post_constants) {
    $post_constants = q|   
MY_POD2TEXT = |. $post_constants .q|
|;
  } else {
    $post_constants = q|
MY_POD2TEXT = echo "perl distro missing 'pod2text' to convert "
|;
  }
  $post_constants .= q|
|. $configtxt .q|
SPAMUID= |. $uid .q|
SPAMGID= |. $gid .q|

|;
  if ($workaround) {
    $post_constants .= pf_handy_list(\%makeparms);
  }
  $post_constants;
}

### replaced in MY::postamble - install_permissions
### 
#	chmod 0644 $(SPAMCANNIBAL_HOME)/config/sc_web.conf.sample
#	if [ -f $(SPAMCANNIBAL_HOME)/config/sc_web.conf ]; then \
#	    chmod 0644 $(SPAMCANNIBAL_HOME)/config/sc_web.conf; \
#	fi
### replaced with ...  below
#	chmod 0644 $(SPAMCANNIBAL_HOME)/config/sc_web*

sub MY::postamble {
  my $postamble;
  $postamble = q|
.PHONY = install_daemon install_spamcannibal clean_CTest pods/INSTALL.pod install_sc_permissions

INSTALL : pods/INSTALL.pod
	@$(MY_POD2TEXT) pods/INSTALL.pod > INSTALL

pods/INSTALL.pod :
	@$(NOOP)

SiteConfig.pm : config.db
	$(PERL) inst/make_Config.pl

install_spamcannibal	: scripts/sc_sesswrap
	@$(MKPATH) $(SPMCNBL_CONFIG_DIR)
	@$(MKPATH) $(SPMCNBL_SCRIPT_DIR)
	$(RM_F) $(SPMCNBL_SCRIPT_DIR)/sc_remotewrap
	$(CP) -p rc.sc_lbdaemon.sample $(SPMCNBL_SCRIPT_DIR)
	$(CP) -p rc.sc_dbwatch	$(SPMCNBL_SCRIPT_DIR)
	$(CP) -p scripts/*.pl $(SPMCNBL_SCRIPT_DIR)
	$(CP) -p scripts/sc_sesswrap $(SPMCNBL_SCRIPT_DIR)
	@ln -s $(SPMCNBL_SCRIPT_DIR)/sc_sesswrap $(SPMCNBL_SCRIPT_DIR)/sc_remotewrap
	$(CP) -p config/*.sample $(SPMCNBL_CONFIG_DIR)
	$(CP) -rp public_html $(SPAMCANNIBAL_HOME)
	$(RM_F) $(SPAMCANNIBAL_HOME)/public_html/admin.cgi
	@ln -s $(SPAMCANNIBAL_HOME)/public_html/cannibal.cgi $(SPAMCANNIBAL_HOME)/public_html/admin.cgi
	@$(MKPATH) $(SPAMCANNIBAL_HOME)/sess
	@$(MKPATH) $(SPAMCANNIBAL_HOME)/private
	$(CP) -p private/* $(SPAMCANNIBAL_HOME)/private

install_sc_permissions	:
	chown -R $(SPAMUID) $(SPAMCANNIBAL_HOME)
	chgrp -R $(SPAMGID) $(SPAMCANNIBAL_HOME)
	chmod 0700 $(SPAMCANNIBAL_HOME)/sess
	chmod 0700 $(SPAMCANNIBAL_HOME)/private
	chmod 0600 $(SPAMCANNIBAL_HOME)/private/*
	chmod 0640 $(SPAMCANNIBAL_HOME)/config/*
	chmod 0644 $(SPAMCANNIBAL_HOME)/config/sc_web*
	chmod 0644 $(SPAMCANNIBAL_HOME)/config/sc_Black*
	chmod 04755 $(SPMCNBL_SCRIPT_DIR)/sc_sesswrap
	chmod 01700 $(SPMCNBL_SCRIPT_DIR)/sc_session.pl
	chmod 0700 $(SPMCNBL_SCRIPT_DIR)/sc_remote.pl
	if [ -d $(SPAMCANNIBAL_HOME)/public_html/tmp ]; then \
	    $(RM_F) $(SPAMCANNIBAL_HOME)/public_html/tmp/*; \
	else \
	    $(MKPATH) $(SPAMCANNIBAL_HOME)/public_html/tmp; \
	    chown -R $(SPAMUID) $(SPAMCANNIBAL_HOME)/public_html/tmp; \
	    chgrp -R $(SPAMGID) $(SPAMCANNIBAL_HOME)/public_html/tmp; \
	    chmod 0777 $(SPAMCANNIBAL_HOME)/public_html/tmp; \
	fi
	if [ -d $(SPAMCANNIBAL_HOME)/public_html/flags ]; then \
	    echo "$(SPAMCANNIBAL_HOME)/public_html/flags exists, skipping..."; \
	else \
	    $(MKPATH) $(SPAMCANNIBAL_HOME)/public_html/flags; \
	    chown -R $(SPAMUID) $(SPAMCANNIBAL_HOME)/public_html/flags; \
	    chgrp -R $(SPAMGID) $(SPAMCANNIBAL_HOME)/public_html/flags; \
	    chmod 0777 $(SPAMCANNIBAL_HOME)/public_html/flags; \
	fi

install_daemon	:
	@cd BDBaccess && $(MAKE) install_daemon $(PASTHRU)
	@cd DNSBLserver && $(MAKE) install_daemon $(PASTHRU)

clean_CTest	:
	@cd BDBaccess && $(MAKE) clean_CTest $(PASTHRU)
	@cd DNSBLserver && $(MAKE) clean_CTest $(PASTHRU)

|;
  if ($workaround) {
    $postamble .= pf_htmlifypods(\%makeparms,\%Config);
  }
  $postamble;
}

sub MY::top_targets {
  my $inherited;
  {
    package MY;   # add dependencies for .pm and xs files
    $inherited = shift->SUPER::top_targets(@_);
  }
  $inherited =~ s|(\npure_all\s+::.+)config(.+)|${1}SiteConfig.pm scripts/sc_sesswrap INSTALL config$2|;
  if ($workaround) {
    $inherited =~ s/(manifypods)/pf_htmlifypods $1/g;
  }
  $inherited .= q|

scripts/sc_sesswrap	: cdata/sc_sesswrap.c
	@$(CC) cdata/sc_sesswrap.c -o scripts/sc_sesswrap

|;
}

sub MY::makefile {
  package MY;
  my $inherited = shift->SUPER::makefile(@_);
  $inherited =~ s/(Makefile\s+:.+)/$1 config.db/;
  $inherited .= q|
config.db :
	@$(NOOP);

|;
}

sub MY::install {
  my $inherited;
  {
    package MY;
    $inherited = shift->SUPER::install(@_);
  }
  $inherited =~ s/(\ninstall\s+::)(.+doc.+install)/$1 install_daemon install_spamcannibal${2} install_sc_permissions/;
  $inherited =~ s/(\ninstall_perl\s+::(.+doc.+install))/$1 install_daemon install_spamcannibal${2} install_sc_permissions/;
  $inherited =~ s/(\ninstall_site\s+::)(.+doc.+install)/$1 install_daemon install_spamcannibal${2} install_sc_permissions/;   
  $inherited =~ s/(\s+)all(\s+)/${1}all clean_CTest${2}/g;
#  $inherited =~ s|(pure_site_install\s+::.*)|$1\n\t\@\$\(MKPATH\) \$\(INSTALLHTMLSITELIBDIR\)|;
  if ($workaround) {
    $inherited = pf_psias($inherited);
  }
  $inherited;
}

sub MY::realclean {
  package MY;   
  my $inherited = shift->SUPER::realclean(@_) . q|
	$(RM_F) config.db
	$(RM_F) SiteConfig.pm
	$(RM_F) scripts/sc_sesswrap
	$(RM_F) INSTALL
|;
}

sub MY::htmlifypods {
  package MY;
  my $inherited = shift->SUPER::htmlifypods(@_) .q|
	./fixuplinks.pl $(INST_HTMLLIBDIR)
|;
}

sub MY::const_config {
  package MY;
  $inherited = shift->SUPER::const_config(@_);
  return q|LANG=en_US
SUPPORTED=en_US:en
|. $inherited;
}

eval {	require IPTables::IPv4::DBTarpit::Inst ||
	die "no IPTables installed"; };

if ($@) {
  print STDERR q|
##########################################################
IPTables::IPv4::DBTarpit missing or not properly installed
##########################################################

|;
  exit 0;
}

WriteMakefile(%makeparms);

