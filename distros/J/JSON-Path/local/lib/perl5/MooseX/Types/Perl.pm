package MooseX::Types::Perl;
# ABSTRACT: Moose types that check against Perl syntax
$MooseX::Types::Perl::VERSION = '0.101343';
use MooseX::Types -declare => [ qw(
  DistName

  ModuleName
  PackageName

  Identifier
  SafeIdentifier

  LaxVersionStr
  StrictVersionStr
  VersionObject
) ];

# =head1 SYNOPSIS
#
#   use MooseX::Types::Perl qw(
#     DistName
#
#     ModuleName
#     PackageName
#
#     Identifier
#     SafeIdentifier
#
#     LaxVersionStr
#     StrictVersionStr
#     VersionObject
#   );
#
# =head1 DESCRIPTION
#
# This library provides L<Moose types|MooseX::Types> for checking things (mostly
# strings) against syntax that is, or is a reasonable subset of, Perl syntax.
#
# =cut

use MooseX::Types::Moose qw(Object Str);
use Params::Util qw(_CLASS);
use version 0.82;

# =head1 TYPES
#
# =head2 ModuleName
#
# =head2 PackageName
#
# These types are identical, and expect a string that could be a package or
# module name.  That's basically a bunch of identifiers stuck together with
# double-colons.  One key quirk is that parts of the package name after the
# first may begin with digits.
#
# The use of an apostrophe as a package separator is not permitted.
#
# =cut

subtype ModuleName,  as Str, where { ! /\P{ASCII}/ && _CLASS($_) };
subtype PackageName, as Str, where { ! /\P{ASCII}/ && _CLASS($_) };

# =head2 DistName
#
# The DistName type checks for a string like C<MooseX-Types-Perl>, the sort of
# thing used to name CPAN distributions.  In general, it's like the more familiar
# L<ModuleName>, but with hyphens instead of double-colons.
#
# In reality, a few distribution names may not match this pattern -- most
# famously, C<CGI.pm> is the name of the distribution that contains CGI.  These
# exceptions are few and far between, and deciding what a C<LaxDistName> type
# would look like has not seemed worth it, yet.
#
# =cut

subtype DistName,
  as Str,
  where   {
    return if /:/;
    (my $str = $_) =~ s/-/::/g;
    $str !~ /\P{ASCII}/ && _CLASS($str)
  },
  message {
    /::/
    ? "$_ looks like a module name, not a dist name"
    : "$_ is not a valid dist name"
  };

# LaxDistName -- how does this work, other than "like some characters, okay?"

# =head2 Identifier
#
# An L<Identifier|perldata/Variable names> is something that could be used as a
# symbol name or other identifier (filehandle, directory handle, subroutine name,
# format name, or label).  It's what you put after the sigil (dollar sign, at
# sign, percent sign) in a variable name.  Generally, it's a bunch of
# alphanumeric characters not starting with a digit.
#
# Although Perl identifiers may contain non-ASCII characters in some
# circumstances, this type does not allow it.  A C<UnicodeIdentifier> type may be
# added in the future.
#
# =cut

subtype Identifier,
  as Str,
  where { / \A [_a-z] [_a-z0-9]* \z /xi; };

# =head2 SafeIdentifier
#
# SafeIdentifiers are just like Identifiers, but omit the single-letter variables
# underscore, a, and b, as these have special significance.
#
# =cut

subtype SafeIdentifier,
  as Identifier,
  where { ! / \A [_ab] \z /x; };

# =head2 LaxVersionStr
#
# =head2 StrictVersionStr
#
# Lax and strict version strings use the L<is_lax|version/is_lax> and
# L<is_strict|version/is_strict> methods from C<version> to check if the given
# string would be a valid lax or strict version.  L<version::Internals> covers
# the details but basically:  lax versions are everything you may do, and strict
# omit many of the usages best avoided.
#
# =cut

subtype LaxVersionStr,
  as Str,
  where { version::is_lax($_) },
  message { "$_ is not a valid lax version string" };

subtype StrictVersionStr,
  as LaxVersionStr,
  where { version::is_strict($_) },
  message { "$_ is not a valid strict version string" };

# =head2 VersionObject
#
# Just for good measure, this type is included to check if a value is a version
# object.  Coercions from LaxVersionStr (and thus StrictVersionStr) are provided.
#
# =cut

subtype VersionObject,
  as Object,
  where { $_->isa('version') };

coerce VersionObject,
  from LaxVersionStr,
  via { version->parse($_) };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Types::Perl - Moose types that check against Perl syntax

=head1 VERSION

version 0.101343

=head1 SYNOPSIS

  use MooseX::Types::Perl qw(
    DistName

    ModuleName
    PackageName

    Identifier
    SafeIdentifier

    LaxVersionStr
    StrictVersionStr
    VersionObject
  );

=head1 DESCRIPTION

This library provides L<Moose types|MooseX::Types> for checking things (mostly
strings) against syntax that is, or is a reasonable subset of, Perl syntax.

=head1 TYPES

=head2 ModuleName

=head2 PackageName

These types are identical, and expect a string that could be a package or
module name.  That's basically a bunch of identifiers stuck together with
double-colons.  One key quirk is that parts of the package name after the
first may begin with digits.

The use of an apostrophe as a package separator is not permitted.

=head2 DistName

The DistName type checks for a string like C<MooseX-Types-Perl>, the sort of
thing used to name CPAN distributions.  In general, it's like the more familiar
L<ModuleName>, but with hyphens instead of double-colons.

In reality, a few distribution names may not match this pattern -- most
famously, C<CGI.pm> is the name of the distribution that contains CGI.  These
exceptions are few and far between, and deciding what a C<LaxDistName> type
would look like has not seemed worth it, yet.

=head2 Identifier

An L<Identifier|perldata/Variable names> is something that could be used as a
symbol name or other identifier (filehandle, directory handle, subroutine name,
format name, or label).  It's what you put after the sigil (dollar sign, at
sign, percent sign) in a variable name.  Generally, it's a bunch of
alphanumeric characters not starting with a digit.

Although Perl identifiers may contain non-ASCII characters in some
circumstances, this type does not allow it.  A C<UnicodeIdentifier> type may be
added in the future.

=head2 SafeIdentifier

SafeIdentifiers are just like Identifiers, but omit the single-letter variables
underscore, a, and b, as these have special significance.

=head2 LaxVersionStr

=head2 StrictVersionStr

Lax and strict version strings use the L<is_lax|version/is_lax> and
L<is_strict|version/is_strict> methods from C<version> to check if the given
string would be a valid lax or strict version.  L<version::Internals> covers
the details but basically:  lax versions are everything you may do, and strict
omit many of the usages best avoided.

=head2 VersionObject

Just for good measure, this type is included to check if a value is a version
object.  Coercions from LaxVersionStr (and thus StrictVersionStr) are provided.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
