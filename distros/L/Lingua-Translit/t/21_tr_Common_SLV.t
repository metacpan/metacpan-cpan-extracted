use strict;
use Test::More tests => 3;

my $name	=   "Common SLV";

# Taken from http://www.unhchr.ch/udhr/lang/slv.htm
my $input	=   "ker sta zanikanje in teptanje človekovih pravic " .
		    "pripeljala do barbarskih dejanj, žaljivih za " .
		    "človeško vest, in ker je bila stvaritev sveta, " .
		    "v katerem bi imeli vsi ljudje svobodo govora " .
		    "in verovanja in v katerem ne bi živeli v strahu " .
		    "in pomanjkanju, spoznana za najvišje prizadevanje " .
		    "človeštva;";
my $output_ok	=   "ker sta zanikanje in teptanje clovekovih pravic " .
		    "pripeljala do barbarskih dejanj, zaljivih za " .
		    "clovesko vest, in ker je bila stvaritev sveta, " .
		    "v katerem bi imeli vsi ljudje svobodo govora in " .
		    "verovanja in v katerem ne bi ziveli v strahu " .
		    "in pomanjkanju, spoznana za najvisje prizadevanje " .
		    "clovestva;";

my $all_caps	=   "KITAJSKA PUŠČAVSKA MAČKA";
my $all_caps_ok	=   "KITAJSKA PUSCAVSKA MACKA";


use Lingua::Translit;

my $tr = new Lingua::Translit($name);


my $output = $tr->translit($input);

# 1
is($tr->can_reverse(), 0, "$name: not reversible");

# 2
is($output, $output_ok, "$name: UDOHR transliteration");

my $o = $tr->translit($all_caps);

# 3
is($o, $all_caps_ok, "$name: all caps");

