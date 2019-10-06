package LWP::Protocol::Patch::CountBytesIn;

our $DATE = '2019-10-05'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
no warnings;
use Log::ger;

use Module::Patch ();
use base qw(Module::Patch);

use Scalar::Util qw(refaddr);

our %config;
our $bytes_in = 0;

sub _get_byte_size {
    my($self, @strings) = @_;
    my $bytes = 0;

    {
        use bytes;
        for my $string (@strings) {
            $bytes += length($string);
        }
    }

    return $bytes;
}

sub _wrap_collect {
    my $ctx = shift;

    my ($self, $arg, $response, $collector) = @_;

    push @{ $response->{handlers}{response_data} }, {
        callback => sub {
            $bytes_in += _get_byte_size(__PACKAGE__, $_[3]);
        },
    };

    $ctx->{orig}->(@_);
}

sub patch_data {
    return {
        v => 3,
        config => {
        },
        patches => [
            {
                action => 'wrap',
                #mod_version => qr/^6\./,
                sub_name => 'collect',
                code => \&_wrap_collect,
            },
        ],
    };
}

1;
# ABSTRACT: Count bytes in

__END__

=pod

=encoding UTF-8

=head1 NAME

LWP::Protocol::Patch::CountBytesIn - Count bytes in

=head1 VERSION

This document describes version 0.001 of LWP::Protocol::Patch::CountBytesIn (from Perl distribution LWP-Protocol-Patch-CountBytesIn), released on 2019-10-05.

=head1 SYNOPSIS

 use LWP::Protocol::Patch::CountBytesIn;

 # ... use LWP

 printf "Total downloaded : %9d bytes\n", $LWP::Protocol::Patch::CountBytesIn::bytes_in;

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/LWP-Protocol-Patch-CountBytesIn>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-LWP-Protocol-Patch-CountBytes>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=LWP-Protocol-Patch-CountBytesIn>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<IO::Socket::ByteCounter>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
