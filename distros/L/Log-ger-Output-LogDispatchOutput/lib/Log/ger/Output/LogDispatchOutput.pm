package Log::ger::Output::LogDispatchOutput;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-11'; # DATE
our $DIST = 'Log-ger-Output-LogDispatchOutput'; # DIST
our $VERSION = '0.006'; # VERSION

use strict;
use warnings;

use Log::ger::Util;

sub meta { +{
    v => 2,
} }

sub get_hooks {
    my %plugin_conf = @_;

    $plugin_conf{output} or die "Please specify output (e.g. ".
        "ArrayWithLimits for Log::Dispatch::ArrayWithLimits)";

    require Log::Dispatch;
    my $mod = "Log::Dispatch::$plugin_conf{output}";
    (my $mod_pm = "$mod.pm") =~ s!::!/!g;
    require $mod_pm;

    return {
        create_outputter => [
            __PACKAGE__, # key
            # we want to handle all levels, thus we need to be higher priority
            # than default Log::ger hooks (10) which will install null loggers
            # for less severe levels.
            9,           # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"

                my $outputter = sub {
                    my ($per_target_conf, $msg, $per_msg_conf) = @_;
                    my $level = $per_msg_conf->{level} // $hook_args{level};

                    return if $level > $Log::ger::Current_Level;

                    # we can use per-target conf to store per-target stuffs
                    $hook_args{per_target_conf}{_ld} ||= Log::Dispatch->new(
                        outputs => [
                            $plugin_conf{_output} ? $plugin_conf{_output} :
                                [
                                    $plugin_conf{output},
                                    min_level => 'warning',
                                    %{ $plugin_conf{args} || {} },
                                ],
                        ],
                    );
                    $hook_args{per_target_conf}{_ld}->warning($msg);
                };
                [$outputter];
            }],
    };
}

1;
# ABSTRACT: Send logs to a Log::Dispatch output

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Output::LogDispatchOutput - Send logs to a Log::Dispatch output

=head1 VERSION

This document describes version 0.006 of Log::ger::Output::LogDispatchOutput (from Perl distribution Log-ger-Output-LogDispatchOutput), released on 2020-03-11.

=head1 SYNOPSIS

 use Log::ger::Output LogDispatchOutput => (
     output => 'Screen', # choose Log::Dispatch::Screen
     args => {stderr=>1, newline=>1},
 );

=head1 DESCRIPTION

This output sends logs to a Log::Dispatch output.

=for Pod::Coverage ^(.+)$

=head1 CONFIGURATION

=head2 output

=head2 args

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-ger-Output-LogDispatchOutput>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-ger-Output-LogDispatchOutput>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-ger-Output-LogDispatchOutput>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Log::ger::Output::LogDispatch>

L<Log::ger>

L<Log::Dispatch>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
