use HTML::TreeBuilder;
use Storable;

my $tree = retrieve 'small.stor';

$tree->dump;

