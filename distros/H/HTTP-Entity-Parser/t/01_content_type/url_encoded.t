use strict;
use warnings;
use Test::More;
use HTTP::Entity::Parser::UrlEncoded;
use JSON::MaybeXS;

while (<DATA>) {
    chomp;
    next unless $_;
    my ($s,$t) = split /\s+=>\s/, $_,2;
    $s =~ s/'//g;
    my $parser = HTTP::Entity::Parser::UrlEncoded->new();
    $parser->add($s);
    my ($params, $uploads) = $parser->finalize();
    is encode_json($params), $t, $s;
    is_deeply $uploads, [];
}

done_testing;

__DATA__
'a=b&c=d'     => ["a","b","c","d"]
'a=b;c=d'     => ["a","b","c","d"]
'a=1&b=2;c=3' => ["a","1","b","2","c","3"]
'a==b&c==d'   => ["a","=b","c","=d"]
'a=b& c=d'    => ["a","b","c","d"]
'a=b; c=d'    => ["a","b","c","d"]
'a=b; c =d'   => ["a","b","c ","d"]
'a=b;c= d '   => ["a","b","c"," d "]
'a=b&+c=d'    => ["a","b"," c","d"]
'a=b&+c+=d'   => ["a","b"," c ","d"]
'a=b&c=+d+'   => ["a","b","c"," d "]
'a=b&%20c=d'  => ["a","b"," c","d"]
'a=b&%20c%20=d' => ["a","b"," c ","d"]
'a=b&c=%20d%20' => ["a","b","c"," d "]
'a&c=d'       => ["a","","c","d"]
'a=b&=d'      => ["a","b","","d"]
'a=b&='       => ["a","b","",""]
'&'           => ["","","",""]
'='           => ["",""]
''            => []

