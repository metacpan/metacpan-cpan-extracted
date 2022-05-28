use strict;
use warnings;
package Devel::REPL::Plugin::LexEnv;
# ABSTRACT: Provide a lexical environment for the REPL

our $VERSION = '1.003029';

use Devel::REPL::Plugin;
use namespace::autoclean;
use Lexical::Persistence;

sub BEFORE_PLUGIN {
    my $self = shift;
    $self->load_plugin('FindVariable');
}

has 'lexical_environment' => (
  isa => 'Lexical::Persistence',
  is => 'rw',
  lazy => 1,
  default => sub { Lexical::Persistence->new }
);

has '_hints' => (
  isa => "ArrayRef",
  is => "rw",
  predicate => '_has_hints',
);

around 'mangle_line' => sub {
  my $orig = shift;
  my ($self, @rest) = @_;
  my $line = $self->$orig(@rest);
  my $lp = $self->lexical_environment;
  # Collate my declarations for all LP context vars then add '';
  # so an empty statement doesn't return anything (with a no warnings
  # to prevent "Useless use ..." warning)
  return join('',
    'BEGIN { if ( $_REPL->_has_hints ) { ( $^H, %^H ) = @{ $_REPL->_hints } } }',
    ( map { "my $_;\n" } keys %{$lp->get_context('_')} ),
    qq{{ no warnings 'void'; ''; }\n},
    $line,
    '; BEGIN { $_REPL->_hints([ $^H, %^H ]) }',
  );
};

around 'execute' => sub {
  my $orig = shift;
  my ($self, $to_exec, @rest) = @_;
  my $wrapped = $self->lexical_environment->wrap($to_exec);
  return $self->$orig($wrapped, @rest);
};

# this doesn't work! yarg. we now just check $self->can('lexical_environment')
# in FindVariable

#around 'find_variable' => sub {
#  my $orig = shift;
#  my ($self, $name) = @_;
#
#  return \( $self->lexical_environment->get_context('_')->{$name} )
#    if exists $self->lexical_environment->get_context('_')->{$name};
#
#  return $orig->(@_);
#};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::REPL::Plugin::LexEnv - Provide a lexical environment for the REPL

=head1 VERSION

version 1.003029

=head1 SYNOPSIS

 # in your re.pl file:
 use Devel::REPL;
 my $repl = Devel::REPL->new;
 $repl->load_plugin('LexEnv');

 $repl->lexical_environment->do(<<'CODEZ');
 use FindBin;
 use lib "$FindBin::Bin/../lib";
 use MyApp::Schema;
 my $s = MyApp::Schema->connect('dbi:Pg:dbname=foo','broseph','elided');
 CODEZ

 $repl->run;

 # after you run re.pl:
 $ warn $s->resultset('User')->first->first_name # <-- note that $s works

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-REPL>
(or L<bug-Devel-REPL@rt.cpan.org|mailto:bug-Devel-REPL@rt.cpan.org>).

There is also an irc channel available for users of this distribution, at
L<C<#devel> on C<irc.perl.org>|irc://irc.perl.org/#devel-repl>.

=head1 AUTHOR

Matt S Trout - mst (at) shadowcatsystems.co.uk (L<http://www.shadowcatsystems.co.uk/>)

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2007 by Matt S Trout - mst (at) shadowcatsystems.co.uk (L<http://www.shadowcatsystems.co.uk/>).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
