# MyMakeMakerExtra.pm -- my shared MakeMaker extras

# Copyright 2009, 2010, 2011 Kevin Ryde

# MyMakeMakerExtras.pm is shared by several distributions.
#
# MyMakeMakerExtras.pm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# MyMakeMakerExtras.pm is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

package MyMakeMakerExtras;
use strict;

# uncomment this to run the ### lines
#use Smart::Comments;

my %my_options;

sub WriteMakefile {
  my %opts = @_;

  if (exists $opts{'META_MERGE'}) {
    # cf. ExtUtils::MM_Any::metafile_data() default ['t','inc']
    foreach ('xt', 'devel', 'examples', 'junk', 'maybe') {
      my $dir = $_;
      if (-d $dir) {
        push @{$opts{'META_MERGE'}->{'no_index'}->{'directory'}}, $dir;
      }
    }

    $opts{'META_MERGE'}->{'resources'}->{'license'}
      ||= 'http://www.gnu.org/licenses/gpl.html';
    _meta_merge_shared_tests (\%opts);
    _meta_merge_shared_devel (\%opts);
  }

  if (! defined $opts{'clean'}->{'FILES'}) {
    $opts{'clean'}->{'FILES'} = '';
  }
  $opts{'clean'}->{'FILES'} .= ' temp-lintian $(MY_HTML_FILES)';

  if (! defined $opts{'realclean'}->{'FILES'}) {
    $opts{'realclean'}->{'FILES'} = '';
  }
  $opts{'realclean'}->{'FILES'} .= ' TAGS';

  if (! defined &MY::postamble) {
    *MY::postamble = \&MyMakeMakerExtras::postamble;
  }

  foreach ('MyMakeMakerExtras_Pod_Coverage',
           'MyMakeMakerExtras_LINT_FILES',
           'MY_NO_HTML',
           'MY_EXTRA_FILE_PART_OF') {
    $my_options{$_} = delete $opts{$_};
  }

  ### chain to WriteMakefile()
  ### %opts
  ExtUtils::MakeMaker::WriteMakefile (%opts);
  ### done
}

sub strip_comments {
  my ($str) = @_;
  $str =~ s/^\s*#.*\n//mg;
  $str
}

#------------------------------------------------------------------------------
# META_MERGE

sub _meta_merge_shared_tests {
  my ($opts) = @_;
  if (-e 'xt/0-Test-Pod.t') {
    _meta_merge_req_add (_meta_merge_maximum_tests($opts),
                         'Test::Pod' => '1.00');
  }
  if (-e 'xt/0-Test-DistManifest.t') {
    _meta_merge_req_add (_meta_merge_maximum_tests($opts),
                         'Test::DistManifest' => 0);
  }
  if (-e 'xt/0-Test-Synopsis.t') {
    _meta_merge_req_add (_meta_merge_maximum_tests($opts),
                         'Test::Synopsis' => 0);
  }
  if (-e 'xt/0-Test-YAML-Meta.t') {
    _meta_merge_req_add (_meta_merge_maximum_tests($opts),
                         'Test::YAML::Meta' => '0.15');
  }
  if (-e 'xt/0-META-read.t') {
    if (_min_perl_version_lt ($opts, 5.00307)) {
      _meta_merge_req_add (_meta_merge_maximum_tests($opts),
                           'FindBin' => 0);
    }
    if (_min_perl_version_lt ($opts, 5.00405)) {
      _meta_merge_req_add (_meta_merge_maximum_tests($opts),
                           'File::Spec' => 0);
    }
    _meta_merge_req_add (_meta_merge_maximum_tests($opts),
                         'YAML'              => 0,
                         'YAML::Syck'        => 0,
                         'YAML::Tiny'        => 0,
                         'YAML::XS'          => 0,
                         'Parse::CPAN::Meta' => 0);
  }
}
# return hashref of "maximum_tests" under $opts, created if necessary
sub _meta_merge_maximum_tests {
  my ($opts) = @_;
  $opts->{'META_MERGE'}->{'optional_features'}->{'maximum_tests'} ||=
    { description => 'Have "make test" do as much as possible.',
      requires => { },
    };
  return $opts->{'META_MERGE'}->{'optional_features'}->{'maximum_tests'}->{'requires'};
}

