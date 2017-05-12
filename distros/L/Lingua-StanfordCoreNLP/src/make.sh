#!/bin/sh

rm -f be/fivebyfive/lingua/stanfordcorenlp/*.class
javac -classpath ../lib/Lingua/StanfordCoreNLP/stanford-corenlp-?.?.?.jar be/fivebyfive/lingua/stanfordcorenlp/*.java
jar   -cf LinguaSCNLP.jar be/fivebyfive/lingua/stanfordcorenlp/*.class
