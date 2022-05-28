use strict;
use warnings;
package Devel::REPL::Plugin::PPI;
# ABSTRACT: PPI dumping of Perl code

our $VERSION = '1.003029';

use Devel::REPL::Plugin;
use PPI;
use PPI::Dumper;
use namespace::autoclean;

sub BEFORE_PLUGIN {
    my $self = shift;
    $self->load_plugin('Turtles');
}

sub expr_command_ppi {
  my ( $self, $eval, $code ) = @_;

  my $document = PPI::Document->new(\$code);
  my $dumper   = PPI::Dumper->new($document);
  return $dumper->string;
}

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::REPL::Plugin::PPI - PPI dumping of Perl code

=head1 VERSION

version 1.003029

=head1 SYNOPSIS

  repl> #ppi Devel::REPL
  PPI::Document
    PPI::Statement
      PPI::Token::Word    'Devel::REPL'

  repl> #ppi {
  > warn $];
  > }
  PPI::Document
    PPI::Statement::Compound
      PPI::Structure::Block       { ... }
        PPI::Token::Whitespace    '\n'
        PPI::Statement
          PPI::Token::Word        'warn'
          PPI::Token::Whitespace          ' '
          PPI::Token::Magic       '$]'
          PPI::Token::Structure   ';'
        PPI::Token::Whitespace    '\n'

=head1 DESCRIPTION

This plugin provides a C<ppi> command that uses L<PPI::Dumper> to dump
L<PPI>-parsed Perl documents.

The code is not actually executed, which means that when used with
L<Deve::REPL::Plugin::OutputCache> there is no new value in C<_>.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-REPL>
(or L<bug-Devel-REPL@rt.cpan.org|mailto:bug-Devel-REPL@rt.cpan.org>).

There is also an irc channel available for users of this distribution, at
L<C<#devel> on C<irc.perl.org>|irc://irc.perl.org/#devel-repl>.

=head1 AUTHOR

Shawn M Moore E<lt>sartak@gmail.comE<gt>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2007 by Matt S Trout - mst (at) shadowcatsystems.co.uk (L<http://www.shadowcatsystems.co.uk/>).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
