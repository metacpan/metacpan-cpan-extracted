require 5.008;
use ExtUtils::MakeMaker;
use File::Basename;
use Alien::Gimp;
use strict;
use warnings;

# list of standard plugins
our %cfg;
my @pins = qw(
  Perl-Server
  Perl-Console
  registry_viewer
  blended2 translogo
  dataurl
  example-fu
  exceptiontest
  colorhtml
  fade-alpha
  animate_cells
  blowinout bricks burst
  centerguide
  ditherize dots dust
  frame_filter frame_reshuffle
  glowing_steel goldenmean guidegrid guides_to_selection
  innerbevel
  layerfuncs mirrorsplit
  map_to_gradient
  perlotine prep4gif
  repdup
  scratches sethspin stamps
  randomart1 randomblends
  selective_sharpen
  warp-sharp webify windify
  xachlego xachshadow xachvision
  yinyang
  gouge
  redeye
  pixelmap
  image_tile
  iland
);

sub install_plugin_target {
  my $plugin = shift;
  my $src = '$(INST_PLUGINS)/'.basename($plugin);
  my $dest = '$(GIMP_PLUGINS)/'.basename($plugin);
  <<EOF;
$dest : $src
	\$(NOECHO) \$(GTINSTALL) "$src"

EOF
}

sub build_plugin_target {
  my $plugin = shift;
  my $dest = '$(INST_PLUGINS)/'.basename($plugin);
  <<EOF;
$dest : $plugin \$(INST_PLUGINS)\$(DFSEP).exists
	\$(NOECHO) \$(RM_F) $dest
	\$(CP) $plugin $dest
	\$(FIXIN) $dest
	-\$(NOECHO) \$(CHMOD) \$(PERM_RWX) $dest

EOF
}

undef &MY::postamble; # suppress warning
*MY::postamble = sub {
   my $self=shift;
   my $UT = Alien::Gimp->gimptool . " --uninstall-admin-bin";
   my $plugindir = Alien::Gimp->gimpplugindir;
   <<EOF;

INST_PLUGINS = ../blib/plugins
GIMP_PLUGINS = $plugindir

\$(INST_PLUGINS)\$(DFSEP).exists :: Makefile.PL
	\$(NOECHO) \$(MKPATH) \$(INST_PLUGINS)
	\$(NOECHO) \$(CHMOD) \$(PERM_DIR) \$(INST_PLUGINS)
	\$(NOECHO) \$(TOUCH) \$(INST_PLUGINS)\$(DFSEP).exists

@{[ join '', map { build_plugin_target($_) } @pins ]}

@{[ join '', map { install_plugin_target($_) } @pins ]}

install :: install-plugins

pure_all :: pure_plugins

pure_plugins : @{[ map { "\$(INST_PLUGINS)/".basename($_) } @pins ]}

install-plugins : @{[ map { "\$(GIMP_PLUGINS)/".basename($_) } @pins ]}

uninstall ::
	cd \$(INST_PLUGINS); for plugin in *; do $UT "\$\$plugin"; done

EOF
};

WriteMakefile(
    'NAME'	=> 'Gimp',
    'VERSION_FROM' => '../lib/Gimp.pm',
    NO_MYMETA	=> 1,
    NO_META	=> 1,
    macro	=> { GTINSTALL => Alien::Gimp->gimptool . " --install-admin-bin" },
);
