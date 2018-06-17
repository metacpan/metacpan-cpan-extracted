package EventStore::Tiny::Snapshot;
use Mo qw(default required );

has state       => (required => 1);
has timestamp   => (required => 1, is => 'ro');

1;
__END__
