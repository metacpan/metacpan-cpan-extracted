package HTTP::Tiny::Cache;

our $DATE = '2019-04-14'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Digest::SHA;
use File::Util::Tempdir;
use Storable qw(store_fd fd_retrieve);

use parent 'HTTP::Tiny';

sub request {
    my ($self, $method, $url, $options) = @_;

    unless ($method eq 'GET') {
        log_trace "Not a GET response, skip caching";
        return $self->SUPER::request($method, $url, $options);
    }

    my $tempdir = File::Util::Tempdir::get_user_tempdir();
    my $cachedir = "$tempdir/http_tiny_cache";
    #log_trace "Cache dir is %s", $cachedir;
    unless (-d $cachedir) {
        mkdir $cachedir or die "Can't mkdir '$cachedir': $!";
    }
    my $cachepath = "$cachedir/".Digest::SHA::sha256_hex($url);
    log_trace "Cache file is %s", $cachepath;

    my $maxage =
        $ENV{HTTP_TINY_CACHE_MAX_AGE} //
        $ENV{CACHE_MAX_AGE} // 86400;
    if (!(-f $cachepath) || (-M _) > $maxage/86400) {
        log_trace "Retrieving response from remote ...";
        my $res = $self->SUPER::request($method, $url, $options);
        return $res unless $res->{status} =~ /\A[23]/; # HTTP::Tiny only regards 2xx as success
        log_trace "Saving response to cache ...";
        open my $fh, ">", $cachepath or die "Can't create cache file '$cachepath' for '$url': $!";
        store_fd $res, $fh;
        close $fh;
        return $res;
    } else {
        log_trace "Retrieving response from cache ...";
        open my $fh, "<", $cachepath or die "Can't read cache file '$cachepath' for '$url': $!";
        local $/;
        my $res = fd_retrieve $fh;
        close $fh;
        return $res;
    }
}

1;
# ABSTRACT: Cache HTTP::Tiny responses

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Tiny::Cache - Cache HTTP::Tiny responses

=head1 VERSION

This document describes version 0.002 of HTTP::Tiny::Cache (from Perl distribution HTTP-Tiny-Cache), released on 2019-04-14.

=head1 SYNOPSIS

 use HTTP::Tiny::Cache;

 my $res  = HTTP::Tiny::Cache->new->get("http://www.example.com/");
 my $res2 = HTTP::Tiny::Cache->request(GET => "http://www.example.com/"); # cached response

=head1 DESCRIPTION

This class is a subclass of L<HTTP::Tiny> that cache responses.

Currently only GET requests are cached. Cache are keyed by SHA256-hex(URL).
Error responses are also cached. Currently no cache-related HTTP request or
response headers (e.g. C<Cache-Control>) are respected.

To determine cache max age, this module will consult environment variables (see
L</"ENVIRONMENT">). If all environment variables are not set, will use the
default 86400 (1 day).

=head1 ENVIRONMENT

=head2 CACHE_MAX_AGE

Int. Will be consulted after L</"HTTP_TINY_CACHE_MAX_AGE">.

=head2 HTTP_TINY_CACHE_MAX_AGE

Int. Will be consulted before L</"CACHE_MAX_AGE">.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HTTP-Tiny-Cache>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HTTP-Tiny-Cache>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTTP-Tiny-Cache>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<HTTP::Tiny>

L<HTTP::Tiny::Patch::Cache>, patch version of this module.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
