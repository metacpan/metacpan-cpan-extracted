use strict;
use warnings;

package Perl::PrereqScanner::Scanner::Aliased;
# ABSTRACT: scan for OO module aliases via aliased.pm
$Perl::PrereqScanner::Scanner::Aliased::VERSION = '1.023';
use Moose;
with 'Perl::PrereqScanner::Scanner';

#pod =head1 DESCRIPTION
#pod
#pod This scanner will look for aliased OO modules:
#pod
#pod   use aliased 'Some::Long::Long::Name' => 'Short::Name';
#pod
#pod   Short::Name->new;
#pod   ...
#pod
#pod =cut

sub scan_for_prereqs {
  my ($self, $ppi_doc, $req) = @_;

  # regular use and require
  my $includes = $ppi_doc->find('Statement::Include') || [];
  for my $node ( @$includes ) {
    # aliasing
    if (grep { $_ eq $node->module } qw{ aliased }) {
      # We only want the first argument to aliased
      my @args = grep {
           $_->isa('PPI::Token::QuoteLike::Words')
        || $_->isa('PPI::Token::Quote')
        } $node->arguments;

      next unless @args;
      my ($module) = $self->_q_contents($args[0]);
      $req->add_minimum($module => 0);
    }
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::PrereqScanner::Scanner::Aliased - scan for OO module aliases via aliased.pm

=head1 VERSION

version 1.023

=head1 DESCRIPTION

This scanner will look for aliased OO modules:

  use aliased 'Some::Long::Long::Name' => 'Short::Name';

  Short::Name->new;
  ...

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
