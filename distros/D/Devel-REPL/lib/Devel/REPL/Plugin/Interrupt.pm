use strict;
use warnings;
package Devel::REPL::Plugin::Interrupt;
# ABSTRACT: Traps SIGINT to kill long-running lines

our $VERSION = '1.003029';

use Devel::REPL::Plugin;
use Sys::SigAction qw(set_sig_handler);
use namespace::autoclean;

around 'run' => sub {
    my ($orig, $self) = (shift, shift);

    local $SIG{INT} = 'IGNORE';

    return $self->$orig(@_);
};

around 'run_once' => sub {
    my ($orig, $self) = (shift, shift);

    # We have to use Sys::SigAction: Perl 5.8+ has safe signal handling by
    # default, and Term::ReadLine::Gnu restarts the interrupted system calls.
    # The result is that the signal handler is not fired until you hit Enter.
    my $sig_action = set_sig_handler INT => sub {
        die "Interrupted.\n";
    };

    return $self->$orig(@_);
};

around 'read' => sub {
    my ($orig, $self) = (shift, shift);

    # here SIGINT is caught and only kills the line being edited
    while (1) {
        my $line = eval { $self->$orig(@_) };
        return $line unless $@;

        die unless $@ =~ /^Interrupted\./;

        # (Term::ReadLine::Gnu kills the line by default, but needs a LF -
        # maybe I missed something?)
        print "\n";
    }
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::REPL::Plugin::Interrupt - Traps SIGINT to kill long-running lines

=head1 VERSION

version 1.003029

=head1 DESCRIPTION

By default L<Devel::REPL> exits on SIGINT (usually Ctrl-C). If you load this
module, SIGINT will be trapped and used to kill long-running commands
(statements) and also to kill the line being edited (like eg. BASH do). (You
can still use Ctrl-D to exit.)

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-REPL>
(or L<bug-Devel-REPL@rt.cpan.org|mailto:bug-Devel-REPL@rt.cpan.org>).

There is also an irc channel available for users of this distribution, at
L<C<#devel> on C<irc.perl.org>|irc://irc.perl.org/#devel-repl>.

=head1 AUTHOR

Shawn M Moore, C<< <sartak at gmail dot com> >>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2007 by Matt S Trout - mst (at) shadowcatsystems.co.uk (L<http://www.shadowcatsystems.co.uk/>).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
