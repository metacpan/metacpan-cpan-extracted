package Mason::Test::RootClass::Compilation;
$Mason::Test::RootClass::Compilation::VERSION = '2.24';
use Moose;
extends 'Mason::Compilation';

before 'parse' => sub {
    my ($self) = @_;
    print STDERR "starting compilation parse - " . $self->path . "\n";
};

__PACKAGE__->meta->make_immutable();

1;
