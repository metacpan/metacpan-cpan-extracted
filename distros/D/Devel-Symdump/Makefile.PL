#!/usr/bin/perl -w -*- mode: cperl -*-
use strict;
use vars qw( $VERSION );
use ExtUtils::MakeMaker qw(:DEFAULT);

my $version_diff = 0; # we'll have to die if this becomes true
my $is_trial = 0;
my $version;
{
  local $^W;
  $ExtUtils::MakeMaker::VERSION = eval $ExtUtils::MakeMaker::VERSION;
}

print "Require Devel::Symdump from the local tarball.\n";

BEGIN {
    local @INC = @INC;
    unshift @INC, './lib';
    require Devel::Symdump;
}

$version = $Devel::Symdump::VERSION;
if ($is_trial && $version !~ /_/) {
    $version .= "-TRIAL";
}
{
  my $version_set_manually = 1; # not by SVN
  if ($ARGV[0] && $ARGV[0] eq "--setversion") {
    die "Your perl is a bit dated[$]].\nDo not make a release with it\n" if $] < 5.008;
    die "Your MakeMaker is a bit dated[$ExtUtils::MakeMaker::VERSION].\nDo not make a release with it\n"
        if $ExtUtils::MakeMaker::VERSION < 6.4502;
    die "Your MakeMaker doesn't do the sign woodoo" unless
        MM->can("signature_target");
    shift @ARGV;
    my $st;
    local $ENV{LANG} = "C";
    my $dirty = `git status --porcelain --untracked-files=no`;
    die "Not everything checked in or out?\n====\n$dirty====\n" if $dirty;

    if ($version_set_manually) {
      # we must control that the VERSION in this .pm is the same as in the Makefile
      open my $fh, "make the-release-name|" or die;
      my $have_version;
      while (<$fh>) {
        next unless /^version\s+([\d\._]+(?:-TRIAL)?)/;
        $have_version = $1;
      }
      die "could not determine current version from Makefile" unless $have_version;
      eval q{
      no warnings "numeric";
      my $dsv = $Devel::Symdump::VERSION;
      if ($dsv != $have_version) {
        warn "Not equal: D:S:VERSION[$dsv] Makefile version[$have_version]";
        $version_diff = 1;
      }
};
      die $@ if $@;
    }
    exit unless $version_diff;
  }
}

my $prereq_pm = {
                 'Test::More' => 0,
                };
my @interesting_modules =
    (
     'Compress::Zlib', # only for t/glob_to_local_typeglob.t
    );
for my $interesting_module (@interesting_modules) {
    my $have = eval "require $interesting_module; 1;";
    if ($have) {
        $prereq_pm->{$interesting_module} ||= 0;
    }
}
my @sign = (MM->can("signature_target") ? (SIGN => 1) : ());
WriteMakefile(
	      NAME => "Devel::Symdump",
	      DISTNAME => "Devel-Symdump",
	      VERSION => $version,
              PREREQ_PM    => $prereq_pm,
              ($ExtUtils::MakeMaker::VERSION >= 6.3002 ?
               (LICENSE      => "perl") : (),
              ),
              ($ExtUtils::MakeMaker::VERSION >= 6.48 ?
               (MIN_PERL_VERSION => '5.004') : (),
              ),
              clean => {
                        FILES => '*/*/*~',
                       },
              @sign,
              ($] >= 5.005 ?
               (
                ABSTRACT_FROM  => 'lib/Devel/Symdump.pm', # retrieve abstract from module
                AUTHOR         => 'Andreas Koenig <andreas.koenig.gmwojprw@franz.ak.mind.de>') : (),
              ),
              dist => {
                       DIST_DEFAULT => join(" ", # note: order matters!
                                            "verify-no-subdir",
                                            "verify-changes-date",
                                            "verify-changes-version",
                                            "Makefile",
                                            "setversion",
                                            "README",
                                            "all",
                                            "tardist",
                                           ),
                       COMPRESS => 'gzip -9',
                      },
              # I took it from RT-CPAN ticket 30098:
              ($ExtUtils::MakeMaker::VERSION >= 6.4502 ?
               (META_ADD => {
                             resources => {
                                 repository => "git://github.com/andk/devel-symdump.git",
                             },
                             keywords => ['symbol table inspection'],
                            }) : ()),
             );

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
    $ret =~ s|cpansign|\`dirname \$(PERL)\`/cpansign|g;
    return $ret;
}
sub macro {
    q{
LC_ALL_noexport=en_GB.utf8

YAML_MODULE=YAML::Syck
}
}

sub postamble {
  q{
# the subdirs on MY OWN BOX are allowed here (only used for make dist!)
OKDIRS=benchmark|bin|blib|lib|scripts|t

verify-no-subdir:
	@$(PERL) -e 'my$$s=join",",grep{!/^($(OKDIRS))\z/x&&-d($$_)}glob"*";' \
		-e 'die"unexpected dir:$$s"if$$s'

verify-changes-date:
	@$(PERL) -ne 'BEGIN{my@t=(localtime)[5,4,3];$$t[0]+=1900;$$t[1]++;$$t=sprintf"%04d-%02d-%02d",@t}' \
		-e '$$ok++,exit if /^$$t\s/; END{die "Alert: did not find <$$t> in Changes file" unless $$ok}' Changes

verify-changes-version:
	@$(PERL) -ne '$$ok++,exit if /\b$(VERSION)\b/; END{die "Alert: did not find <$(VERSION)> in Changes file" unless $$ok}' Changes

setversion:
	$(PERL) Makefile.PL --setversion

README: lib/Devel/Symdump.pm Makefile
	-test -r $@ && chmod +w $@
	-$(PERL) -MPod::Text -e 'Pod::Text->new->parse_from_file(\*ARGV)' lib/Devel/Symdump.pm > $@

the-release-name :
	$(NOECHO) $(ECHO) 'version ' $(VERSION)
	$(NOECHO) $(ECHO) 'release-name ' $(DISTVNAME).tar$(SUFFIX)

release :: disttest
	git tag -m 'This is $(VERSION)' "$(VERSION)"
	ls -l $(DISTVNAME).tar$(SUFFIX)
	rm -rf $(DISTVNAME)
	$(NOECHO) $(ECHO) '#### Suggested next steps:'
	$(NOECHO) $(ECHO) '  git push --tags origin master'

sign:
	cpansign -s

howto-release:
	@$(ECHO) manually set version in Symdump.pm, edit ChangeLog
	@$(ECHO) make ci dist \&\& make release
}
}

sub dist_ci {
  return qq{ci :
	svn ci
};
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
	$(CP) $(DISTVNAME)/META.json  ./META.json
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
