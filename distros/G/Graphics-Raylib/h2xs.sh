#!/bin/sh
h2xs -n Graphics::Raylib::XS raylib.h \
    -b5.8.0 -F-Wno-format -x -O -M'^(?x:
(?!GetDroppedFiles)

(?!LIGHTGRAY)
(?!GRAY)
(?!DARKGRAY)
(?!YELLOW)
(?!GOLD)
(?!ORANGE)
(?!PINK)
(?!RED)
(?!MAROON)
(?!GREEN)
(?!LIME)
(?!DARKGREEN)
(?!SKYBLUE)
(?!BLUE)
(?!DARKBLUE)
(?!PURPLE)
(?!VIOLET)
(?!DARKPURPLE)
(?!BEIGE)
(?!BROWN)
(?!DARKBROWN)
(?!WHITE)
(?!BLACK)
(?!BLANK)
(?!MAGENTA)
(?!RAYWHITE)

(?!RLAPI)
(?!CLITERAL)

(?!PI)
).*$'

echo 'mv Graphics-Raylib-XS XS'
rm -rd XS
mv Graphics-Raylib-XS XS

echo 'Patching generated .xs'
perl -pi -e 's/int format/int/g;s/arg3/format/g' XS/XS.xs

echo 'Patching Makefile.PL to use Alien'
perl -pi -e 'BEGIN{undef $/;} 
s{
^WriteMakefile\( 
  (.*?)
^\);$
}{
use Alien::raylib;

WriteMakefile(
    $1,

    LIBS              => [ Alien::raylib->libs,
                          "-L/usr/local/lib -l__cpu_model"],
    INC               => Alien::raylib->cflags,
    dynamic_lib =>  { OTHERLDFLAGS => "-framework OpenGL -framework OpenAL" },
);
}xsm;' XS/Makefile.PL


