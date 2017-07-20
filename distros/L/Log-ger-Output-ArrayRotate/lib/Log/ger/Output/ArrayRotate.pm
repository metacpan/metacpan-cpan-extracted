package Log::ger::Output::ArrayRotate;

our $DATE = '2017-07-16'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

sub get_hooks {
    my %conf = @_;

    my $ary = $conf{array} or die "Please specify array";
    ref $ary eq 'ARRAY' or die "Please specify arrayref in array";

    return {
        create_log_routine => [
            __PACKAGE__, 50,
            sub {
                my %args = @_;

                my $logger = sub {
                    my ($ctx, $msg) = @_;
                    push @$ary, $msg;
                    if (defined $conf{max_elems} && @$ary > $conf{max_elems}) {
                        shift @$ary;
                    }
                };
                [$logger];
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

This document describes version 0.001 of Log::ger::Output::ArrayRotate (from Perl distribution Log-ger-Output-ArrayRotate), released on 2017-07-16.

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

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
