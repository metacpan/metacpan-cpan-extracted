package Example::Sugar::Executor;
use strict;
use warnings;
use JSON::PP ();
use Scalar::Util qw(blessed refaddr);

# Synchronous, single-process teaching executor. No durable resume or retries.
sub _copy { return JSON::PP->new->allow_nonref->decode(JSON::PP->new->allow_nonref->encode($_[0])) }
sub new {
  my ($class, %args) = @_;
  my $plan = $args{plan};
  die "Executor requires a bound plan\n" unless ref($plan) eq 'HASH' && exists $plan->{active_total};
  my $self = bless { plan => $plan, results => {}, states => {}, attempts => {}, errors => {} }, $class;
  $self->{states}{$_->{key}} = $_->{active} ? 'pending' : 'skipped' for @{$plan->{steps}};
  return $self;
}
sub has_result { return exists $_[0]{results}{$_[1]} }
sub result {
  my ($self, $key) = @_;
  die "Result '$key' is unavailable\n" unless $self->has_result($key);
  return _copy($self->{results}{$key});
}
sub results { return _copy($_[0]{results}) }
sub states { return { %{$_[0]{states}} } }
sub attempts { return { %{$_[0]{attempts}} } }
sub progress {
  my ($self) = @_;
  return { active_total => $self->{plan}{active_total},
    succeeded => scalar(keys %{$self->{results}}),
    skipped => scalar(grep { $_ eq 'skipped' } values %{$self->{states}}),
    failed => scalar(grep { $_ eq 'failed' } values %{$self->{states}}),
  };
}
sub run {
  my ($self, $subject) = @_;
  die "Subject must be an object\n" unless blessed($subject);
  die "Executor is already running\n" if $self->{running};
  my $id = refaddr($subject);
  die "Executor cannot be reused for another subject\n" if defined($self->{subject_id}) && $self->{subject_id} != $id;
  $self->{subject_id} = $id;
  local $self->{running} = 1;
  for my $step (@{$self->{plan}{steps}}) {
    my $key = $step->{key};
    next unless $step->{active};
    next if exists $self->{results}{$key};
    $self->{states}{$key} = 'running';
    ++$self->{attempts}{$key};
    my ($value, $error);
    {
      local $@;
      my $ok = eval {
        for my $dep (@{$step->{requires}}) {
          die "Missing result '$dep' for '$key'\n" unless $self->has_result($dep);
        }
        $value = $step->{code}->($subject);
        die "Step '$key' must return an unblessed hashref\n" unless ref($value) eq 'HASH';
        $value = _copy($value); # rejects code, handles, and ordinary blessed objects
        1;
      };
      $error = $@ unless $ok;
    }
    if (defined $error) {
      $self->{states}{$key} = 'failed';
      $self->{errors}{$key} = "$error";
      die "Step '$key' failed: $error";
    }
    $self->{results}{$key} = $value;
    $self->{states}{$key} = 'succeeded';
    delete $self->{errors}{$key};
  }
  return $self->results;
}
1;
