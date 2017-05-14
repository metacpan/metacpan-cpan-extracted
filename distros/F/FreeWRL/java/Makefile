JAVAC=javac_g

all:
	perl genfields.pl
	$(JAVAC) -classpath /usr/lib/jdk1.1/lib/classes.zip:./classes/ -d ./classes/ *.java fields/*.java

tjl:
	$(JAVAC) -classpath /usr/lib/jdk1.1/lib/classes.zip:./classes/ -d ./classes/ Tjl*.java

eai::
	(cd eai; make)
