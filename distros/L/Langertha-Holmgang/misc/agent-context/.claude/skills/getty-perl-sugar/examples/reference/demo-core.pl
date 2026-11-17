use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use JSON::PP ();
use Example::Sugar::Registry ();
use Example::Sugar::Plan ();
use Example::Sugar::Executor ();

# This adapter is deliberately plain Perl. It is not a Moose simulation.
{
  package Example::CoreSubject;
  sub new { my ($class, %args) = @_; return bless \%args, $class }
  sub url { return $_[0]{url} }
  sub deep { return $_[0]{deep} }
  sub result { return $_[0]{executor}->result($_[1]) }
}
Example::Sugar::Registry::register_step('Example::CoreProbe', undef, 'Probe input', 'probe', sub { {ok=>1} });
Example::Sugar::Registry::register_step('Example::CoreCheck', undef, 'Parse input', 'parts', sub { {len=>length $_[0]->url} });
Example::Sugar::Registry::register_step('Example::CoreCheck', 'deep', 'Deep check', 'deeper', sub {
  {probe=>$_[0]->result('probe')->{ok}, len=>$_[0]->result('parts')->{len}}
}, phase=>'analyse', requires=>[qw(probe parts)]);
my $subject = Example::CoreSubject->new(url=>'https://example.invalid', deep=>1);
my $plan = Example::Sugar::Plan::compile([qw(Example::CoreProbe Example::CoreCheck)]);
my $bound = Example::Sugar::Plan::bind($plan, $subject);
my $executor = Example::Sugar::Executor->new(plan=>$bound);
$subject->{executor} = $executor;
print JSON::PP->new->canonical->pretty->encode({
  plan => Example::Sugar::Plan::manifest($bound), results => $executor->run($subject),
  progress => $executor->progress,
});
