use strict;
use warnings;

use Test::More;

eval { require Test::MemoryGrowth };
if ($@) {
	plan skip_all => 'Test::MemoryGrowth not installed or not working';
}

use JavaScript::Duktape::XS;

my $options = {
    gather_stats     => 1,
    save_messages    => 1,
    max_memory_bytes => 256*1024,
    max_timeout_us   => 2_000_000,
};

no_growth {
   my $vm = JavaScript::Duktape::XS->new($options);
} 'Constructing JavaScript::Duktape::XS does not grow memory';

no_growth {
  #Create a new VM everytime
  my $vm = JavaScript::Duktape::XS->new($options);
  #Create a silly large object that we want to expose to the JS environment via a closure
  my $answer = 'a large object';
  my $largeObject = {};
  for (1..100) {
    $largeObject->{$_}= $answer;
  }

  #Add a perl function to the vm, creating a closure
  $vm->set('SomeTask', sub {
      #extract from our object and return it to the JS environment
      return $largeObject->{1};
  });

  my $got = $vm->eval(q[SomeTask()]);
  die "not matched: $got" if $got ne $answer;
} 'Using closures does not grow memory';

done_testing;
