package LWP::UserAgent::Plugin::Cache;

our $DATE = '2019-04-15'; # DATE
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

    my $cachedir = "$tempdir/lwp_useragent_plugin_cache";
    unless (-d $cachedir) {
        mkdir $cachedir or die "Can't mkdir '$cachedir': $!";
    }

    my $cachepath = "$cachedir/".Digest::SHA::sha256_hex($url);

    ($cachedir, $cachepath);
}

sub before_request {
    my ($self, $r) = @_;

    my ($ua, $request, $arg, $size, $previous) = @{ $r->{argv} };
    unless ($request->method eq 'GET') {
        log_trace "Not a GET response, skip caching";
        return -1; # decline
    }

    my $url = $request->uri;
    my ($cachedir, $cachepath) = $self->_get_cache_dir_path($url);
    log_trace "Cache file is %s", $cachepath;

    my $max_age = $r->{config}{max_age} //
        $ENV{LWP_USERAGENT_PLUGIN_CACHE_MAX_AGE} //
        $ENV{CACHE_MAX_AGE} // 86400;

    if (!(-f $cachepath) || (-M _) > $max_age/86400) {
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

    my ($ua, $request, $arg, $size, $previous) = @{ $r->{argv} };
    my $url = $request->uri;

    my ($cachedir, $cachepath) = $self->_get_cache_dir_path($url);

  CACHE_RESPONSE:
    {
        last unless $r->{cache_response};
        if ($r->{config}{cache_if}) {
            if (ref $r->{config}{cache_if} eq 'Regexp') {
                last unless $r->{response}->code =~ $r->{config}{cache_if};
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
# ABSTRACT: Cache LWP::UserAgent responses

__END__

=pod

=encoding UTF-8

=head1 NAME

LWP::UserAgent::Plugin::Cache - Cache LWP::UserAgent responses

=head1 VERSION

This document describes version 0.001 of LWP::UserAgent::Plugin::Cache (from Perl distribution LWP-UserAgent-Plugin-Cache), released on 2019-04-15.

=head1 SYNOPSIS

 use LWP::UserAgent::Plugin 'Cache' => {
     max_age  => '3600',     # defaults to LWP_USERAGENT_PLUGIN_CACHE_MAX_AGE or CACHE_MAX_AGE or 86400
     cache_if => qr/^[23]/,  # optional, default is to cache all responses
 };

 my $res  = LWP::UserAgent::Plugin->new->get("http://www.example.com/");
 my $res2 = LWP::UserAgent::Plugin->request(GET => "http://www.example.com/"); # cached response

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

Int. Will be consulted after L</"LWP_USERAGENT_PLUGIN_CACHE_MAX_AGE">.

=head2 LWP_USERAGENT_PLUGIN_CACHE_MAX_AGE

Int. Will be consulted before L</"CACHE_MAX_AGE">.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/LWP-UserAgent-Plugin-Cache>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-LWP-UserAgent-Plugin-Cache>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=LWP-UserAgent-Plugin-Cache>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<LWP::UserAgent::Plugin>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
