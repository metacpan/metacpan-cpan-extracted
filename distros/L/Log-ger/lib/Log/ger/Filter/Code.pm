package Log::ger::Filter::Code;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-29'; # DATE
our $DIST = 'Log-ger'; # DIST
our $VERSION = '0.041'; # VERSION

sub meta { +{
    v => 1,
} }

sub get_hooks {
    my %conf = @_;

    $conf{code} or die "Please specify code";

    return {
        create_filter => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"

                [$conf{code}];
            }],
    };
}

1;
# ABSTRACT: Filter using a coderef

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Filter::Code - Filter using a coderef

=head1 VERSION

version 0.041

=head1 SYNOPSIS

 use Log::ger::Filter Code => (
     code => sub { ... },
 );

=head1 DESCRIPTION

Mainly for testing only.

=for Pod::Coverage ^(.+)$

=head1 CONFIGURATION

=head2 code => coderef

Required.

=head1 SEE ALSO

L<Log::ger>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2020, 2019, 2018, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
