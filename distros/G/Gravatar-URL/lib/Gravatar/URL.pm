package Gravatar::URL;

use strict;
use warnings;

use URI::Escape qw(uri_escape);
use Digest::MD5 qw(md5_hex);
use Carp;

our $VERSION = '1.07';

use parent 'Exporter';
our @EXPORT = qw(
    gravatar_id
    gravatar_url
);    

my $Gravatar_Http_Base  = "http://www.gravatar.com/avatar/";
my $Gravatar_Https_Base = "https://secure.gravatar.com/avatar/";

=head1 NAME

Gravatar::URL - Make URLs for Gravatars from an email address

=head1 SYNOPSIS

    use Gravatar::URL;

    my $gravatar_id  = gravatar_id($email);

    my $gravatar_url = gravatar_url(email => $email);

=head1 DESCRIPTION

A Gravatar is a Globally Recognized Avatar for a given email address.
This allows you to have a global picture associated with your email
address.  You can look up the Gravatar for any email address by
constructing a URL to get the image from L<gravatar.com>.  This module
does that.

Examples of use include the author faces on L<http://search.cpan.org>.

See L<http://gravatar.com> for more info.

=head1 Functions

=head3 B<gravatar_url>

    # By email
    my $url = gravatar_url( email => $email, %options );

    # By gravatar ID
    my $url = gravatar_url( id => $id, %options );

Constructs a URL to fetch the gravatar for a given C<$email> or C<$id>.

C<$id> is a gravatar ID.  See L</gravatar_id> for more information.

C<%options> are optional and are...

=head4 rating

A user can rate how offensive the content of their gravatar is, like a
movie.  The ratings are g, pg, r and x.  If you specify a rating it is
the highest rating that will be given.

    rating => "r"   # includes g, pg and r

=head4 size

Specifies the desired width and height of the gravatar (gravatars are square).

Valid values are from 1 to 512 inclusive. Any size other than 80 may
cause the original gravatar image to be downsampled using bicubic
resampling before output.

    size    => 40,  # 40 x 40 image

=head4 default

The url to use if the user has no gravatar or has none that fits your rating requirements.

    default => "https://secure.wikimedia.org/wikipedia/en/wiki/File:Mad30.jpg"

Relative URLs will be relative to the base (ie. gravatar.com), not your web site.

Gravatar defines special values that you may use as a default to
produce dynamic default images. These are "identicon", "monsterid",
"wavatar" and "retro".  "404" will cause the URL to return an HTTP 404 "Not Found"
error instead whereas "mm" will display the same "mystery man" image for all
missing people.  See L<http://en.gravatar.com/site/implement/url> for
more info.

If omitted, Gravatar will serve up their default image, the blue G.

=head4 border

B<DEPRECATED!> This key has been removed from the Gravatar protocol.
It will be removed from future versions of Gravatar::URL.

Gravatars can be requested to have a 1 pixel colored border.  If you'd
like that, pass in the color to border as a 3 or 6 digit hex string.

    border => "000000",  # a black border, like my soul
    border => "000",     # black, but in 3 digits

=head4 base

This is the URL of the location of the Gravatar server you wish to
grab Gravatars from.  Defaults to
L<http://www.gravatar.com/avatar/"> for HTTP and
L<https://secure.gravatar.com/avatar/> for HTTPS.

=head4 short_keys

If true, use short key names when constructing the URL.  "s" instead
of "size", "r" instead of "ratings" and so on.

short_keys defaults to true.

=head4 https

If true, serve avatars over HTTPS instead of HTTP.

You should select this option if your site is served over HTTPS to
avoid browser warnings about the presence of insecure content.

https defaults to false.

=cut

my %defaults = (
    short_keys  => 1,
    base_http   => $Gravatar_Http_Base,
    base_https  => $Gravatar_Https_Base,
    https       => 0,
);

sub gravatar_url {
    my %args = @_;

    exists $args{id} or exists $args{email} or 
        croak "Cannot generate a Gravatar URI without an email address or gravatar id";

    exists $args{id} xor exists $args{email} or
        croak "Both an id and an email were given.  gravatar_url() only takes one";

    _apply_defaults(\%args, \%defaults);

    if ( exists $args{size} ) {
        $args{size} >= 1 and $args{size} <= 512
            or croak "Gravatar size must be 1 .. 512";
    }

    if ( exists $args{rating} ) {
        $args{rating} =~ /\A(?:g|pg|r|x)\Z/i
            or croak "Gravatar rating can only be g, pg, r, or x";
        $args{rating} = lc $args{rating};
    }

    if ( exists $args{border} ) {
        carp "The border key is deprecated";
        $args{border} =~ /\A[0-9A-F]{3}(?:[0-9A-F]{3})?\Z/
            or croak "Border must be a 3 or 6 digit hex number in caps";
    }
    
    $args{gravatar_id} = $args{id} || gravatar_id($args{email});

    $args{default} = uri_escape($args{default})
        if $args{default};

    # Use a fixed order to make testing easier
    my @pairs;
    for my $arg ( qw( rating size default border ) ) {
        next unless exists $args{$arg};

        my $key = $arg;
        $key = substr($key, 0, 1) if $args{short_keys};
        push @pairs, join("=", $key, $args{$arg});
    }

    my $uri = $args{base};
    $uri   .= "/" unless $uri =~ m{/$};
    $uri   .= $args{gravatar_id};
    $uri   .= "?".join("&",@pairs) if @pairs;

    return $uri;
}


sub _apply_defaults {
    my($hash, $defaults) = @_;

    for my $key (keys %$defaults) {
        next if 'base_http' eq $key or 'base_https' eq $key;
        next if exists $hash->{$key};
        $hash->{$key} = $defaults->{$key};
    }

    if (not exists $hash->{'base'}) {
        $hash->{'base'} = $hash->{'https'} ? $defaults->{base_https} : $defaults->{base_http};
    }

    return;
}

=head3 B<gravatar_id>

    my $id = gravatar_id($email);

Converts an C<$email> address into its Gravatar C<$id>.

=cut

sub gravatar_id {
    my $email = shift;
    return md5_hex(lc $email);
}


=head1 THANKS

Thanks to L<gravatar.com> for coming up with the whole idea and Ashley
Pond V from whose L<Template::Plugin::Gravatar> I took most of the
original code.


=head1 LICENSE

Copyright 2007 - 2009, Michael G Schwern <schwern@pobox.com>.
Copyright 2011, Francois Marier <fmarier@gmail.com>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/artistic.html>


=head1 SEE ALSO

L<Template::Plugin::Gravatar> - a Gravatar plugin for Template Toolkit

L<http://www.gravatar.com> - The Gravatar web site

L<http://en.gravatar.com/site/implement/url> - The Gravatar URL implementor's guide

=cut


1;
