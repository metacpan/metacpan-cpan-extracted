
use strict;
use warnings;

use Test::More tests => 1;    # last test to print
use Gentoo::Dependency::AST;

my $string = <<"_EOF_";
      app-admin/eselect-qtgraphicssystem
      media-libs/fontconfig
      media-libs/freetype:2
      media-libs/libpng:0
      sys-libs/zlib
      virtual/jpeg:0
      ~dev-qt/qtcore-4.8.4[aqua=,debug=,glib=,qt3support=]
      ~dev-qt/qtscript-4.8.4[aqua=,debug=]
      !aqua? (
          x11-libs/libICE
          x11-libs/libSM
          x11-libs/libX11
          x11-libs/libXcursor
          x11-libs/libXext
          x11-libs/libXi
          x11-libs/libXrandr
          x11-libs/libXrender
          xinerama? (
              x11-libs/libXinerama
          )
          xv? (
              x11-libs/libXv
          )
      )
      cups? (
          net-print/cups
      )
      dbus? (
          ~dev-qt/qtdbus-4.8.4[aqua=,debug=]
      )
      egl? (
          media-libs/mesa[egl]
      )
_EOF_

use Data::Dump qw(pp);
isa_ok( Gentoo::Dependency::AST->parse_dep_string($string), "Gentoo::Dependency::AST::Node::TopLevel" );

