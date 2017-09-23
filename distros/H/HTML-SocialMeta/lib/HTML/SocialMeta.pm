package HTML::SocialMeta;
use Moo;
use List::MoreUtils qw(uniq);

use HTML::SocialMeta::Twitter;
use HTML::SocialMeta::OpenGraph;

use MooX::LazierAttributes qw/lzy bld/;
use MooX::ValidateSubs;
use Types::Standard qw/Str Object ArrayRef Split/;

our $VERSION = '0.73';

our %encode;
BEGIN {
        %encode = ( q{&} => q{&amp;}, q{"} => q{&quot;}, q{'} => q{&apos;}, q{<} => q{&lt;}, q{>} => q{&gt;} );
        $encode{regex} = join "|", keys %encode;
}

attributes(
    [qw(card_type card site site_name title description image image_alt url creator operatingSystem
    app_country app_name app_id app_url player player_height player_width fb_app_id)] => [ Str, {lzy, coerce => sub { 
        $_[0] =~ s/($encode{regex})/$encode{$1}/g;
		$_[0]; 
	}} ],
    [qw(twitter opengraph)] => [ Object, { lzy, bld } ],
    social => [ sub { [qw/twitter opengraph/] } ],
);

validate_subs(
    create => {
        params => [ [ Str, 'card_type' ], [ (ArrayRef[Str])->plus_coercions(Split[qr/\s/]), 'social' ] ], # I expect this to be an arrayref
    },
    required_fields => {
        params => [ [ Str, 'card_type' ], [ (ArrayRef[Str])->plus_coercions(Split[qr/\s/]), 'social' ] ],
    },
);

sub create {
    return join "\n", map { $_[0]->$_->create( $_[1] ) } @{ $_[2] }; # it doesn't coerce my value
}

sub required_fields {
    return uniq(
        map { $_[0]->$_->required_fields( $_[0]->$_->meta_option( $_[1] ) ) }
          @{ $_[2] } );
}

sub _build_twitter {
    HTML::SocialMeta::Twitter->new(
        (
            map { defined $_[0]->$_ ? ( $_ => $_[0]->$_ ) : () }
              qw/card_type site title description image image_alt url creator
              operatingSystem app_country app_name app_id app_url
              player player_width player_height/
        )
    );
}

sub _build_opengraph {
    HTML::SocialMeta::OpenGraph->new(
        (
            map { defined $_[0]->$_ ? ( $_ => $_[0]->$_ ) : () }
              qw/card_type site_name title description image operatingSystem player
              image_alt player_width player_height fb_app_id/
        ),
        (
            $_[0]->app_url || $_[0]->url
            ? ( url => $_[0]->app_url ? $_[0]->app_url : $_[0]->url )
            : ()
        ),
    );
}

#
# The End
#
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

HTML::SocialMeta - Module to generate Social Media Meta Tags, 

=head1 VERSION

Version 0.73

=head1 SYNOPSIS

    use HTML::SocialMeta;
    # summary or featured image card setup
    my $social = HTML::SocialMeta->new(
        site => '',
        site_name => '',
        title => '',
        description => '',
        image	=> '',
        fb_app_id => '',
	    url  => '',  # optional
        ... => '',
        ... => '',
    );

    # returns meta tags for all providers	
    # additional options 'featured_image',  'app', 'player'   
    my $meta_tags = $social->create('summary');

    # returns meta tags specificly for a single provider
    my $twitter_tags = $social->twitter;
    my $opengraph_tags = $social->opengraph;

    my $twitter = $social->twitter;
    my $twitter->create('summary');
    
    # Alternatively call a card directly
    my $summary_card = $meta_tags->twitter->create_summary;
    
    ....
    # You then need to insert these meta tags in the head of your html, 
    # one way of implementing this if you are using Catalyst and Template Toolkit would be ..
    
    # controller 
    $c->stash->{meta_tags} = $meta_tags;
    
    # template
    [% meta_tags | html %]

=head1 DESCRIPTION

This module generates social meta tags.

i.e  $social->create('summary') will generate:
    
    <meta name="twitter:card" content="summary"/>
    <meta name="twitter:site" content="@example_twitter"/>
    <meta name="twitter:title" content="You can have any title you wish here"/>
    <meta name="twitter:description" content="Description goes here may have to do a little validation"/>
    <meta name="twitter:image" content="www.urltoimage.com/blah.jpg"/>
    <meta property="og:type" content="thumbnail"/>
    <meta property="og:title" content="You can have any title you wish here"/>
    <meta property="og:description" content="Description goes here may have to do a little validation"/>
    <meta property="og:url" content="www.someurl.com"/>
    <meta property="og:image" content="www.urltoimage.com/blah.jpg"/>
    <meta property="og:site_name" content="Example Site, anything"/>
    <meta property="fb:app_id" content="123433223543"/>'

It allows you to optimize sharing on several social media platforms such as Twitter, Facebook, Google+ 
and Pinerest by defining exactly how titles, descriptions, images and more appear in social streams.

It generates all the required META data for the following Providers:

    * Twitter
    * OpenGraph

This module currently allows you to generate the following meta cards:

    $social->create()  $twitter->create_       $opengraph->create_  	
    summary            summary                 thumbnail         	
    featured_image     summary_large_image     article            	 
    player             player                  video              	
    app                app                     product             	                 

=head1 SUBROUTINES/METHODS

=head2 Constructor

Returns an instance of this class. Requires C<$url> as an argument;

=over

=item card

OPTIONAL - if you always want the same card type you can set it 

=item site

The Twitter @username the card should be attributed to. Required for Twitter Card analytics. 

=item site_name

This is Used by Facebook, you can just set it as your organisations name.

=item title

The title of your content as it should appear in the card 

=item description

A description of the content in a maximum of 200 characters

=item image

A URL to a unique image representing the content of the page

=item image_alt

OPTIONAL - A text description of the image, for use by vision-impaired users

=item url

OPTIONAL OPENGRAPH - allows you to specify an alternative url link you want the reader to be redirected

=item player

HTTPS URL to iframe player. This must be a HTTPS URL which does not generate active mixed content warnings in a web browser

=item player_width

Width of IFRAME specified in twitter:player in pixels

=item player_height

Height of IFRAME specified in twitter:player in pixels

=item operating_system

IOS or Android 

=item app_country      

UK/US ect

=item app_name   

The applications name

=item app_id 

String value, and should be the numeric representation of your app ID in the App Store (.i.e. 307234931)

=item app_url 

Application store url - direct link to App store page

=item fb_app_id

This field is required to use social meta with facebook, you must register your website/app/company with facebook.
They will then provide you with a unique app_id.

=back

=head2 Summary Card

The Summary Card can be used for many kinds of web content, from blog posts and news articles, to products and restaurants. 
It is designed to give the reader a preview of the content before clicking through to your website.

    ,-----------------------------------,
    |   TITLE                 *-------* |
    |                         |       | |
    |   DESCRIPTION           |       | |
    |                         *-------* |
    *-----------------------------------*

Returns an instance for the summary card:
	
    $meta->create('summary');
    # call meta provider specifically
    $card->twitter->create_summary;
    $card->opengraph->create_thumbnail;

fields required:

    * card   
    * site_name - OpenGraph
    * site - Twitter Site
    * title
    * description
    * image

=head2 Featured Image Card

The Featured Image Card features a large, full-width prominent image. 
It is designed to give the reader a rich photo experience, clicking on the image brings the user to your website.

    ,-----------------------------------,
    | *-------------------------------* |
    | |                               | |
    | |                               | |
    | |                               | |
    | |                               | |
    | |                               | |
    | |                               | |
    | *-------------------------------* |
    |  TITLE                            |
    |  DESCRIPTION                      |
    *-----------------------------------*

Returns an instance for the featured image card:

    $card->create('featured_image');	
    # call meta provider specifically
    $card->twitter->create_featured_image;
    $card->opengraph->create_article;

Fields Required:

    * card - Twitter
    * site - Twitter
    * site_name  - Open Graph
    * creator - Twitter
    * title
    * image
    * url - Open Graph

Optional Fields:

    * image_alt

=cut

=head2 Player Card

The Player Card allows you to share Video clips and audio stream.

    ,-----------------------------------,
    | Title                             |	
    | link   				|
    | *-------------------------------* |
    | |                               | |
    | |                               | |
    | |                               | |
    | |            <play>             | |
    | |                               | |
    | |                               | |
    | *-------------------------------* |
    *-----------------------------------*

Returns an instance for the player card:

    $card->create('player');
    # call meta provider specifically
    $card->twitter->create_player;
    $card->opengraph->create_video;

Fields Required:

    * site
    * title
    * description
    * image
    * player
    * player_width
    * player_height

Optional Fields:

    * image_alt

image to be displayed in place of the player on platforms that does not support iframes or inline players. You should make this image the same dimensions
as your player. Images with fewer than 68,600 pixels (a 262 x 262 square image, or a 350 x 196 16:9 image) will cause the player card not to render.
Image must be less than 1MB in size

=cut

=head2 App Card

The App Card is a great way to represent mobile applications on Social Media Platforms and to drive installs.

    ,-----------------------------------,
    |   APP NAME              *-------* |
    |   APP INFO              |  app  | |
    |                         | image | |
    |                         *-------* |
    |   DESCRIPTION                     |
    *-----------------------------------*

Return an instance for the provider specific app card:

    $card->create('app);	
    # call meta provider specifically
    $card->twitter->create_app;
    $card->opengraph->create_product;

Fields Required

    * site
    * title
    * description
    * operatingSystem   
    * app_country      
    * app_name        
    * app_id           
    * app_url           

=cut

=head2 create

Create the Meta Tags - this returns the meta information for all the providers:
    
    * Twitter
    * OpenGraph
    * Google
	
You just need to specify the card type on create

    #'summary', 'featured_image', 'app', 'player'
    $social->create('summary');

=cut

=head2 required_fields

Returns a list of fields that are required to build the meta tags

    $social = HTML->SocialMeta->new();
    # @fields = qw{}
    my @fields = $social->required_fields('summary');

=cut

=head1 BUGS AND LIMITATIONS
 
Please report any bugs at http://rt.cpan.org/.

Add support for Schema.org Rich Snippets
Improve Unit Tests
Add support for additional card types

=head1 DEPENDENCIES

Moo - Version 1.001000, 
List::MoreUtils - Version 0.413 

=head1 DIAGNOSTICS

A. Twitter Validation Tool

L<https://cards-dev.twitter.com/validator>

Before your cards show on Twitter, you must first have your domain approved. Fortunately, 
it's a super-easy process. After you implement your cards, simply enter your sample URL into 
the validation tool. After checking your markup, select the "Submit for Approval" button.

B. Facebook Debugger

L<https://developers.facebook.com/tools/debug>

You do not need prior approval for your meta information to show on Facebook, 
but the debugging tool they offer gives you a wealth of information about all your 
tags and can also analyze your Twitter tags.

C. Google Structured Data Testing Tool

L<https://search.google.com/structured-data/testing-tool>

Webmasters traditionally use the structured data testing tool to test authorship markup and preview
how snippets will appear in search results, but you can also use see what other types of
meta data Google is able to extract from each page.

=head1 AUTHOR

Robert Acock <ThisUsedToBeAnEmail@gmail.com>
Robert Haliday <robh@cpan.org>
Jason McIntosh (JMAC) <jmac@jmac.org>

=head1 CONFIGURATION AND ENVIRONMENT

=head1 INCOMPATIBILITIES

=head1 LICENSE AND COPYRIGHT
 
Copyright 2017 Robert Acock.
 
This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:
 
L<http://www.perlfoundation.org/artistic_license_2_0>
 
Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.
 
If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.
 
This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.
 
This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.
 
Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



