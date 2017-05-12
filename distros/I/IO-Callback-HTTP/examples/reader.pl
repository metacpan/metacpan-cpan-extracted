use 5.010;
use strict;
use IO::Callback::HTTP;

my $fh = IO::Callback::HTTP->new("<", "http://www.example.com/");

while (my $line = <$fh>)
{
	print $line;
}
