
use Config;



my $script = <<'EO_SCRIPT';
~~startperl~~

use LEGO::RCX;

my $rcx = new LEGO::RCX();

print "Let us cycle throught the various types of beeps
in your RCX\n";

my @beepDescription = 
   (
    "Click",
    "Double Beep",
    "Cycle Down",
    "Cycle Up",
    "Low Beep",
    "Cycle Fast Up"
    );
         
                             
for( my $x = 0; $x < @beepDescription; $x ++ ) {
   print "$x is $beepDescription[ $x ]\n";
   $rcx->beep( $x );
   sleep 1;

}

EO_SCRIPT

my $config = {};
$config->{'startperl'} = $Config{'startperl'};

my $file = $0;
$file =~ s/PL$/pl/;

$script =~ s/\~~(\w+)\~~/$config->{$1}/eg;
if (!(open(FILE, ">$file"))  ||
    !(print FILE $script)  ||
    !(close(FILE))) {
    die "Error while writing $file\n";
}
else {
   chmod 0755, $file;
}
