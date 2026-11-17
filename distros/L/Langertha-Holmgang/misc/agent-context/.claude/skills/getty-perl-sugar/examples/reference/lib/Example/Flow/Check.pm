package Example::Flow::Check;
use Example::Sugar;
with 'Example::Flow::Probe';
has url => (is=>'ro', isa=>'Str', required=>1);
has deep => (is=>'ro', isa=>'Bool', default=>0);
step 'Parse input' => parts => sub { return {len=>length $_[0]->url} };
step_if 'deep' => 'Deep check' => deeper => sub {
  return {probe=>$_[0]->result('probe')->{ok}, len=>$_[0]->result('parts')->{len}};
}, phase=>'analyse', requires=>[qw(probe parts)];
no Example::Sugar;
__PACKAGE__->meta->make_immutable;
1;
