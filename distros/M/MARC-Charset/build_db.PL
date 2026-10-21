use strict;
use warnings;
use MARC::Charset::Compiler;

# etc/codetables.xml is vendored from the Library of Congress
# (https://www.loc.gov/marc/specifications/codetables.xml) with local
# corrections; see "DATA SOURCE" in MARC::Charset::Compiler's POD
# before replacing it with a fresh download.
print "compiling marc8/utf8 database, please be patient\n";
my $compiler = MARC::Charset::Compiler->new();
$compiler->compile('etc/codetables.xml');
$compiler->compile('etc/additional-iii-characters.xml');
$compiler->compile('etc/cccii.xml');
