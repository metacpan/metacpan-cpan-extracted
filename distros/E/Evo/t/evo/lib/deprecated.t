use Evo 'Test::More';

plan skip_all => "ws_fn && compine_thunks are under deprecation trial";

## compine_thunks --------------
#like exception { combine_thunks() }, qr/provide.+$0/i;
#
#my @got;
#
## empty
#combine_thunks(sub { @got = @_ })->(1, 2);
#is_deeply \@got, [1, 2];
#
## ok
#my @log;
#
#sub logh($n) {
#  sub($next) { push @log, $n; $next->() }
#}
#
#combine_thunks(logh(1), logh(2), sub { @got = @_ })->(1, 2);
#is_deeply \@got, [1, 2];
#is_deeply \@log, [1, 2];
#
## too_many_times
#@log = ();
#
#sub log_bad($n) {
#  sub($next) { push @log, $n; $next->(); $next->(); }
#}
#
#like exception {
#  combine_thunks(log_bad(1), log_bad(2), sub { @got = @_ })->(1, 2);
#},
#  qr/2 times/;
#is_deeply \@got, [1, 2];
#is_deeply \@log, [1, 2];
#
#
## zero times
#like exception {
#  combine_thunks(sub { }, sub { })->();
#}, qr/0 times/;
#is_deeply \@got, [1, 2];
#is_deeply \@log, [1, 2];
#
#
#
## ws_fn --------------
#sub w_add($add) {
#  sub($next) {
#    sub($val) {
#      $next->($val + $add);
#    };
#  };
#}
#
## 1
#is ws_fn(w_add(44), sub($val) { return "ret $val" })->(22), 'ret ' . (22 + 44);
#
## many
#is ws_fn(w_add(1), w_add(2), w_add(3), sub($val) { return "ret $val" })->(22),
#  'ret ' . (22 + 1 + 2 + 3);
#
## only cb
#is ws_fn(sub($val) { return "ret $val" })->(22), 'ret ' . 22;
#
#
#like exception { ws_fn() }, qr/Provide.+$0/;
