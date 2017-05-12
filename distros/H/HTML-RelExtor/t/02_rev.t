use strict;
use Test::Base;

use HTML::RelExtor;
plan 'no_plan';

filters { expected => 'yaml' };

run {
    my $block = shift;
    my $p = HTML::RelExtor->new(base => $block->base || undef);
    $p->parse($block->input);

    my @links = $p->links;
    my @data  = map {
        +{ tag => $_->tag, href => $_->href, rev => [ $_->rev ] }
    } @links;

    is_deeply \@data, $block->expected;
}

__END__

=== rev=canoncial
--- input
<link rev="canonical" href="http://flic.kr/foo" />

--- expected
- tag: link
  href: http://flic.kr/foo
  rev: [ canonical ]

=== rev=made
--- input
<link rev="made" href="mailto:miyagawa@cpan.org" />

--- expected
- tag: link
  href: mailto:miyagawa@cpan.org
  rev: [ made ]
