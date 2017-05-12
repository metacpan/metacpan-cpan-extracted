package t::lib::Test::Parser;

use Test::Routine;
use Test::More;
use Test::Exception;

with 't::lib::Util::ResponseFixtures';

has [qw{
    parser
    parse_ok
    parse
    parse_type
    test_fail
    test_ok
}] => ( is => 'ro' );

has 'full_class' => (
    is => 'ro',
    lazy => 1,
    default => sub { 'Finance::Bank::Bankwest::Parser::' . shift->parser },
);

test 'parser existence' => sub {
    use_ok( shift->full_class );
};

test 'testing of acceptable data' => sub {
    my $self = shift;
    plan skip_all => 'no acceptable test, or this is tested by parsing'
        if not defined $self->test_ok;

    my $response = $self->response_for( $self->test_ok );
    lives_ok
        { $self->full_class->new( response => $response )->handle; }
        'testing must succeed for fixture ' . $self->test_ok;
};

test 'parsing of acceptable data' => sub {
    my $self = shift;
    plan skip_all => 'this parser does not return structured data'
        if not defined $self->parse_ok;

    my $response = $self->response_for( $self->parse_ok );
    my @results;
    lives_ok
        {
            @results
                = $self->full_class->new( response => $response )->handle;
        }
        'parsing must succeed for fixture ' . $self->parse_ok;
    is @results, @{ $self->parse },
        'the right number of results must be returned by the parse';
    for my $i (0 .. $#results) {
        my $actual = $results[$i];
        my $expected = $self->parse->[$i];
        isa_ok $actual, 'Finance::Bank::Bankwest::' . $self->parse_type,
            'returned data must be of the correct type';
        for my $key (sort keys %$expected) {
            is $actual->$key, $expected->{$key},
                "returned data must have the correct '$key' value";
        }
    }
};

test 'handler must decline Google fixture' => sub {
    my $self = shift;
    my $response = $self->response_for('google');
    throws_ok
        { $self->full_class->new( response => $response )->handle; }
        'HTTP::Response::Switch::HandlerDeclinedResponse';
};

test 'exception throwing for certain test data' => sub {
    my $self = shift;
    plan skip_all => 'this parser does not throw specific exceptions'
        if not $self->test_fail;

    for my $fixture (sort keys %{ $self->test_fail }) {
        my $error_class = $self->test_fail->{$fixture};
        my $response = $self->response_for($fixture);
        throws_ok
            { $self->full_class->new( response => $response )->handle; }
            'Finance::Bank::Bankwest::Error::' . $error_class,
            "$error_class exception must be thrown for fixture $fixture";
    }
};
