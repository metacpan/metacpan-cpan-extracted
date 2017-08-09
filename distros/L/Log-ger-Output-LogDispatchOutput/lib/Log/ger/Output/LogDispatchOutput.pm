package Log::ger::Output::LogDispatchOutput;

our $DATE = '2017-08-03'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

use Log::ger::Util;

sub get_hooks {
    my %conf = @_;

    $conf{output} or die "Please specify output (e.g. ".
        "ArrayWithLimits for Log::Dispatch::ArrayWithLimits)";

    require Log::Dispatch;
    my $mod = "Log::Dispatch::$conf{output}";
    (my $mod_pm = "$mod.pm") =~ s!::!/!g;
    require $mod_pm;

    return {
        create_logml_routine => [
            __PACKAGE__, 50,
            sub {
                my %args = @_;

                my $logger = sub {
                    my ($ctx, $level, $msg) = @_;

                    return if $level > $Log::ger::Current_Level;

                    # we can use init_args to store per-target stuffs
                    $args{init_args}{_ld} ||= Log::Dispatch->new(
                        outputs => [
                            [
                                $conf{output},
                                min_level => 'warning',
                                %{ $conf{args} || {} },
                            ],
                        ],
                    );
                    $args{init_args}{_ld}->warning($msg);
                };
                [$logger];
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

This document describes version 0.002 of Log::ger::Output::LogDispatchOutput (from Perl distribution Log-ger-Output-LogDispatchOutput), released on 2017-08-03.

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

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
