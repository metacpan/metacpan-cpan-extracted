use strict;
use warnings;

use Module::Build;

eval { require Alien::IUP };
if ($@) {
  warn "You need to have Alien::IUP installed\n";
  exit 0;
}

unless (Alien::IUP->havelib( qw/iup im cd/ )) {
  warn "Some of the essential libraries - iup, im, cd - are missing!\n";
  warn "Alien::IUP::VERSION=$Alien::IUP::VERSION\n";
  warn "Gonna quit!\n";
  exit 0;
}

my $lflags = Alien::IUP->config('LIBS');
my $cflags = Alien::IUP->config('INC');

$cflags .= ' -DHAVELIB_IUPCD'         if Alien::IUP->havelib('iupcd');
$cflags .= ' -DHAVELIB_IUPIM'         if Alien::IUP->havelib('iupim');
$cflags .= ' -DHAVELIB_IUPGL'         if Alien::IUP->havelib('iupgl');
$cflags .= ' -DHAVELIB_IUPGLCONTROLS' if Alien::IUP->havelib('iupglcontrols');
$cflags .= ' -DHAVELIB_IUPOLE'        if Alien::IUP->havelib('iupole');
$cflags .= ' -DHAVELIB_IUPCONTROLS'   if Alien::IUP->havelib('iupcontrols');
$cflags .= ' -DHAVELIB_IUP_PPLOT'     if Alien::IUP->havelib('iup_pplot');
$cflags .= ' -DHAVELIB_IUP_PLOT'      if Alien::IUP->havelib('iup_plot');
$cflags .= ' -DHAVELIB_IUP_MGLPLOT'   if Alien::IUP->havelib('iup_mglplot');
$cflags .= ' -DHAVELIB_IUP_SCINTILLA' if Alien::IUP->havelib('iup_scintilla');
$cflags .= ' -DHAVELIB_IUPIMGLIB'     if Alien::IUP->havelib('iupimglib');
$cflags .= ' -DHAVELIB_CDCONTEXTPLUS' if Alien::IUP->havelib('cdcontextplus');

my $class = 'Module::Build';
if (-d '.git') { #adding some custom actions relevant only for module development
  $class = Module::Build->subclass( class => "Module::Build::Custom", code => <<'CODE' );
  sub ACTION_xt {
    system(qw[prove -bl xt/*.t]);
    return;
  }
  sub ACTION_gencode {
    system($^X, qw[_generators/generate.pl -dst lib/IUP/Internal]);
    return;
  }
  sub ACTION_gendoc {
    system($^X, qw[_generators/proc-pod.tt2pod.pl -podtt _generators/pod.tt -pod lib]);
    system($^X, qw[_generators/proc-pod2cpan.html.pl -html tmp.cpan-like.html -pod lib]);
    return;
  }
  sub ACTION_touch {
    my $self = shift;
    system($^X, qw[-MFile::Touch -e touch('lib/IUP/Internal/LibraryIup.xs')]);
    return;
  }
  sub ACTION_xs {
    my $self = shift;
    $self->depends_on(qw[touch build]);
  }
CODE
}

my $builder = $class->new(
  module_name          => 'IUP',
  license              => 'mit',
  dist_abstract        => 'IUP bindings to Perl',
  dist_author          => 'KMX <kmx@cpan.org>',
  dist_version_from    => 'lib/IUP.pm',
  requires             => {
    'perl'                 => 5.008008,
  },
  build_requires       => { # need to have for running: ./Build (install|test)
    'perl'                 => 5.008008,
    'Module::Build'        => 0.36,
    'Alien::IUP'           => 0.709,
    'Test::More'           => 0,
  },
  configure_requires   => { # need to have for running: perl Buil.PL
    'perl'                 => 5.008008,
    'Module::Build'        => 0.36,
    'Alien::IUP'           => 0.709,
  },
  c_source             => 'src', # ppport.h
  extra_linker_flags   => $lflags,
  extra_compiler_flags => $cflags,  
  meta_merge => {
    keywords => [ qw[IUP portable toolkit graphical user interfaces tecgraf cross-platform GUI Windows GTK Motif X11] ],
    resources => {
      bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=IUP',
      repository => 'https://github.com/kmx/perl-iup',
    }
  },
);

#set features for later use vie IUP::ConfigData->feature('name');
$builder->feature('CanvasGL', 1)   if Alien::IUP->havelib('iupgl');
$builder->feature('PPlot', 1)      if Alien::IUP->havelib('iup_pplot');
$builder->feature('Plot', 1)       if Alien::IUP->havelib('iup_plot');
$builder->feature('MGLPlot', 1)    if Alien::IUP->havelib('iup_mglplot');
$builder->feature('OLE', 1)        if Alien::IUP->havelib('iupole');
$builder->feature('ImgLib', 1)     if Alien::IUP->havelib('iupimglib');
$builder->feature('Controls', 1)   if Alien::IUP->havelib('iupcontrols');
$builder->feature('GLControls', 1) if Alien::IUP->havelib('iupglcontrols');
$builder->feature('Scintilla', 1)  if Alien::IUP->havelib('iup_scintilla');

$builder->create_build_script();
