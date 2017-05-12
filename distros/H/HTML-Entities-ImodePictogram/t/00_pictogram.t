use strict;
use Test::More tests => 6;

use HTML::Entities::ImodePictogram qw(:all);

# てすと[晴れ][曇り]てすと
my $raw  = "\x82\xc4\x82\xb7\x82\xc6\xf8\x9f\xf8\xa0\x82\xc4\x82\xb7\x82\xc6";
my $html = "\x82\xc4\x82\xb7\x82\xc6&#63647;&#63648;\x82\xc4\x82\xb7\x82\xc6";

is(encode_pictogram($raw), $html);
is(decode_pictogram($html), $raw);
is(length(remove_pictogram($raw)), 6 * 2);

my $text = $raw;
my(@bin, @num);
my $num_found = find_pictogram($text, sub { push @bin, $_[0]; push @num, $_[1]; });

is_deeply \@bin, ["\xf8\x9f", "\xf8\xa0"];
is_deeply \@num, [ 63647, 63648 ];
is($num_found, 2);



