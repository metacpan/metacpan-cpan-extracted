#!perl -d:SmallProf

# In the change from 5.005_04 to 5.6.0, some changes were made in the 
# debugging hooks (upon which SmallProf depends).  The result was that a 
# file which invokes SmallProf from the shebang line (as this one does) 
# doesn't have it's contents put into the symbol table.  Thus this shim which
# invokes the real part1 so that its contents are visible.

do 't/part1.b' or die "$!";
