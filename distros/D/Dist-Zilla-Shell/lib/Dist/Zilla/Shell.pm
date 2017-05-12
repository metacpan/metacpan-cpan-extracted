use strict;
use warnings;
# ABSTRACT: An interactive shell to run Dist::Zilla commands
package Dist::Zilla::Shell;
{
  $Dist::Zilla::Shell::VERSION = '0.005';
}

1;
__END__

=head1 NAME

Dist::Zilla::Shell - An interactive shell for Dist::Zilla

=head1 SYNOPSIS

    $ dzil shell
    
    DZ> build
    ...
    
    DZ> test
    ...
    
    DZ> release
    ...
    
    DZ> q

=head1 DESCRIPTION

This module adds a new command to L<Dist::Zilla>: C<shell>. Run it and an
interactive shell is opened. You can then run any other Dist::Zilla
command that you usually run with "dzil I<command>" (even C<shell> itself, to
open a sub-shell, but that is useless). Type C<q|quit|exit|x> to exit the shell.

Any command unknown to Dist::Zilla is executed in a system shell, so you can
mix DZ commands and system commands (ls, prove, git...).

Running DZ commands from a shell brings the benefit of avoiding the huge
startup cost due to Moose and all Dist::Zilla plugins. So the first run of
a command under the shell may be still slow, but any successive run will be
much faster.

=head1 TRIVIA

I started to seriously learn L<Dist::Zilla> at the QA Hackathon 2011 in
Amsterdam. I immediately had the idea of this shell as DZ is really
slow to start. Six months after, this the first DZ extension that I have
written.

=head1 SEE ALSO

=over 4

=item *

L<http://dzil.org/>, L<Dist::Zilla>

=item *

L<Dist::Zilla::App::Command::shell>, the class that implements the command

=back

=head1 AUTHOR

Olivier MenguE<eacute>, L<mailto:dolmen@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright E<copy> 2011 Olivier MenguE<eacute>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

