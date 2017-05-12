package Devel::Declare::Parser::Method;
use strict;
use warnings;

use base 'Devel::Declare::Parser::Sublike';
use Devel::Declare::Interface;
Devel::Declare::Interface::register_parser( 'method' );

sub inject {('my $self = shift')}

1;

=head1 NAME

Devel::Declare::Parser::Method - Parser that shifts $self automatically in
codeblocks.

=head1 DESCRIPTION

This parser can be used to define a function that takes a single name, and a
single codeblock. This is just like the 'sub' keyword. The name can be either a
bareword, or a quoted string.

=head1 EXTRAS WHEN USING THE KEYWORD

Codeblocks defined when using the keyword will have '$self' shifted off
automatically.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Devel-Declare-Parser is free software; Standard perl licence.

Devel-Declare-Parser is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the license for more details.
