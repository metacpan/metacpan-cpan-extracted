#!perl
# https://rt.cpan.org/Public/Bug/Display.html?id=58030
use strict;
use warnings;
use Test::More;

use if $] < 5.010_000, 'Test::More', skip_all => 'Perl 5.8.8 triggers stringification';

my $stringified = 0;
{
    package Foo;

    use overload '""' => \&stringify;

    sub new { bless {}, shift @_ };

    sub stringify {
        #use Carp qw(cluck); cluck "stringified";
        $stringified++;
        'foo';
    };

}

use Hash::FieldHash qw[ fieldhash ];

fieldhash my %h;

my $x = Foo->new;
my $y = Foo->new;

$h{$x} = 'X';
$h{$y} = 'Y';

#use Data::Dumper; print Dumper \%h;

is $h{$x}, 'X';
is $h{$y}, 'Y';

is $stringified, 0, 'not stringified';

done_testing;
