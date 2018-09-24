package HTTP::Tiny::Patch::Cache;

our $DATE = '2018-09-20'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Module::Patch qw();
use base qw(Module::Patch);

our %config;

my $p_request = sub {
    require Digest::SHA;
    require File::Util::Tempdir;
    require JSON::MaybeXS;

    my $ctx = shift;
    my $orig = $ctx->{orig};

    my ($self, $method, $url) = @_;

    unless ($method eq 'GET') {
        log_trace "Not a GET response, skip caching";
        return $orig->(@_);
    }

    my $tempdir = File::Util::Tempdir::get_user_tempdir();
    my $cachedir = "$tempdir/http_tiny_patch_cache";
    log_trace "Cache dir is %s", $cachedir;
    unless (-d $cachedir) {
        mkdir $cachedir or die "Can't mkdir '$cachedir': $!";
    }
    my $cachepath = "$cachedir/".Digest::SHA::sha256_hex($url);
    log_trace "Cache file is %s", $cachepath;
    my $maxage = $ENV{CACHE_MAX_AGE} // 86400;
    if (!(-f $cachepath) || (-M _) > $maxage/86400) {
        log_trace "Retrieving response from remote ...";
        my $res = $orig->(@_);
        log_trace "Saving response to cache ...";
        open my $fh, ">", $cachepath or die "Can't create cache file '$cachepath' for '$url': $!";
        print $fh JSON::MaybeXS::encode_json($res);
        close $fh;
        return $res;
    } else {
        log_trace "Retrieving response from cache ...";
        open my $fh, "<", $cachepath or die "Can't read cache file '$cachepath' for '$url': $!";
        local $/;
        my $res = JSON::MaybeXS::decode_json(scalar <$fh>);
        close $fh;
        return $res;
    }
};

sub patch_data {
    return {
        v => 3,
        config => {
            #-max_age => {
            #    schema  => 'posint*',
            #    default => 86400,
            #},
        },
        patches => [
            {
                action      => 'wrap',
                mod_version => qr/^0\.*/,
                sub_name    => 'request',
                code        => $p_request,
            },
        ],
    };
}

1;
# ABSTRACT: Cache HTTP::Tiny responses

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Tiny::Patch::Cache - Cache HTTP::Tiny responses

=head1 VERSION

This document describes version 0.002 of HTTP::Tiny::Patch::Cache (from Perl distribution HTTP-Tiny-Patch-Cache), released on 2018-09-20.

=head1 SYNOPSIS

From Perl:

 use HTTP::Tiny::Patch::Cache;

 my $res  = HTTP::Tiny->new->get("http://www.example.com/");
 my $res2 = HTTP::Tiny->request(GET => "http://www.example.com/"); # cached response

From command-line (one-liner):

 % perl -MHTTP::Tiny::Patch::Cache -E'my $res = HTTP::Tiny->new->get("..."); ...'

To customize cache period (default is one day, the example below sets it to 2
hours):

 % CACHE_MAX_AGE=7200 perl -MHTTP::Tiny::Patch::Cache ...

To clear cache, you can temporarily set cache period to 0:

 % CACHE_MAX_AGE=0 perl -MHTTP::Tiny::Patch::Cache ...

Or you can delete I<$tempdir/http_tiny_patch_cache/>, where I<$tempdir> is
retrieved from L<File::Util::Tempdir>'s C<get_user_tempdir()>.

=head1 DESCRIPTION

This module patches L<HTTP::Tiny> to cache responses. Currently only GET
requests are cached. Cache are keyed by SHA256-hex(URL). Error responses are
also cached. Currently no cache-related HTTP request or response headers (e.g.
C<Cache-Control>) are respected. This patch is mostly useful when testing (e.g.
saving bandwidth when repeatedly getting huge HTTP pages).

=for Pod::Coverage ^(patch_data)$

=head1 CONFIGURATION

=head1 FAQ

=head1 ENVIRONMENT

=head2 CACHE_MAX_AGE

Int. Default 86400. Set period of cache.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HTTP-Tiny-Patch-Cache>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HTTP-Tiny-Patch-Cache>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTTP-Tiny-Patch-Cache>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<LWP::Simple::WithCache>

L<LWP::UserAgent::WithCache>

L<MooX::Role::CachedURL>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
