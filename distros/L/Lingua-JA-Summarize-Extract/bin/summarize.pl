use strict;
use warnings;

use lib 'lib';
use Lingua::JA::Summarize::Extract;

my $text = join '', <>;

my $smlz = Lingua::JA::Summarize::Extract->extract($text);
my $ret =  "$smlz";
utf8::encode($ret);
print $ret;
