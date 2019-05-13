package LWP::UserAgent::Patch::SetUserAgent;

our $DATE = '2019-05-10'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
no warnings;

use Module::Patch qw();
use base qw(Module::Patch);

our %config;

my $p_agent = sub {
    my $agent = $config{-agent} // $ENV{HTTP_USER_AGENT} or
        die "Either set -agent configuration or HTTP_USER_AGENT environment";
    $agent;
};

sub patch_data {
    return {
        v => 3,
        config => {
            -agent => {
                schema => 'str*',
            },
        },
        patches => [
            {
                action => 'replace',
                sub_name => '_agent',
                code => $p_agent,
            },
        ],
    };
}

1;
# ABSTRACT: Set User-Agent

__END__

=pod

=encoding UTF-8

=head1 NAME

LWP::UserAgent::Patch::SetUserAgent - Set User-Agent

=head1 VERSION

This document describes version 0.001 of LWP::UserAgent::Patch::SetUserAgent (from Perl distribution LWP-UserAgent-Patch-SetUserAgent), released on 2019-05-10.

=head1 SYNOPSIS

In Perl:

 use LWP::UserAgent::Patch::SetUserAgent -agent => "Blah/1.0";

From command-line:

 % perl -MLWP::UserAgent::Patch::SetUserAgent=-agent,'Blah/1.0' script-that-uses-lwp.pl ...
 % HTTP_USER_AGENT=Blah/1.0 perl -MLWP::UserAgent::Patch::SetUserAgent script-that-uses-lwp.pl ...

=head1 DESCRIPTION

This patch sets L<LWP::UserAgent>'s default User-Agent string, from
C<libwww-perl/XXX> to a value from either L</-agent> configuration or from
environment variable L</HTTP_USER_AGENT>.

You can still override it using the usual:

 my $ua = LWP::UserAgent->new(
     agent => '...',
     ...
 );

or

 $ua->agent('...');

=head1 CONFIGURATION

=head2 -agent

String.

=head1 ENVIRONMENT

=head2 HTTP_USER_AGENT

String. Used to set default for L</-agent> configuration.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/LWP-UserAgent-Patch-SetUserAgent>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-LWP-UserAgent-Patch-SetUserAgent>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=LWP-UserAgent-Patch-SetUserAgent>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

If you want to check the sent User-Agent header in requests, you can use
L<Log::ger::For::LWP>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
