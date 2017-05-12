This is the Git repository for the Perl CPAN module Java::Makefile.

It is designed to be a quick and painless way to create standalone Jar files for Java projects from some simple XML declaring the classes in the project and the jars that are depended upon.

Jars are injected directly into the build jar file, and their contents are accessible to the built Java project by way of the "jarinjarloader". The "jarinjarloader" is taken from the Eclipse source tree. It is modified only to change the namespace. The namespace has been changed as additional futures changes may be made to it.

This project is licensed under CC-BY-SA 4.0. "jarinjarloader" is licensed under the EPL 1.0.