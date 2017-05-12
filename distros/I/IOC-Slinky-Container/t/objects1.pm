{
    package Item;
    use Moose;
    no Moose;
}
{
    package Car;
    use Moose;
    has 'brand'     => ( is => 'rw', isa => 'Str', required => 1 );
    has 'type'      => ( is => 'rw', isa => 'Str' );
    has 'model'     => ( is => 'rw', isa => 'Str' );
    has 'year'      => ( is => 'rw', isa => 'Int' );
    has 'test_item' => ( is => 'rw', isa => 'Item' );
    no Moose;
}
{
    package NonMooseThing;
    use strict;
    sub new {
        my ($CLASS, $args) = @_;
        my $self = bless { }, $CLASS;
        (ref($args) eq 'ARRAY')
            or die "args not an ARRAYREF";
        $self->{name} = $args->[0]->{name};
        $self->{key2} = $args->[0]->{key2};
        return $self;
    }
}

1;
