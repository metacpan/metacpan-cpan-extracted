package Devel::Optic::Lens::Perlish;
$Devel::Optic::Lens::Perlish::VERSION = '0.011';
# ABSTRACT: Perl-ish syntax for querying data structures

use strict;
use warnings;

use Devel::Optic::Lens::Perlish::Parser qw(parse);
use Devel::Optic::Lens::Perlish::Interpreter qw(run);

our @CARP_NOT = qw(Devel::Optic);
sub new {
    my ($class) = @_;
    my $self = {};
    bless $self, $class;
}

sub inspect {
    my ($self, $scope, $query) = @_;
    my $ast = parse($query);
    return run($scope, $ast);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::Optic::Lens::Perlish - Perl-ish syntax for querying data structures

=head1 VERSION

version 0.011

=head1 AUTHOR

Ben Tyler <btyler@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Ben Tyler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
