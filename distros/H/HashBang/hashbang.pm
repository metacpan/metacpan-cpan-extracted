package hashbang;
$VERSION = '0.10';

1;

=head1 NAME

HashBang - Write your own language interpreters

=head1 SYNOPSIS

    #!/usr/bin/foo

=head1 DESCRIPTION

This CPAN distribution will install a binary program on your system
called 'C<hashbang>'. You can use this program to write your own
hashbang style interpreters in Perl. Let's say you've implemented a
language called C<foo> in a file called C<foo.pl>. Put the file in the
same directory as the C<hashbang> executable. And then create a symbolic
link from C<foo> to C<hashbang>. Like this:

    cd /usr/bin
    cp ~/foo.pl .
    ln -fs hashbang foo

=head1 EXAMPLE

The CPAN distribution, C<HashBang-ParrotScript> makes use of HashBang to create a simple interpreter for the Parrot Assembler language.

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 CONTRIBUTORS

Hugo van der Sanden - helped with the initial C code

Norman Nunley - Helped me develop this over a Mexican dinner in San Diego

=head1 COPYRIGHT

Copyright (c) 2001, 2002. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
