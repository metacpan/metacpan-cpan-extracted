use strict;
use warnings;
 
$| = 1;
 
my $x = 11;
my $q = f("foo\nbar");
$x++;
my @q = g( 'baz', "foo\nbar", 'moo' );
$x++;
my %q = h( bar => "foo\nbar", moo => 42 );
$x++;
 
 
sub f {
    my ($in) = @_;
    my $x = 1;
    return $in;
}
 
sub g {
    my (@in) = @_;
    my $x = 1;
    return @in;
}
 
sub h {
    my (%in) = @_;
    my $x = 1;
    return %in;
}
