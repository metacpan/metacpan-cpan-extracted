#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Gzip::Faster;
my $gf = Gzip::Faster->new ();
$gf->file_name ("blash.gz");
my $something = $gf->zip ("stuff");
my $no = $gf->file_name ();
if ($no) {
    print "WHAT?\n";
}
else {
    print "The file name has been deleted by the call to zip.\n";
}
my $gf2 = Gzip::Faster->new ();
$gf2->unzip ($something);
my $file_name = $gf2->file_name ();
print "Got back file name $file_name\n";
