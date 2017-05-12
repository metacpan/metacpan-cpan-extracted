use strict;
use warnings;
package Exception::Reporter::Summarizer::MooseException;
# ABSTRACT: a summarizer for Moose exceptions
$Exception::Reporter::Summarizer::MooseException::VERSION = '0.014';
use parent 'Exception::Reporter::Summarizer';

#pod =head1 OVERVIEW
#pod
#pod This summarizer handles only L<Moose::Exception> objects.  A dumped exception
#pod will result in two summaries:
#pod
#pod   * a text summary of the exceptions full message
#pod   * a dump of the exception object, just in case it's hiding secrets!@
#pod
#pod =cut

use Try::Tiny;

sub can_summarize {
  my ($self, $entry) = @_;
  return try { $entry->[1]->isa('Moose::Exception') };
}

sub summarize {
  my ($self, $entry, $internal_arg) = @_;
  my ($name, $exception, $arg) = @$entry;

  my $fn_base = $self->sanitize_filename($name);

  my $ident = $exception->message;
  ($ident) = split /\n/, $ident; # only the first line, please

  # I've never seen this happen with Moose, but we handle it for
  # Exception::Class, so... -- rjbs, 2016-01-26
  $ident = "Moose exception of class " . ref $exception unless length $ident;

  my @summaries = (
    {
      filename => "exception-msg.txt",
      mimetype => 'text/plain',
      ident    => $ident,
      body     => $exception->as_string,
    },
    {
      filename => "exception-dump.txt",
      %{ $self->dump($exception, { basename => 'exception-dump' }) },
      ident    => "exception dump",
    },
  );

  return @summaries;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Exception::Reporter::Summarizer::MooseException - a summarizer for Moose exceptions

=head1 VERSION

version 0.014

=head1 OVERVIEW

This summarizer handles only L<Moose::Exception> objects.  A dumped exception
will result in two summaries:

  * a text summary of the exceptions full message
  * a dump of the exception object, just in case it's hiding secrets!@

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
