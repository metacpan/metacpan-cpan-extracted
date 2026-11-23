use strict;
use warnings;
use Test::More tests => 6;
use Time::HiRes qw(time);
use MIME::Head;
use MIME::Field::ParamVal;
# Cost of one mime_attr() call on a Content-Type field with a run of "(" before
# a single ")" and a semicolon: quadratic grows 4x per doubling, linear 2x.
sub median_cost {
    my ($k, $reps) = @_;
    my $field = "Content-Type: text/plain" . ("(" x $k) . "); x=y\n";
    my $head  = MIME::Head->new([$field]);
    my @cost;
    for (1 .. $reps) {
        my $t0 = time;
        $head->mime_attr('content-type');
        push @cost, time - $t0; }
    @cost = sort { $a <=> $b } @cost;
    return $cost[int(@cost / 2)]; }
my $small = median_cost(50_000, 3);
my $large = median_cost(100_000, 3);
cmp_ok($small, '>', 0, 'a 50000-character run takes measurable time');
my $ratio = $large / $small;
cmp_ok($ratio, '<', 3.2,
       sprintf('doubling the run costs %.2fx (a quadratic scan costs about 4x)', $ratio));
my $open = MIME::Field::ParamVal->parse("text/plain" . ("(" x 20) . " x=y; a=b");
ok($open->{'@unparsed_parameters'}, 'an unclosed comment marks the parameters unparsed');
my $closed = MIME::Field::ParamVal->parse("text/plain; (note) charset=us-ascii");
ok(!$closed->{'@unparsed_parameters'}, 'a closed comment does not mark them unparsed');
my $after = MIME::Field::ParamVal->parse("text/plain) x=y" . ("(" x 20) . "; a=b");
ok($after->{'@unparsed_parameters'}, 'a run opened after the last ")" marks them unparsed');
my $nested = MIME::Field::ParamVal->parse("text/plain (open ( x=y; a=b");
ok($nested->{'@unparsed_parameters'}, 'nested unclosed comments mark them unparsed');
