use strict;
use warnings;
use Test::More;
use Fluent::LibFluentBit;

my $y2020= 1577836800;
ok( my $flb= Fluent::LibFluentBit::flb_create(), 'flb_create' );
ok( (my $in_ffd= $flb->flb_input("lib", undef)) >= 0, 'flb_input' );
ok( (my $out_ffd= $flb->flb_output("stdout", undef)) >= 0, 'flb_output' );
ok( $flb->flb_start >= 0, 'flb_start' );
ok( $flb->flb_lib_push($in_ffd, qq|[ $y2020, { "message":"Hello World" } ]|) >= 0, 'flb_lib_push' );
ok( $flb->flb_stop >= 0, 'flb_stop' );
ok( eval { undef $flb; 1; }, 'flb_destroy via undef' );

done_testing;
