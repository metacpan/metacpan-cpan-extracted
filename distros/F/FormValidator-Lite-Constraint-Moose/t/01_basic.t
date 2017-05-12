use strict;
use Test::More;
use Test::Fatal;
use FormValidator::Lite;

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

subtest 'Int' => sub {
    $req->set_param( 'foo' => 1 );
    my $validator = FormValidator::Lite->new($req);
    $validator->check( foo => ['Int'] );
    ok( !$validator->has_error, 'It is Int' );

    $req->set_param( 'foo' => 'bar' );
    $validator->check( foo => ['Int'] );
    ok( $validator->has_error, 'It is not Int' );
};

subtest 'ArrayRef' => sub {
    $req->set_param( 'foo' => [qw/foo bar/] );
    my $validator = FormValidator::Lite->new($req);
    $validator->check( foo => ['ArrayRef'] );
    ok( !$validator->has_error, 'It is ArrayRef' );

    $req->set_param( 'foo' => 'bar' );
    $validator->check( foo => ['ArrayRef'] );
    ok( $validator->has_error, 'It is not ArrayRef' );

};

subtest 'Custom Type' => sub {
    $req->set_param( 'foo' => 1 );
    my $validator = FormValidator::Lite->new($req);
    like( exception {
            $validator->check( foo => ['Int|Str'] );
        },
        qr/^unknown rule/
    );
};

done_testing();
