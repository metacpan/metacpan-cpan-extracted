package Devel::Mutator::Generator;

use strict;
use warnings;

use PPI;

my %operators_map = (
    '+'   => '-',
    '=='  => '!=',
    '++'  => '--',
    '=~'  => '!~',
    '*'   => '/',
    'gt'  => 'lt',
    'ge'  => 'le',
    '>'   => '<=',
    '>='  => '<',
    '||'  => '&&',
    'and' => 'or',
    'eq'  => 'ne',
    '//'  => '||',
    '//=' => '||=',
);
my %reversed_operators_map = reverse %operators_map;

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    return $self;
}

sub generate {
    my $self = shift;
    my ($code) = @_;

    my $ppi = PPI::Document->new(\$code);

    my @mutants;
    if (my $operators = $ppi->find('PPI::Token::Operator')) {
        foreach my $operator (@$operators) {
            my $new_operator = find_map($operator->content);

            next unless $new_operator;

            my $old_operator = $operator->content;
            $operator->set_content($new_operator);

            push @mutants,
              {
                id      => $ppi->hex_id,
                content => $ppi->serialize
              };

            $operator->set_content($old_operator);
        }
    }

    return @mutants;
}

sub find_map {
    my ($operator) = @_;

    return $operators_map{$operator} if exists $operators_map{$operator};
    return $reversed_operators_map{$operator}
      if exists $reversed_operators_map{$operator};
    return;
}

1;
__END__
=pod

=encoding utf-8

=head1 NAME

Devel::Mutator::Generator - Module

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new>

=head2 C<find_map($operator)>

=head2 C<generate($code)>

=head1 AUTHOR

Viacheslav Tykhanovskyi, E<lt>viacheslav.t@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

This program is distributed in the hope that it will be useful, but without any
warranty; without even the implied warranty of merchantability or fitness for
a particular purpose.

=cut
