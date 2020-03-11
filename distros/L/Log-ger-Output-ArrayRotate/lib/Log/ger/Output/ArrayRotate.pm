package Log::ger::Output::ArrayRotate;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-11'; # DATE
our $DIST = 'Log-ger-Output-ArrayRotate'; # DIST
our $VERSION = '0.004'; # VERSION

use strict;
use warnings;

sub meta { +{
    v => 2,
} }

sub get_hooks {
    my %plugin_conf = @_;

    my $ary = $plugin_conf{array} or die "Please specify array";
    ref $ary eq 'ARRAY' or die "Please specify arrayref in array";

    return {
        create_outputter => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"

                my $outputter = sub {
                    my ($ctx, $msg) = @_;
                    push @$ary, $msg;
                    if (defined $plugin_conf{max_elems} && @$ary > $plugin_conf{max_elems}) {
                        shift @$ary;
                    }
                };
                [$outputter];
            }],
    };
}

1;
# ABSTRACT: Log to array, rotating old elements

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Output::ArrayRotate - Log to array, rotating old elements

=head1 VERSION

This document describes version 0.004 of Log::ger::Output::ArrayRotate (from Perl distribution Log-ger-Output-ArrayRotate), released on 2020-03-11.

=head1 SYNOPSIS

 use Log::ger::Output ArrayRotate => (
     array         => $ary,
     max_elems     => 100,  # defaults unlimited
 );

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 CONFIGURATION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-ger-Output-ArrayRotate>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-ger-Output-ArrayRotate>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-ger-Output-ArrayRotate>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Log::ger>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
