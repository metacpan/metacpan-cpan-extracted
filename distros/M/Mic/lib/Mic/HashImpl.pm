package Mic::HashImpl;

require Mic::Implementation;

our @ISA = qw( Mic::Implementation );

1;

__END__

=head1 NAME

Mic::HashImpl

=head1 SYNOPSIS

    package Example::Construction::Acme::Set_v1;

    use Mic::HashImpl
        has => {
            SET => {
                default => sub { {} },
                init_arg => 'items',
            }
        },
    ;

    sub has {
        my ($self, $e) = @_;
        exists $self->{$SET}{$e};
    }

    sub add {
        my ($self, $e) = @_;
        ++$self->{$SET}{$e};
    }

    1;

=head1 DESCRIPTION

Mic::HashImpl is an alias of L<Mic::Implementation>, provided for convenience.
