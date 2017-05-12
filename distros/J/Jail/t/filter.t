# -*- mode: perl -*-

use Jail;

print "1..27\n";

$img = new Jail();
print "ok " . ++$n . "\n";

if (!$img->load("t/spam.jpg")) {
    die($img->getErrorString());
} else {
    print "ok " . ++$n . ", loaded spam.jpg\n";
}


$dupImg = $img->duplicate();
if ($img->getWidth() != $dupImg->getWidth()) {
    die("Error while duplicate");
} else {
    print "ok " . ++$n . ", duplicate\n";
}

if (!$img->edgeDetection()) {
    die($img->getErrorString());
} else {
    print "ok " . ++$n . ", edgeDetection\n";
}

if (!$img->rotateZoom(45, 0.8, 0.8)) {
    die($img->getErrorString());
} else {
    print "ok " . ++$n . ", rotateZoom\n";
}

if (!open(FILE,">/tmp/jail_f0.jpg")) {
    die "cant open file /tmp/jail_f0.jpg: $!";
}

if (!$img->saveFile(FILE,"JFIF")) {
    die($img->getErrorString());
} else {
    print "ok " . ++$n . ", saved in fhandle /tmp/jail_f0.jpg\n";
}
close(FILE);

$img = $dupImg->duplicate();
if ($img->getWidth() != $dupImg->getWidth()) {
    die("Error while duplicate2");
} else {
    print "ok " . ++$n . ", duplicate\n";
}

for ($i=1;$i<4;$i++) {
    if (!$img->sharp($i)) {
	die($img->getErrorString());
    } else {
	print "ok " . ++$n . ", sharp $i\n";
    }

    $file = "/tmp/jail_f${i}.gif";

    if (!$img->save($file,"GIF")) {
	die($img->getErrorString());
    } else {
	print "ok " . ++$n . ", saved in $file\n";
    }   
}

$img = $dupImg->duplicate();
if ($img->getWidth() != $dupImg->getWidth()) {
    die("Error while duplicate3");
} else {
    print "ok " . ++$n . ", duplicate\n";
}

if (!$img->blur()) {
    die($img->getErrorString());
} else {
    print "ok " . ++$n . ", edgeDetection\n";
}

if (!$img->save("/tmp/jail_f4.rgb","RGB")) {
    die($img->getErrorString());
} else {
    print "ok " . ++$n . ", saved in /tmp/jail_f4.rgb\n";
}

$img = $dupImg->duplicate();
if ($img->getWidth() != $dupImg->getWidth()) {
    die("Error while duplicate4");
} else {
    print "ok " . ++$n . ", duplicate\n";
}

if (!$img->compass(90)) {
    die($img->getErrorString());
} else {
    print "ok " . ++$n . ", compass\n";
}

if (!$img->save("/tmp/jail_f5.jpg","JFIF")) {
    die($img->getErrorString());
} else {
    print "ok " . ++$n . ", saved in /tmp/jail_f5.jpg\n";
}

$img = $dupImg->duplicate();
if ($img->getWidth() != $dupImg->getWidth()) {
    die("Error while duplicate5");
} else {
    print "ok " . ++$n . ", duplicate\n";
}

if (!$img->laplace()) {
    die($img->getErrorString());
} else {
    print "ok " . ++$n . ", laplace\n";
}

if (!$img->save("/tmp/jail_f6.jpg","JFIF")) {
    die($img->getErrorString());
} else {
    print "ok " . ++$n . ", saved in /tmp/jail_f6.jpg\n";
}
