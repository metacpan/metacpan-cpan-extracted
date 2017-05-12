package Foo::Zoo;
use Devel::Stub on => "t/lib";

stub 'new' => sub {
    my $class = shift;
    bless { zoo => 1 },$class;
};


1;
