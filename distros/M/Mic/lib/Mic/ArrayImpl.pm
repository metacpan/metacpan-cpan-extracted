package Mic::ArrayImpl;

use Readonly;
require Mic::Implementation;

our @ISA = qw( Mic::Implementation );

sub update_args {
    my ($class, $arg) = @_;

    $arg->{arrayimp} = 1;
}

sub add_attribute_syms {
    my ($class, $arg, $stash) = @_;

    my @slots = (
        '__', # semiprivate pkg
        keys %{ $arg->{has} },
        ( map {
            @{ $arg->{traits}{$_}{attributes} || []  }
          }
          keys %{ $arg->{traits} }
        ),
    );
    my %seen_attr;
    foreach my $i ( 0 .. $#slots ) {
        next if exists $seen_attr{ $slots[$i] };

        $seen_attr{ $slots[$i] }++;
        $class->add_sym($arg, $stash, $slots[$i], $i);
    }
}

sub add_sym {
    my ($class, $arg, $stash, $slot, $i) = @_;

    Readonly my $sym_val => $i;
    $arg->{slot_offset}{$slot} = $sym_val;

    $stash->add_symbol(
        sprintf('$%s', uc $slot),
        \ $sym_val
    );
}

1;

__END__

=head1 NAME

Mic::ArrayImpl

=head1 SYNOPSIS

    package Example::ArrayImps::HashSet;

    use Mic::ArrayImpl
        has => { set => { default => sub { {} } } },
    ;

    sub has {
        my ($self, $e) = @_;

        exists $self->[ $SET ]{$e};
    }

    sub add {
        my ($self, $e) = @_;

        ++$self->[ $SET ]{$e};
    }

    1;

=head1 DESCRIPTION

Mic::ArrayImpl can be used to create implementations based on blessed array refs (which may be desirable due to 
having faster access and less memory usage compared to hash based objects). 

Mic::ArrayImpl is used in the same way as L<Mic::Implementation>,
the only difference being that the former creates array based objects.
