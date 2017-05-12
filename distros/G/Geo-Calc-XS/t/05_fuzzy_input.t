use strict;
use warnings FATAL => 'all';
use utf8;

use Test::More;
BEGIN {
    my $needed_modules = [ 'Test::Exception', 'Data::Dumper' ];
    foreach my $module ( @{ $needed_modules } ) {
        eval "use $module";
        if ($@) {
            plan skip_all => join( ', ', @{ $needed_modules } ). " are needed";
        }
    }
}

use_ok 'Geo::Calc::XS';

my $gc = Geo::Calc::XS->new(lat => 3.2, lon => 54);

# Note that warnings are turned into exceptions

my @methods = (qw(
    bearing_to
    boundry_box
    destination_point
    distance_at
    distance_to
    final_bearing_to
    get_lat
    get_lon
    get_radius
    get_units
    intersection
    midpoint_to
    rhumb_bearing_to
    rhumb_destination_point
    rhumb_distance_to
));

foreach my $method (@methods) {
    my @random_args;
    for my $i (0 .. (rand(10) + 1)) {
        push @random_args, "zzz" . random_string();
    }

    dies_ok { $gc->$method(@random_args) } "$method(\@random_args) died but did not segfault"
        or diag(Dumper(\@random_args));
}

foreach my $method (@methods) {
    my $rh_random_arg = {};
    for my $i (0 .. (rand(5) * 2 + 1)) {
        $rh_random_arg->{"zzz" . random_string()} = "zzz" . random_string();
    }

    dies_ok { $gc->$method($rh_random_arg) } "$method(\$rh_random_arg) died but did not segfault";
}


foreach my $ra_new_args (
        [],
        [ lon => 2.3 ],
        [ lat => 4, lon => 24, 'uneven' ],
        [ lat => 4, lon => 5, unexpected => 4 ],
        [ lat => 2, lat => 4 ]
    ) {
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Useqq = 1;
    local $Data::Dumper::Indent = 0;
    my $dumped = join(", ", map { Dumper( $_ ) } @$ra_new_args);
    dies_ok { Geo::Calc::XS->new( @{ $ra_new_args } ) } "Geo::Calc::XS->new( $dumped ) died but did not segfault";
}

done_testing();



sub random_string {
    my $length = rand(10)+6;
    my $str = "";
    for my $i (1..$length) {
        $str .= chr(ord('a') + rand(26));
    }
    return $str;
}
