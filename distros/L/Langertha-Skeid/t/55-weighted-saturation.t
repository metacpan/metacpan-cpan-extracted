use strict;
use warnings;
use Test::More;
use Langertha::Skeid;

{
  package Local::CountingSkeid;
  use Moo;
  extends 'Langertha::Skeid';

  has admission_calls => (is => 'rw', default => sub { 0 });

  sub reset_admission_calls {
    my ($self) = @_;
    $self->admission_calls(0);
    return;
  }

  sub _node_can_take {
    my ($self, @args) = @_;
    $self->admission_calls($self->admission_calls + 1);
    return $self->SUPER::_node_can_take(@args);
  }
}

sub weighted_skeid {
  my ($weight_a, $weight_b) = @_;
  my $skeid = Local::CountingSkeid->new;
  $skeid->add_node(
    id => 'a', url => 'http://a/v1', model => 'm', weight => $weight_a, max_conns => 1,
  );
  $skeid->add_node(
    id => 'b', url => 'http://b/v1', model => 'm', weight => $weight_b, max_conns => 1,
  );
  return $skeid;
}

# Every eligible node is saturated. Admission is a property of a node, not of each slot in its
# weighted range, so one selection pass checks each node at most once regardless of weight size.
for my $case (
  [1,    2, 'weights 1:1'],
  [1000, 2, 'weights 1000:1000'],
) {
  my ($weight, $want_calls, $label) = @$case;
  my $skeid = weighted_skeid($weight, $weight);
  ok $skeid->start_request('a'), "$label: saturate node a";
  ok $skeid->start_request('b'), "$label: saturate node b";
  $skeid->reset_admission_calls;

  ok !defined($skeid->pick_node(model => 'm')), "$label: no node is admitted";
  is $skeid->admission_calls, $want_calls,
    "$label: full saturation checks admission once per node";
}

# With no saturation, compression of the ranges must not change weighted order or the cursor.
{
  my $skeid = weighted_skeid(3, 1);
  my @picked = map { $skeid->pick_node(model => 'm')->{id} } 1 .. 8;
  is_deeply \@picked, [qw(a a a b a a a b)],
    'the normal weighted sequence remains three a slots followed by one b slot';
  is $skeid->_rr_cursor->{$skeid->_route_key(model => 'm')}, 0,
    'a complete weighted cycle leaves the cursor at its original position';
}

# When the current range is saturated, the later admitted node is selected while the cursor still
# advances one weighted slot. If the first node frees, routing resumes from that exact position.
{
  my $skeid = weighted_skeid(3, 1);
  ok $skeid->start_request('a'), 'partially saturated: occupy node a';

  $skeid->reset_admission_calls;
  is $skeid->pick_node(model => 'm')->{id}, 'b', 'the first saturated a slot falls through to b';
  is $skeid->admission_calls, 2, 'the partial pass checks a and b once';
  is $skeid->_rr_cursor->{$skeid->_route_key(model => 'm')}, 1,
    'fall-through advances the cursor by one weighted slot';

  $skeid->reset_admission_calls;
  is $skeid->pick_node(model => 'm')->{id}, 'b', 'the second saturated a slot also falls through to b';
  is $skeid->admission_calls, 2, 'the next partial pass remains bounded by the node count';
  is $skeid->_rr_cursor->{$skeid->_route_key(model => 'm')}, 2,
    'the cursor retains its weighted position across partial saturation';

  ok $skeid->finish_request('a', ok => 1), 'free node a';
  is $skeid->pick_node(model => 'm')->{id}, 'a', 'routing resumes at the pending a slot after it frees';
  is $skeid->_rr_cursor->{$skeid->_route_key(model => 'm')}, 3,
    'the resumed pick advances to the final range';
}

# Starting inside a large saturated final range used to re-check that node for every remaining
# weighted slot before wrapping. Skip the whole occupied range after one admission result, then
# preserve the historical wrapped cursor position (the slot after target zero).
{
  my $skeid = weighted_skeid(1000, 1000);
  my $key = $skeid->_route_key(model => 'm');
  $skeid->_rr_cursor->{$key} = 1000;
  ok $skeid->start_request('b'), 'large partial saturation: occupy node b';
  $skeid->reset_admission_calls;

  is $skeid->pick_node(model => 'm')->{id}, 'a',
    'routing wraps from the saturated final range to the admitted first node';
  is $skeid->admission_calls, 2,
    'large partial saturation checks each node once instead of each weighted slot';
  is $skeid->_rr_cursor->{$key}, 1,
    'the wrapped pick keeps the existing cursor semantics';
}

done_testing;
