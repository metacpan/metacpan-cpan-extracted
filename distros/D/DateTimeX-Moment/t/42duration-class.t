use strict;
use warnings;

use Test::More skip_all => 'unsupported';
use DateTimeX::Moment;

{

    package DateTime::MySubclass;
    use base 'DateTimeX::Moment';

    sub duration_class {'DateTimeX::Moment::Duration::MySubclass'}

    package DateTimeX::Moment::Duration::MySubclass;
    use base 'DateTimeX::Moment::Duration';

    sub is_my_subclass {1}
}

my $dt    = DateTime::MySubclass->now;
my $delta = $dt - $dt;

isa_ok( $delta,       'DateTimeX::Moment::Duration::MySubclass' );
isa_ok( $dt + $delta, 'DateTime::MySubclass' );

my $delta_days = $dt->delta_days($dt);
isa_ok( $delta_days, 'DateTimeX::Moment::Duration::MySubclass' );

done_testing();
