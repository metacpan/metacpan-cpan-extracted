package GnuPG::HashInit;
use Moo::Role;

sub hash_init {
    my ($self, %args) = @_;
    while ( my ( $method, $value ) = each %args ) {
        $self->$method($value);
    }
}

1;
__END__
