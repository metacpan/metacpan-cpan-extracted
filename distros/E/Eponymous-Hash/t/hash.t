use Test::More;

subtest default_name => sub {
  use Eponymous::Hash;

  my ($one, $two) = qw/ three four /;

  is_deeply {eponymous_hash($one, $two)} => {qw/ one three two four /}
};

subtest specified_name => sub {
  use Eponymous::Hash 'epy';

  my ($one, $two) = qw/ three four /;

  is_deeply {epy($one, $two)} => {qw/ one three two four /}
};

subtest hash_and_keys => sub {
  use Eponymous::Hash 'epy';

  my $hash = {qw/ one two three four /};

  is_deeply $hash => {epy($hash, qw/ one three /)};
};

subtest hash_and_attributes => sub {
  use Eponymous::Hash 'epy';

  my $blessed_object = Object->new;

  is_deeply {epy($blessed_object, qw/ one three /)} => {qw/ one two three four /};
};

done_testing;

package Object;
sub new {bless {} => shift}
sub one {'two'}
sub three {'four'}
