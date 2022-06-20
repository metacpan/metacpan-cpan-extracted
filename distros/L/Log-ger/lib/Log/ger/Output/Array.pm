package Log::ger::Output::Array;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-06-10'; # DATE
our $DIST = 'Log-ger'; # DIST
our $VERSION = '0.040'; # VERSION

sub meta { +{
    v => 2,
} }

sub get_hooks {
    my %plugin_conf = @_;

    $plugin_conf{array} or die "Please specify array";

    return {
        create_outputter => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"

                my $outputter = sub {
                    my ($per_target_conf, $msg, $per_msg_conf) = @_;
                    push @{$plugin_conf{array}}, $msg;
                };
                [$outputter];
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

version 0.040

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

This software is copyright (c) 2022, 2020, 2019, 2018, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
