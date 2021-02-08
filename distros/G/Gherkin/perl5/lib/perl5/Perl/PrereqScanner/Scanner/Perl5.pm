use strict;
use warnings;

package Perl::PrereqScanner::Scanner::Perl5;
# ABSTRACT: scan for core Perl 5 language indicators of required modules
$Perl::PrereqScanner::Scanner::Perl5::VERSION = '1.023';
use Moose;
with 'Perl::PrereqScanner::Scanner';

#pod =head1 DESCRIPTION
#pod
#pod This scanner will look for the following indicators:
#pod
#pod =begin :list
#pod
#pod * plain lines beginning with C<use>, C<require>, or C<no> in your perl modules and scripts, including minimum perl version
#pod
#pod * regular inheritance declared with the C<base> and C<parent> pragmata
#pod
#pod =end :list
#pod
#pod Since Perl does not allow you to supply a version requirement with a
#pod C<require> statement, the scanner will check the statement after the
#pod C<require Module> to see if it is C<< Module->VERSION( minimum_version ); >>.
#pod
#pod In order to provide a minimum version, that method call must meet the
#pod following requirements:
#pod
#pod =begin :list
#pod
#pod * it must be the very next statement after C<require Module>.  Nothing can separate them but whitespace and comments (and one semicolon).
#pod
#pod * C<Module> must be a bareword, and match the C<require> exactly.
#pod
#pod * C<minimum_version> must be a literal number, v-string, or single-quoted string.  Double quotes are not allowed.
#pod
#pod =end :list
#pod
#pod =cut

sub scan_for_prereqs {
  my ($self, $ppi_doc, $req) = @_;

  # regular use, require, and no
  my $includes = $ppi_doc->find('Statement::Include') || [];
  for my $node ( @$includes ) {
    # minimum perl version
    if ( $node->version ) {
      $req->add_minimum(perl => $node->version);
      next;
    }

    # inheritance
    if (grep { $_ eq $node->module } qw{ base parent }) {
      # rt#55713: skip arguments to base or parent, focus only on inheritance
      my @meat = grep {
           $_->isa('PPI::Token::QuoteLike::Words')
        || $_->isa('PPI::Token::Quote')
        } $node->arguments;

      my @parents = map { $self->_q_contents($_) } @meat;
      $req->add_minimum($_ => 0) for @parents;
    }

    # regular modules
    my $version = $node->module_version ? $node->module_version->content : 0;

    # rt#55851: 'require $foo;' shouldn't add any prereq
    next unless $node->module;

    # See if the next statement after require is Module->VERSION(min):
    $version = $self->_check_required_version($node) || 0
        if not $version and $node->type =~ /\A(?:require|use)\z/;

    $req->add_minimum($node->module, $version);
  }
}

# For "require Module", see if the next statement is Module->VERSION(min):
sub _check_required_version {
  my ($self, $node) = @_;

  my $next = $node->snext_sibling;

  return unless $next and $next->class eq 'PPI::Statement';

  my ($invocant, $op, $method, $list, $too_much) = $next->schildren;

  return unless defined $list # need enough children
      and $op->class eq 'PPI::Token::Operator'
      and $op->content eq '->'
      and $method->content eq 'VERSION'
      and (not defined $too_much # but not too many children
           or $too_much->content eq ';')
      and $invocant->content eq $node->module
      and $list->class eq 'PPI::Structure::List'
      and $list->braces eq '()'
      and $list->schildren == 1;

  my $exp = $list->schild(0);

  return unless $exp->class eq 'PPI::Statement::Expression'
      and $exp->schildren == 1;

  my $arg = $exp->schild(0);

  if ($arg->isa('PPI::Token::Number')) {
    return $arg->content;
  } elsif ($arg->isa('PPI::Token::Quote') and $arg->can('literal')) {
    return $arg->literal;
  }

  return;                       # No minimum version found
} # end _check_required_version

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::PrereqScanner::Scanner::Perl5 - scan for core Perl 5 language indicators of required modules

=head1 VERSION

version 1.023

=head1 DESCRIPTION

This scanner will look for the following indicators:

=over 4

=item *

plain lines beginning with C<use>, C<require>, or C<no> in your perl modules and scripts, including minimum perl version

=item *

regular inheritance declared with the C<base> and C<parent> pragmata

=back

Since Perl does not allow you to supply a version requirement with a
C<require> statement, the scanner will check the statement after the
C<require Module> to see if it is C<< Module->VERSION( minimum_version ); >>.

In order to provide a minimum version, that method call must meet the
following requirements:

=over 4

=item *

it must be the very next statement after C<require Module>.  Nothing can separate them but whitespace and comments (and one semicolon).

=item *

C<Module> must be a bareword, and match the C<require> exactly.

=item *

C<minimum_version> must be a literal number, v-string, or single-quoted string.  Double quotes are not allowed.

=back

=head1 AUTHORS

=over 4

=item *

Jerome Quelin

=item *

Ricardo Signes <rjbs@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
