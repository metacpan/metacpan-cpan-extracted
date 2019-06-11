package HTTP::Tiny::Patch::LogGer;

our $DATE = '2019-06-09'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
#no warnings;
use Log::ger;

use Module::Patch ();
use base qw(Module::Patch);

our %config;

sub _render_headers {
    my $headers = shift;
    join("", map {
        my $k = $_;
        my $v = $headers->{$_};
        join("", map { "$k: $_\n"} ref($v) eq 'ARRAY' ? @$v : ($v))
    } sort keys %$headers);
}

my $p_write_header_lines = sub {
    my $ctx = shift;
    my ($self) = @_;
    $self->{_is_writing_header_lines} = 1;
    $ctx->{orig}->(@_);
};

my $p_write = sub {
    my $ctx = shift;
    my ($self, $buf) = @_;
    if ($self->{_is_writing_header_lines}) {
        if ($config{-log_request} && log_is_trace()) {
            log_trace("HTTP::Tiny request header (raw, %d bytes):\n%s", $buf);
        }
        undef $self->{_is_writing_header_lines};
    }
    $ctx->{orig}->(@_);
};

my $p_request = sub {
    my $ctx = shift;

    if ($config{-log_request} && log_is_trace()) {
        my ($self, $method, $url, $args) = @_;
        my $hh = $args->{headers} // {};
        log_trace("HTTP::Tiny request header (not raw):\n%s %s\n%s\n",
                  $method, $url,
                  _render_headers($hh));
        if ($config{-log_request_content} && defined $args->{content}) {
            log_trace("HTTP::Tiny request body (%d bytes):\n%s\n",
                      length($args->{content} // ''),
                      $args->{content})
        }
    }

    my $res = $ctx->{orig}->(@_);

    if ($config{-log_response} && log_is_trace()) {
        my $hh = $res->{headers} // {};
        log_trace("HTTP::Tiny response header:\n%s %s %s\n%s\n",
                  $res->{status}, $res->{reason}, $res->{protocol},
                  _render_headers($hh),
              );
    }

    if ($config{-log_response_content} && log_is_trace()) {
        log_trace("HTTP::Tiny response content (%d bytes):\n%s",
                  length($res->{content} // ""), $res->{content});
    }

    $res;
};

sub patch_data {
    return {
        v => 3,
        config => {
            -log_request => {
                schema  => 'bool*',
                default => 1,
            },
            -log_request_content => {
                schema  => 'bool*',
                default => 1,
            },
            -log_response => {
                schema  => 'bool*',
                default => 1,
            },
            -log_response_content => {
                schema  => 'bool*',
                default => 0,
            },
        },
        patches => [
            {
                action      => 'wrap',
                sub_name    => 'request',
                code        => $p_request,
            },
        ],
        after_patch => sub {
            ${__PACKAGE__."::_Handle_handle"} = Module::Patch::patch_package(
                'HTTP::Tiny::Handle', [
                    {
                        action      => 'wrap',
                        sub_name    => 'write',
                        code        => $p_write,
                    },
                    {
                        action      => 'wrap',
                        sub_name    => 'write_header_lines',
                        code        => $p_write_header_lines,
                    },
                ]);
        },
        before_unpatch => sub {
            undef ${__PACKAGE__."::_Handle_handle"};
        },
    };
}

1;
# ABSTRACT: Log HTTP::Tiny with Log::ger

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Tiny::Patch::LogGer - Log HTTP::Tiny with Log::ger

=head1 VERSION

This document describes version 0.003 of HTTP::Tiny::Patch::LogGer (from Perl distribution HTTP-Tiny-Patch-LogGer), released on 2019-06-09.

=head1 SYNOPSIS

 use HTTP::Tiny::Patch::LogGer (
     -log_request          => 1, # default 1
     -log_request_content  => 1, # default 1
     -log_response         => 1, # default 1
     -log_response_content => 1, # default 0
 );

=head1 DESCRIPTION

This module patches L<HTTP::Tiny> to log various stuffs with L<Log::ger>.
Currently this is what gets logged:

=over

=item * HTTP request

The raw request sent on-the-wire as well as non-raw request. The raw request is
not sent if connection cannot be established; that's why we log both the raw as
well as non-raw request.

=item * HTTP response

Currently *NOT* the raw/on-the-wire response.

=back

=for Pod::Coverage ^(patch_data)$

=head1 CONFIGURATION

=head2 -log_request => BOOL

=head2 -log_request_content => BOOL

=head2 -log_response => BOOL

Content will not be logged though, enable C<-log_response_content> for that.

=head2 -log_response_content => BOOL

=head1 FAQ

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

L<Log::ger::For::LWP>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
