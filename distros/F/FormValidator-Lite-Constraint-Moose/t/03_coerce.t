use Test::More;
use Test::Fatal;
use Moose::Util::TypeConstraints;
use FormValidator::Lite;

subtype 'PositiveInt' => as 'Int' => where { $_ > 0 };

coerce 'PositiveInt' => from 'ScalarRef' => via { ${$_} };

FormValidator::Lite->load_constraints(qw/Moose/);

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

subtest 'you can define coercions for type constraints' => sub {
    $req->set_param( 'foo' => \'1' );
    my $validator = FormValidator::Lite->new($req);
    $validator->check( foo => ['PositiveInt'] );
    ok( !$validator->has_error, 'PositiveInt' );
};


done_testing();
