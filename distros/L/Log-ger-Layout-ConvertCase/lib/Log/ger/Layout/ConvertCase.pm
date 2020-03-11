package Log::ger::Layout::ConvertCase;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-09'; # DATE
our $DIST = 'Log-ger-Layout-ConvertCase'; # DIST
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;

sub meta { +{
    v => 1,
} }

sub get_hooks {
    my %plugin_conf = @_;
    $plugin_conf{case} or die "Please specify case";
    $plugin_conf{case} =~ /\A(upper|lower)\z/
        or die "Invalid value for 'case', please use 'upper' or 'lower'";
    return {
        create_layouter => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"

                my $layouter = sub {
                    $plugin_conf{case} eq 'upper' ? uc($_[0]) : lc($_[0]);
                };

                [$layouter];
            },
        ],
    };
}

1;
# ABSTRACT: Example layout plugin to convert the case of message

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Layout::ConvertCase - Example layout plugin to convert the case of message

=head1 VERSION

This document describes version 0.003 of Log::ger::Layout::ConvertCase (from Perl distribution Log-ger-Layout-ConvertCase), released on 2020-03-09.

=head1 SYNOPSIS

 use Log::ger::Layout ConvertCase => (
     case => 'upper',
 );
 use Log::ger;

 log_warn "hello, world";

The final message will be:

 HELLO, WORLD

=head1 DESCRIPTION

This is an example layout plugin, mentioned in the Log::ger tutorial.

=for Pod::Coverage ^(.+)$

=head1 CONFIGURATION

=head2 case

Str. Required. Either C<upper> or C<lower>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-ger-Layout-ConvertCase>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-ger-Layout-ConvertCase>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-ger-Layout-ConvertCase>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Log::ger>

L<Log::ger::Manual::Tutorial>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
