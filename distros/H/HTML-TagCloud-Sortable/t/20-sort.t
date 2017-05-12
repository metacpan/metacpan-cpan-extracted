use strict;
use Test::More tests => 8;
use_ok('HTML::TagCloud::Sortable');

my $cloud = HTML::TagCloud::Sortable->new;
isa_ok($cloud, 'HTML::TagCloud::Sortable');

my $tags = tags();
# added sort to keys for consistent insertion order
foreach my $tag (sort keys %$tags) {
  my $count = $tags->{$tag};
  my $url   = "/show/$tag";
  $cloud->add($tag, $url, $count);
}

my $html;

$html = $cloud->html( { limit => 3, sort_field => 'count', sort_type => 'numeric' } );
is(lines($html), 5);
is($html, q{<div id="htmltagcloud">
<span class="tagcloud0"><a href="/show/amsterdam">amsterdam</a></span>
<span class="tagcloud0"><a href="/show/diane">diane</a></span>
<span class="tagcloud3"><a href="/show/laptop">laptop</a></span>
</div>});

$html = $cloud->html( { limit => 3, sort_field => 'count', sort_order => 'desc', sort_type => 'numeric' } );
is(lines($html), 5);
is($html, q{<div id="htmltagcloud">
<span class="tagcloud3"><a href="/show/laptop">laptop</a></span>
<span class="tagcloud0"><a href="/show/amsterdam">amsterdam</a></span>
<span class="tagcloud0"><a href="/show/diane">diane</a></span>
</div>});

$html = $cloud->html( { limit => 3, sort_field => sub { $_[ 1 ]->{ count } <=> $_[ 0 ]->{ count } || $_[ 0 ]->{ name } cmp $_[ 1 ]->{ name } } } );
is(lines($html), 5);
is($html, q{<div id="htmltagcloud">
<span class="tagcloud3"><a href="/show/laptop">laptop</a></span>
<span class="tagcloud0"><a href="/show/amsterdam">amsterdam</a></span>
<span class="tagcloud0"><a href="/show/diane">diane</a></span>
</div>});

sub tags {
  return {
    'laptop'                 => 11,
    'diane'                  => 10,
    'grand central station'  => 2,
    'fog'                    => 4,
    'amsterdam'              => 10,
  }
}

sub lines {
  my $text = shift;
  my @lines = split "\n", $text;
  return scalar(@lines);
}
