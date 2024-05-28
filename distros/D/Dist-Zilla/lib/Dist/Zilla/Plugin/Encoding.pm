package Dist::Zilla::Plugin::Encoding 6.032;
# ABSTRACT: set the encoding of arbitrary files

use Moose;
with 'Dist::Zilla::Role::EncodingProvider';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

#pod =head1 SYNOPSIS
#pod
#pod This plugin allows you to explicitly set the encoding on some files in your
#pod distribution. You can either specify the exact set of files (with the
#pod "filenames" parameter) or provide the regular expressions to check (using
#pod "match").
#pod
#pod In your F<dist.ini>:
#pod
#pod   [Encoding]
#pod   encoding = Latin-3
#pod
#pod   filename = t/esperanto.t  ; this file is Esperanto
#pod   match     = ^t/urkish/    ; these are all Turkish
#pod
#pod =cut

sub mvp_multivalue_args { qw(filenames matches ignore) }
sub mvp_aliases { return { filename => 'filenames', match => 'matches' } }

#pod =attr encoding
#pod
#pod This is the encoding to set on the selected files. The special value "bytes"
#pod can be used to indicate raw files that should not be encoded.
#pod
#pod =cut

has encoding => (
  is   => 'ro',
  isa  => 'Str',
  required => 1,
);

#pod =attr filenames
#pod
#pod This is an arrayref of filenames to have their encoding set.
#pod
#pod =cut

has filenames => (
  is   => 'ro',
  isa  => 'ArrayRef',
  default => sub { [] },
);

#pod =attr matches
#pod
#pod This is an arrayref of regular expressions.  Any file whose name matches one of
#pod these regex will have its encoding set.
#pod
#pod =cut

has matches => (
  is   => 'ro',
  isa  => 'ArrayRef',
  default => sub { [] },
);

#pod =attr ignore
#pod
#pod This is an arrayref of regular expressions.  Any file whose name matches one of
#pod these regex will B<not> have its encoding set. Useful to ignore a few files
#pod that would otherwise be selected by C<matches>.
#pod
#pod =cut

has ignore => (
  is   => 'ro',
  isa  => 'ArrayRef',
  default => sub { [] },
);

sub set_file_encodings {
  my ($self) = @_;

  # never match (at least the filename characters)
  my $matches_regex = qr/\000/;

  $matches_regex = qr/$matches_regex|$_/ for @{$self->matches};

  # \A\Q$_\E should also handle the `eq` check
  $matches_regex = qr/$matches_regex|\A\Q$_\E/ for @{$self->filenames};

  my( $ignore_regex ) = map { $_ && qr/$_/ } join '|', @{ $self->ignore };

  for my $file (@{$self->zilla->files}) {
    next unless $file->name =~ $matches_regex;

    next if $ignore_regex and $file->name =~ $ignore_regex;

    $self->log_debug([
      'setting encoding of %s to %s',
      $file->name,
      $self->encoding,
    ]);

    $file->encoding($self->encoding);
  }

  return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Encoding - set the encoding of arbitrary files

=head1 VERSION

version 6.032

=head1 SYNOPSIS

This plugin allows you to explicitly set the encoding on some files in your
distribution. You can either specify the exact set of files (with the
"filenames" parameter) or provide the regular expressions to check (using
"match").

In your F<dist.ini>:

  [Encoding]
  encoding = Latin-3

  filename = t/esperanto.t  ; this file is Esperanto
  match     = ^t/urkish/    ; these are all Turkish

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

=head1 ATTRIBUTES

=head2 encoding

This is the encoding to set on the selected files. The special value "bytes"
can be used to indicate raw files that should not be encoded.

=head2 filenames

This is an arrayref of filenames to have their encoding set.

=head2 matches

This is an arrayref of regular expressions.  Any file whose name matches one of
these regex will have its encoding set.

=head2 ignore

This is an arrayref of regular expressions.  Any file whose name matches one of
these regex will B<not> have its encoding set. Useful to ignore a few files
that would otherwise be selected by C<matches>.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
