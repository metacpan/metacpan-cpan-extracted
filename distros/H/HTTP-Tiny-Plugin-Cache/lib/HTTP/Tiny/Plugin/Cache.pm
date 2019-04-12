package HTTP::Tiny::Plugin::Cache;

our $DATE = '2019-04-12'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Digest::SHA;
use File::Util::Tempdir;
use Storable qw(store_fd fd_retrieve);

sub _get_cache_dir_path {
    my ($self, $url) = @_;

    my $tempdir = File::Util::Tempdir::get_user_tempdir();

    my $cachedir = "$tempdir/http_tiny_plugin_cache";
    unless (-d $cachedir) {
        mkdir $cachedir or die "Can't mkdir '$cachedir': $!";
    }

    my $cachepath = "$cachedir/".Digest::SHA::sha256_hex($url);

    ($cachedir, $cachepath);
}

sub before_request {
    my ($self, $r) = @_;

    my ($ht, $method, $url, $options) = @{ $r->{argv} };
    unless ($method eq 'GET') {
        log_trace "Not a GET response, skip caching";
        return -1; # decline
    }

    my ($cachedir, $cachepath) = $self->_get_cache_dir_path($url);
    log_trace "Cache file is %s", $cachepath;

    my $maxage = $r->{config}{max_age} //
        $ENV{HTTP_TINY_PLUGIN_CACHE_MAX_AGE} //
        $ENV{CACHE_MAX_AGE} // 86400;

    if (!(-f $cachepath) || (-M _) > $maxage/86400) {
        # cache does not exist or too old, we execute request() as usual and
        # later save
        $r->{cache_response}++;
        return 1; # ok
    } else {
        log_trace "Retrieving response from cache ...";
        open my $fh, "<", $cachepath
            or die "Can't read cache file '$cachepath' for '$url': $!";
        $r->{response} = fd_retrieve $fh;
        close $fh;
        return 99; # skip request()
    }
}

sub after_request {
    my ($self, $r) = @_;

    my ($ht, $method, $url, $options) = @{ $r->{argv} };

    my ($cachedir, $cachepath) = $self->_get_cache_dir_path($url);

  CACHE_RESPONSE:
    {
        last unless $r->{cache_response};
        if ($r->{config}{cache_if}) {
            if (ref $r->{config}{cache_if} eq 'Regexp') {
                last unless $r->{response}{status} =~ $r->{config}{cache_if};
            } else {
                last unless $r->{config}{cache_if}->($self, $r->{response});
            }
        }
        log_trace "Saving response to cache ...";
        open my $fh, ">", $cachepath
            or die "Can't create cache file '$cachepath' for '$url': $!";
        store_fd $r->{response}, $fh;
        close $fh;
        undef $r->{cache_response};
    }
    1; # ok
}

1;
# ABSTRACT: Cache HTTP::Tiny responses

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Tiny::Plugin::Cache - Cache HTTP::Tiny responses

=head1 VERSION

This document describes version 0.001 of HTTP::Tiny::Plugin::Cache (from Perl distribution HTTP-Tiny-Plugin-Cache), released on 2019-04-12.

=head1 SYNOPSIS

 use HTTP::Tiny::Plugin 'Cache' => {
     max_age  => '3600',     # defaults to HTTP_TINY_PLUGIN_CACHE_MAX_AGE or CACHE_MAX_AGE or 86400
     cache_if => qr/^[23]/,  # optional, default is to cache all responses
 };

 my $res  = HTTP::Tiny::Plugin->new->get("http://www.example.com/");
 my $res2 = HTTP::Tiny::Plugin->request(GET => "http://www.example.com/"); # cached response

=head1 DESCRIPTION

This plugin can cache responses to cache files.

Currently only GET requests are cached. Cache are keyed by SHA256-hex(URL).
Error responses are also cached (unless you configure C</cache_if>). Currently
no cache-related HTTP request or response headers (e.g. C<Cache-Control>) are
respected.

=for Pod::Coverage .+

=head1 CONFIGURATION

=head2 max_age

Int.

=head2 cache_if

Regex or code. If regex, then will be matched against response status. If code,
will be called with arguments: C<< ($self, $response) >>.

=head1 ENVIRONMENT

=head2 CACHE_MAX_AGE

Int. Will be consulted after L</"HTTP_TINY_PLUGIN_CACHE_MAX_AGE">.

=head2 HTTP_TINY_PLUGIN_CACHE_MAX_AGE

Int. Will be consulted before L</"CACHE_MAX_AGE">.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HTTP-Tiny-Plugin-Cache>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HTTP-Tiny-Plugin-Cache>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTTP-Tiny-Plugin-Cache>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<HTTP::Tiny::Plugin>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
