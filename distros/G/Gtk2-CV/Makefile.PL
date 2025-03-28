require 5.008;

print <<EOF;

**
** If you get any errors, make sure you have libmagic (from "file"),
** libjpeg, Gtk2 and Glib. On debian, this should get you there:
**
** apt-get install libextutils-depends-perl
** apt-get install libgtk2-ex-podviewer-perl libgtk2-gladexml-perl
** apt-get install libmagic-dev libjpeg62-dev libglib-perl libgtk2-perl
** apt-get install libgtk2.0-dev
**
** Optional dependencies:
** apt-get install libwebp-dev
** jpeg-xl reference implementation
**

EOF

use ExtUtils::MakeMaker;
use ExtUtils::Depends;

my $pkg = new ExtUtils::Depends ("Gtk2::CV");

my $lib = "-ljpeg -lmagic";
my $inc = "";

if (!system "pkg-config --exists libwebp libwebpdemux") {
   $inc .= " -DWEBP=1";
   $inc .= " " . qx<pkg-config --cflags libwebp libwebpdemux>;
   $lib .= " " . qx<pkg-config --libs   libwebp libwebpdemux>;
}

if (!system "pkg-config --exists libjxl libjxl_threads") {
   $inc .= " -DJXL=1";
   $inc .= " " . qx<pkg-config --cflags libjxl libjxl_threads>;
   $lib .= " " . qx<pkg-config --libs   libjxl libjxl_threads>;
}

s/\n/ /g
   for $inc, $lib;

$pkg->add_deps ("Gtk2", "Glib");
$pkg->set_libs ($lib);
$pkg->set_inc  ($inc);

sub MY::postamble {
   my $self=shift;
   <<EOF

.PHONY: doc

run: all
	\$(PERL) -Mblib -MCarp=verbose bin/cv

EOF
}

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text bin/cv | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    PREREQ_PM	=> {
                    common::sense	=> 3.6,
                    Guard		=> 1.02,
                    AnyEvent            => 6,
                    AnyEvent::Fork      => 0,
		    Glib		=> 1.08,
		    Gtk2		=> 1.246,
		    Gtk2::Ex::PodViewer	=> 0.17,
		    Gtk2::GladeXML      => 0.93,
#                    GStreamer		=> 0.11,
		    IO::AIO             => 4,
		    JSON::XS            => 2.2,
		   },
    DIR		=> [],
    NAME	=> 'Gtk2::CV',
    VERSION_FROM => 'lib/Gtk2/CV.pm',
    EXE_FILES	=> [qw(bin/cv)],
    $pkg->get_makefile_vars,
    PM		=> {
       'lib/Gtk2/CV/ImageWindow.pm'		=> '$(INST_LIB)/Gtk2/CV/ImageWindow.pm',
       'lib/Gtk2/CV/Schnauzer.pm'		=> '$(INST_LIB)/Gtk2/CV/Schnauzer.pm',
       'lib/Gtk2/CV/PostScript.pm'		=> '$(INST_LIB)/Gtk2/CV/PostScript.pm',
       'lib/Gtk2/CV/PrintDialog.pm'		=> '$(INST_LIB)/Gtk2/CV/PrintDialog.pm',
       'lib/Gtk2/CV/Jobber.pm'			=> '$(INST_LIB)/Gtk2/CV/Jobber.pm',
       'lib/Gtk2/CV/Plugin.pm'			=> '$(INST_LIB)/Gtk2/CV/Plugin.pm',
       'lib/Gtk2/CV/Plugin/NameCluster.pm'	=> '$(INST_LIB)/Gtk2/CV/Plugin/NameCluster.pm',
       'lib/Gtk2/CV/Plugin/PatRenamer.pm'	=> '$(INST_LIB)/Gtk2/CV/Plugin/PatRenamer.pm',
       'lib/Gtk2/CV/Plugin/RCluster.pm'		=> '$(INST_LIB)/Gtk2/CV/Plugin/RCluster.pm',
       'lib/Gtk2/CV/Plugin/MetaCluster.pm'	=> '$(INST_LIB)/Gtk2/CV/Plugin/MetaCluster.pm',
       'lib/Gtk2/CV/Progress.pm'		=> '$(INST_LIB)/Gtk2/CV/Progress.pm',
       'lib/Gtk2/CV.pm'				=> '$(INST_LIB)/Gtk2/CV.pm',

       'gtkrc'					=> '$(INST_LIB)/Gtk2/CV/gtkrc',
       'cv.glade'				=> '$(INST_LIB)/Gtk2/CV/cv.glade',

       'images/cv.png'				=> '$(INST_LIB)/Gtk2/CV/images/cv.png',
       'images/error.png'			=> '$(INST_LIB)/Gtk2/CV/images/error.png',
       'images/dir-unvisited.png'		=> '$(INST_LIB)/Gtk2/CV/images/dir-unvisited.png',
       'images/dir-visited.png'			=> '$(INST_LIB)/Gtk2/CV/images/dir-visited.png',
       'images/dir-xvpics.png'			=> '$(INST_LIB)/Gtk2/CV/images/dir-xvpics.png',
       'images/dir-empty.png'			=> '$(INST_LIB)/Gtk2/CV/images/dir-empty.png',
       'images/dir-symlink.png'			=> '$(INST_LIB)/Gtk2/CV/images/dir-symlink.png',
       'images/file.png'			=> '$(INST_LIB)/Gtk2/CV/images/file.png',
       'images/file-avi.png'			=> '$(INST_LIB)/Gtk2/CV/images/file-avi.png',
       'images/file-ogm.png'			=> '$(INST_LIB)/Gtk2/CV/images/file-ogm.png',
       'images/file-tif.png'			=> '$(INST_LIB)/Gtk2/CV/images/file-tif.png',
       'images/file-gif.png'			=> '$(INST_LIB)/Gtk2/CV/images/file-gif.png',
       'images/file-jpeg.png'			=> '$(INST_LIB)/Gtk2/CV/images/file-jpeg.png',
       'images/file-mpeg.png'			=> '$(INST_LIB)/Gtk2/CV/images/file-mpeg.png',
       'images/file-png.png'			=> '$(INST_LIB)/Gtk2/CV/images/file-png.png',
       'images/file-txt.png'			=> '$(INST_LIB)/Gtk2/CV/images/file-txt.png',
       'images/file-wmv.png'			=> '$(INST_LIB)/Gtk2/CV/images/file-wmv.png',
       'images/file-mov.png'			=> '$(INST_LIB)/Gtk2/CV/images/file-mov.png',
       'images/file-asf.png'			=> '$(INST_LIB)/Gtk2/CV/images/file-asf.png',
       'images/file-rar.png'			=> '$(INST_LIB)/Gtk2/CV/images/file-rar.png',
       'images/file-zip.png'			=> '$(INST_LIB)/Gtk2/CV/images/file-zip.png',
       'images/file-ace.png'			=> '$(INST_LIB)/Gtk2/CV/images/file-ace.png',
       'images/file-audio.png'			=> '$(INST_LIB)/Gtk2/CV/images/file-audio.png',
       'images/file-mp2.png'			=> '$(INST_LIB)/Gtk2/CV/images/file-mp2.png',
       'images/file-mp3.png'			=> '$(INST_LIB)/Gtk2/CV/images/file-mp3.png',
       'images/file-midi.png'			=> '$(INST_LIB)/Gtk2/CV/images/file-midi.png',
       'images/file-rm.png'			=> '$(INST_LIB)/Gtk2/CV/images/file-rm.png',
       'images/file-par.png'			=> '$(INST_LIB)/Gtk2/CV/images/file-par.png',
    },
);



