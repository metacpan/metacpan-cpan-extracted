# Copyright (C) 1998 Tuomas J. Lukka
# DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
# See the GNU Library General Public License (file COPYING in the distribution)
# for conditions of use and redistribution.

JAVAC=javac_g -classpath /usr/lib/jdk1.1/lib/classes.zip:../classes/ -d ../classes/ 

all: 
	$(JAVAC) *.java fields/*.java

%.com: %.java
	$(JAVAC) $<
