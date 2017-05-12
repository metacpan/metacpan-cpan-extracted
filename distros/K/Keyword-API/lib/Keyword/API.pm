package Keyword::API;
BEGIN {
  $Keyword::API::VERSION = '0.0004';
}
use 5.012;
use strict;
use warnings;
use Exporter 'import';
require XSLoader;

our @EXPORT = qw/
    install_keyword
    uninstall_keyword 
    lex_read_space
    lex_read
    lex_read_to_ws
    lex_stuff
    lex_unstuff
    lex_unstuff_to
    lex_unstuff_to_ws
    /;

XSLoader::load('Keyword::API', $Keyword::API::VERSION);

1;


=pod

=head1 NAME

Keyword::API

=head1 VERSION

version 0.0004

=head1 SYNOPSIS

    use Keyword::API;

    sub import { 
        my ($class, %params) = @_; 

        my $name = %params && $params{-as} ? $params{-as} : "method";

        install_keyword(__PACKAGE__, $name);
    }

    sub unimport { uninstall_keyword() }

    sub parser {
        lex_read_space(0);
        my $sub_name = lex_unstuff_to_ws();
        my $sig = lex_unstuff_to('{');
        my ($roll) = $sig =~ /\((.+)\)\s*{/;
        lex_stuff("sub $sub_name {my (\$self, $roll) = \@_;");
    };

=head1 DESCRIPTION

This module provides a pure perl interface for the keywords API added to the perl core in 5.12.

=head1 NAME

Keyword::API - Perl interface to the keyword API

=head1 EXPERIMENTAL

This module is likely to change in the near future. Patches and feedback most welcome.

=head2 EXPORT

    install_keyword
    uninstall_keyword 
    lex_read_space
    lex_read
    lex_read_to_ws
    lex_stuff
    lex_unstuff
    lex_unstuff_to
    lex_unstuff_to_ws

=head1 FUNCTIONS

=head2 install_keyword

pass your package name and provide the name of your keyword e.g 'method'

=head2 uninstall_keyword

remove the keyword hook, no arguments required.

=head2 lex_read_space

    lex_read_space(0);

reads white space and comments in the text currently being lexed. 

=head2 lex_read

    my $str = lex_read($n);

Consumes $n bytes of text from the lexer buffer.

=head2 lex_read_to_ws

    my $toke = lex_read_token();

Consumes any text in the lexer until white space is reached.

=head2 lex_stuff

    lex_stuff("sub foo { ...");

Injects a string into the lexer buffer.

=head2 lex_unstuff

    my $discarded_text = lex_unstuff($n);

Discard $n bytes from the lexers buffer 

=head2 lex_unstuff_to

    my $discarded_text = lex_unstuff_to("{");

Discard everything in the buffer until the character is met.

=head2 lex_unstuff_to_ws

    my $discarded_text = lext_unstuff_token();

Discard everything in the buffer until white space is met

=head1 SEE ALSO

L<perlapi> Devel::Declare Filter::Simple Syntax::Feature::Method

=head1 AUTHOR

Robin Edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Robin Edwards.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

