package Dist::Zilla::Plugin::FileFinder::ByName 6.032;
# ABSTRACT: FileFinder matching on pathnames

use Moose;
with 'Dist::Zilla::Role::FileFinder';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

#pod =head1 SYNOPSIS
#pod
#pod In your F<dist.ini>:
#pod
#pod   [FileFinder::ByName / MyFiles]
#pod   dir   = bin     ; look in the bin/ directory
#pod   dir   = lib     ; and the lib/ directory
#pod   file  = *.pl    ; for .pl files
#pod   match = \.pm$   ; and for .pm files
#pod   skip  = ignore  ; that don't have "ignore" in the path
#pod
#pod =head1 CREDITS
#pod
#pod This plugin was originally contributed by Christopher J. Madsen.
#pod
#pod =cut

use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw(ArrayRef RegexpRef Str);

use Text::Glob 0.08 qw(glob_to_regex_string);

#pod =attr dir
#pod
#pod The file must be located in one of the specified directories (relative
#pod to the root directory of the dist).
#pod
#pod =attr file
#pod
#pod The filename must match one of the specified patterns (which are
#pod converted to regexs using L<Text::Glob> and combined with any C<match>
#pod rules).
#pod
#pod =cut

has dirs => (
  is       => 'ro',
  isa      => ArrayRef[Str],
  default  => sub { [] },
);

has files => (
  is      => 'ro',
  isa      => ArrayRef[Str],
  default => sub { [] },
);

{
  my $type = subtype as ArrayRef[RegexpRef];
  coerce $type, from ArrayRef[Str], via { [map { qr/$_/ } @$_] };

#pod =attr match
#pod
#pod The pathname must match one of these regular expressions.
#pod
#pod =attr skip
#pod
#pod The pathname must I<not> match any of these regular expressions.
#pod
#pod =cut

  has matches => (
    is      => 'ro',
    isa     => $type,
    coerce  => 1,
    default => sub { [] },
  );

  has skips => (
    is      => 'ro',
    isa     => $type,
    coerce  => 1,
    default => sub { [] },
  );
}

sub mvp_aliases { +{ qw(
  dir      dirs
  file     files
  match    matches
  matching matches
  skip     skips
  except   skips
) } }

sub mvp_multivalue_args { qw(dirs files matches skips) }

sub _join_re {
  my $list = shift;
  return undef unless @$list;
  # Special case to avoid stringify+compile
  return $list->[0] if @$list == 1;
  # Wrap each element to ensure that alternations are isolated
  my $re = join('|', map { "(?:$_)" } @$list);
  qr/$re/
}

sub find_files {
  my $self = shift;

  my $skip  = _join_re($self->skips);
  my $dir   = _join_re([ map { qr!^\Q$_/! } @{ $self->dirs } ]);
  my $match = _join_re([
    (map { my $re = glob_to_regex_string($_); qr!(?:\A|/)$re\z! }
         @{ $self->files }),
    @{ $self->matches }
  ]);

  my $files = $self->zilla->files;

  $files = [ grep {
    my $name = $_->name;
    (not defined $dir   or $name =~ $dir)   and
    (not defined $match or $name =~ $match) and
    (not defined $skip  or $name !~ $skip)
  } @$files ];

  $self->log_debug("No files found") unless @$files;
  $self->log_debug("Found " . $_->name) for @$files;

  $files;
}

__PACKAGE__->meta->make_immutable;
1;

#pod =head1 DESCRIPTION
#pod
#pod FileFinder::ByName is a L<FileFinder|Dist::Zilla::Role::FileFinder> that
#pod selects files by matching the criteria you specify against the pathname.
#pod
#pod There are three types of criteria you can use.  C<dir> limits the
#pod search to a particular directory.  C<match> is a regular expression
#pod that must match the pathname.  C<skip> is a regular expression that
#pod must not match the pathname.
#pod
#pod Each key can be specified multiple times.  Multiple occurrences of the
#pod same key are ORed together.  Different keys are ANDed together.  That
#pod means that to be selected, a file must be located in one of the
#pod C<dir>s, must match one of the C<match> regexs, and must not match any
#pod of the C<skip> regexs.
#pod
#pod Note that C<file> and C<match> are considered to be the I<same> key.
#pod They're just different ways to write a regex that the pathname must match.
#pod
#pod Omitting a particular key means that criterion will not apply to the
#pod search.  Omitting all keys will select every file in your dist.
#pod
#pod Note: If you need to OR different types of criteria, then use more
#pod than one instance of FileFinder::ByName.  A
#pod L<FileFinderUser|Dist::Zilla::Role::FileFinderUser> should allow you
#pod to specify more than one FileFinder to use.
#pod
#pod =for Pod::Coverage
#pod mvp_aliases
#pod mvp_multivalue_args
#pod find_files

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::FileFinder::ByName - FileFinder matching on pathnames

=head1 VERSION

version 6.032

=head1 SYNOPSIS

In your F<dist.ini>:

  [FileFinder::ByName / MyFiles]
  dir   = bin     ; look in the bin/ directory
  dir   = lib     ; and the lib/ directory
  file  = *.pl    ; for .pl files
  match = \.pm$   ; and for .pm files
  skip  = ignore  ; that don't have "ignore" in the path

=head1 DESCRIPTION

FileFinder::ByName is a L<FileFinder|Dist::Zilla::Role::FileFinder> that
selects files by matching the criteria you specify against the pathname.

There are three types of criteria you can use.  C<dir> limits the
search to a particular directory.  C<match> is a regular expression
that must match the pathname.  C<skip> is a regular expression that
must not match the pathname.

Each key can be specified multiple times.  Multiple occurrences of the
same key are ORed together.  Different keys are ANDed together.  That
means that to be selected, a file must be located in one of the
C<dir>s, must match one of the C<match> regexs, and must not match any
of the C<skip> regexs.

Note that C<file> and C<match> are considered to be the I<same> key.
They're just different ways to write a regex that the pathname must match.

Omitting a particular key means that criterion will not apply to the
search.  Omitting all keys will select every file in your dist.

Note: If you need to OR different types of criteria, then use more
than one instance of FileFinder::ByName.  A
L<FileFinderUser|Dist::Zilla::Role::FileFinderUser> should allow you
to specify more than one FileFinder to use.

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

=head2 dir

The file must be located in one of the specified directories (relative
to the root directory of the dist).

=head2 file

The filename must match one of the specified patterns (which are
converted to regexs using L<Text::Glob> and combined with any C<match>
rules).

=head2 match

The pathname must match one of these regular expressions.

=head2 skip

The pathname must I<not> match any of these regular expressions.

=head1 CREDITS

This plugin was originally contributed by Christopher J. Madsen.

=for Pod::Coverage mvp_aliases
mvp_multivalue_args
find_files

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
