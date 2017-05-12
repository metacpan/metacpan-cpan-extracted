#!/home/ben/software/install/bin/perl
use warnings;
use strict;

# This makes the contents of tEXT.t.

my @tests = (

{
file => 'ct0n0g04',
comment => 'no textual data',

},
{
file => 'ct1n0g04',
comment => 'with textual data',
},
{
file => 'ctzn0g04',
comment => 'with compressed textual data',
},
{
file => 'cten0g04',
comment => 'english',
},
{
file => 'ctfn0g04',
comment => 'finnish',
},
{
file => 'ctgn0g04',
comment => 'greek',
},
{
file => 'cthn0g04',
comment => 'hindi',
},
{
file => 'ctjn0g04',
comment => 'japanese',
},
);

for my $test (@tests) {
    my $png = read_png_file ("$FindBin::Bin/libpng/$test->{file}.png");
    my $texts = $png->get_text ();
    print "{\n";
    print "file => '$test->{file}',\n";
    print "comment => '$test->{comment}',\n";
    if ($texts) {
	print "chunks => [\n";
	for my $text (@$texts) {
	    print "{\n";
	    for my $key (keys %$text) {
		my $v = $text->{$key};
		if (! defined $v) {
		    $v = 'undef';
		}
		elsif (! looks_like_number ($v)) {
		    $v =~ s/'/\\'/g;
		    $v = "'$v'";
		}
		print "$key => $v,\n";
	    }
	    print "},\n";
	}
	print "],\n";
    }
    else {
	print "empty => 1,\n";
    }
    print "},\n";
}

