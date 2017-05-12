#!perl

use strict;
use warnings;
use Test::More;

use Test::More tests => 12;
use Filter::Heredoc qw ( hd_labels );

my %marker;

# read out the default labels
%marker = hd_labels();

is( $marker{source}, q{S}, 'default source marker');
is( $marker{ingress}, q{I}, 'default ingress marker');
is( $marker{heredoc}, q{H}, 'default heredoc marker');
is( $marker{egress}, q{E}, 'default egress marker');

#change to new labels
%marker = (
        source => q{1},
        ingress => q{2},
        heredoc => q{3},
        egress => q{4},
);   
hd_labels ( %marker );   # sets our new labels

# read out the new defaults
is( $marker{source}, q{1}, 'new source marker');
is( $marker{ingress}, q{2}, 'new ingress marker');
is( $marker{heredoc}, q{3}, 'new heredoc marker');
is( $marker{egress}, q{4}, 'new egress marker');

# read out again (check persitance)
is( $marker{source}, q{1}, 'new source marker');
is( $marker{ingress}, q{2}, 'new ingress marker');
is( $marker{heredoc}, q{3}, 'new heredoc marker');
is( $marker{egress}, q{4}, 'new egress marker');




