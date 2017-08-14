package Mic::Impl;

require Mic::ArrayImpl;

our @ISA = qw( Mic::ArrayImpl );

1;

__END__

=head1 NAME

Mic::Impl

=head1 SYNOPSIS

    package Example::Construction::Acme::Counter;

    use Mic::Impl
        has  => {
            COUNT => { init_arg => 'start' },
        }, 
    ;

    sub next {
        my ($self) = @_;

        $self->[ $COUNT ]++;
    }

    1;

=head1 DESCRIPTION

Mic::Impl is an alias of L<Mic::ArrayImpl>, provided for convenience.
