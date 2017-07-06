package Log::ger::Format::Flogger;

our $DATE = '2017-06-25'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

use String::Flogger qw(flog);

sub get_hooks {
    my %conf = @_;

    return {
        create_formatter => [
            __PACKAGE__, 50,
            sub {
                [sub { flog(@_) }];
            }],
    };
}

1;
# ABSTRACT: Use String::Flogger for formatting instead of sprintf

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Format::Flogger - Use String::Flogger for formatting instead of sprintf

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 use Log::ger::Format 'Flogger';
 use Log::ger;

After that:

 log_error 'simple!';
 log_warn [ 'slightly %s complex', 'more' ];
 log_info [ 'and inline some data: %s', { look => 'data!' } ];
 log_debug [ 'and we can defer evaluation of %s if we want', sub { 'stuff' } ];
 log_trace sub { 'while avoiding sprintfiness, if needed' };

To install only for current package:

 use Log::ger::Format;
 Log::ger::Format->set_for_current_package('Flogger');
 use Log::ger;

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 SEE ALSO

L<Log::ger>

L<String::Flogger>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
