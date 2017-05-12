use strict;
use warnings;
use Test::More 0.88;
use JSON::MaybeXS ();

our @call;

sub Fake::new { bless({}, 'Fake') }
sub Fake::foo { push @call, a => $_[1] }
sub Fake::bar { push @call, c => $_[1] }

{
  local $JSON::MaybeXS::JSON_Class = 'Fake';

  my @args = (foo => 'b', bar => 'd');

  foreach my $args (\@args, [ { @args } ]) {

    local @call;

    my $obj = JSON::MaybeXS->new(@$args);

    is(ref($obj), 'Fake', 'Object of correct class');

    is(join(' ', sort @call), 'a b c d', 'Methods called');
  }
}

done_testing;
