##-*- Mode: CPerl -*-
use ExtUtils::MakeMaker;
use Config;
use 5.010;       ##-- in case old EU::MM doesn't grok MIN_PERL_VERSION

##----------------------------------------------------------------------
## PDL-dependencies (for CONFIGURE_REQUIRES)
my %pdl_deps = (
  'PDL' => '2.007',             ##-- dist:2.007, local:2.014
  'PDL::CCS' => '1.23.1',
  'PDL::VectorValued' => '1.0.5',
);

##-- disable PDL-Utils build if PDL isn't installed
my $WANT_PDL = prompt("Use PDL for (term x document) matrix modelling if available?", "y");
if ($WANT_PDL =~ /^\s*y/i) {
  eval "use PDL;";
  $WANT_PDL = defined($PDL::VERSION);
  warn("$0 WARNING: PDL module is missing or broken, TDF relation will be disabled!") if (!$WANT_PDL);
} else {
  $WANT_PDL = 0;
}

##-- only enable c++ optimizations under linux/gcc
my $WANT_XS_DEFAULT = ($^O =~ /linux/i && $Config{cc} =~ /gcc/ && $] >= 5.020);
my $WANT_XS = prompt("Build DiaColloDB::XS utilities (Linux+GCC only)?", ($WANT_XS_DEFAULT ? "y" : "n"));
if ($WANT_XS =~ /^\s*y/i) {
  warn("$0 WARNING: this doesn't appear to be linux+gcc - c++ optimizations disabled!") if (!$WANT_XS_DEFAULT);
} else {
  $WANT_XS = 0;
}

##-- workaround for irritating "/some/symlinked/file is encountered a second time at File/Find.pm line 79." errors
##   under ExtUtils::MakeMaker 7.1002 (see also RT bug #99018)
#*ExtUtils::MakeMaker::_check_files = sub {};
#*ExtUtils::MakeMaker::check_manifest = sub {};
do "./find.hack" if (-e "./find.hack");

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------
WriteMakefile
  (
    NAME		=> 'DiaColloDB',
    AUTHOR       => 'Bryan Jurish <moocow@cpan.org>',
    ABSTRACT	=> 'Diachronic collocation index',
    VERSION_FROM	=> 'DiaColloDB.pm',
    LICENSE      => 'perl_5',
    MIN_PERL_VERSION => 5.010,  ##-- v5.10.0
    META_MERGE   => {
      'meta-spec' => { version => 2 }, ##-- doesn't seem to work
      resources  => {
        repository => {
          type => 'git',
          url => 'https://github.com/moocow-the-bovine/DiaColloDB.git',
          web => 'https://github.com/moocow-the-bovine/DiaColloDB'
        },
      },
      ##-- prereqs: for Meta::Spec v2
      prereqs => {
        runtime => {
          recommends => {
            'DDC::XS' => 0.23,
            %pdl_deps
          },
          #suggests => {},
        },
        build => {
          recommends => { %pdl_deps },
        },
      },
    },


    PREREQ_PM    => {
      'Algorithm::BinarySearch::Vec' => '0.07', ##-- for fast integer-set operations
      #'Cwd' => 0, ##-- for abs_path
      'DB_File' => 0,           ##-- for temporary hashes; 1.831
      'DDC::Concordance' => 0.44, ##-- for $DDC::Client::JSON_BACKEND
      'File::Copy'    => 0,       ##-- for move()
      'File::Find'    => 0,
      'File::Map'     => 0,       # 0.63
      'File::Path'    => 0,       ##-- make_tree, remove_path; 2.08_01
      'File::Spec'    => 0,
      'File::Temp'    => 0,
      'Getopt::Long'  => 0,
      'IPC::Run'      => 0,          # 0.94
      'JSON'          => 0,          # 2.53
      'Log::Log4perl' => 1.07,       # 1.29
      'LWP::UserAgent' => 0,         ##-- 6.06, for http client-mode
      'Tie::File::Indexed' => '0.08', ##-- for temporary object arrays
      'Time::HiRes' => 0,             ##-- for runtime profiling
      'XML::LibXML' => '1.70', ##-- for XML-based input formats (TCF, TEI)
      'Test::More' => 0,
      ($Config{usethreads}
       ? ('threads' => 0,                       ##-- 2.07
          'threads::shared' => 0,               ##-- 1.51
        )
       : ('forks' => 0.36,
          'forks::shared' => 0.36,
        )),
      ##
      ##-- for (term x document) models (TDF, formerly "Vsem")
      #%pdl_deps,
    },
    CONFIGURE_REQUIRES => {
      'ExtUtils::MakeMaker' => 6.52, ##-- for CONFIGURE_REQUIRES
      #%pdl_deps,
    },


    EXE_FILES => [ glob('dcdb-*.perl'), ],
    ##
    #NORECURS  => 1, ##-- don't recurse into local 'MUDL' mirror dir
    ##
    DIR => [
      ($WANT_PDL ? 'PDL-Utils' : qw()),
      ($WANT_XS  ? 'XS'        : qw()),
    ],
  );

