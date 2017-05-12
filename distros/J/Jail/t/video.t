# -*- mode: perl -*-

use Jail;

print "1..3\n";

$img = new Jail();
print "ok " . ++$n . "\n";

if (!$img->getVideoSnapshot()) {
    die($img->getErrorString());
} else {
    print "ok " . ++$n . ", snapshot\n";
}

if (!$img->save("/tmp/jail_v0.tiff","TIFF")) {
    die($img->getErrorString());
} else {
    print "ok " . ++$n . ", saved /tmp/jail_v0.tiff\n";
}
