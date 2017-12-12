package Mic::ArrayImpl;

require Mic::Implementation;

our @ISA = qw( Mic::Implementation );

1;

__END__

=head1 NAME

Mic::ArrayImpl

=head1 SYNOPSIS

    package Example::ArrayImps::HashSet;

    use Mic::ArrayImpl
        has => { SET => { default => sub { {} } } },
    ;

    sub has {
        my ($self, $e) = @_;

        exists $self->[SET]{$e};
    }

    sub add {
        my ($self, $e) = @_;

        ++$self->[SET]{$e};
    }

    1;

=head1 DESCRIPTION

Mic::ArrayImpl is an alias of L<Mic::Impl>.