##-----------------------------------------------------------------------
## Extensions
##-----------------------------------------------------------------------

##---------------------------------------------------------------
sub MY::constants {
  package MY;
  my $css = 'perlpod.css';
  my $inherited = shift->SUPER::constants(@_);
  $inherited .= (
    ###-- constants: html css
    "\n"
    ."CSS ?= $css\n"
  );
  return $inherited;
}

##---------------------------------------------------------------
sub MY::pasthru {
  package MY;
  my $css = 'perlpod.css';
  my $inherited = shift->SUPER::pasthru(@_);

  ##-- suppress passing down gcc/g++ flags, b/c we need both gcc (PDL-Utils) and g++ (XS)
  $inherited =~ s/\b((?:OPTIMIZE|LD)=\S+\\)/orig_$1/g;
  return $inherited;
}

##---------------------------------------------------------------
sub MY::depend {
  package MY;
  my $inherited = shift->SUPER::depend(@_);
  $inherited .= (
    ###-- depends -> README.txt
    "\n\n"
    ."readme: README.txt\n"
    ."\n"
    ."dist: README.txt\n"
    ."\n"
    ."create_distdir: README.txt\n"
    ."\n"
    ."distcheck: README.txt\n"
    ."\n"
    ."manicheck: README.txt\n"
    ."\n"
  );
  return $inherited;
}

##---------------------------------------------------------------
sub MY::special_targets {
  package MY;
  my $inherited = shift->SUPER::special_targets(@_);
  $inherited .=
    "
.SUFFIXES: .pm .pod .rpod .man .txt .html

.pm.html:
\tpod2html --css=\$(CSS) --infile=\$< --outfile=\$@

.pm.txt:
\tpod2text \$< \$@

.pod.html:
\tpod2html --css=\$(CSS) --infile=\$< --outfile=\$@

.pod.txt:
\tpod2text \$< \$@

.rpod.html:
\tpod2html --css=\$(CSS) --infile=\$< --outfile=\$@

.rpod.txt:
\tpod2text \$< \$@

";

  return $inherited;
}

