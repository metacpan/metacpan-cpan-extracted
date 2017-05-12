use warnings;
use Encode;
use Test::More tests => 1;
use HTML::Truncate;

my $html = <<"";
<dl>
<dt><a href="http://lumberjaph.net/blog/index.php/2009/05/13/a-simple-feed-aggregator-with-modern-perl-part-4/">A simple feed aggregator with modern Perl - part 4</a></dt>
<dd>
We have the model, the aggregator (and some tests), now we can do a basic frontend to read our feed. For this I will create a webapp using <a href="http://www.catalystframework.org/">Catalyst</a>.
<a href="http://search.cpan.org/~flora/Catalyst-Devel-1.13/lib/Catalyst/Devel.pm">…<a class="readmore" href="http://lumberjaph.net/blog/index.php/2009/05/13/a-simple-feed-aggregator-with-modern-perl-part-4/">[more]</a></a>
<div class="datetime">
2009.05.13 7:44PM
</div>
</dd>
</dl>

my $expected = <<"";
<dl>
<dt><a href="http://lumberjaph.net/blog/index.php/2009/05/13/a-simple-feed-aggregator-with-modern-perl-part-4/">A simple feed aggregator with modern Perl - part 4</a>…<a href="/a/link/somewhere">[more]</a></dt></dl>

my $ht = HTML::Truncate->new();
$ht->chars(50);
$ht->ellipsis(chr(8230) . '<a href="/a/link/somewhere">[more]</a>');

TODO: {
    local $TODO = "Known bug: treating ellipsis as element not yet supported";
    is( Encode::encode_utf8( $ht->truncate($html) ),
        Encode::encode_utf8( $expected ),
       "Output properly closes <a/> before appending ellipsis");
};

__END__

$ht->repair(1);

ok( $ht->repair, '$ht->repair(1)' );

$ht->repair();

ok( $ht->repair, 'No change' );

$ht->repair(0);

ok( !$ht->repair, '$ht->repair(0)' );

$ht->repair(1);

for my $key (sort keys %{$cases}) {
    is( $ht->truncate($cases->{$key}->[0]), $cases->{$key}->[1],
        "Repaired case $key");
}

1;
