use Test::More tests => 6;
use Devel::OptreeDiff 'fmt_optree_diff';
use Config '%Config';

my @diff = fmt_optree_diff( sub { print @_ or die $! },
			    sub { print @_ } );

is( scalar @diff,
    5,
    '5 chunks detected' );

is( $diff[0],
    '- /leavesub/lineseq/nextstate*null
-                                 .op_flags = 4
-                                 .op_private = 1
-                                 .op_targ = 0
- /leavesub/lineseq/nextstate*null/or
-                                    .op_flags = 4
-                                    .op_other = 0
-                                    .op_private = 1
-                                    .op_targ = 0
- /leavesub/lineseq/nextstate*null/or/print
+ /leavesub/lineseq/nextstate*print
',
    'Chunk 1' );

is( $diff[1],
    '- /leavesub/lineseq/nextstate*null/or/print/pushmark
+ /leavesub/lineseq/nextstate*print/pushmark
',
    'Chunk 2' );

is( $diff[2],
    '- /leavesub/lineseq/nextstate*null/or/print/pushmark*rv2av
+ /leavesub/lineseq/nextstate*print/pushmark*rv2av
',
    'Chunk 3' );

is( $diff[3],
    '- /leavesub/lineseq/nextstate*null/or/print/pushmark*rv2av/gv
+ /leavesub/lineseq/nextstate*print/pushmark*rv2av/gv
',
    'Chunk 4' );

if ($Config{usethreads}) {
    is( $diff[4],
        '- /leavesub/lineseq/nextstate*null/or/print/pushmark*rv2av/gv.op_private = 0
-                                                            .op_targ = 0
- /leavesub/lineseq/nextstate*null/or/print*die
-                                              .op_flags = 6
-                                              .op_private = 1
-                                              .op_targ = 4
- /leavesub/lineseq/nextstate*null/or/print*die/pushmark
-                                                       .op_flags = 2
-                                                       .op_private = 0
-                                                       .op_targ = 0
- /leavesub/lineseq/nextstate*null/or/print*die/pushmark*rv2sv
-                                                             .op_flags = 6
-                                                             .op_private = 1
-                                                             .op_targ = 15
- /leavesub/lineseq/nextstate*null/or/print*die/pushmark*rv2sv/gvsv
-                                                                  .op_flags = 2
-                                                                  .op_padix = 3
',
    );
}
else {
    is( $diff[4],
        '- /leavesub/lineseq/nextstate*null/or/print/pushmark*rv2av/gv.op_flags = 2
-                                                            .op_private = 0
-                                                            .op_targ = 0
- /leavesub/lineseq/nextstate*null/or/print*die
-                                              .op_flags = 6
-                                              .op_private = 1
-                                              .op_targ = 2
- /leavesub/lineseq/nextstate*null/or/print*die/pushmark
-                                                       .op_flags = 2
-                                                       .op_private = 0
-                                                       .op_targ = 0
- /leavesub/lineseq/nextstate*null/or/print*die/pushmark*rv2sv
-                                                             .op_flags = 6
-                                                             .op_private = 1
-                                                             .op_targ = 15
- /leavesub/lineseq/nextstate*null/or/print*die/pushmark*rv2sv/gvsv
-                                                                  .GV = main::!
',
        'Chunk 5' );
}
