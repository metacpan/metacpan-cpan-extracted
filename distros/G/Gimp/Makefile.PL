use strict;
use warnings;
use ExtUtils::Depends;
use ExtUtils::MakeMaker;

sub MY::postamble {
   my $self=shift;
   <<'EOF';
install-po:
	cd po && \$(MAKE) install

install ::
	cd examples && \$(MAKE) install

# generate tags file
tags: .
	ctags --lang=c `find . -name '*.xs' -print`

# set \$VERSION in all modules
setver:
	$(PERL) -pi -e 's/^(\s*(?:our)?\s*\$$VERSION\s*=\s*)[^a-z]*;/$${1}"$(VERSION)";/' lib/Gimp/*.pm

EOF
}

my $IDIR = 'lib/Gimp/Install';
my $IFILES = "$IDIR/Files.pm";
my $pkg = eval {
  my @ext_deps = qw(Alien::Gimp Gtk2 PDL);
  my $pkg = ExtUtils::Depends->new('Gimp', @ext_deps);
  mkdir $IDIR unless -d $IDIR;
  $pkg->save_config($IFILES);
  # reinit so no PM which breaks XSMULTI
  $pkg = ExtUtils::Depends->new('Gimp', @ext_deps);
  $pkg->set_inc(q{-Ddatadir='""'});
  $pkg;
};

my $runtime_reqs = {
  'Gtk2'		=> 1.0,
  'PDL'		=> '2.064', # pdlnew returns viable null
  'Data::Dumper'	=> 2.0,
  'IO::All'		=> 0,
  'Gtk2::Ex::PodViewer'	=> 0,
  'IO::Scalar'		=> 0,
  'Web::Scraper'	=> 0,
  'HTML::Entities'	=> 0,
  'Alien::Gimp'	=> '0.01',
};

WriteMakefile(
  NAME	=> 'Gimp',
  VERSION_FROM => 'lib/Gimp.pm',
  dist	=> { PREOP => 'make setver && chmod -R u=rwX,go=rX . ;' },
  XSMULTI => 1,
  MIN_PERL_VERSION => '5.014001',
  CONFIGURE_REQUIRES	=> {
    'ExtUtils::MakeMaker'	=> '7.14', # XSMULTI
    'ExtUtils::Depends'	=> '0.402',
    'Alien::Gimp'	=> '0.01',
    'IO::All'		=> 0,
    'Gtk2'		=> 1.0,
    'PDL'		=> '2.007_04',
  },
  TEST_REQUIRES	=> {
    'Test::More'	=> '0.88',
    %$runtime_reqs, # since tests exercise all plugins
  },
  PREREQ_PM	=> $runtime_reqs,
  META_MERGE => {
    "meta-spec" => { version => 2 },
    resources => {
      x_IRC => 'irc://irc.gnome.org/#gimp',
      repository => {
	type => 'git',
	url => 'git@gitlab.gnome.org:GNOME/gimp-perl.git',
	web => 'https://gitlab.gnome.org/GNOME/gimp-perl/',
      },
    },
  },
  DIR	=> [ qw/examples/ ], # exclude po
  EXE_FILES => [ map { "utils/$_" } qw(gimpdoc xcftopnm embedxpm scm2perl) ],
  clean	=> { FILES => $IFILES },
  ($pkg ? $pkg->get_makefile_vars : ()),
);
