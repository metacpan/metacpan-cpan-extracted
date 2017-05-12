# MyMakeMakerExtra.pm -- my shared MakeMaker extras

# Copyright 2009, 2010, 2011, 2012 Kevin Ryde

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
  }

  if (! defined $opts{'clean'}->{'FILES'}) {
    $opts{'clean'}->{'FILES'} = '';
  }
  $opts{'clean'}->{'FILES'} .= ' temp-lintian $(MY_HTML_FILES)';

  # if (! defined $opts{'realclean'}->{'FILES'}) {
  #   $opts{'realclean'}->{'FILES'} = '';
  # }
  # $opts{'realclean'}->{'FILES'} .= ' TAGS';

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
  # ------ pc: test vars ------
  # the "." obscures it from MyExtractUse.pm
  $post .= "\t-\$(PERLRUNINST) -e 'use "."Test::Vars; all_vars_ok()'\n";

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

  # ------ check-copyright-years ------
  $post .= <<'HERE';

HERE

  $post .= "\n";
  $post .= ("MY_EXTRA_FILE_PART_OF = " 
            . ($my_options{'MY_EXTRA_FILE_PART_OF'}||'')
            . "\n");
  $post .= <<'HERE';
check-file-part-of:
	if grep --text 'This file is'' part of ' -r . | egrep -iv '$(DISTNAME)$(MY_EXTRA_FILE_PART_OF)'; then false; else true; fi

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




# Old stuff:

# #------------------------------------------------------------------------------
# # META_MERGE
# 
# sub _meta_merge_req_add {
#   my $req = shift;
#   ### MyMakeMakerExtras META_MERGE: @_
#   while (@_) {
#     my $module = shift;
#     my $version = shift;
#     if (defined $req->{$module}) {
#       if ($req->{$module} > $version) {
#         $version = $req->{$module};
#       }
#     }
#     $req->{$module} = $version;
#   }
# }

# # return hashref of "maximum_devel" under $opts, created if necessary
# sub _meta_merge_maximum_devel {
#   my ($opts) = @_;
#   $opts->{'META_MERGE'}->{'optional_features'}->{'maximum_devel'} ||=
#     { description => 'Stuff used variously for development.',
#       requires => { },
#     };
#   return $opts->{'META_MERGE'}->{'optional_features'}->{'maximum_devel'}->{'requires'};
# }

#     _meta_merge_shared_devel (\%opts);
# sub _meta_merge_shared_devel {
#   my ($opts) = @_;
#   if (exists $opts->{'META_MERGE'}->{'optional_features'}->{'maximum_devel'}) {
#     _meta_merge_req_add (_meta_merge_maximum_devel($opts),
#                          # the "make unused" target below
#                          'warnings::unused' => 0);
#     _meta_merge_req_add (_meta_merge_maximum_devel($opts),
#                          # used a lot
#                          'Smart::Comments' => 0,
#                          'Devel::Comments' => 0);
#     if (-e 'inc/my_pod2html') {
#       if (_min_perl_version_lt ($opts, 5.009003)) {
#         _meta_merge_req_add (_meta_merge_maximum_devel($opts),
#                              'Pod::Simple::HTML' => 0);
#       }
#     }
#   }
# }


    # _meta_merge_shared_tests (\%opts);
# sub _meta_merge_shared_tests {
#   my ($opts) = @_;
# 
#   if (exists $opts->{'META_MERGE'}->{'optional_features'}->{'maximum_devel'}) {
#     # only if "maximum_devel" in use
# 
#     if (-e 'xt/0-Test-Pod.t') {
#       _meta_merge_req_add (_meta_merge_maximum_devel($opts),
#                            'Test::Pod' => '1.00');
#     }
#     if (-e 'xt/0-Test-DistManifest.t') {
#       _meta_merge_req_add (_meta_merge_maximum_devel($opts),
#                            'Test::DistManifest' => 0);
#     }
#     if (-e 'xt/0-Test-Synopsis.t') {
#       _meta_merge_req_add (_meta_merge_maximum_devel($opts),
#                            'Test::Synopsis' => 0);
#     }
#     if (-e 'xt/0-Test-YAML-Meta.t') {
#       _meta_merge_req_add (_meta_merge_maximum_devel($opts),
#                            'Test::YAML::Meta' => '0.15');
#     }
#     if (-e 'xt/0-META-read.t') {
#       if (_min_perl_version_lt ($opts, 5.00307)) {
#         _meta_merge_req_add (_meta_merge_maximum_devel($opts),
#                              'FindBin' => 0);
#       }
#       if (_min_perl_version_lt ($opts, 5.00405)) {
#         _meta_merge_req_add (_meta_merge_maximum_devel($opts),
#                              'File::Spec' => 0);
#       }
#       _meta_merge_req_add (_meta_merge_maximum_devel($opts),
#                            'YAML'              => 0,
#                            'YAML::Syck'        => 0,
#                            'YAML::Tiny'        => 0,
#                            'YAML::XS'          => 0,
#                            'Parse::CPAN::Meta' => 0);
#     }
#   }
# }

# # return hashref of "maximum_tests" under $opts, created if necessary
# sub _meta_merge_maximum_tests {
#   my ($opts) = @_;
#   $opts->{'META_MERGE'}->{'optional_features'}->{'maximum_tests'} ||=
#     { description => 'Have "make test" do as much as possible.',
#       requires => { },
#     };
#   return $opts->{'META_MERGE'}->{'optional_features'}->{'maximum_tests'}->{'requires'};
# }

# # return true if MIN_PERL_VERSION in $opts is < $ver, or no MIN_PERL_VERSION
# sub _min_perl_version_lt {
#   my ($opts, $perlver) = @_;
#   return (! defined $opts->{'MIN_PERL_VERSION'}
#           || $opts->{'MIN_PERL_VERSION'} < $perlver);
# }

