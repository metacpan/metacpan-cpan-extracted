package Mic::Class;
use strict;
use Mic ();

sub import {
    my ($class, %arg) = @_;

    strict->import();
    Mic->assemble(\%arg);
}

1;

__END__

=head1 NAME

Mic::Class

=head1 SYNOPSIS

    # A simple Set class:

    package Example::Synopsis::Set;

    use Mic::Class
        interface => {
            object => {
                add => {},
                has => {},
            },
            class => {
                new => {},
            }
        },

        implementation => 'Example::Synopsis::ArraySet',
        ;
    1;

=head1 DESCRIPTION

Mic::Class allows a class to be defined whose implementation is in a separate file.

It is the compile time equivalent of calling C<< Mic->define_class(...) >>, and takes the same keyword parameters (see L<Mic/USAGE>).