sub _meta_merge_shared_devel {
  my ($opts) = @_;
  _meta_merge_req_add (_meta_merge_maximum_devel($opts),
                       # the "make unused" target below
                       'warnings::unused' => 0);
  _meta_merge_req_add (_meta_merge_maximum_devel($opts),
                       # used a lot
                       'Smart::Comments' => 0);
  if (-e 'inc/my_pod2html') {
    if (_min_perl_version_lt ($opts, 5.009003)) {
      _meta_merge_req_add (_meta_merge_maximum_devel($opts),
                           'Pod::Simple::HTML' => 0);
    }
  }
}
# return hashref of "maximum_devel" under $opts, created if necessary
sub _meta_merge_maximum_devel {
  my ($opts) = @_;
  $opts->{'META_MERGE'}->{'optional_features'}->{'maximum_devel'} ||=
    { description => 'Stuff used variously for development.',
      requires => { },
    };
  return $opts->{'META_MERGE'}->{'optional_features'}->{'maximum_devel'}->{'requires'};
}

# return true if MIN_PERL_VERSION in $opts is < $ver, or no MIN_PERL_VERSION
sub _min_perl_version_lt {
  my ($opts, $perlver) = @_;
  return (! defined $opts->{'MIN_PERL_VERSION'}
          || $opts->{'MIN_PERL_VERSION'} < $perlver);
}

sub _meta_merge_req_add {
  my $req = shift;
  ### MyMakeMakerExtras META_MERGE: @_
  while (@_) {
    my $module = shift;
    my $version = shift;
    if (defined $req->{$module}) {
      if ($req->{$module} > $version) {
        $version = $req->{$module};
      }
    }
    $req->{$module} = $version;
  }
}

#------------------------------------------------------------------------------
# postamble()

