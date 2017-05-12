
use Config;



my $script = <<'EO_SCRIPT';
~~startperl~~

use LEGO::RCX;

my $rcx = new LEGO::RCX();

print "
This sample expects you to have a motor attached to output
A.
";
print "Hit Enter to continue> "; <STDIN>;

print "Motor Should be going forward\n";
$rcx->motorDir( "A", "forward" );
$rcx->motorOn( "A" );

print "Hit enter to Stop Motor> "; <STDIN>;
$rcx->motorOff( "A" );

print "Hit enter to Reverse Motor> "; <STDIN>;
$rcx->motorDir( "A", "reverse" );
$rcx->motorOn( "A" );


print "Hit enter to Toggle Motor Dir> "; <STDIN>;
$rcx->motorDir( "A", "toggle" );

print "Hit enter to Stop Motor> "; <STDIN>;
$rcx->motorOff( "A" );

print "Now try to tur the motors axel. It should be hard
to turn

";
print "Hit enter to Float the Motor> "; <STDIN>;
$rcx->motorFloat( "A" );
print "Now the motors axel should turn quite freely.\n";

print "\n\nThe End\n";

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
