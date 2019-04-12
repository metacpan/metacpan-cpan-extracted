package Log::ger::Output::Array;

our $DATE = '2019-04-12'; # DATE
our $VERSION = '0.026'; # VERSION

use strict;
use warnings;

sub get_hooks {
    my %conf = @_;

    $conf{array} or die "Please specify array";

    return {
        create_log_routine => [
            __PACKAGE__, 50,
            sub {
                my %args = @_;

                my $logger = sub {
                    my ($ctx, $msg) = @_;
                    push @{$conf{array}}, $msg;
                };
                [$logger];
            }],
    };
}

1;
# ABSTRACT: Log to array

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Output::Array - Log to array

=head1 VERSION

version 0.026

=head1 SYNOPSIS

 use Log::ger::Output Array => (
     array         => $ary,
 );

=head1 DESCRIPTION

Mainly for testing only.

=for Pod::Coverage ^(.+)$

=head1 CONFIGURATION

=head2 array => arrayref

Required.

=head1 SEE ALSO

L<Log::ger>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
