print "1..2\n";

use Digest::MD6 ();

$md6 = Digest::MD6->new;

eval {
   use vars qw(*FOO);
   $md6->addfile(*FOO);
};
print "not " unless $@ =~ /^Bad filehandle: FOO at/;
print "ok 1\n";

open(BAR, "no-existing-file.$$");
eval {
    $md6->addfile(*BAR);
};
print "not " unless $@ =~ /^No filehandle passed at/;
print "ok 2\n";
