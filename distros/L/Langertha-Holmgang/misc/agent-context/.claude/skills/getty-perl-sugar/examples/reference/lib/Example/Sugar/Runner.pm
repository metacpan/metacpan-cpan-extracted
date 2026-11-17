package Example::Sugar::Runner;
use Moose::Role;
use Example::Sugar::Owners ();
use Example::Sugar::Plan ();
use Example::Sugar::Executor ();

has _sugar_executor => (is=>'ro', lazy=>1, builder=>'_build_sugar_executor', init_arg=>undef);
sub _build_sugar_executor {
  my ($self) = @_;
  my $plan = Example::Sugar::Plan::compile(Example::Sugar::Owners::for_class(ref $self));
  my $bound = Example::Sugar::Plan::bind($plan, $self);
  return Example::Sugar::Executor->new(plan=>$bound);
}
sub steps {
  my ($invocant) = @_;
  my $class = ref($invocant) || $invocant;
  my $plan = Example::Sugar::Plan::compile(Example::Sugar::Owners::for_class($class));
  return Example::Sugar::Plan::manifest($plan);
}
sub result { return $_[0]->_sugar_executor->result($_[1]) }
sub has_result { return $_[0]->_sugar_executor->has_result($_[1]) }
sub results { return $_[0]->_sugar_executor->results }
sub progress { return $_[0]->_sugar_executor->progress }
sub run { return $_[0]->_sugar_executor->run($_[0]) }
no Moose::Role;
1;
