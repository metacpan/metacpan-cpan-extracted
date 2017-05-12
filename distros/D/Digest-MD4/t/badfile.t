print "1..2\n";

use Digest::MD4 ();

$md4 = Digest::MD4->new;

eval {
   use vars qw(*FOO);
   $md4->addfile(*FOO);
};
print "not " unless $@ =~ /^Bad filehandle: FOO at/;
print "ok 1\n";

open(BAR, "no-existing-file.$$");
eval {
    $md4->addfile(*BAR);
};
print "not " unless $@ =~ /^No filehandle passed at/;
print "ok 2\n";
