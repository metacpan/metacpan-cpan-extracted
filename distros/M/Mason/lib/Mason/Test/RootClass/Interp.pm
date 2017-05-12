package Mason::Test::RootClass::Interp;
$Mason::Test::RootClass::Interp::VERSION = '2.24';
use Moose;
extends 'Mason::Interp';

before 'run' => sub {
    print STDERR "starting interp run\n";
};

__PACKAGE__->meta->make_immutable();

1;
