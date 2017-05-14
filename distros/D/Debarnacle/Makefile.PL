# $Id: Makefile.PL,v 1.5 2002/05/11 06:34:14 itz Exp $

use ExtUtils::MakeMaker;
use File::Basename;
use FileHandle; 
use Config;

# this is here because otherwise Perl includes Emacs backup files (ie. *~)
our %pm_hash = ();
foreach my $pm (glob "lib/Debian/Debarnacle/*.pm") {
    my $base = basename $pm;
    $pm_hash{$pm} = '$(INST_LIBDIR)/Debian/Debarnacle/' . $base;
}

WriteMakefile(

              NAME                   => 'Debarnacle',
              VERSION_FROM           => 'debarnacle',
              PREREQ_PM              => {
                  'DB_File' => '1.75',
                  'Fcntl' => '1.03',
                  'FileHandle' => '2.00',
                  'Cwd' => '2.04',
                  'Getopt::Std' => '1.02',
                  'File::Glob' => '0.991',
              },
              PM                     => \%pm_hash,
              EXE_FILES		     => ['debarnacle'],
              MAN1PODS               => {'debarnacle.pod' => '$(INST_MAN1DIR)/debarnacle.1'},
              MAN3PODS               => {},
              realclean             => {FILES => '$(shell find . -name "*~")' },
              );


# omit the stupid Makefile -> Makefile.old rule

our $fh_mm = FileHandle->new("<Makefile");
defined $fh_mm or die "can't open Makefile: $!";
our $fh_mm_tmp = FileHandle->new(">Makefile.tmp");
defined $fh_mm_tmp or die "can't write to Makefile.tmp: $!";
our $mm_line = $fh_mm->getline();
while ($mm_line !~ /MakeMaker makefile section/ ) {
    $fh_mm_tmp->print($mm_line);
    $mm_line = $fh_mm->getline();
}
while ($mm_line !~ /^\tfalse\s*$/ ) { 
    $mm_line = $fh_mm->getline();
}
$mm_line = $fh_mm->getline();
while ($mm_line) {
    $fh_mm_tmp->print($mm_line);
    $mm_line = $fh_mm->getline();
}

our $sysconfdir = $ENV{'sysconfdir'} || '/etc';

our $new_rulez = <<"EOF";

# This portion copied verbatim from Makefile.PL
Makefile : Makefile.PL \$(CONFIGDEP)
	\$(PERL) \"-I\$(PERL_ARCHLIB)\" \"-I\$(PERL_LIB)\"  Makefile.PL 

sysconfdir=$sysconfdir
pkgconfdir=\$(sysconfdir)/debarnacle
plugindir=\$(pkgconfdir)/plugin.d

pure_site_install pure_vendor_install ::
	$Config::Config{mkdir} -p \$(sysconfdir)
	$Config::Config{mkdir} -p \$(pkgconfdir)
	$Config::Config{mkdir} -p \$(plugindir)
	$Config::Config{cp} etc/prune \$(pkgconfdir)
	$Config::Config{cp} etc/globs \$(pkgconfdir)

pure_all ::
	$Config::Config{sed} -e 's://etc//:\$(sysconfdir):' \$(INST_SCRIPT)/debarnacle >\$(INST_SCRIPT)/debarnacle.tmp
	$Config::Config{cp} \$(INST_SCRIPT)/debarnacle.tmp \$(INST_SCRIPT)/debarnacle
	$Config::Config{rm} \$(INST_SCRIPT)/debarnacle.tmp

EOF

$fh_mm_tmp->print($new_rulez);
$fh_mm->close();
$fh_mm_tmp->close();

rename("Makefile.tmp", "Makefile") or die "Can't rename Makefile.tmp to Makefile: $!";
