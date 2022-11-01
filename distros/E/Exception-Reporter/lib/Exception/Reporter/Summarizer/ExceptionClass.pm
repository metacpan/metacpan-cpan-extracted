use strict;
use warnings;
package Exception::Reporter::Summarizer::ExceptionClass 0.015;
# ABSTRACT: a summarizer for Exception::Class exceptions

use parent 'Exception::Reporter::Summarizer';

#pod =head1 OVERVIEW
#pod
#pod This summarizer handles only L<Exception::Class> objects.  A dumped exception
#pod will result in between one and four summaries:
#pod
#pod   * a text summary of the exceptions full message
#pod   * if available, a dump of the exception's pid, time, uid, etc.
#pod   * if available, the stringification of the exception's stack trace
#pod   * if any fields are defined, a dump of the exception's fields
#pod
#pod =cut

use Exception::Class 1.30; # NoContextInfo
use Try::Tiny;

sub can_summarize {
  my ($self, $entry) = @_;
  return try { $entry->[1]->isa('Exception::Class::Base') };
}

sub summarize {
  my ($self, $entry, $internal_arg) = @_;
  my ($name, $exception, $arg) = @$entry;

  my $fn_base = $self->sanitize_filename($name);

  my $ident = $exception->error;
  ($ident) = split /\n/, $ident; # only the first line, please

  # Yes, I have seen the case below need handling! -- rjbs, 2012-07-03
  $ident = "exception of class " . ref $exception unless length $ident;

  # Another option here is to dump this in a few parts:
  # * a YAML dump of the message, error, and fields
  # * a dump of the stack trace
  my @summaries = ({
    filename => "exception-msg.txt",
    mimetype => 'text/plain',
    ident    => $ident,
    body     => $exception->full_message,
  });

  if (! $exception->NoContextInfo) {
    my $context = $self->dump({
      time => $exception->time,
      pid  => $exception->pid,
      uid  => $exception->uid,
      euid => $exception->euid,
      gid  => $exception->gid,
      egid => $exception->egid,
    }, { basename => 'exception-context' });

    push @summaries, (
      {
        filename => "exception-stack.txt",
        mimetype => 'text/plain',
        ident    => "stack trace",
        body     => $exception->trace->as_string({
          max_arg_length => 0,
        }),
      },
      {
        filename => 'exception-context.txt',
        %$context,
        ident    => 'exception context info',
      },
    );
  }

  if ($exception->Fields) {
    my $hash = {};
    for my $field ($exception->Fields) {
      $hash->{ $field } = $exception->$field;
    }

    my $fields = $self->dump($hash, { basename => 'exception-fields' });
    push @summaries, {
      filename => "exception-fields.txt",
      %$fields,
      ident    => "exception fields",
    };
  }

  return @summaries;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Exception::Reporter::Summarizer::ExceptionClass - a summarizer for Exception::Class exceptions

=head1 VERSION

version 0.015

=head1 OVERVIEW

This summarizer handles only L<Exception::Class> objects.  A dumped exception
will result in between one and four summaries:

  * a text summary of the exceptions full message
  * if available, a dump of the exception's pid, time, uid, etc.
  * if available, the stringification of the exception's stack trace
  * if any fields are defined, a dump of the exception's fields

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
