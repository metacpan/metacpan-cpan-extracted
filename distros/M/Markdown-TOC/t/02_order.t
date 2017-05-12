use strict;
use Test::More;
use Markdown::TOC;

my $toc_array = [];
my $handler = sub {
    my %p = @_;
    push @$toc_array, $p{order_formatted};
};


my $toc = Markdown::TOC->new(handler => $handler);

my $md = q{
# first level
## second level
## second level 2
### third level
## second level 3
# first level 2
};

$toc->process($md);
is_deeply $toc_array, ['1. ', '1.1. ', '1.2. ', '1.2.1. ', '1.3. ', '2. '];

done_testing;
