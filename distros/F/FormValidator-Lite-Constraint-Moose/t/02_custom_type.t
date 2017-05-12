use Test::More;
use Test::Fatal;
use Moose::Util::TypeConstraints;
use FormValidator::Lite;

subtype 'Int.or.Str' => as 'Int|Str';

FormValidator::Lite->load_constraints(qw/Moose/);

subtype 'TimeStr' => as 'Str' => where { /^¥d{1,2}¥:¥d{1,2}¥:¥d{1,2}$/ };

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

subtest 'union type can use for constraint' => sub {
    $req->set_param( 'foo' => 1 );
    my $validator = FormValidator::Lite->new($req);
    $validator->check( foo => ['Int.or.Str'] );
    ok( !$validator->has_error, 'Int.or.Str' );

    $req->set_param( 'foo' => 'bar' );
    $validator->check( foo => ['Int.or.Str'] );
    ok( !$validator->has_error, 'Int.or.Str' );
};

subtest 'can not use type constraint that defined after call load_constraints().' => sub {
    $req->set_param( 'foo' => '00:00:00' );
    my $validator = FormValidator::Lite->new($req);
    like(
        exception {
            $validator->check( foo => ['TimeStr'] );
        },
        qr/^unknown rule/
    );
};

done_testing();
