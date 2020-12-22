use warnings;
use strict;
use FindBin '$Bin';
use Test::More;
use Image::PNG::Libpng ':all';

BEGIN: {
    use lib "$Bin";
    use IPNGLT;
};

chunk_ok ('cHRM');

my $image = "$Bin/libpng/ccwn2c08.png";
my $rpng = create_read_struct ();
open my $ifh, "<:raw", $image or die $!;
init_io ($rpng, $ifh);
read_png ($rpng);
close $ifh or die $!;
my $valid = get_valid ($rpng);
ok ($valid->{cHRM}, "has cHRM chunk");
#for my $k (keys %$valid) {
#    print "$k -> $valid->{$k}\n";
#}
my $cHRM = get_cHRM ($rpng);
# Spot check
ok ($cHRM->{green_x} - 0.3 < 0.001, "Green X value OK");

#for my $k (keys %$cHRM) {
#    print "$k -> $cHRM->{$k}\n";
#}
done_testing ();
