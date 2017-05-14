#-*-perl-*-

require 5.00405; # probably just need Test?

use ExtUtils::MakeMaker;

warn "
       Please read ./INSTALL for hints on installing.

       Please read ./UPGRADE if you are upgrading.

";

use Symbol;
my $fh = gensym;
if (open $fh, ">Conf.pm") {
  print $fh "0\n";
  close $fh;
}

die "Makefile.PL must be run from the current directory.\n"
    if !-e './envy.IN';
if (-d "./blib") {
    print "rm -rf ./blib\n";
    system "rm -rf ./blib";
}

# set up example .env areas
unlink "./example/area1/etc/envy/area2.env";
symlink "../../../../example/area2/etc/envy/area2.env",
    "./example/area1/etc/envy/area2.env" or warn $!;
unlink "./example/area2/etc/envy/area1.env";
symlink "../../../../example/area1/etc/envy/area1.env",
    "./example/area2/etc/envy/area1.env" or warn $!;

# option to disable @dot?
my @dot = qw(
  dot.profile profile.part2 dot.shrc
  dot.cshrc dot.login login.part2
  bash.inputrc dot.dtprofile
) if 1;

my @prefix = (PREFIX => $ENV{PERL5PREFIX})
    if exists $ENV{PERL5PREFIX};

my @test = ('test.env' => '$(INST_ETC)/envy/test.env')
    if exists $ENV{PERL5PREFIX};

WriteMakefile(@prefix,
	      NAME => 'Envy',
	      PREREQ_PM => { Test => 1 },
	      EXE_FILES => [qw(envy.pl wrapper launche envied)],
	      MAN1PODS => {}, # MANPATH might be unset! :-)
	      MAN3PODS => {},
	      PL_FILES => {'set_defaults.PL' => join(' ',values %$subst_files) },
	      VERSION_FROM => './VERSION',
	      PM => {
		     'Conf.pm' => '$(INST_LIBDIR)/Envy/Conf.pm',
		     'DefaultConf.pm' => '$(INST_LIBDIR)/Envy/DefaultConf.pm',
		     'Load.pm' => '$(INST_LIBDIR)/Envy/Load.pm',
		     'Import.pm' => '$(INST_LIBDIR)/Envy/Import.pm',
		     'UI.pm' => '$(INST_LIBDIR)/Envy/UI.pm',
		     'DB.pm' => '$(INST_LIBDIR)/Envy/DB.pm',
		     @test,
		     (map { ("etc/login/$_", '$(INST_ETC)/login/'.$_) } @dot),
		    },
	      'macro' => {
			  INST_ETC=> 'blib/etc',
			  INSTALLPRIVETC=> '$(PREFIX)/etc',
			 },
	      );

# hack ETC install
sub MY::postamble {
    require "./subst.pm";
    my ($self) = @_;
    my $str='';

    while (my($k,$v)=each %$subst_files) {
	$str .= "
$v :: $k set_defaults.PL Conf.pm DefaultConf.pm ".'
	$(PERL) set_defaults.PL'."\n";
    }
    $str .= "
clean ::
	echo 0 > Conf.pm
	rm -f ".join(' ', values %$subst_files)."\n";
    
    $str .= q{

set_defaults.PL :: Conf.pm DefaultConf.pm

pure_site_install ::
	}.$self->{NOECHO}.'$(MOD_INSTALL) \
		read '.$self->catfile('$(SITEARCHEXP)','auto','$(FULLEXT)','.packlist').' \
		write '.$self->catfile('$(INSTALLSITEARCH)','auto','$(FULLEXT)','.packlist').' \
		$(INST_ETC) $(INSTALLPRIVETC)
';
    $str .= '

diff :: all
	'.$self->{NOECHO}.'$(PERL) ./rundiff \
		$(INST_SCRIPT) $(INSTALLSCRIPT) \
		$(INST_LIB) $(INSTALLSITELIB) \
		$(INST_ETC) $(INSTALLPRIVETC)

';

    $str;
}
