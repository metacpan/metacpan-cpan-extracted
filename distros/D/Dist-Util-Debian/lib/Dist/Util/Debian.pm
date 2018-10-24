package Dist::Util::Debian;

our $DATE = '2018-10-23'; # DATE
our $VERSION = '0.007'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       dist2deb
                       deb_exists
                       dist_has_deb
                       deb_ver
                       dist_deb_ver
               );

sub dist2deb {
    my $dist = shift;
    return "lib" . lc($dist) . "-perl";
}

sub _deb_exists_or_deb_ver {
    my $which = shift;
    my $opts = ref($_[0]) eq 'HASH' ? shift : {};

    if ($opts->{use_allpackages}) {
        require File::Slurper::Temp;
        require File::Util::Tempdir;
        require HTTP::Tiny;
        require IO::Uncompress::Gunzip;
        my $url  = "https://packages.debian.org/unstable/allpackages?format=txt.gz";
        my $path = File::Util::Tempdir::get_tempdir() . "/allpackages.txt";
        my @stat = stat($path);
        unless (@stat && $stat[9] > time() - 86400) {
            log_trace "Downloading $url ...";
            my $res = HTTP::Tiny->new->get($url);
            unless ($res->{success}) {
                warn "Can't download $url: $res->{status} - $res->{reason}";
                return undef;
            }
            my $uncompressed = "";
            IO::Uncompress::Gunzip::gunzip(\($res->{content}), \$uncompressed)
                  or die "gunzip failed: $IO::Uncompress::Gunzip::GunzipError";
            File::Slurper::Temp::write_text($path, $uncompressed);
        }
        my %versions;
        my $re = join("|", map { quotemeta($_) } @_); $re = qr/^($re) \(([^\)]+?)(?:\)|\s)/;
        log_trace "Reading $path ...";
        open my($fh), "<", $path or die "Can't open $path: $!";
        while (defined(my $line = <$fh>)) {
            if ($line =~ $re) {
                $versions{$1} = $2;
            }
        }
        return map { $which eq 'deb_exists' ? (defined $versions{$_} ? 1:0) : $versions{$_} } @_;
    } else {
        require HTTP::Tiny;
        my @res;
        for my $deb (@_) {
            my $url = "https://packages.debian.org/sid/$deb";
            log_trace "Checking package $deb from $url ...";
            my $res = HTTP::Tiny->new->get($url);
            unless ($res->{success}) {
                warn "Can't check $url: $res->{status} - $res->{reason}";
                push @res, undef;
                next;
            }
            if ($res->{content} =~ /No such package/) {
                push @res, $which eq 'deb_exists' ? 0 : undef;
                next;
            } elsif ($res->{content} =~ /Package: \Q$deb\E \(([^\)]+?)(?:\)|\s)/) {
                push @res, $which eq 'deb_exists' ? 1 : $1;
                next;
            } else {
                warn "Can't understand the content of $url, no indication of ".
                    "package exists or doesn't exist";
                push @res, undef;
                next;
            }
        }
        return @res;
    }
}

sub deb_exists {
    _deb_exists_or_deb_ver('deb_exists', @_);
}

sub deb_ver {
    _deb_exists_or_deb_ver('deb_ver', @_);
}

sub dist_has_deb {
    my $opts = ref($_[0]) eq 'HASH' ? shift : {};

    deb_exists($opts, map { dist2deb($_) } @_);
}

sub dist_deb_ver {
    my $opts = ref($_[0]) eq 'HASH' ? shift : {};

    deb_ver($opts, map { dist2deb($_) } @_);
}

1;
# ABSTRACT: Utilities related to Perl distribution and Debian

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Util::Debian - Utilities related to Perl distribution and Debian

=head1 VERSION

This document describes version 0.007 of Dist::Util::Debian (from Perl distribution Dist-Util-Debian), released on 2018-10-23.

=head1 SYNOPSIS

 use Dist::Util::Debian qw(
     dist2deb
     deb_exists
     dist_has_deb
     deb_ver
     dist_deb_ver
 );

 say dist2deb("HTTP-Tiny"); # -> libhttp-tiny-perl

 say dist_has_deb("HTTP-Tiny"); # -> 1
 say dist_has_deb("Foo");       # -> 0
 say dist_has_deb({use_allpackages=>1}, "HTTP-Tiny", "Foo"); # -> (1, 0)

 say dist_deb_ver("HTTP-Tiny"); # -> "0.070-1"
 say dist_deb_ver("Foo");       # -> undef
 say dist_deb_ver({use_allpackages=>1}, "HTTP-Tiny", "Foo"); # -> ("0.070-1", undef)

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 dist2deb($dist, ...) => list

It uses the simple rule of turning C<$dist> to lowercase and adds "lib" +
"-perl" prefix and suffix. A small percentage of distributions do not follow
this rule.

=head2 dist_has_deb([ \%opts, ] $dist, ...) => bool|list[bool]

Return true if distribution named C<$dist> has a corresponding Debian package.
Currently the way the routine checks this is rather naive: it checks the
corresponding Debian package against this URL:
L<https://packages.debian.org/sid/$package>.

Will warn and return undef on error, e.g. the URL cannot be checked or does not
contain negative/positive indicator of existence.

Can accept multiple dists and will return a list of bools in that case.

Known options:

=over

=item * use_allpackages => bool

If you need to check a lot of distributions (hundreds or more) then the default
way of checking each distribution against a URL might be too slow. An
alternative way, enabled if you set this option to true, is to download
L<https://packages.debian.org/unstable/allpackages?format=txt.gz> (at the time
of this writing, Jan 2017, the size is about 1.7M) then parse it locally. The
file will be cached to a temporary file and reused for a day.

Function will return undef if the allpackages index cannot be donwloaded.

=back

=head2 deb_exists([ \%opts, ] $deb, ...) => bool|list[bool]

=head2 deb_ver([ \%opts, ] $deb, ...) => str|list[str]

=head2 dist_deb_ver([ \%opts, ] $deb, ...) => str|list[str]

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Util-Debian>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Util-Debian>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Util-Debian>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
