package Dist::Zilla::Role::PPI 6.032;
# ABSTRACT: a role for plugins which use PPI

use Moose::Role;

use Dist::Zilla::Pragmas;

use Digest::MD5 qw(md5);

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod This role provides some common utilities for plugins which use L<PPI>.
#pod
#pod =method ppi_document_for_file
#pod
#pod   my $document = $self->ppi_document_for_file($file);
#pod
#pod Given a dzil file object (anything that does L<Dist::Zilla::Role::File>), this
#pod method returns a new L<PPI::Document> for that file's content.
#pod
#pod Internally, this method caches these documents. If multiple plugins want a
#pod document for the same file, this avoids reparsing it.
#pod
#pod =cut

my %CACHE;

sub ppi_document_for_file {
  my ($self, $file) = @_;

  my $encoded_content = $file->encoded_content;

  # We cache on the MD5 checksum to detect if the document has been modified
  # by some other plugin since it was last parsed, making our document invalid.
  my $md5 = md5($encoded_content);
  return $CACHE{$md5}->clone if $CACHE{$md5};

  my $content = $file->content;

  require PPI::Document;
  my $document = PPI::Document->new(\$content)
    or Carp::croak(PPI::Document->errstr . ' while processing file ' . $file->name);

  return ($CACHE{$md5} = $document)->clone;
}

#pod =method save_ppi_document_to_file
#pod
#pod   my $document = $self->save_ppi_document_to_file($document,$file);
#pod
#pod Given a L<PPI::Document> and a dzil file object (anything that does
#pod L<Dist::Zilla::Role::File>), this method saves the serialized document in the
#pod file.
#pod
#pod It also updates the internal PPI document cache with the new document.
#pod
#pod =cut

sub save_ppi_document_to_file {
  my ($self, $document, $file) = @_;

  my $new_content = $document->serialize;

  $file->content($new_content);

  my $encoded = $file->encoded_content;

  $CACHE{ md5($encoded) } = $document->clone;
}

#pod =method document_assigns_to_variable
#pod
#pod   if( $self->document_assigns_to_variable($document, '$FOO')) { ... }
#pod
#pod This method returns true if the document assigns to the given variable (the
#pod sigil must be included).
#pod
#pod =cut

sub document_assigns_to_variable {
  my ($self, $document, $variable) = @_;

  my $package_stmts = $document->find('PPI::Statement::Package');
  my @namespaces = map { $_->namespace } @{ $package_stmts || []};

  my ($sigil, $varname) = ($variable =~ m'^([$@%*])(.+)$');

  my $package;
  my $finder = sub {
    my $node = $_[1];

    if ($node->isa('PPI::Statement')
      && !$node->isa('PPI::Statement::End')
      && !$node->isa('PPI::Statement::Data')) {

      if ($node->isa('PPI::Statement::Variable')) {
        return (grep { $_ eq $variable } $node->variables) ? 1 : undef;
      }

      return 1 if grep {
        my $child = $_;
        $child->isa('PPI::Token::Symbol')
          and grep {
            $child->canonical eq "${sigil}${_}::${varname}"
                and $node->content =~ /\Q${sigil}${_}::${varname}\E.*=/
          } @namespaces
      } $node->children;
    }
    return 0;   # not found
  };

  my $rv = $document->find_any($finder);
  Carp::croak($document->errstr) unless defined $rv;

  return $rv;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::PPI - a role for plugins which use PPI

=head1 VERSION

version 6.032

=head1 DESCRIPTION

This role provides some common utilities for plugins which use L<PPI>.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 METHODS

=head2 ppi_document_for_file

  my $document = $self->ppi_document_for_file($file);

Given a dzil file object (anything that does L<Dist::Zilla::Role::File>), this
method returns a new L<PPI::Document> for that file's content.

Internally, this method caches these documents. If multiple plugins want a
document for the same file, this avoids reparsing it.

=head2 save_ppi_document_to_file

  my $document = $self->save_ppi_document_to_file($document,$file);

Given a L<PPI::Document> and a dzil file object (anything that does
L<Dist::Zilla::Role::File>), this method saves the serialized document in the
file.

It also updates the internal PPI document cache with the new document.

=head2 document_assigns_to_variable

  if( $self->document_assigns_to_variable($document, '$FOO')) { ... }

This method returns true if the document assigns to the given variable (the
sigil must be included).

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
