package Log::ger::Output::Callback;

our $DATE = '2018-12-20'; # DATE
our $VERSION = '0.004'; # VERSION

use strict;
use warnings;

sub get_hooks {
    my %conf = @_;

    my $hooks = {};

    if ($conf{logging_cb}) {
        $hooks->{create_logml_routine} = [
            __PACKAGE__, 50,
            sub {
                my %args = @_;
                my $logger = sub {
                    $conf{logging_cb}->(@_);
                };
                [$logger];
            },
        ];
    }

    if ($conf{detection_cb}) {
        $hooks->{create_is_routine} = [
            __PACKAGE__, 50,
            sub {
                my %args = @_;
                my $logger = sub {
                    $conf{detection_cb}->($args{level});
                };
                [$logger];
            },
        ];
    }

    return $hooks;
}

1;
# ABSTRACT: Send logs to a subroutine

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Output::Callback - Send logs to a subroutine

=head1 VERSION

This document describes version 0.004 of Log::ger::Output::Callback (from Perl distribution Log-ger-Output-Callback), released on 2018-12-20.

=head1 SYNOPSIS

 use Log::ger::Output Callback => (
     logging_cb   => sub { my ($ctx, $numlevel, $msg) = @_; ... }, # optional
     detection_cb => sub { my ($numlevel) = @_; ... },             # optional
 );

=head1 DESCRIPTION

This output plugin provides an easy way to do custom logging in L<Log::ger>. If
you want to be more proper, you can also create your own output plugin, e.g.
L<Log::ger::Output::Screen> or L<Log::ger::Output::File>. To do so, follow the
tutorial in L<Log::ger::Manual::Tutorial::49_WritingAnOutputPlugin> or
alternatively just peek at the source code of this module.

=for Pod::Coverage ^(.+)$

=head1 CONFIGURATION

=head1 logging_cb => code

=head1 detection_cb => code

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-ger-Output-Callback>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-ger-Output-Callback>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-ger-Output-Callback>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Log::ger>

Modelled after L<Log::Any::Adapter::Callback>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
