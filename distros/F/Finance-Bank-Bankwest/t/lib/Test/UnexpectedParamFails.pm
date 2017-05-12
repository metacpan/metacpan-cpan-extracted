package t::lib::Test::UnexpectedParamFails;

use Test::Routine;
use Test::More;
use Test::Exception;

has 'class' => ( is => 'ro' );

has 'good_args' => (
    traits  => ['Hash'],
    handles => { 'good_args' => 'elements' },
);

has 'full_class' => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        return $self->class if $self->class =~ /^t::/;
        return 'Finance::Bank::Bankwest::' . $self->class;
    },
);

test 'class existence' => sub {
    my $self = shift;
    plan skip_all => 'class is internally defined by the test suite'
        if $self->full_class =~ /^t::/;
    use_ok( $self->full_class );
};

test 'construction must succeed with acceptable parameters' => sub {
    my $self = shift;
    my $obj = $self->full_class->new( $self->good_args );
    isa_ok($obj, $self->full_class);
};

test 'constructor must not accept an unexpected parameter' => sub {
    my $self = shift;
    throws_ok
        {
            $self->full_class->new(
                $self->good_args,
                unexpected_param => 'hello',
            );
        }
        qr/unexpected_param/;
};
