use strict;
use warnings;
package Devel::REPL::Plugin::Peek;
# ABSTRACT: L<Devel::Peek> plugin for L<Devel::REPL>.

our $VERSION = '1.003029';

use Devel::REPL::Plugin;
use Devel::Peek qw(Dump);
use namespace::autoclean;

sub BEFORE_PLUGIN {
    my $self = shift;
    $self->load_plugin('Turtles');
}

sub expr_command_peek {
  my ( $self, $eval, $code ) = @_;

  my @res = $self->eval($code);

  if ( $self->is_error(@res) ) {
    return $self->format(@res);
  } else {
    # can't override output properly
    # FIXME do some dup wizardry
    Dump(@res);
    return ""; # this is a hack to print nothing after Dump has already printed. PLZ TO FIX KTHX!
  }
}

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::REPL::Plugin::Peek - L<Devel::Peek> plugin for L<Devel::REPL>.

=head1 VERSION

version 1.003029

=head1 SYNOPSIS

  repl> #peek "foo"
  SV = PV(0xb3dba0) at 0xb4abc0
    REFCNT = 1
    FLAGS = (POK,READONLY,pPOK)
    PV = 0x12bcf70 "foo"\0
    CUR = 3
    LEN = 4

=head1 DESCRIPTION

This L<Devel::REPL::Plugin> adds a C<peek> command that calls
L<Devel::Peek/Dump> instead of the normal printing.

=head1 SEE ALSO

L<Devel::REPL>, L<Devel::Peek>

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-REPL>
(or L<bug-Devel-REPL@rt.cpan.org|mailto:bug-Devel-REPL@rt.cpan.org>).

There is also an irc channel available for users of this distribution, at
L<C<#devel> on C<irc.perl.org>|irc://irc.perl.org/#devel-repl>.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2007 by Matt S Trout - mst (at) shadowcatsystems.co.uk (L<http://www.shadowcatsystems.co.uk/>).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
