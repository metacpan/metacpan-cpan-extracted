use strict;
use warnings;
package Exception::Reporter::Summarizer::File 0.015;
# ABSTRACT: a summarizer for a File object

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

version 0.015

=head1 OVERVIEW

This summarizer expects L<Exception::Reporter::Dumpable::File> objects, and
summarizes them just as you might expect.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
