use strict;
use warnings;

use Test::More;

use lib 'lib';
use Inline::CLIPS;

my $clips = Inline::CLIPS->new;
isa_ok($clips, 'Inline::CLIPS');

ok(defined $clips->library, 'library accessor is defined (may be empty)');

{
  local $ENV{INLINE_CLIPS_EXECUTABLE} = '/tmp/fake-clips-bin';
  is(Inline::CLIPS->new->executable, '/tmp/fake-clips-bin', 'env overrides executable');
}

{
  my $error;
  eval { Inline::CLIPS->new(executable => q{})->run_file('/tmp/missing.clp') };
  $error = $@;
  like($error, qr/CLIPS file not found/, 'run_file validates input file existence');
}

done_testing;
