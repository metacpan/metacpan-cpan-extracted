#!perl
#
# Simple LCD demonstration script
#

use Device::BCM2835::LCD;

$foo = Device::BCM2835::LCD->new();
print "Display init: B+ GPIO map, default pins, 20 x 4 screen\n";
$foo->init(
    pin_rs  => RPI_GPIO_P1_24,
    pin_e   => RPI_GPIO_P1_23,
    pin_d4  => RPI_GPIO_P1_07,
    pin_d5  => RPI_GPIO_P1_11,
    pin_d6  => RPI_GPIO_P1_13,
    pin_d7  => RPI_GPIO_P1_15,
    RPI_PIN => V1,
    Display => 2004
);

#$foo->debug(1);
$foo->ClearDisplay;
print "PutMsg/SetPos:\n";
$foo->PutMsg("Device::BCM2835::LCD");
$foo->SetPos( 2, 0 );
$foo->PutMsg("version 0.02");
$foo->SetPos( 4, 0 );
$foo->PutMsg("Bignum demo in ");

for ( $i = 9 ; $i > 0 ; $i-- ) {
    $foo->SetPos( 4, 15 );
    $foo->PutMsg($i);
    sleep(1);
}
print "Clear display:\n";
$foo->ClearDisplay;
print "Set cursor to home position:\n";
$foo->SetPos( 1, 0 );

print "Loading Bignum font CGRAM chars:\n";
$foo->PutMsg("Loading custom");
$foo->SetPos( 2, 0 );
$foo->PutMsg("CGRAM characters");
$foo->LoadCGRAM;
$foo->delay(1000);

print "Bignums:\n";
for ( $i = 0 ; $i < 10 ; $i++ ) {
    $foo->ClearDisplay;
    $foo->cmd(0x81);
    $foo->BigNum( 0, $i );
    $foo->delay(500);
}
print "reset display:\n";

$foo->delay(500);
$foo->ClearDisplay;
$foo->cmd(0x81);

print "Bignum+chars:\n";
for ( $k = 0 ; $k < 100 ; $k++ ) {
    $num = "00" . $k;
    $j = substr( $num, -3, 3 );
    $foo->BigNum( 0, 0 );
    $foo->BigNum( 1, substr( $j, 0, 1 ) );
    $foo->BigNum( 2, substr( $j, 1, 1 ) );
    $foo->BigNum( 3, substr( $j, 2, 1 ) );
    $foo->SetPos( 1, 17 );
    $foo->PutMsg($j);
    $foo->delay(25);
}
$foo->ClearDisplay;
$foo->delay(100);
print "Alternate big/small chars:\n";
for ( $i = 0 ; $i < 10 ; $i++ ) {
    $foo->BigNum( 0, $i );
    $foo->BigNum( 1, $i );
    $foo->BigNum( 2, $i );
    $foo->BigNum( 3, $i );
    $foo->BigNum( 4, $i );
    $foo->delay(250);
    $foo->SetPos( 1, 0 );
    $foo->PutMsg( "$i" x 80 );
    $foo->delay(250);
    $foo->ClearDisplay;
    $foo->delay(5);
}
print "Clear display:\n";
$foo->ClearDisplay;
$foo->SetPos( 1, 0 );
$foo->PutMsg("LCD demo complete.");
print "flash screen:\n";
for ( $i = 0 ; $i < 10 ; $i++ ) {
    $foo->cmd(8);
    $foo->delay(300);
    $foo->cmd(12);
    $foo->delay(300);
}
print "Demo complete.\n";
