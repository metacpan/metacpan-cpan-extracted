# -*- mode: perl -*-

use Jail;

print "1..8\n";

$dst = new Jail();
print "ok " . ++$n . "\n";

if (!$dst->load("t/pinguin.gif")) {
    die($dst->getErrorString());
} else {
    print "ok " . ++$n . ", loaded pinguin.gif\n";    
}

$msk = new Jail();
print "ok " . ++$n . "\n";

if (!$msk->load("t/mask.gif")) {
    die($msk->getErrorString());
} else {
    print "ok " . ++$n . ", loaded mask.gif\n";    
}

$src = new Jail();
print "ok " . ++$n . "\n";

if (!$src->load("t/sgilogo.gif")) {
    die($src->getErrorString());
} else {
    print "ok " . ++$n . ", loaded sgilogo.gif\n";    
}

if (!$dst->blendImg($src,$msk)) {
    die($dst->getErrorString());
} else {
    print "ok " . ++$n . ", blending\n";    
}

if (!$dst->save("/tmp/jail_b0.rgb","RGB")) {
    die($dst->getErrorString());
} else {
    print "ok " . ++$n . ", saved /tmp/jail_b0.rgb ".$dst->getErrorString()."\n";
}

