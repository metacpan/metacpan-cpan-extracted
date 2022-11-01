use strict;
use warnings;
package Exception::Reporter::Summarizer::Fallback 0.015;
# ABSTRACT: a summarizer for stuff you couldn't deal with otherwise

use parent 'Exception::Reporter::Summarizer';

#pod =head1 OVERVIEW
#pod
#pod This summarizer will accept any input and summarize it by dumping it with the
#pod Exception::Reporter's dumper.
#pod
#pod I recommended that this summarizer is always in your list of summarizers,
#pod and always last.
#pod
#pod =cut

use Try::Tiny;

sub can_summarize { 1 }

sub summarize {
  my ($self, $entry, $internal_arg) = @_;
  my ($name, $value, $arg) = @$entry;

  my $fn_base = $self->sanitize_filename($name);

  my $dump = $self->dump($value, { basename => $fn_base });

  return {
    filename => "$fn_base.txt",
    ident    => "dump of $name",
    %$dump,
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Exception::Reporter::Summarizer::Fallback - a summarizer for stuff you couldn't deal with otherwise

=head1 VERSION

version 0.015

=head1 OVERVIEW

This summarizer will accept any input and summarize it by dumping it with the
Exception::Reporter's dumper.

I recommended that this summarizer is always in your list of summarizers,
and always last.

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
