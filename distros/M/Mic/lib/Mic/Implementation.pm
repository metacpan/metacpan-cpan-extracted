package Mic::Implementation;

use strict;
use Package::Stash;
use Params::Validate qw(:all);

sub import {
    my $class = shift;

    my %arg = validate(@_, {
        has         => { type => HASHREF },
        classmethod => { type => ARRAYREF, optional => 1 },
    });

    strict->import();

    $arg{-caller} = (caller)[0];
    $class->define(%arg);
}

sub define {
    my ($class, %arg) = @_;

    my $caller_pkg = delete $arg{-caller} || (caller)[0];
    my $stash = Package::Stash->new($caller_pkg);

    $class->add_attribute_syms(\%arg, $stash);

    $stash->add_symbol('%__meta__', \%arg);
}

sub add_attribute_syms {
    my ($class, $arg, $stash) = @_;

    my @slots = (
        keys %{ $arg->{has} },
    );
    my %seen_attr;
    foreach my $i ( 0 .. $#slots ) {
        next if exists $seen_attr{ $slots[$i] };

        $seen_attr{ $slots[$i] }++;
        $class->add_sym($arg, $stash, $slots[$i], $i);
    }
}

sub add_sym {
    my ($class, $arg, $stash, $slot, $sym_val) = @_;

    $arg->{slot_offset}{$slot} = $sym_val;

    $stash->add_symbol(
        sprintf('&%s', $slot),
        sub () { $sym_val }
    );
}

1;

__END__

=head1 NAME

Mic::Implementation

=head1 DESCRIPTION

Mic::Implementation is an alias of L<Mic::Impl>.
