use strict;
use warnings;
use ExtUtils::MakeMaker;
$ExtUtils::MakeMaker::VERSION =~ s/_//g;
my @sign = (MM->can("signature_target") ? (SIGN => 1) : ());
my $version_diff = 0; # we'll have to die if this becomes true
$::version_from = 'lib/Devel/SawAmpersand.pm';
my $mmgenereatedversionfrom = MM->parse_version($::version_from);
if ($ARGV[0] && $ARGV[0] eq "--setversion") {
    die "Your perl is a bit dated[$]].\nDo not make a release with it\n" if $] < 5.008;
    warn "Your MakeMaker is a bit dated[$ExtUtils::MakeMaker::VERSION].\nYou should get a new one\n"
        if $ExtUtils::MakeMaker::VERSION < 6.4502;
    # not for XS modules: eval {  require $::version_from; }; die $@ if $@;
    my $makefile = "Makefile";
    unless (-f $makefile) {
        $makefile = "Makefile.old";
    }
    unless (-f $makefile) {
        die "no Makefile and no Makefile.old found";
    }
    my $dirty = `git status --porcelain --untracked-files=no`;
    die "Not everything checked in or out?\n====\n$dirty====\n" if $dirty;
    # open my $fh, "make -f $makefile the-release-name|" or die "Could not fork: $!";
    # local $/;
    # my ($have_version) = <$fh> =~ /^version\s+([\d\._]+)/m;
    # close $fh or die "Could not close: $!";
    # my ($namespace) = $::version_from;
    # $namespace =~ s|^lib/(.+)\.pm$|$1|;
    # $namespace =~ s|/|::|g;
    # eval qq{ if (\$$namespace\::VERSION != \$have_version) {
    #     warn "Not equal: Devel::SawAmpersand::VERSION[\$$namespace\::VERSION] Makefile version[\$have_version]";
    #     \$version_diff = 1;
    # }};
    # eval qq{ if (\$$namespace\::VERSION != \$mmgenereatedversionfrom) {
    #     warn "Not equal: Devel::SawAmpersand::VERSION[\$$namespace\::VERSION] MM generated version[\$mmgenereatedversionfrom]";
    #     \$version_diff = 1;
    # }};
}

my %indirect_dependencies =
    (
     'CPAN::Meta::Converter' => '2.110440',
    );
my %interesting_modules;
for my $m (qw(
    Parse::CPAN::Meta
    )){
    if (eval "require $m; 1") {
        $interesting_modules{$m} = $m->VERSION;
    }
}

my $prereq_pm =
    {
     'Test::More'                  => 0,
    };

# intentionally avoiding any size comparisons, trying to catch
# interesting cases that happen during WriteMakefile, like
# http://www.cpantesters.org/cpan/report/e1942da8-5fcc-11e0-994f-224f8e2a057c
while (my($k,$v) = each %interesting_modules) {
    $prereq_pm->{$k} ||= $v;
}
while (my($k,$v) = each %indirect_dependencies) {
    $prereq_pm->{$k} ||= $v;
}

eval { WriteMakefile
    (
     'NAME' => 'Devel::SawAmpersand',
     'VERSION_FROM' => $::version_from,
     'PREREQ_PM' => $prereq_pm,
     'INSTALLDIRS' => 'site',
     LICENSE => "perl",
     ABSTRACT => "parse reports to www.cpantesters.org from various sources",
     'PL_FILES' => {},
     'LIBS'   => [''],   # e.g., '-lm' 
     'DEFINE' => '',     # e.g., '-DHAVE_SOMETHING' 
     'INC'    => '',     # e.g., '-I/usr/include/other' 
     dist => {
              DIST_DEFAULT => join(" ", # note: order matters!
                                   "verify-changes-date",
                                   "Makefile",
                                   "META.yml",
                                   "setversion",
                                   "all",
                                   "tardist",
                                  ),
              COMPRESS => 'gzip -9f',
              SUFFIX => ".gz",
             },
     ($ExtUtils::MakeMaker::VERSION >= 6.4502 ?
      (META_ADD => {
                    provides => { "Devel::SawAmpersand" => { version => $mmgenereatedversionfrom, file => $::version_from }},
                   }) : ()),
     @sign,
    );
   };
if (my $err = $@) {
    while (my($k,$v) = each %interesting_modules) {
        warn "Found $k version $v\n";
    }
    die $err;
}

if ($version_diff){
  die "
==> I had to update some \$VERSIONs <==
==> Your Makefile has been rebuilt. <==
==> Please rerun the make command.  <==
";
}

package MY;
sub distsignature {
    my($self) = shift;
    my $ret = $self->SUPER::distsignature_target(@_);
    $ret =~ s|cpansign|\$(PERL) \`dirname \$(PERL)\`/cpansign|g;
    return $ret;
}
sub postamble {
  my @m;
  push @m, q{
# the subdirs on MY OWN BOX are allowed here (only used for make dist!)
OKDIRS=DIST|bin|blib|cover_db\
       |lib|t

Makefile: }.$::version_from.q{

META.yml: metafile
	$(CP) $(DISTVNAME)/META.yml  ./META.yml

setversion:
	$(PERL) Makefile.PL --setversion

verify-changes-date:
	@$(PERL) -ne 'BEGIN{my@t=(localtime)[5,4,3];$$t[0]+=1900;$$t[1]++;$$t=sprintf"%04d-%02d-%02d",@t}' \
		-e '$$ok++,exit if /^$$t\s/; END{die "Alert: did not find <$$t> in Changes file" unless $$ok}' Changes

verify-no-subdir:
	@$(PERL) -e 'my$$s=join",",grep{!/^($(OKDIRS))\z/x&&-d($$_)}glob"*";' \
		-e 'die"unexpected dir:$$s"if$$s'

the-release-name :
	$(NOECHO) $(ECHO) 'version ' $(VERSION)
	$(NOECHO) $(ECHO) 'release-name ' $(DISTVNAME).tar$(SUFFIX)

release :: disttest
	git tag -m 'This is $(VERSION)' $(VERSION)
	ls -l $(DISTVNAME).tar$(SUFFIX)
	rm -rf $(DISTVNAME)

sign:
	$(PERL) `dirname $(PERL)`/cpansign -s
};
  join "", @m;
}

sub dist_test {
  return q{
# if we depend on $(DISTVNAME).tar$(SUFFIX), then the rest of the
# Makefile breaks our intent to NOT remake dist
disttest :
	rm -rf $(DISTVNAME)
	tar xvzf $(DISTVNAME).tar$(SUFFIX)
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) test $(PASTHRU)

distdir ::
	touch $(DISTVNAME)/SIGNATURE && $(CP) $(DISTVNAME)/SIGNATURE ./SIGNATURE
	$(CP) $(DISTVNAME)/META.yml  ./META.yml
	$(CP) $(DISTVNAME)/MANIFEST  ./MANIFEST

}
}

sub distdir {
  my $self = shift;
  my $out = $self->SUPER::distdir;
  $out =~ s/distdir :/distdir ::/g;
  return $out;
}

# dist_dir was the name in very old MakeMaker as of 5.005_04
sub dist_dir {
  my $self = shift;
  my $out = $self->SUPER::dist_dir;
  $out =~ s/distdir :/distdir ::/g;
  return $out;
}
