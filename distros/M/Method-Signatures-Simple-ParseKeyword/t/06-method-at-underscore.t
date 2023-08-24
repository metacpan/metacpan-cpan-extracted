
use strict;
use warnings;
use Test::More;

{
    package My::Obj;
    use Method::Signatures::Simple::ParseKeyword;

    method new ($class:) {
        bless {}, $class;
    }
    method met  {
        return @_;
    }
}
my $m = My::Obj->new;
my @c = $m->met(3,4,5);
is_deeply \@c, [3,4,5];
my $c = $m->met(1,2,3,4);
is $c, 4;

done_testing;


