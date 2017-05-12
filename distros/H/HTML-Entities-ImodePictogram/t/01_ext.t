use strict;
use Test::More tests => 9;

use HTML::Entities::ImodePictogram qw(:all);

# てすと[iアプリ][iアプリ(枠付き)][カメラ]てすと
my $raw  = "\x82\xc4\x82\xb7\x82\xc6\xf9\xb1\xf9\xb2\xf8\xe2\x82\xc4\x82\xb7\x82\xc6";
my $con_html = "\x82\xc4\x82\xb7\x82\xc6&#xe70c;&#xe70d;&#63714;\x82\xc4\x82\xb7\x82\xc6";
my $uni_html = "\x82\xc4\x82\xb7\x82\xc6&#xe70c;&#xe70d;&#xe681;\x82\xc4\x82\xb7\x82\xc6";

is(encode_pictogram($raw), $con_html, "co-existing &#xFFFF; and &#NNNNN;");
is(encode_pictogram($raw, unicode => 1), $uni_html, "unicode => 1");
is(decode_pictogram($con_html), $raw, "decode co-exiting");
is(decode_pictogram($uni_html), $raw, "decode unicode");
is(length(remove_pictogram($raw)), 6 * 2);

my $text = $raw;
my(@bin, @num, @cp);
my $num_found = find_pictogram($text, sub {
				   push @bin, $_[0];
				   push @num, $_[1];
				   push @cp, $_[2];
			       });

is_deeply \@bin, ["\xf9\xb1", "\xf9\xb2", "\xf8\xe2"];
is_deeply \@num, [ 63921, 63922, 63714 ];
is_deeply \@cp, [ 59148, 59149, 59009 ];
is($num_found, 3);
