use strict;
use Test::Base;

use Encode;
use Lingua::JA::Hepburn::Passport;

sub hepburn {
    Lingua::JA::Hepburn::Passport->new( strict => 1 )->romanize( decode_utf8($_[0]) );
}

filters {
    input => [ 'chomp' ],
    expected => [ 'chomp' ],
};

plan tests => 1 * blocks;

run {
    my $block = shift;
    eval { hepburn($block->input) };
    ok $@, encode_utf8($@);
}

__END__

===
--- input
ほっtち

===
--- input
Foo Bar

===
--- input
ぁぃぅ