##---------------------------------------------------------------
sub MY::manifypods {
  package MY;
  my $inherited = shift->SUPER::manifypods(@_);
  my $out = $inherited;

  my $new = $inherited;
  my $html_ns_sep = ".";
  $new =~ s/.*(?=^manifypods\b)//sm;
  $new =~ s/\n\n.*//s;
  my ($deps0,$rules0) = split(/(?<!\\)\n/, $new, 2);
  my ($deps,$rules);

  ##-----------------------
  ## html
  my $htmlvars ='

##--- pod -> HTML

.SUFFIXES: .html

INST_CSS ?= ../../$(CSS)
POD2HTMLFLAGS ?= --css="$(INST_CSS)" --backlink="(Back to Top)" --podroot=blib --podpath="lib:script" --header
POD2HTML ?= pod2html $(POD2HTMLFLAGS)

INST_HTMLDIR ?= blib/html

HTML_EXT ?= html
HTML1EXT ?= $(HTML_EXT)
HTML3EXT ?= $(HTML_EXT)

##-- lifted from MakeMaker blibdir section
$(INST_HTMLDIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_HTMLDIR)
	$(NOECHO) $(CHMOD) 755 $(INST_HTMLDIR)
	$(NOECHO) $(TOUCH) $(INST_HTMLDIR)$(DFSEP).exists

';
  ($deps,$rules) = ($deps0,$rules0);
  $deps =~ s/^manifypods\b/htmlifypods/;
  $deps .= "\\\n\t".'$(INST_HTMLDIR)$(DFSEP).exists';
  $rules =~ s/POD2MAN/POD2HTML/g;
  $rules =~ s/MAN(\d)EXT/HTML$1EXT/g;
  $rules =~ s/INST_MAN\dDIR/INST_HTMLDIR/g;
  $rules =~ s/^\s+\$\(NOECHO\).*?\n//smg;
  $rules =~ s/::/${html_ns_sep}/sg if ($html_ns_sep ne '::');
  $rules =~ s/\\\n/\n/sg;
  my $hackit = ("\\\n"
                ."\t | ".'$(PERL) -p'." \\\n"
                ."\t   ".'-e\'sub hackhref {($$href=shift)=~s{^/*}{}; $$href=~s{^(?:script|lib)/}{}; $$href=~s{/}{'.$html_ns_sep.'}g; $$href;}\''." \\\n"
                ."\t   ".'-e\'s/<a href="([^"]*)/\'\\\'\'<a href="\'\\\'\'.hackhref($$1)/eg;\''
              );
  #$hackit = ' | cat - ';
  $rules =~ s/\t\s+(\S+)\s+(\S+)/\t\$(POD2HTML) --infile=$1 ${hackit} \\\n\t > $2 || (rm -f $2 && false)/sg;
  $out .= $htmlvars.$deps."\n".$rules."\n\n";

  ##-----------------------
  ## text
  my $text_ns_sep = $html_ns_sep;
  my $textvars ='

##--- pod -> txt
.SUFFIXES: .txt

POD2TEXT ?= pod2text

INST_TEXTDIR ?= blib/txt
TEXT_EXT ?= txt
TEXT1EXT ?= $(TEXT_EXT)
TEXT3EXT ?= $(TEXT_EXT)

##-- lifted from MakeMaker blibdir section
$(INST_TEXTDIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_TEXTDIR)
	$(NOECHO) $(CHMOD) 755 $(INST_TEXTDIR)
	$(NOECHO) $(TOUCH) $(INST_TEXTDIR)$(DFSEP).exists

';
  ($deps,$rules) = ($deps0,$rules0);
  $deps =~ s/^manifypods\b/textifypods/;
  $deps .= "\\\n\t".'$(INST_TEXTDIR)$(DFSEP).exists';
  $rules =~ s/POD2MAN/POD2TEXT/g;
  $rules =~ s/MAN(\d)EXT/TEXT$1EXT/g;
  $rules =~ s/INST_MAN\dDIR/INST_TEXTDIR/g;
  $rules =~ s/^\s+\$\(NOECHO\).*?\n//smg;
  $rules =~ s/::/${text_ns_sep}/sg if ($text_ns_sep ne '::');
  $rules =~ s/\\\n/\n/sg;
  $rules =~ s/\t\s+(\S+)\s+(\S+)/\t\$(POD2TEXT) $1 $2/sg;
  $rules .= "\n\ntxtifypods: textifypods\n\n";
  $out .= $textvars.$deps."\n".$rules."\n\n";

  ##-----------------------
  ## pod
  my $pod_ns_sep = $html_ns_sep;
  my $podvars ='

##--- pod+perl -> pod

.SUFFIXES: .pod

POD2POD ?= podselect -section ""

INST_PODDIR ?= blib/pod
POD_EXT ?= pod
POD1EXT ?= $(POD_EXT)
POD3EXT ?= $(POD_EXT)

##-- lifted from MakeMaker blibdir section
$(INST_PODDIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_PODDIR)
	$(NOECHO) $(CHMOD) 755 $(INST_PODDIR)
	$(NOECHO) $(TOUCH) $(INST_PODDIR)$(DFSEP).exists

';
  ($deps,$rules) = ($deps0,$rules0);
  $deps =~ s/^manifypods\b/podifypods/;
  $deps .= "\\\n\t".'$(INST_PODDIR)$(DFSEP).exists';
  $rules =~ s/POD2MAN/POD2POD/g;
  $rules =~ s/MAN(\d)EXT/POD$1EXT/g;
  $rules =~ s/INST_MAN\dDIR/INST_PODDIR/g;
  $rules =~ s/^\s+\$\(NOECHO\).*?\n//smg;
  $rules =~ s/::/${pod_ns_sep}/sg if ($pod_ns_sep ne '::');
  $rules =~ s/\\\n/\n/sg;
  $rules =~ s/\t\s+(\S+)\s+(\S+)/\t\$(POD2POD) $1 > $2/sg;
  $out .= $podvars.$deps."\n".$rules."\n\n";

  ##-- return
  return $out;
}

##---------------------------------------------------------------
sub MY::dist_basics {
  package MY;
  my $inherited = shift->SUPER::dist_basics(@_);
  $inherited =~ s{(-MExtUtils::Manifest=.*? -e)\s*(\S+)}{$1 "do './find.hack'; $2"}mg;
  return $inherited;
}

##---------------------------------------------------------------
sub MY::distdir {
  package MY;
  my $inherited = shift->SUPER::distdir(@_);
  return $inherited;            #.$local;
}

##---------------------------------------------------------------
sub MY::postamble {
  package MY;
  my $inherited = shift->SUPER::postamble(@_);
  return $inherited;
}
