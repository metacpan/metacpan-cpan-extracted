package Log::ger::For::HTTP::Tiny;

our $DATE = '2019-06-09'; # DATE
our $VERSION = '0.003'; # VERSION

sub import {
    my $class = shift;
    require HTTP::Tiny::Patch::LogGer;
    HTTP::Tiny::Patch::LogGer->import(@_);
}

1;
# ABSTRACT: Alias for HTTP::Tiny::Patch::LogGer

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::For::HTTP::Tiny - Alias for HTTP::Tiny::Patch::LogGer

=head1 VERSION

This document describes version 0.003 of Log::ger::For::HTTP::Tiny (from Perl distribution HTTP-Tiny-Patch-LogGer), released on 2019-06-09.

=head1 SYNOPSIS

Use like you would use L<HTTP::Tiny::Patch::LogGer>:

 use Log::ger::For::HTTP::Tiny (
     -log_request          => 1, # default 1
     -log_request_content  => 1, # default 1
     -log_response         => 1, # default 1
     -log_response_content => 1, # default 0
 );

On the command-line:

 % perl -MLog::ger::For::HTTP::Tiny -e'...'

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HTTP-Tiny-Patch-LogGer>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HTTP-Tiny-Patch-LogGer>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTTP-Tiny-Patch-LogGer>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<HTTP::Tiny::Patch::LogGer>

L<HTTP::Tiny>

L<Log::ger>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
