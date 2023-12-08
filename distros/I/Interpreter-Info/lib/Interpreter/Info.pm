package Interpreter::Info;

use strict;
use warnings;
use Log::ger;

use Exporter qw(import);
use IPC::System::Options 'readpipe', 'system', -log=>1;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-07'; # DATE
our $DIST = 'Interpreter-Info'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw(
                       get_interpreter_info

                       get_perl_info
                       get_python_info
                       get_nodejs_info
                       get_ruby_info
                       get_bash_info

                       get_rakudo_info
               );

our %SPEC;

our %argspecs_common = (
    path => {
        summary => 'Choose specific path for interpreter',
        schema => 'filename*',
    },
);

$SPEC{get_perl_info} = {
    v => 1.1,
    summary => 'Get information about perl interpreter',
    args => {
        %argspecs_common,
    },
};
sub get_perl_info {
    require File::Which;

    my %args = @_;

    my $path;
    if (defined $args{path}) {
        $path = $args{path};
    } else {
        my $p;
        for (qw/perl perl5/) {
            if (defined($p = File::Which::which($_))) {
                log_trace "Picking $p as path to perl";
                $path = $p;
                last;
            }
        }
        return [412, "Can't find perl in PATH"] unless defined $p;
    }

    my $out = readpipe({shell=>0}, $path, "-V");
    return [500, "Can't run $path -V: $!"] if $!;
    return [500, "$path -V exits non-zero: $?"] if $?;

    my $info = {path=>$path};
  VERSION: {
        $out =~ /revision (\d+) version (\d+) subversion (\d+)/ or do {
            warn "Can't extract perl version";
            last;
        };
        $info->{version} = "$1.$2.$3";
    };

    [200, "OK", $info];
}

$SPEC{get_python_info} = {
    v => 1.1,
    summary => 'Get information about python interpreter',
    args => {
        %argspecs_common,
    },
};
sub get_python_info {
    require File::Which;

    my %args = @_;

    my $path;
    if (defined $args{path}) {
        $path = $args{path};
    } else {
        my $p;
        for (qw/python3 python2 python/) {
            if (defined($p = File::Which::which($_))) {
                log_trace "Picking $p as path to python";
                $path = $p;
                last;
            }
        }
        return [412, "Can't find python in PATH"] unless defined $p;
    }

    my $out;
    system({shell=>0, capture_merged=>\$out}, $path, "-v", "-c1");
    return [500, "Can't run $path -v -c1: $!"] if $!;
    return [500, "$path -v -c1 exits non-zero: $?"] if $?;

    my $info = {path=>$path};
  VERSION: {
        $out =~ /^Python (\d+(?:\.\d+)+) /m or do {
            warn "Can't extract Python version";
            last;
        };
        $info->{version} = $1;
    };

    [200, "OK", $info];
}

$SPEC{get_nodejs_info} = {
    v => 1.1,
    summary => 'Get information about nodejs interpreter',
    args => {
        %argspecs_common,
    },
};
sub get_nodejs_info {
    require File::Which;

    my %args = @_;

    my $path;
    if (defined $args{path}) {
        $path = $args{path};
    } else {
        my $p;
        for (qw/nodejs node/) {
            if (defined($p = File::Which::which($_))) {
                log_trace "Picking $p as path to nodejs";
                $path = $p;
                last;
            }
        }
        return [412, "Can't find nodejs in PATH"] unless defined $p;
    }

    my $out;
    system({shell=>0, capture_merged=>\$out}, $path, "-v");
    return [500, "Can't run $path -v: $!"] if $!;
    return [500, "$path -v exits non-zero: $?"] if $?;

    my $info = {path=>$path};
  VERSION: {
        $out =~ /^v(\d+(?:\.\d+)+)/m or do {
            warn "Can't extract nodejs version";
            last;
        };
        $info->{version} = $1;
    };

    [200, "OK", $info];
}

