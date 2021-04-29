use FindBin '$Bin';
use lib $Bin;
use JCT;

my @funky = ("8.5", "9", "10.5");
my @copy;
for (@funky) {
    $_ = int ($_);
    push @copy, int ($_);
}
# http://mikan/bugs/bug/2375
my $funkyjson = create_json (\@funky);
unlike ($funkyjson, qr!"!,
	'Remove quotes from numbers where "int" has been applied');
# This was OK already.
my $copyjson = create_json (\@copy);
unlike ($copyjson, qr!"!);
done_testing ();
