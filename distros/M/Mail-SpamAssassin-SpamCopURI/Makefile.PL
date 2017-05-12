use ExtUtils::MakeMaker;
use strict;
use Mail::SpamAssassin;
use Config;

my $sa_version = $Mail::SpamAssassin::VERSION;
($sa_version == 2.63 or $sa_version == 2.64) or 
  die "*** YOU MUST USE SPAMASSASSIN 2.63 or 2.64 to run this - see INSTALL";



my $CONF_PM = 'Mail/SpamAssassin/Conf.pm';
my $SA_PM = 'Mail/SpamAssassin.pm';
my $PERMSG_PM = 'Mail/SpamAssassin/PerMsgStatus.pm';

my %install_targets = (
  installsitelib   => 'site',
  installvendorlib => 'vendor',
  installprivlib   => 'perl',
);

my $target;

(my $sa_path = $INC{$SA_PM}) =~ s#/$SA_PM$##;

# try to figure out where SA is installed
foreach my $k (keys %install_targets) {

  if ($Config{$k} eq $sa_path) {
    print "# SAPATH $sa_path\n";
    print "# $k $Config{$k}\n";
    $target = $install_targets{$k};
  }
}

my @INSTALLDIRS = ();

if ($target) {

  if ($INC{$CONF_PM} eq "$sa_path/$CONF_PM" &&
      $INC{$PERMSG_PM} eq "$sa_path/$PERMSG_PM") {
    @INSTALLDIRS = ('INSTALLDIRS', $target);

  } else {

    warn "$CONF_PM / $PERMSG_PM seem to be installed differently than Mail::SpamAssassin";
    warn "found $SA_PM in $sa_path";
    warn "found $CONF_PM in $INC{$CONF_PM}";
    warn "found $PERMSG_PM in $INC{$PERMSG_PM}";
  }

}

print "# @INSTALLDIRS\n";



unlink("lib/$PERMSG_PM");

print "# linking plib/$sa_version/$PERMSG_PM -> lib/$PERMSG_PM\n";

link("plib/$sa_version/$PERMSG_PM",
     "lib/$PERMSG_PM") or die "failed to link appropiate PerMsgStatus.pm: $!";

WriteMakefile(
    'NAME'          => 'Mail::SpamAssassin::SpamCopURI',
    'VERSION_FROM'  => 'lib/Mail/SpamAssassin/SpamCopURI.pm', # finds $VERSION
    'PREREQ_PM'     => { 'Mail::SpamAssassin' => 2.63, URI => 1.28, 'Net::DNS' => 0  }, 
    @INSTALLDIRS
    # e.g., Module::Name => 1.1
);

sub MY::postamble {
  return <<'MAKE_FRAG';
cover: 
	HARNESS_PERL_SWITCHES=-MDevel::Cover=-ignore,Storable make test

MAKE_FRAG
}

