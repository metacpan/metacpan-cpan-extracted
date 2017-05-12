BEGIN { $| = 1; print "1..1\n"; }
use Lingua::Ident;

if (-d "data")
{
   $datadir = 'data';
}
elsif (-d "../data")
{
   $datadir = '../data';
}
else
{
   $datadir = "Cannot find data directory";
}

$ident = new Lingua::Ident("$datadir/data.de", "$datadir/data.en",
                           "$datadir/data.it", "$datadir/data.fr",
                           "$datadir/data.ko", "$datadir/data.zh");

$lang = $ident->identify("Ein Beamter geht zu den drei Männern.");

if($lang eq "de.iso-8859-1")
{
   print "ok 1\n";
}
else
{
   print "not ok 1\n";
}
