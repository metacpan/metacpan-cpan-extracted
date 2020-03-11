package Log::ger::Plugin::Debug::DumpRoutines;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-11'; # DATE
our $DIST = 'Log-ger-Plugin-Debug-DumpRoutines'; # DIST
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;
use Data::Dump::Color;

sub meta { +{
    v => 2,
} }

sub get_hooks {
    my %plugin_conf = @_;

    return {
        before_install_routines => [
            __PACKAGE__, # key
            99,          # priority (after all the other plugins)
            sub {        # hook
                my %hook_args = @_;

                dd $hook_args{routines};
                [undef];
            },
        ],
    };
}

1;
# ABSTRACT: Dump routines before Log::ger instals them

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Plugin::Debug::DumpRoutines - Dump routines before Log::ger instals them

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 use Log::ger::Plugin->set('Debug::DumpRoutines');
 use Log::ger;

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 CONFIGURATION

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
