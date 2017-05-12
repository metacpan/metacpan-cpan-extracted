# -*- mode: perl -*-

use Jail;

print "1..18\n";

$img = new Jail();
print "ok " . ++$n . "\n";

if (!$img->load("t/capture.gif")) {
    die($img->getErrorString());
} else {
    print "ok " . ++$n . ", loaded capture.gif\n";
}

if (!($font = openBDF Font ("t/helvetica26.bdf"))) {
    die($font->getErrorString());
} else {
    print "ok " . ++$n . ", opened helvetica26.bdf\n";
}
$count1=$count2=0;
if (!($text1 = $font->getText("karo",$count1))) {
    die($font->getErrorString());
} else {
    print "ok " . ++$n . ", got text1\n";
}

if (!($text2 = $font->getText("\@artcom.net",$count2))) {
    die($font->getErrorString());
} else {
    print "ok " . ++$n . ", got text2\n";
}

if (!($glyph1 = merge Glyph ($text1, $count1))) {
    die("cant merge glyphlist");
} else {
    print "ok " . ++$n . ", merged 1\n";
}

if (!($glyph2 = merge Glyph ($text2, $count2))) {
    die("cant merge glyphlist");
} else {
    print "ok " . ++$n . ", merged 2\n";
}

$glyph1->setForeground(255,0,0);
print "ok " . ++$n . "\n";

$glyph2->setForeground(30,30,255);
print "ok " . ++$n . "\n";

$jg = new JailGlyph();
print "ok " . ++$n . "\n";

if (!$jg->addGlyph($glyph1)) {
    die("cant add glyph");
} else {
    print "ok " . ++$n . " added Glyph 1\n";
}

if (!$jg->addGlyph($glyph2)) {
    die("cant add glyph");
} else {
    print "ok " . ++$n . " added Glyph 2\n";
}

$wi = $img->getWidth();
$hi = $img->getHeight();
$wg = $jg->getWidth();
$hg = $jg->getHeight();

if (!$wi || !$hi || !$wg || !$hg) {
    die ("hmm cant get props");
} else {
    print "ok " . ++$n . "\n";    
}

$glyph1->setBackground(10,140,80);
print "ok " . ++$n . "\n";

if (!($newImg = $jg->createImg())) {
    die($jg->getErrorString());
} else {
    print "ok " . ++$n . ", new image created\n";
}

$glyph1->setBackground(0,0,0,255);

if (!$newImg->save("/tmp/jail_bf0.rgb","RGB")) {
    die($img->getErrorString());
} else {
    print "ok " . ++$n . ", saved in /tmp/jail_bf0.rgb\n";
}

if (!$jg->blittInImage($img, $wi/2 - $wg/2, $hi/2 - $hg/2)) {
    die($jg->getErrorString());
} else {
    print "ok " . ++$n . ", blitted\n";
}

if (!$img->save("/tmp/jail_bf1.jpg","JFIF")) {
    die($img->getErrorString());
} else {
    print "ok " . ++$n . ", saved in /tmp/jail_bf1.jpg\n";
}
