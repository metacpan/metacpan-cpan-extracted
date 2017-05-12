use strict;
use warnings;
use MARC::Charset::Compiler;
print "compiling marc8/utf8 database, please be patient\n";
my $compiler = MARC::Charset::Compiler->new();
$compiler->compile('etc/codetables.xml');
$compiler->compile('etc/additional-iii-characters.xml');
