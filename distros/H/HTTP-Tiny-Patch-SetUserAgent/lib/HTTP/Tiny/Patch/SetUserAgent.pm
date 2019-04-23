package HTTP::Tiny::Patch::SetUserAgent;

our $DATE = '2019-04-20'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Module::Patch qw();
use base qw(Module::Patch);

our %config;

my $p_agent = sub {
    my $self = shift;

    my $agent = $config{-agent} // $ENV{HTTP_TINY_USER_AGENT};
    die "Please specify -agent configuration" unless defined $agent;

    $self->{agent} = $agent;
};

sub patch_data {
    return {
        v => 3,
        config => {
            -agent => {
                schema  => 'str*',
                req => 1,
            },
        },
        patches => [
            {
                action      => 'replace',
                mod_version => qr/^0\.*/,
                sub_name    => 'agent',
                code        => $p_agent,
            },
        ],
    };
}

1;
# ABSTRACT: Set User-Agent header

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Tiny::Patch::SetUserAgent - Set User-Agent header

=head1 VERSION

This document describes version 0.001 of HTTP::Tiny::Patch::SetUserAgent (from Perl distribution HTTP-Tiny-Patch-SetUserAgent), released on 2019-04-20.

=head1 SYNOPSIS

From Perl:

 use HTTP::Tiny::Patch::SetUserAgent
     -agent => 'Foo 1.0', # required
 ;

=head1 DESCRIPTION

This

=for Pod::Coverage ^(patch_data)$

=head1 CONFIGURATION

=head2 -agent

=head1 FAQ

=head1 ENVIRONMENT

=head2 HTTP_TINY_USER_AGENT

Set default for HTTP_TINY_USER_AGENT.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HTTP-Tiny-Patch-SetUserAgent>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HTTP-Tiny-Patch-SetUserAgent>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTTP-Tiny-Patch-SetUserAgent>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<HTTP::Tiny::Plugin::SetUserAgent>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
