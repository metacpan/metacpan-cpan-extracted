use 5.008001;
use strict;
use warnings;

package Dist::Zilla::Plugin::CheckStrictVersion;
# ABSTRACT: BeforeRelease plugin to check for a strict version number
our $VERSION = '0.001'; # VERSION

use Moose 2;
use version ();

with 'Dist::Zilla::Role::BeforeRelease';

#pod =attr decimal_only
#pod
#pod If true, only a decimal (non-tuple) version is allowed.  Default is false.
#pod
#pod =cut

has decimal_only => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

#pod =attr tuple_only
#pod
#pod If true, only a tuple (a.k.a. 'dotted-decimal') version is allowed.  Default is
#pod false.
#pod
#pod =cut

has tuple_only => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

# methods

sub before_release {
    my $self = shift;
    my $ver  = $self->zilla->version;

    $ver = version->parse($ver);

    $self->log_fatal("version $ver fails version::is_strict")
      unless version::is_strict("$ver");

    if ( $self->decimal_only ) {
        $self->log_fatal("version $ver is not a decimal type version")
          if $ver->is_qv;
    }

    if ( $self->tuple_only ) {
        $self->log_fatal("version $ver is not a tuple type version")
          unless $ver->is_qv;
    }

    return;
}

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::CheckStrictVersion - BeforeRelease plugin to check for a strict version number

=head1 VERSION

version 0.001

=head1 SYNOPSIS

In your F<dist.ini> file:

    [CheckStrictVersion]
    decimal_only = 1

=head1 DESCRIPTION

This module enforces strict versions, with optional enforcement of 'decimal' or 'tuple'
(a.k.a 'dotted decimal') forms.

As a reminder, here are the rules for strict versions from L<version::Internals>:

    v1.234.5
        For dotted-decimal versions, a leading 'v' is required, with three
        or more sub-versions of no more than three digits. A leading 0
        (zero) before the first sub-version (in the above example, '1') is
        also prohibited.

    2.3456
        For decimal versions, an integer portion (no leading 0), a decimal
        point, and one or more digits to the right of the decimal are all
        required.

=head1 ATTRIBUTES

=head2 decimal_only

If true, only a decimal (non-tuple) version is allowed.  Default is false.

=head2 tuple_only

If true, only a tuple (a.k.a. 'dotted-decimal') version is allowed.  Default is
false.

=for Pod::Coverage before_release

=head1 SEE ALSO

=over 4

=item *

L<Version numbers should be boring|http://www.dagolden.com/index.php/369/version-numbers-should-be-boring/>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/Dist-Zilla-Plugin-CheckStrictVersion/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/Dist-Zilla-Plugin-CheckStrictVersion>

  git clone https://github.com/dagolden/Dist-Zilla-Plugin-CheckStrictVersion.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
