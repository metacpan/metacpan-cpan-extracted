use strict;
use warnings;
package Exception::Reporter::Summarizer::File;
# ABSTRACT: a summarizer for a File object
$Exception::Reporter::Summarizer::File::VERSION = '0.014';
use parent 'Exception::Reporter::Summarizer';

#pod =head1 OVERVIEW
#pod
#pod This summarizer expects L<Exception::Reporter::Dumpable::File> objects, and
#pod summarizes them just as you might expect.
#pod
#pod =cut

use File::Basename ();
use Try::Tiny;

sub can_summarize {
  my ($self, $entry) = @_;
  return try { $entry->[1]->isa('Exception::Reporter::Dumpable::File') };
}

sub summarize {
  my ($self, $entry) = @_;
  my ($name, $value, $arg) = @$entry;

  my $fn_base = $self->sanitize_filename(
    File::Basename::basename($value->path)
  );

  return {
    filename => $fn_base,
    mimetype => $value->mimetype,
    ident    => "file at $name",
    body     => ${ $value->contents_ref },
    body_is_bytes => 1,
    ($value->charset ? (charset => $value->charset) : ()),
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Exception::Reporter::Summarizer::File - a summarizer for a File object

=head1 VERSION

version 0.014

=head1 OVERVIEW

This summarizer expects L<Exception::Reporter::Dumpable::File> objects, and
summarizes them just as you might expect.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
