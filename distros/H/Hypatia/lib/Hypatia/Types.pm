package Hypatia::Types;
{
  $Hypatia::Types::VERSION = '0.029';
}
use MooseX::Types -declare=>[
    qw(
	PositiveNum
	PositiveInt
	HypatiaDBI
    )
];
use MooseX::Types::Moose qw(Num Int HashRef);

#ABSTRACT: A Type Library for Hypatia

subtype PositiveNum, as Num, where {$_ > 0};

subtype PositiveInt, as Int, where { $_ > 0};

subtype HypatiaDBI, as class_type("Hypatia::DBI");
coerce HypatiaDBI, from HashRef, via { Hypatia::DBI->new($_) };

1;

__END__

=pod

=head1 NAME

Hypatia::Types - A Type Library for Hypatia

=head1 VERSION

version 0.029

=head1 AUTHOR

Jack Maney <jack@jackmaney.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jack Maney.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
