package # Hide from indexer
    MyStandardizer;
use Moose;

sub standardize {
    return 'hello!';
}

1;