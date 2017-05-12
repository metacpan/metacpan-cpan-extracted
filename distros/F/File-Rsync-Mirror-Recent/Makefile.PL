use strict;
use warnings;
use ExtUtils::MakeMaker;
$ExtUtils::MakeMaker::VERSION =~ s/_//g;
my @sign = (MM->can("signature_target") ? (SIGN => 1) : ());
my $version_diff = 0; # we'll have to die if this becomes true
my $version_from = 'lib/File/Rsync/Mirror/Recent.pm';
my $version = MM->parse_version($version_from);
if ($ARGV[0]){
    if ($ARGV[0] eq "--setversion") {
        die "Your perl is a bit dated[$]].\nDo not make a release with it\n" if $] < 5.008;
        die "Your MakeMaker is a bit dated[$ExtUtils::MakeMaker::VERSION].\nDo not make a release with it\n"
            if $ExtUtils::MakeMaker::VERSION < 6.48;
        local $ENV{LANG} = "C";
        my $dirty = `git status --porcelain --untracked-files=no`;
        die "Not everything checked in or out?\n====\n$dirty====\n" if $dirty;
        use lib "lib";
        eval {  require $version_from; }; die $@ if $@;
        my $makefile = "Makefile";
        unless (-f $makefile) {
            $makefile = "Makefile.old";
        }
        unless (-f $makefile) {
            die "no Makefile and no Makefile.old found";
        }
        open my $fh, "make -f $makefile the-release-name|" or die "Could not fork: $!";
        local $/;
        my ($have_version) = <$fh> =~ /^version\s+([\d\._]+)/m;
        close $fh or die "Could not close: $!";
        my ($namespace) = $version_from;
        $namespace =~ s|^lib/(.+)\.pm$|$1|;
        $namespace =~ s|/|::|g;
        eval qq{ if (\$$namespace\::VERSION != \$version) {
        warn "Not equal: $namespace\\::VERSION[\$$namespace\::VERSION] MM generated version[\$version]";
        \$version_diff = 1;
    }};
    } elsif ($ARGV[0] eq "--trial") {
        die "FIXME: --trial does not seem to work";
        $version .= "-TRIAL";
    }
}
# $version .= "-TRIAL";

my $provides = {
                "File::Rsync::Mirror::Recent" =>
                {
                 version => $version,
                 file => $version_from,
                }
               };
for my $m (qw(Recentfile Recentfile::Done Recentfile::FakeBigFloat )) {
    my $fullm = "File::Rsync::Mirror::$m";
    my $file = $fullm;
    $file =~ s/::/\//g;
    $file = "lib/$file.pm";
    my $v = MM->parse_version($file);
    $provides->{$fullm} = {
                           version => $v,
                           file => $file,
                          };
}

my $preferzip = "bzip2"; # bzip2 | gzip
WriteMakefile
    (
     NAME                => 'File::Rsync::Mirror::Recent',
     VERSION             => $version,
     AUTHOR              => 'Andreas König <andreas.koenig.7os6VVqR@franz.ak.mind.de>',
     PL_FILES            => {},
     PREREQ_PM =>
     {
      # 'Data::Serializer' => 0.46, # restricted to YAML without it
      'Data::Float'      => 0,
      'Data::Serializer' => 0,
      'ExtUtils::MakeMaker' => 6.48,
      'File::Basename'   => 0,
      'File::Find::Rule' => 0,
      'File::Path'       => 0,
      'File::Rsync'      => 0,
      'File::Spec'       => 0,
      'File::Temp'       => '0.21', # removes bogus test on parent directory
      'JSON'             => '2',
      'List::MoreUtils'  => 0,
      'List::Pairwise'   => 0,
      'Pod::Usage'       => '1.61', # 1.16 from perl-5.8.1 failed, 1.61 is
                                    # the oldest working on CPAN now
      'Scalar::Util'     => 0,
      'Test::More'       => 0,
      'Time::HiRes'      => 0,
      'YAML::Syck'       => 0,
      'accessors'        => 0,
      'version'          => 0,
     },
     EXE_FILES    => [
                      grep { !/~/ } glob("bin/rrr bin/rrr-*")
                     ],
     dist => {
              DIST_DEFAULT => join(" ", # note: order matters!
                                   "verify-changes-date",
                                   "verify-changes-version",
                                   "Makefile",
                                   "META.yml",
                                   "setversion",
                                   "all",
                                   "tardist",
                                   "memo-howto-release",
                                  ),
              $preferzip eq "bzip2" ?
              (COMPRESS => 'bzip2 -9f',
               SUFFIX => ".bz2") :
              (COMPRESS => 'gzip -9f',
               SUFFIX => ".gz"),
             },
     META_MERGE => {
                    # write: git push git+ssh://repo.or.cz/srv/git/rersyncrecent.git master
                    resources => {
                                  repository => "git://repo.or.cz/rersyncrecent.git",
                                 },
                    provides => $provides,
                   },
     MIN_PERL_VERSION => '5.006',
     @sign,
     clean               => { FILES => 'File-Rsync-Mirror-Recent-*' },
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
    $ret =~ s|cpansign|\$(PERL) \`dirname \$(PERL)\`/cpansign|g;
    return $ret;
}
sub postamble {
  my @m;
  push @m, q{
Makefile: }.$version_from.q{

META.yml: metafile
	$(CP) $(DISTVNAME)/META.yml  ./META.yml

setversion:
	$(PERL) Makefile.PL --setversion

verify-changes-date:
	@$(PERL) -ne 'BEGIN{my@t=(localtime)[5,4,3];$$t[0]+=1900;$$t[1]++;$$t=sprintf"%04d-%02d-%02d",@t}' \
		-e '$$ok++,exit if /^$$t\s/; END{die "Alert: did not find <$$t> in Changes file" unless $$ok}' Changes

verify-changes-version:
	@$(PERL) -ne '$$ok++,exit if /\b$(VERSION)\b/; END{die "Alert: did not find <$(VERSION)> in Changes file" unless $$ok}' Changes

verify-no-subdir:
	@$(PERL) -e 'my$$s=join",",grep{!/^($(OKDIRS))\z/x&&-d($$_)}glob"*";' \
		-e 'die"unexpected dir:$$s"if$$s'

the-release-name :
	$(NOECHO) $(ECHO) 'version ' $(VERSION)
	$(NOECHO) $(ECHO) 'release-name ' $(DISTVNAME).tar$(SUFFIX)

memo-howto-release:
	$(NOECHO) $(ECHO) 'after successful make dist and upload do not forget to'
	$(NOECHO) $(ECHO) ' make tag'
	$(NOECHO) $(ECHO) ' git push --tags'
	$(NOECHO) $(ECHO) 'before writing Changes do not forget to'
	$(NOECHO) $(ECHO) ' git --no-pager log --no-merges --pretty=format:" %x20%x20 - %s (%an)" | less'

tag ::
	git tag -m 'This is $(VERSION)' "$(VERSION)"

sign:
	$(PERL) `dirname $(PERL)`/cpansign -s

test-server-run:
	$(PERL) bin/rrr-init --force t/testserver
	$(PERL) bin/rrr-server t/testserver/RECENT-1h.yaml &
	$(PERL) bin/rrr-init --force t/testserver
};
  join "", @m;
}

sub dist_test {
  return q{
# if we depend on $(DISTVNAME).tar$(SUFFIX), then the rest of the
# Makefile breaks our intent to NOT remake dist
disttest :
	rm -rf $(DISTVNAME)
	tar xvjf $(DISTVNAME).tar$(SUFFIX)
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
