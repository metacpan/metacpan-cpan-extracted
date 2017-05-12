package Log::Any::For::HTTP::Tiny;

our $DATE = '2015-08-17'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

use HTTP::Tiny::Patch::LogAny qw();

my %opts;

sub import {
    my $self = shift;
    %opts = @_;

    HTTP::Tiny::Patch::LogAny->import(%opts);
}

sub unimport {
    HTTP::Tiny::Patch::LogAny->unimport();
}

1;
# ABSTRACT: Add logging to HTTP::Tiny

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::For::HTTP::Tiny - Add logging to HTTP::Tiny

=head1 VERSION

This document describes version 0.02 of Log::Any::For::HTTP::Tiny (from Perl distribution Log-Any-For-HTTP-Tiny), released on 2015-08-17.

=head1 SYNOPSIS

 use Log::Any::For::LWP
     -log_request          => 1, # optional, default 1 (from HTTP::Tiny::Patch::LogAny)
     -log_response         => 1, # optional, default 1 (from HTTP::Tiny::Patch::LogAny)
     -log_response_content => 1, # optional, default 0 (from HTTP::Tiny::Patch::LogAny)
 ;

=head1 DESCRIPTION

An alias for L<HTTP::Tiny::Patch::LogAny>.

=for Pod::Coverage ^(import|unimport)$

=head1 SEE ALSO

L<HTTP::Tiny::Patch::LogAny>

L<Log::Any>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-Any-For-HTTP-Tiny>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Log-Any-For-HTTP-Tiny>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-Any-For-HTTP-Tiny>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
