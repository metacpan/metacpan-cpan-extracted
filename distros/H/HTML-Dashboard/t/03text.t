
use Test::More tests => 2;
use HTML::Dashboard;

my $data = [ [ 'A',  0, 'foo', 3.12, 'smith' ],
	     [ 'B',  1, 'bar', 6.22, 'smith' ],
	     [ 'C',  2, 'gzx', 3.16, 'smith' ],
	     [ 'D',  3, 'baz', 7.12, 'allan' ],
	     [ 'E',  4, 'bnk', 3.47, 'allan' ],
	     [ 'F',  5, 'hue', 4.18, 'joedo' ],
	     [ 'G',  6, 'gzi', 3.13, 'joedo' ],
	     [ 'H',  7, 'fct', 7.15, 'joedo' ],
	     [ 'I',  8, 'blo', 2.42, 'joedo' ] ];

my $dash;

# ------------------------------------------------------------
# All default - as text

$dash = HTML::Dashboard->new();
$dash->set_data_without_captions( $data );

my $val;
foreach my $row ( @{ $data } ) {
  $val .= join( "\t", @{ $row } ) . "\n"
}
# chop $val; NOT! the last newline is not chopped, text ends with newline!

print ",$val,\n", $dash->as_text(), "\n";

ok( $dash->as_text() eq $val );

# ------------------------------------------------------------
# Escaping...

my $str1 = "a\tb\nc\td\n\\\tx";
my $str2 = $str1;
$str2 =~ s/([\t\n\\])/\\$1/g;
$str2 .= "\n"; # Trailing newline, as before...

$dash = HTML::Dashboard->new();
$dash->set_data_without_captions( [[ $str1 ]] );

ok( $dash->as_text() eq $str2 );
