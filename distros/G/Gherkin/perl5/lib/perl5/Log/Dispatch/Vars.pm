package Log::Dispatch::Vars;

use strict;
use warnings;

our $VERSION = '2.70';

use Exporter qw( import );

our @EXPORT_OK = qw(
    %CanonicalLevelNames
    %LevelNamesToNumbers
    @OrderedLevels
);

## no critic (Variables::ProhibitPackageVars)
our %CanonicalLevelNames = (
    (
        map { $_ => $_ }
            qw(
            debug
            info
            notice
            warning
            error
            critical
            alert
            emergency
            )
    ),
    warn  => 'warning',
    err   => 'error',
    crit  => 'critical',
    emerg => 'emergency',
);

our @OrderedLevels = qw(
    debug
    info
    notice
    warning
    error
    critical
    alert
    emergency
);

our %LevelNamesToNumbers = (
    ( map { $OrderedLevels[$_] => $_ } 0 .. $#OrderedLevels ),
    warn  => 3,
    err   => 4,
    crit  => 5,
    emerg => 7,
);

1;

# ABSTRACT: Variables used internally by multiple packages

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatch::Vars - Variables used internally by multiple packages

=head1 VERSION

version 2.70

=head1 DESCRIPTION

There are no user-facing parts here.

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/houseabsolute/Log-Dispatch/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Log-Dispatch can be found at L<https://github.com/houseabsolute/Log-Dispatch>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
