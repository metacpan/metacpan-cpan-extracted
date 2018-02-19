package Dist::Zilla::Types 6.011;
# ABSTRACT: dzil-specific type library

use namespace::autoclean;

#pod =head1 OVERVIEW
#pod
#pod This library provides L<MooseX::Types> types for use by Dist::Zilla.  These
#pod types are not (yet?) for public consumption, and you should not rely on them.
#pod
#pod Dist::Zilla uses a number of types found in L<MooseX::Types::Perl>.  Maybe
#pod that's what you want.
#pod
#pod =cut

use MooseX::Types -declare => [qw(
  License OneZero YesNoStr ReleaseStatus 
  Path ArrayRefOfPaths
  _Filename
)];
use MooseX::Types::Moose qw(Str Int Defined ArrayRef);
use Path::Tiny;

subtype License, as class_type('Software::License');

subtype Path, as class_type('Path::Tiny');
coerce Path, from Defined, via {
  require Dist::Zilla::Path;
  Dist::Zilla::Path::path($_);
};

subtype ArrayRefOfPaths, as ArrayRef[Path];
coerce ArrayRefOfPaths, from ArrayRef[Defined], via {
  require Dist::Zilla::Path;
  [ map { Dist::Zilla::Path::path($_) } @$_ ];
};

subtype OneZero, as Str, where { $_ eq '0' or $_ eq '1' };

subtype YesNoStr, as Str, where { /\A(?:y|ye|yes)\Z/i or /\A(?:n|no)\Z/i };

subtype ReleaseStatus, as Str, where { /\A(?:stable|testing|unstable)\z/ };

coerce OneZero, from YesNoStr, via { /\Ay/i ? 1 : 0 };

subtype _Filename, as Str,
  where   { $_ !~ qr/(?:\x{0a}|\x{0b}|\x{0c}|\x{0d}|\x{85}|\x{2028}|\x{2029})/ },
  message { "Filename not a Str, or contains a newline or other vertical whitespace" };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Types - dzil-specific type library

=head1 VERSION

version 6.011

=head1 OVERVIEW

This library provides L<MooseX::Types> types for use by Dist::Zilla.  These
types are not (yet?) for public consumption, and you should not rely on them.

Dist::Zilla uses a number of types found in L<MooseX::Types::Perl>.  Maybe
that's what you want.

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
