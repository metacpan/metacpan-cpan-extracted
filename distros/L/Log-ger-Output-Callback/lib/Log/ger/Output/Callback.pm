package Log::ger::Output::Callback;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-07'; # DATE
our $DIST = 'Log-ger-Output-Callback'; # DIST
our $VERSION = '0.006'; # VERSION

use 5.010001;
use strict;
use warnings;

sub get_hooks {
    my %plugin_conf = @_;

    my $hooks = {};

    if ($plugin_conf{logging_cb}) {
        $hooks->{create_outputter} = [
            __PACKAGE__, # key
            # we want to handle all levels, thus we need to be higher priority
            # than default Log::ger hooks (10) which will install null loggers
            # for less severe levels.
            9,           # priority
            sub {        # hook
                my %hook_args = @_;
                my $outputter = sub {
                    my ($per_target_conf, $msg, $per_msg_conf) = @_;
                    my $level = $per_msg_conf->{level} // $hook_args{level};
                    $plugin_conf{logging_cb}->($per_target_conf, $level, $msg, $per_msg_conf);
                };
                [$outputter];
            },
        ];
    }

    if ($plugin_conf{detection_cb}) {
        $hooks->{create_level_checker} = [
            __PACKAGE__, # key
            9,          # priority
            sub {        # hook
                my %hook_args = @_;
                my $level_checker = sub {
                    $plugin_conf{detection_cb}->($hook_args{level});
                };
                [$level_checker];
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

This document describes version 0.006 of Log::ger::Output::Callback (from Perl distribution Log-ger-Output-Callback), released on 2020-03-07.

=head1 SYNOPSIS

 use Log::ger::Output Callback => (
     logging_cb   => sub { my ($per_target_conf, $lvlnum, $msg, $per_msg_conf) = @_; ... }, # optional
     detection_cb => sub { my ($lvlnum) = @_; ... },                                        # optional
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

This software is copyright (c) 2020, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
