# Copyright (C) 1998 Tuomas J. Lukka
# DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
# See the GNU Library General Public License (file COPYING in the distribution)
# for conditions of use and redistribution, EXCEPT on the files                 
# which belong under the mozilla public license.                                
                                                                                

# a.out: js.c
# 	 cc -I js/Linux_All_DBG.OBJ/ -Ijs/ js.c -L js/Linux_All_DBG.OBJ/ -ljs -lm

use ExtUtils::MakeMaker;

# Add several possible places for -L. 

WriteMakefile(
	NAME => 'VRML::JS',
	VERSION => '0.01',
#
# You have to explain here how to find your opengl libs.
#
#    LIBS      => '-Ljs/Linux_All_DBG.OBJ -ljs',
    LIBS      => $VRML_CONFIG{JS_LIBS},
    INC => $VRML_CONFIG{JS_INC},

    DEFINE => '',
);

#
#      ['-L/usr/X11R6/lib -L/usr/lib/mesa/ -lGL -lGLU -lMesaGL -lMesaGLU -lXext -lX11 '],
#



