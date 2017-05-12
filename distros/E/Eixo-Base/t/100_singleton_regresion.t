package Config;

use Eixo::Base::Clase qw(Eixo::Base::Singleton);

has(
    path => '/tmp/a'
);

sub initialize{

    my ($self, %args) = @_;

    $self->{path} = $args{'path'} || '/tmp/c';
}


__PACKAGE__->make_singleton(path=>"/tmp/c");

1;


package Main;

use t::test_base;
use Config;
use Data::Dumper;

ok(
    Config->path eq '/tmp/c',
    "Por defecto vai seteado no obxeto o valor do atributo establecido no metodo initialize"
);

my $c = Config->new(path =>'/tmp/b');

ok( 
    $c->path eq '/tmp/b',

    "Podemos inicializar o obxeto singleton facendo un new"
);

my $d = Config->new(path => '/tmp/d');
ok(
    ref($d) eq ref($c),

    "E con seguintes chamadas a new podemos seguimos alterando os atributos, pero siguen sendo o mesmo objexto"
);

done_testing();
