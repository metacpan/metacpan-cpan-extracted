package Flickr::Embed;

use strict;
use warnings;
use Flickr::API;
use HTML::Entities;
our $VERSION = 0.01;
require 5.005;

sub _get_cc_licences {
    my ($xml) = @_;

    my @creativecommons;
    my %licence_names;

    for my $e (@$xml) {
	if ($e->{name} && $e->{name} eq 'licenses') {
	    for my $c (@{$e->{children}}) {
		next unless $c->{name} && $c->{name} eq 'license';
		if (index($c->{attributes}->{url}, 'creativecommons')!=-1) {
		    push @creativecommons, $c->{attributes}->{'id'};
		    $licence_names{$c->{attributes}->{id}} = $c->{attributes}->{name};
		}
	    }
	}
    }

    return (join (',', @creativecommons), \%licence_names);
}

sub _safe_execute {
    my ($api, $method, @params) = @_;

    my $response = $api->execute_method($method, @params);

    die "Flickr::Embed ($method) " . $response->{error_message} unless $response->{success};

    return $response;
}

sub _fish_out_attributes {
    my ($tree) = @_;

    my @result;

    if (ref($tree) eq 'HASH') {

	push @result, $tree->{attributes} if $tree->{attributes};

	push @result, _fish_out_attributes ($tree->{children}) if $tree->{children};


    } elsif (ref($tree) eq 'ARRAY') {
	@result = map { _fish_out_attributes($_) } @$tree;
    }

    return @result;
}

sub _photo_details {
    my ($api, $id) = @_;

    my %result;

    my $response = _safe_execute($api, 'flickr.photos.getSizes',
				 {photo_id => $id,}
	);

    my @attrs = _fish_out_attributes($response->{tree});

    for (@attrs) {
	%result = (%result, %$_) if
	    $_->{candownload} ||
	    ($_->{label} && $_->{label} eq 'Medium');
    }

    return %result;
}

sub embed {
    my (%opts) = @_;

    for (qw(tags key secret)) {
	die "Flickr::Embed::embed: $_ parameter is required"
	    unless $opts{$_};
    }

    my %exclusions;

    %exclusions = map { $_=>1 } @{$opts{exclude}} if $opts{exclude};

    my $api = new Flickr::API({
	key => $opts{key},
	secret => $opts{secret},
	});

    my $response = _safe_execute($api, 'flickr.photos.licenses.getInfo');

    my ($cc_licences, $licence_names) = _get_cc_licences($response->{tree}->{children});

    $response = _safe_execute($api, 'flickr.photos.search',
	{tags => $opts{tags},
	 tag_mode => 'all',
	 license => $cc_licences,
	 per_page => $opts{per_page} || '100',
	 extras => 'license,owner_name',}
	);

    my @photos;

    for (@{ $response->{tree}->{children} }) {
	@photos = map {
	    $_->{attributes}
	    } grep {
	    $_->{name} && $_->{name} eq 'photo'
	    } @{ $_->{children} } if ($_->{name} && $_->{name} eq 'photos');
    }

    my @result;

    for (@photos) {
	next if $exclusions{$_->{id}};

	my %result = (
	    %$_,
	    _photo_details($api, $_->{id}),
	);

	# should honour $result{canblog} here, but it's always 0 even on
	# cc photos.

	my $title = encode_entities($result{title});
	my $author = encode_entities($result{ownername});
	my $url = $result{url};

	$url =~ s!sizes/./!!;

	$result{html} = "<a title=\"$title by $author, on Flickr\" ".
	    "href=\"$result{source}\">" .
	    "<img src=\"$url\" alt=\"$title\" ".
	    "width=\"$result{width}\" height=\"$result{height}\" align=\"right\" /></a>";

	$result{attribution} = "Copyright &copy; $author. ".
	    $licence_names->{$result{license}};

	push @result, \%result;

	last unless wantarray;
    }

    # later, if result==(), and we've excluded any, go round and get the next ones

    return $result[0] unless wantarray;
    return @result;
}

1;

=head1 NAME

Flickr::Embed - Simple embedding of Flickr pictures into HTML

=head1 SYNOPSIS

 use Flickr::Embed;

 my $fe = Flickr::Embed::embed(
    tags=>'carrots',
    key=>'key',
    secret=>'secret',
 );

 my $blog = "$fe{html}This is a post which will appear on my blog.".
   "<br/><i>$fe{attribution}</i>";

=head1 DESCRIPTION

When you have an automated system to produce blog posts, sometimes you
want to attach random pictures to it on some theme or other.  For example,
you might post the output of your unit tests every day and decide it would
look good if each one had a different picture of a camel next to it.
C<Flickr::Embed> will look up your search terms on Flickr and return a
given picture each time.

=head1 SYNOPSIS

=head2 embed()

Returns a hash of information taken from Flickr.  In list context, returns
everything it received from Flickr, subject to exclusions.  In scalar context,
returns just the first one, subject to exclusions.  The return type is
described in THE CONTENTS OF THE HASH, below.  Takes a set of named parameters,
described below.

=head1 PARAMETERS TO THE EMBED FUNCTION

=head2 key

A Flickr API key.  See WHERE TO GET A KEY, below.  Required.

=head2 secret

A Flickr API secret.  See WHERE TO GET A KEY, below.  Required.

=head2 tags

Tags to look for.  Separate multiple tags with commas; only pictures which
match all given tags will be returned.  Required.

=head2 exclude

An arrayref of IDs of photos not to retrieve, presumably because you've seen them
already.

=head2 per_page

How many photos to return (if this call is in list context).  You will get at most
this many; if any exclusions match, or if there aren't enough photos on Flickr
with the given tags, you will get fewer.

=head1 THE CONTENTS OF THE HASH

=head2 html

A block of HTML ready to paste into a blog post.

=head2 attribution

An attribution of the author, including the licence.  Most Creative Commons licences
require attribution, and anyway it's good manners, so be sure to put this in
somewhere.

=head2 Everything returned by flickr.photos.Search

for this photo, and and also

=head2 Everything returned by flickr.photos.getSizes

for the current size; see the Flickr API documentation.

=head1 WHERE TO GET A KEY

http://www.flickr.com/services/api/keys/apply/

If you don't have this, most of the tests will be skipped.

=head1 BUGS

If you exclude all the pictures in the first fetch, C<Flickr::Embed> does not yet
go back and get another batch; it behaves as if there were no pictures found.
By default this will only happen if you have at least 100 exclusions.
This will be fixed in a later release.

=head1 SEE ALSO

C<Flickr::API>.

=head1 AUTHOR

Thomas Thurman, tthurman@gnome.org.

=head1 COPYRIGHT

This Perl module is copyright (C) Thomas Thurman, 2009.
This is free software, and can be used/modified under the same terms as Perl itself.
