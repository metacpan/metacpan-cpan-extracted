package # Hide from indexer
    Geo::Address::Mail::Standardizer::Mock;
use Moose;

sub standardize {
    return 'hello!';
}

1;