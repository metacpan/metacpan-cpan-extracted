package Game::Life::NDim::Dim;

# Created on: 2010-01-08 18:43:32
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use version;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;

use overload
    '""'  => sub { '[' . ( join ',', @{ $_[0]->elements } ) . ']' },
    '@{}' => sub { $_[0]->elements },
    '=='  => sub { for (0..@{$_->[0]}-1) { return 0 if $_[0][$_] != $_[1][$_] } return 1 },
    '+'   => \&sum_list;

our $VERSION     = version->new('0.0.4');
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();

has elements => (
    is       => 'rw',
    isa      => 'ArrayRef',
    required => 1,
);

has max => (
    is       => 'rw',
    isa      => 'ArrayRef[Int]',
    weak_ref => 1,
);

around new => sub {
    my ($new, $class, @args) = @_;

    if ( @args == 1 && ref $args[0] eq 'ARRAY' ) {
        @args = ( elements => $args[0] );
    }
    else {
        my %params = @args;
        if (!exists $params{elements} && exists $params{max}) {
            $params{elements} = [ @{ $params{max} } ];
            return $new->($class, %params)->zero;
        }
    }

    return $new->($class, @args);
};

sub increment {
    my ($self, $max) = @_;
    my $last;

    for my $i ( reverse 0 .. @{ $max } - 1 ) {
        die "max[$i] == 0 which is not allowed!" if $max->[$i] == 0;
        if ( $self->[$i] + 1 <= $max->[$i] ) {
            $self->[$i]++;
            $last = $i;
            last;
        }
        $self->[$i] = 0;
    }

    return if !defined $last;

    return $self;
}

sub clone {
    my ($self) = @_;

    return $self->new(elements => [ @{ $self } ]);
}

sub zero {
    my ($self) = @_;

    for my $item (@{ $self }) {
        $item = 0;
    }

    return $self;
}

sub sum_list {
    my ($self, $list) = @_;

    my @new;
    for my $i ( 0 .. @{ $self } - 1 ) {
        die Dumper $i, $self, $list if !defined $self->[$i] || !defined $list->[$i];
        $new[$i] = $self->[$i] + $list->[$i];
    }

    return __PACKAGE__->new(\@new);
}

1;

__END__

=head1 NAME

Game::Life::NDim::Dim - The dimension of a board?

=head1 VERSION

This documentation refers to Game::Life::NDim::Dim version 0.0.4.


=head1 SYNOPSIS

   use Game::Life::NDim::Dim;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<increment (  )>

=head2 C<clone (  )>

=head2 C<zero (  )>

=head2 C<sum_list (  )>

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
