use strict;
use utf8;
use warnings;

use JavaBin;
use Test::More;

my $string = "Grüßen";

my $bytes = do { no utf8; "Grüßen" };

isnt $string, $bytes, 'string ne bytes';

my $string_bin = to_javabin $string;
my $bytes_bin  = to_javabin $bytes;

is $string_bin, $bytes_bin, 'to_javabin(string) eq to_javabin(bytes)';

my $string_again = from_javabin $string_bin;
my $bytes_again  = from_javabin $bytes_bin;

is $string_again, $bytes_again, 'from(to(string)) eq from(to(bytes))';

is $string_again, $string, 'from(to(string)) eq string';
is $bytes_again, $string, 'from(to(bytes)) eq string';

done_testing;
