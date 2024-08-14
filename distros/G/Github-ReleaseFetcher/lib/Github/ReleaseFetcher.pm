package Github::ReleaseFetcher 1.001;

use strict;
use warnings;

# ABSTRACT: Fetch either the latest or a particular named version of a file in a release from github
use 5.006;
use v5.14.0;    # Before 5.006, v5.10.0 would not be understood.

use Carp::Always;
use HTTP::Tiny();
use HTML::TreeBuilder::Select();
use File::Basename qw{basename};


our $BASE_URI = "http://github.com";

sub fetch {
    my ( $outdir, $owner, $project, $search, $rename, $version, $ua ) = @_;

    die "Must pass outdir that exists" if $outdir && !-d $outdir;
    die "Must pass owner"   unless $owner;
    die "Must pass project" unless $owner;

    $outdir //= "";

    $version //= 'latest';
    my $index = "$BASE_URI/$owner/$project/releases/$version";

    $ua //= HTTP::Tiny->new();
    my $res;

    # Figure out *what* the latest version number is.
    if ( $version eq 'latest' ) {
        my $res = $ua->get($index);
        die "$res->{reason} :\n$res->{content}\n" unless $res->{success};

        #Snag the url we were redirected to, as this is the actual version
        $version = basename( $res->{url} );
    }
    $index = "$BASE_URI/$owner/$project/releases/expanded_assets/$version";
    $res   = $ua->get($index);
    die "$res->{reason} :\n$res->{content}\n" unless $res->{success};

    my $parsed = HTML::TreeBuilder::Select->new_from_content( $res->{content} );
    my @matches =
      map  { $_->[0][0] }
      grep { ref $_ eq "ARRAY" && ref $_->[0] eq "ARRAY"; }
      map  { $_->extract_links() } $parsed->select('a');
    @matches = grep { $_ =~ $search } @matches if $search;

    my %names = map {
        my $subj = $_;
        my $name = $rename // basename($subj);
        "$BASE_URI/$subj" => "$outdir/$name"
    } @matches;

    foreach my $to_write ( reverse sort keys %names ) {
        $ua->mirror( $to_write, $names{$to_write} ) if $outdir;
        last                                        if $rename;
    }

    return keys(%names) unless $outdir;

    my @written = values(%names);
    return pop(@written) if $rename;
    return @written;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Github::ReleaseFetcher - Fetch either the latest or a particular named version of a file in a release from github

=head1 VERSION

version 1.001

=head1 SYNOPSIS

    my @files = Github::ReleaseFetcher::fetch(".", "SeleniumHQ", "selenium", qr/\.jar$/ );

=head1 DESCRIPTION

Scrapes the github release page and reads the hrefs from the 'Assets' section.
This is because there isn't a publicly accessable machine-readable version of this listing.
As such you need this instead of freebasing JSON directly into your veins.

Relies both on the 'latest' redirect for releases on github, and the expanded_assets page.
If either of these stop working, so will this module.

=head1 SUBROUTINES

=head2 fetch(STRING $outdir, STRING $owner, STRING $project, [REGEXP $search, STRING $rename, STRING $version, HTTP::Tiny $ua])

Fetches the file(s) from the latest release within $owner's $project (optionally matching the regex described by $search).

Optionally fetch it from a specified version instead, rename the output files via the passed substitution, and pass in a configured HTTP::Tiny user agent to do the fetch.

In the event of a rename (which will result in multiple files being named the same thing), the last lexically sorted result will hold precedence.

Returns list of files written, or in the case that outdir is a false value, the URIs where said assets reside.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-Github-ReleaseFetcher/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2024 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