sub postamble {
  my ($makemaker) = @_;
  ### MyMakeMakerExtras postamble(): $makemaker

  my $post = $my_options{'postamble_docs'};

  my @exefiles_html;
  my @pmfiles_html;
  unless ($my_options{'MY_NO_HTML'}) {
    $post .= <<'HERE';

#------------------------------------------------------------------------------
# docs stuff -- from inc/MyMakeMakerExtras.pm

MY_POD2HTML = $(PERL) inc/my_pod2html

HERE
    my $munghtml_extra = $makemaker->{'MY_MUNGHTML_EXTRA'};
    if ($munghtml_extra) {
      $post =~ s/apt-file!'/apt-file!'\\
$munghtml_extra/;
    }

    my @pmfiles = keys %{$makemaker->{'PM'}};
    @pmfiles = grep {!/\.mo$/} @pmfiles; # not LocaleData .mo files
    my @exefiles = (defined $makemaker->{'EXE_FILES'}
                    ? @{$makemaker->{'EXE_FILES'}}
                    : ());
    my %html_files;

    my $html_rule = sub {
      my ($pm) = @_;
      my $fullhtml = $pm;
      $fullhtml =~ s{lib/}{};     # remove lib/
      $fullhtml =~ s{\.p[ml]$}{}; # remove .pm or .pl
      $fullhtml .= '.html';
      my $parthtml = $fullhtml;

      $fullhtml =~ s{/}{-}g;      # so Foo-Bar.html
      unless ($html_files{$fullhtml}++) {
        $post .= <<"HERE";
$fullhtml: $pm Makefile
	\$(MY_POD2HTML) $pm >$fullhtml
HERE
      }
      $parthtml =~ s{.*/}{};      # remove any directory part, just Bar.html
      unless ($html_files{$parthtml}++) {
        $post .= <<"HERE";
$parthtml: $pm Makefile
	\$(MY_POD2HTML) $pm >$parthtml
HERE
      }
      return $parthtml;
    };

    foreach (@exefiles) {
      push @exefiles_html, &$html_rule ($_);
    }
    foreach (@pmfiles) {
      push @pmfiles_html, &$html_rule ($_);
    }

    $post .= "MY_HTML_FILES = " . join(' ', keys %html_files) . "\n";
    $post .= <<'HERE';
html: $(MY_HTML_FILES)
HERE
  }

  $post .= <<'HERE';

#------------------------------------------------------------------------------
# development stuff -- from inc/MyMakeMakerExtras.pm

version:
	$(NOECHO)$(ECHO) $(VERSION)

HERE

  my $lint_files = $my_options{'MyMakeMakerExtras_LINT_FILES'};
  if (! defined $lint_files) {
    $lint_files = 'Makefile.PL $(EXE_FILES) $(TO_INST_PM)';
    # would prefer not to lock down the 't' dir existance at ./Makefile.PL
    # time, but it's a bit hard without without GNU make extensions
    if (-d 't') { $lint_files .= ' t/*.t'; }
    if (-d 'xt') { $lint_files .= ' xt/*.t'; }

    my ($dir, $pattern);
    foreach $dir ('t', 'xt', 'examples', 'devel') {
      foreach $pattern ("$dir/*.pl", "$dir/*.pm") {
        my @glob = glob($pattern);
        ### $pattern
        ### @glob
        if (@glob) {
          $lint_files .= " $pattern";
          ### $lint_files
        }
      }
    }
  }

  $post .= "LINT_FILES = $lint_files\n"
    . <<'HERE';
lint:
	perl -MO=Lint $(LINT_FILES)
HERE

  # ------ pc: ------
  $post .= <<'HERE';
pc:
HERE
  # ------ pc: podcoverage ------
  foreach (@{$my_options{'MyMakeMakerExtras_Pod_Coverage'}}) {
    my $class = $_;
    # the "." obscures it from MyExtractUse.pm
    $post .= "\t-\$(PERLRUNINST) -e 'use "."Pod::Coverage package=>$class'\n";
  }
  # ------ pc: podlinkcheck ------
  $post .= <<'HERE';
	-podlinkcheck -I lib `ls $(LINT_FILES) | grep -v '\.bash$$|\.desktop$$\.png$$|\.xpm$$'`
HERE
  # ------ pc: podchecker ------
  # "podchecker -warnings -warnings" too much reporting every < and >
  $post .= <<'HERE';
	-podchecker `ls $(LINT_FILES) | grep -v '\.bash$$|\.desktop$$\.png$$|\.xpm$$'`
	perlcritic $(LINT_FILES)
HERE
  # ------ cpants_lint ------
  $post .= <<'HERE';
kw:
	make $(DISTVNAME).tar.gz
	-cpants_lint $(DISTVNAME).tar.gz
HERE

  # ------ unused ------
  $post .= <<'HERE';
unused:
	for i in $(LINT_FILES); do perl -Mwarnings::unused -I lib -c $$i; done

HERE

  # ------ myman ------
  $post .= <<'HERE';
myman:
	-mv MANIFEST MANIFEST.old
	touch SIGNATURE
	(make manifest 2>&1; diff -u MANIFEST.old MANIFEST) |less

# find files in the dist with mod times this year, but without this year in
# the copyright line
MY_HIDE=
check-copyright-years:
	year=`date +%Y`; \
	tar tvfz $(DISTVNAME).tar.gz \
	| egrep "$$year-|debian/copyright" \
	| sed 's:^.*$(DISTVNAME)/::' \
	| (result=0; \
	  while read i; do \
	    GREP=grep; \
	    case $$i in \
	      '' | */ \
	      | ppport.h \
	      | debian/changelog | debian/compat | debian/doc-base \
	      | debian/patches/*.diff | debian/source/format \
	      | COPYING | MANIFEST* | SIGNATURE | META.yml \
	      | version.texi | */version.texi \
	      | *utf16* | examples/rs''s2lea''fnode.conf \
	      | */MathI''mage/ln2.gz | */MathI''mage/pi.gz \
	      | *.mo | *.locatedb* | t/samp.* \
	      | t/empty.dat | t/*.xpm | t/*.xbm | t/*.jpg | t/*.gif \
	      | t/*.g$(MY_HIDE)d) \
	        continue ;; \
	      *.gz) GREP=zgrep ;; \
	    esac; \
	    if test -e "$(srcdir)/$$i"; then f="$(srcdir)/$$i"; \
	    else f="$$i"; fi; \
	    if ! $$GREP -q "Copyright.*$$year" $$f; then \
	      echo "$$i":"1: this file"; \
	      grep Copyright $$f; \
	      result=1; \
	    fi; \
	  done; \
	  exit $$result)

check-spelling:
	if find . -type f | egrep -v '(Makefile|dist-deb)' | xargs egrep --color=always -nHi '[a]djustement|[g]lpyh|[r]ectanglar|[a]vailabe|[g]rabing|[c]usor|[r]efering|[w]riteable|[n]ineth|\b[o]mmitt?ed|[o]mited|[$$][rd]elf|[r]equrie|[n]oticable|[c]ontinous|[e]xistant|[e]xplict|[a]gument|[d]estionation|\b[t]he the\b|\b[i]n in\b|\b[tw]hen then\b|\b[n]ote sure\b'; \
	then false; else true; fi
HERE

  $post .= "\n";
  $post .= ("MY_EXTRA_FILE_PART_OF = " 
            . ($my_options{'MY_EXTRA_FILE_PART_OF'}||'')
            . "\n");
  $post .= <<'HERE';
check-file-part-of:
	if grep --text 'This file is'' part of ' -r . | egrep -iv '$(DISTNAME)$(MY_EXTRA_FILE_PART_OF)'; then false; else true; fi

diff-prev:
	rm -rf diff.tmp
	mkdir diff.tmp
	cd diff.tmp \
	&& tar xfz ../$(DISTNAME)-`expr $(VERSION) - 1`.tar.gz \
	&& tar xfz ../$(DISTNAME)-$(VERSION).tar.gz
	-cd diff.tmp; diff -ur $(DISTNAME)-`expr $(VERSION) - 1` \
	                       $(DISTNAME)-$(VERSION) >tree.diff
	-$${PAGER:-less} diff.tmp/tree.diff
	rm -rf diff.tmp

# in a hash-style multi-const this "use constant" pattern only picks up the
# first constant, unfortunately, but it's better than nothing
TAG_FILES = $(TO_INST_PM)
TAGS: $(TAG_FILES)
	etags \
	  --regex='{perl}/use[ \t]+constant\(::defer\)?[ \t]+\({[ \t]*\)?\([A-Za-z_][^ \t=,;]+\)/\3/' \
	  $(TAG_FILES)

HERE

  my $have_XS = scalar %{$makemaker->{'XS'}};
  my $arch = ($have_XS
              ? `dpkg --print-architecture`
              : 'all');
  chomp($arch);
  my $debname = (defined $makemaker->{'EXE_FILES'}
                 && $makemaker->{'EXE_FILES'}->[0] !~ /^gtk2/
                 ? lc($makemaker->{'DISTNAME'})
                 : lc("lib$makemaker->{'DISTNAME'}-perl"));
  $post .=
    "DEBNAME = $debname\n"
      . "DPKG_ARCH = $arch\n"
        . <<'HERE';
DEBVNAME = $(DEBNAME)_$(VERSION)-1
DEBFILE = $(DEBVNAME)_$(DPKG_ARCH).deb

# ExtUtils::MakeMaker 6.42 of perl 5.10.0 makes "$(DISTVNAME).tar.gz" depend
# on "$(DISTVNAME)" distdir directory, which is always non-existent after a
# successful dist build, so the .tar.gz is always rebuilt.
#
# So although the .deb depends on the .tar.gz don't express that here or it
# rebuilds the .tar.gz every time.
#
# The right rule for the .tar.gz would be to depend on the files which go
# into it of course ...
#
# DISPLAY is unset for making a deb since under fakeroot gtk stuff may try
# to read config files like ~/.pangorc from root's home dir /root/.pangorc,
# and that dir will be unreadable by ordinary users (normally), provoking
# warnings and possible failures from nowarnings().
#
$(DEBFILE) deb:
	test -f $(DISTVNAME).tar.gz || $(MAKE) $(DISTVNAME).tar.gz
	debver="`dpkg-parsechangelog -c1 | sed -n -r -e 's/^Version: (.*)-[0-9.]+$$/\1/p'`"; \
	  echo "debver $$debver", want $(VERSION); \
	  test "$$debver" = "$(VERSION)"
	rm -rf $(DISTVNAME)
	tar xfz $(DISTVNAME).tar.gz
	unset DISPLAY; export DISPLAY; \
	  cd $(DISTVNAME) \
	  && dpkg-checkbuilddeps debian/control \
	  && fakeroot debian/rules binary
	rm -rf $(DISTVNAME)

lintian-deb: $(DEBFILE)
	lintian -I -i --suppress-tags new-package-should-close-itp-bug,desktop-entry-contains-encoding-key \
	  $(DEBFILE)
lintian-source:
	rm -rf temp-lintian; \
	mkdir temp-lintian; \
	cd temp-lintian; \
	cp ../$(DISTVNAME).tar.gz $(DEBNAME)_$(VERSION).orig.tar.gz; \
	tar xfz $(DEBNAME)_$(VERSION).orig.tar.gz; \
	mv -T $(DISTVNAME) $(DEBNAME)-$(VERSION); \
	dpkg-source -b $(DEBNAME)-$(VERSION) \
	               $(DEBNAME)_$(VERSION).orig.tar.gz; \
	lintian -I -i --suppress-tags empty-debian-diff *.dsc; \
	cd ..; \
	rm -rf temp-lintian

HERE

  {
    my $list_html = join(' ',@exefiles_html);
    if (! $list_html && @pmfiles_html <= 3) {
      $list_html = join(' ',@pmfiles_html);
    }
    if (! -e 'inc/my_pod2html') {
      $list_html = '';
    }
    my $make_list_html = ($list_html ? "\n\tmake $list_html" : "");
    $post .= <<"HERE";
my-list:$make_list_html
	ls -l -U $list_html \$(EXE_FILES) *.tar.gz *.deb
HERE
    $post .= <<'HERE';
	@echo -n '$(DEBFILE) '
	@dpkg-deb -f $(DEBFILE) | grep Installed-Size
HERE
    if ($list_html) {
      $post .= "\trm -f $list_html\n";
    }
  }

  return $post;
}

1;
__END__
