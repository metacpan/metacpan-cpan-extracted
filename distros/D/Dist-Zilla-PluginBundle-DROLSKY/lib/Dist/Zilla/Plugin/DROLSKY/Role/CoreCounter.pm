package Dist::Zilla::Plugin::DROLSKY::Role::CoreCounter;

use v5.10;

use strict;
use warnings;
use autodie;
use namespace::autoclean;

our $VERSION = '1.08';

use File::Which qw( which );

use Moose::Role;

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _core_count {
    my $nproc = which('nproc');
    return 2 unless $nproc;

    ## no critic (InputOutput::ProhibitBacktickOperators)
    my $count = `$nproc`;
    return 2 unless defined $count;

    $count =~ s/^\s+|\s+$//g;

    return $count * 2;
}

1;

# ABSTRACT: Knows how to count cores (on Linux only for now)

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::DROLSKY::Role::CoreCounter - Knows how to count cores (on Linux only for now)

=head1 VERSION

version 1.08

=for Pod::Coverage .*

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/autarch/Dist-Zilla-PluginBundle-DROLSKY/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Dist-Zilla-PluginBundle-DROLSKY can be found at L<https://github.com/autarch/Dist-Zilla-PluginBundle-DROLSKY>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 - 2020 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
