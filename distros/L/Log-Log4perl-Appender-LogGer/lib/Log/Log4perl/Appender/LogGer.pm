package Log::Log4perl::Appender::LogGer;

our $DATE = '2018-04-18'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;
use Log::ger;

our @ISA = qw(Log::Log4perl::Appender);

sub new {
    my($class, @options) = @_;

    my $self = {
        @options,
    };

    bless $self, $class;
}

sub log {
    my($self, %params) = @_;

    #use DD; dd \%params;

    my $message = $params{message};
    my $level = $params{level};
    if ($level == 0) {
        log_debug $message;
    } elsif ($level <= 1) {
        log_info $message;
    } elsif ($level <= 3) {
        log_warn $message;
    } elsif ($level <= 6) {
        log_error $message;
    } else {
        log_fatal $message;
    }
}

1;

1;
# ABSTRACT: Log to Log::ger

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Log4perl::Appender::LogGer - Log to Log::ger

=head1 VERSION

This document describes version 0.001 of Log::Log4perl::Appender::LogGer (from Perl distribution Log-Log4perl-Appender-LogGer), released on 2018-04-18.

=head1 SYNOPSIS

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-Log4perl-Appender-LogGer>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-Log4perl-Appender-LogGer>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-Log4perl-Appender-LogGer>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Log::ger>

L<Log::Log4perl>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
