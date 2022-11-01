use strict;
use warnings;
package Exception::Reporter::Summarizer::Text 0.015;
# ABSTRACT: a summarizer for plain text strings

use parent 'Exception::Reporter::Summarizer';

#pod =head1 OVERVIEW
#pod
#pod This summarizer will summarize simple, non-empty strings by accepting them
#pod verbatim.  They are assumed to be text, and will be encoded to UTF-8.  If that
#pod fails, they will be used verbatim, possibly with strange results.
#pod
#pod The summary's C<ident> will be the first non-blank line of the string.
#pod
#pod =cut

# Maybe in the future we can have options to allow empty strings. -- rjbs,
# 2013-02-06

use Encode ();
use Try::Tiny;

sub can_summarize {
  my ($self, $entry) = @_;
  my $value = $entry->[1];
  return unless defined $value;
  return if ref $value;
  return if ref \$value ne 'SCALAR';
  return 1;
}

sub summarize {
  my ($self, $entry, $internal_arg) = @_;
  my ($name, $value, $arg) = @$entry;

  my $fn_base = $self->sanitize_filename($name);

  my $octets = try {
    encode('utf-8', $value, Encode::FB_CROAK);
  } catch {
    $value;
  };

  my $ident = $value;
  $ident =~ s/\A\n+//;
  ($ident) = split /\n/, $ident;

  return {
    filename => "$fn_base.txt",
    ident    => $ident,
    mimetype => 'text/plain',
    charset  => 'utf-8', # possibly a lie if the try failed
    body     => "$value",
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Exception::Reporter::Summarizer::Text - a summarizer for plain text strings

=head1 VERSION

version 0.015

=head1 OVERVIEW

This summarizer will summarize simple, non-empty strings by accepting them
verbatim.  They are assumed to be text, and will be encoded to UTF-8.  If that
fails, they will be used verbatim, possibly with strange results.

The summary's C<ident> will be the first non-blank line of the string.

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
