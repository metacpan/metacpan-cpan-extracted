#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper;
use Hash::Convert;

my $rules = {
    visit   => { from => 'created_at' },
    count   => { from => 'count', via => sub { $_[0] + 1 }, default => 1 },
    visitor => {
        contain => {
            name => { from => 'name' },
            mail => { from => 'mail' },
        },
        default => {
            name => 'anonymous',
            mail => 'anonymous',
        }
    },
    price => {
        from => [qw/item.cost item.discount/],
        via => sub {
            my $cost     = $_[0];
            my $discount = $_[1];
            return $cost * ( (100 - $discount) * 0.01 );
        },
    },
};
my $opts = { pass => 'locate' };

my $converter = Hash::Convert->new($rules, $opts);

my $before = {
    created_at => time,
    count      => 1,
    name       => 'hixi',
    mail       => 'hixi@cpan.org',
    locate     => 'JP',
    item => {
        name     => 'chocolate',
        cost     => 100,
        discount => 10,
    },
};
my $after = $converter->convert($before);
print Dumper $after;
#{
#    'visitor' => {
#        'mail' => 'hixi@cpan.org',
#        'name' => 'hixi'
#    },
#    'count' => 2,
#    'visit' => '1377019766',
#    'price' => 90,
#    'locate' => 'JP'
#}
