package Magpie::SymbolTable;
$Magpie::SymbolTable::VERSION = '1.163200';
#ABSTRACT: Core Magpie Event Symbol Table Object
use strict;
use warnings;

sub new {
    return bless [], shift;
}

# for reference
# $self = [ [$name, [...]], ];

sub get_symbol {
    my $idx = $_[0]->symbol_index($_[1]);
    if ( defined( $idx ) ) {
        return $_[0]->[$idx]->[1];
    }
    return undef;
}

sub has_symbol {
    my $idx = $_[0]->symbol_index($_[1]);
    return 1 if defined($idx);
    return undef;
}

sub add_symbol {
    my $idx = $_[0]->symbol_index($_[1]);
    if ( defined( $idx ) ) {
       push @{$_[0]->[$idx]->[1]}, $_[2];
    }
    else {
       push @{$_[0]}, [ $_[1], [ $_[2] ] ];
    }
}

sub reset_symbol {
    my $idx = $_[0]->symbol_index($_[1]);
    if ( defined( $idx ) ) {
       $_[0]->[$idx]->[1] = [];
    }
}

sub reset_table {
    $_[0] = bless [];
}

sub symbol_names {
    return map { $_->[0] } @{$_[0]};
}

sub symbol_index {
    my $self = shift;
    my $name = shift;
    my $i;
    for ($i=0;$i<scalar(@$self);$i++) {
        return $i if $self->[$i]->[0] eq $name;
    }
    return undef;
}

# SEEALSO: Magpie

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Magpie::SymbolTable - Core Magpie Event Symbol Table Object

=head1 VERSION

version 1.163200

=head1 AUTHORS

=over 4

=item *

Kip Hampton <kip.hampton@tamarou.com>

=item *

Chris Prather <chris.prather@tamarou.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Tamarou, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
