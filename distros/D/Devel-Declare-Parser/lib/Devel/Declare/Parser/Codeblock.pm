package Devel::Declare::Parser::Codeblock;
use strict;
use warnings;

use base 'Devel::Declare::Parser';
use Devel::Declare::Interface;
Devel::Declare::Interface::register_parser( 'codeblock' );

sub rewrite {
    my $self = shift;
    $self->bail(
        "Syntax error near: " . join( ' and ',
            map { $self->format_part($_)}
                @{ $self->parts }
        )
    ) if $self->parts && @{ $self->parts };
    1;
}

1;

__END__

=head1 NAME

Devel::Declare::Parser::Codeblock - Parser for functions that just take a
codeblock.

=head1 DESCRIPTION

This parser can be used to define a function that takes ONLY a codeblock. This
is just like a function with the (&) prototype. The difference here is that you
do not need to end your block with a semicolon.

=head1 RESTRICTIONS

Any arguments before the codeblock will be treated as a syntax error.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Devel-Declare-Parser is free software; Standard perl licence.

Devel-Declare-Parser is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the license for more details.
