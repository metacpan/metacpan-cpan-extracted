use diagnostics;
use strict;
use warnings;
use Test::More tests => 4;
BEGIN {
    use_ok('Digest::SHA2')
};

BEGIN {
    open INFILE, "t/file08.dat";
    my $sha2obj = new Digest::SHA2;
    $sha2obj->addfile(*INFILE);
    my $digest = $sha2obj->hexdigest();
    is("e4326d0459653d7d3514674d713e74dc3df11ed4d30b4013fd327fdb9e394c26",
        $digest);

    close INFILE;

    open INFILE, "t/file08.dat";
    my $sha2obj2 = new Digest::SHA2 384;
    $sha2obj2->addfile(*INFILE);
    my $digest2 = $sha2obj2->hexdigest();
    is("1ca650f38480fa9dfb5729636bec4a935ebc1cd4c0055ee50cad2aa627e066871044fd8e6fdb80edf10b85df15ba7aab",
        $digest2);

    close INFILE;

    open INFILE, "t/file08.dat";
    my $sha2obj3 = new Digest::SHA2 512;
    $sha2obj3->addfile(*INFILE);
    my $digest3 = $sha2obj3->hexdigest();
    is("d399507bbf5f2d0da51db1ff1fc51c1c9ff1de0937e00d01693b240e84fcc3400601429f45c297acc6e8fcf1e4e4abe9ff21a54a0d3d88888f298971bd206cd5",
        $digest3);

    close INFILE;
};

