use 5.12.0;
use strict;
use warnings FATAL   => 'all';
use Test::More tests => 17;
use FindBin qw/$Bin/;
use File::Spec;

BEGIN {
    use_ok('Lingua::Norms::SUBTLEX') || print "Bail out!\n";
}

diag(
"Testing Lingua::Norms::SUBTLEX $Lingua::Norms::SUBTLEX::VERSION, Perl $], $^X"
);

# Test that all sample data can be located at new() and are readable text files:

my $field_file = File::Spec->catfile($Bin, qw'.. lib Lingua Norms SUBTLEX specs.csv');
ok(-e $field_file, 'Cannot find the required field lookup file: ' . $field_file);

my $subtlex;
for my $langfile(qw/UK.csv US.csv DE.txt FR.txt NL_all.with-pos.csv/) {
    my $path = File::Spec->catfile($Bin, 'samples', $langfile);
    $langfile =~ /^(\w+)\./;
    my $lang = $1;
    ok(-e $path, 'Cannot find the sample SUBTLEX file: ' . $path);
    eval {
    $subtlex =
      Lingua::Norms::SUBTLEX->new(path => $path, fieldpath =>  $field_file, lang => $lang );
};
    ok( !$@, $@ );
    ok( -f $subtlex->{'_PATH'}, 'Could not determine path to sample data file' );
}

1;
