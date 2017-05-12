package t::lib::Test::ErrorSubclass;

use Test::Routine;
use Test::More;
use Test::Exception;

has [qw{ class parent text }] => ( is => 'ro' );
has 'args' => ( traits => ['Hash'], handles => { 'args' => 'elements' } );

for my $attr (qw{ class parent }) {
    has "full_$attr" => (
        is => 'ro',
        lazy => 1,
        default => sub {
            my $self = shift;
            length $self->$attr
                ? 'Finance::Bank::Bankwest::Error::' . $self->$attr
                : 'Finance::Bank::Bankwest::Error'
        },
    );
}

test 'correct superclass' => sub {
    my $self = shift;
    use_ok( $self->full_class );
    isa_ok( $self->full_class, $self->full_parent );
};

test 'stringification' => sub {
    my $self = shift;
    my $text = $self->text;
    plan skip_all => 'this error class is not instantiated'
        if not defined $text;

    throws_ok
        { $self->full_class->throw( $self->args ) }
        qr/\Q$text\E/,
        'error must stringify correctly';
};