$SPEC{get_ruby_info} = {
    v => 1.1,
    summary => 'Get information about Ruby interpreter',
    args => {
        %argspecs_common,
    },
};
sub get_ruby_info {
    require File::Which;

    my %args = @_;

    my $path;
    if (defined $args{path}) {
        $path = $args{path};
    } else {
        my $p;
        for (qw/ruby/) {
            if (defined($p = File::Which::which($_))) {
                log_trace "Picking $p as path to ruby";
                $path = $p;
                last;
            }
        }
        return [412, "Can't find ruby in PATH"] unless defined $p;
    }

    my $out;
    system({shell=>0, capture_merged=>\$out}, $path, "-v");
    return [500, "Can't run $path -v: $!"] if $!;
    return [500, "$path -v exits non-zero: $?"] if $?;

    my $info = {path=>$path};
  VERSION: {
        $out =~ /^^ruby (\d+(?:\.\d+)+(?:p\d+)?) /m or do {
            warn "Can't extract version";
            last;
        };
        $info->{version} = $1;
        $out =~ / \((\d{4}-\d{2}-\d{2})/m or do {
            warn "Can't extract release date";
            last;
        };
        $info->{release_date} = $1;
    };

    [200, "OK", $info];
}

$SPEC{get_bash_info} = {
    v => 1.1,
    summary => 'Get information about bash interpreter',
    args => {
        %argspecs_common,
    },
};
sub get_bash_info {
    require File::Which;

    my %args = @_;

    my $path;
    if (defined $args{path}) {
        $path = $args{path};
    } else {
        my $p;
        for (qw/bash/) {
            if (defined($p = File::Which::which($_))) {
                log_trace "Picking $p as path to bash";
                $path = $p;
                last;
            }
        }
        return [412, "Can't find bash in PATH"] unless defined $p;
    }

    my $out;
    system({shell=>0, capture_merged=>\$out}, $path, "--version");
    return [500, "Can't run $path --version: $!"] if $!;
    return [500, "$path --version exits non-zero: $?"] if $?;

    my $info = {path=>$path};
  VERSION: {
        $out =~ /version ((\d+(?:\.\d+)+)\S*) /m or do {
            warn "Can't extract version";
            last;
        };
        $info->{version} = $1;
        $info->{version_simple} = $2;
    };

    [200, "OK", $info];
}

$SPEC{get_rakudo_info} = {
    v => 1.1,
    summary => 'Get information about rakudo interpreter',
    args => {
        %argspecs_common,
    },
};
sub get_rakudo_info {
    require File::Which;

    my %args = @_;

    my $path;
    if (defined $args{path}) {
        $path = $args{path};
    } else {
        my $p;
        for (qw/rakudo/) {
            if (defined($p = File::Which::which($_))) {
                log_trace "Picking $p as path to rakudo";
                $path = $p;
                last;
            }
        }
        return [412, "Can't find rakudo in PATH"] unless defined $p;
    }

    my $out;
    system({shell=>0, capture_merged=>\$out}, $path, "-v");
    return [500, "Can't run $path -v: $!"] if $!;
    return [500, "$path -v exits non-zero: $?"] if $?;

    my $info = {path=>$path};
  VERSION: {
        $out =~ /v(\d+(?:\.\d+)+)/m or do {
            warn "Can't extract version";
            last;
        };
        $info->{version} = $1;
        $out =~ /^Implementing.+ v(\d+\.\w)/m or do {
            warn "Can't extract spec_version";
            last;
        };
        $info->{spec_version} = $1;
    };

    [200, "OK", $info];
}

1;
# ABSTRACT: Get information about rakudo interpreter

__END__

=pod

=encoding UTF-8

=head1 NAME

Interpreter::Info - Get information about rakudo interpreter

=head1 VERSION

This document describes version 0.001 of Interpreter::Info (from Perl distribution Interpreter-Info), released on 2023-12-07.

=head1 FUNCTIONS


=head2 get_bash_info

Usage:

 get_bash_info(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get information about bash interpreter.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<path> => I<filename>

Choose specific path for interpreter.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 get_nodejs_info

Usage:

 get_nodejs_info(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get information about nodejs interpreter.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<path> => I<filename>

Choose specific path for interpreter.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 get_perl_info

Usage:

 get_perl_info(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get information about perl interpreter.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<path> => I<filename>

Choose specific path for interpreter.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 get_python_info

Usage:

 get_python_info(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get information about python interpreter.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<path> => I<filename>

Choose specific path for interpreter.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 get_rakudo_info

Usage:

 get_rakudo_info(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get information about rakudo interpreter.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<path> => I<filename>

Choose specific path for interpreter.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 get_ruby_info

Usage:

 get_ruby_info(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get information about Ruby interpreter.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<path> => I<filename>

Choose specific path for interpreter.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Interpreter-Info>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Interpreter-Info>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Interpreter-Info>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
