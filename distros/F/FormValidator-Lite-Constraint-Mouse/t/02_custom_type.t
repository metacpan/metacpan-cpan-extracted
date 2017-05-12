use Test::More;
use Mouse::Util::TypeConstraints;
use FormValidator::Lite;

subtype 'Int-or-Str' => as 'Int|Str';

FormValidator::Lite->load_constraints(qw/Mouse/);

{

    package T::Mock::Request;

    sub new {
        my ( $class, $args ) = @_;
        $args ||= {};
        return bless {%$args}, $class;
    }

    sub set_param {
        my ( $self, $name, $param ) = @_;
        $self->{$name} = $param;
    }

    sub param {
        my ( $self, $name ) = @_;
        return $self->{$name};
    }
}

my $req = T::Mock::Request->new;

subtest 'union type can use for constraint' => sub{
    $req->set_param( 'foo' => 1 );
    my $validator = FormValidator::Lite->new($req);
    $validator->check( foo => ['Int-or-Str'] );
    ok( !$validator->has_error, 'It is Int' );

    $req->set_param( 'foo' => 'bar' );
    $validator->check( foo => ['Int-or-Str'] );
    ok(!$validator->has_error, 'It is Str' );
};

done_testing();