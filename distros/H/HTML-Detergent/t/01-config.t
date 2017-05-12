#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 4;

use_ok('HTML::Detergent::Config');

my %links = (
    'dct:author' => 'John Q. Winning',
    'dct:subject' => [qw(puppies kitties unicorns)],
);

my $cfg = HTML::Detergent::Config->new(
    match => [qw(/foo /bar), [qw(/bitz /stuff.xsl)]],
    link  => \%links,
);

is($cfg->stylesheet('/bitz'), '/stuff.xsl', 'map coercion works');

is_deeply([$cfg->matches], [qw(/foo /bar /bitz)], '"matches" matches');

#require Data::Dumper;
#diag(Data::Dumper::Dumper($cfg->links));

# the single value should be coerced into an array ref
is_deeply($cfg->links,
          { %links, 'dct:author' => ['John Q. Winning'] }, 'links match');

# by induction the meta tags should work too
