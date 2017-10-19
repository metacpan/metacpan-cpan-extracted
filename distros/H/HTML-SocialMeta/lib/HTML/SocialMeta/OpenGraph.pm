package HTML::SocialMeta::OpenGraph;
use Moo;
use Carp;

our $VERSION = '0.730004';

extends 'HTML::SocialMeta::Base';

use MooX::LazierAttributes qw/rw lzy/;
use MooX::ValidateSubs;
use Types::Standard qw/Str/;

attributes(
    '+meta_attribute' => ['property'],
    '+meta_namespace' => ['og'],
    fb_namespace      => [ rw, Str, {lzy} ],
    '+card_options'   => [
        sub {
            {
                summary        => q(create_thumbnail),
                featured_image => q(create_article),
                player         => q(create_video),
                app            => q(create_product),
            };
        }
    ],
    '+build_fields' => [
        sub {
            return {
                thumbnail =>
                  [qw(type title description url image image_alt site_name fb_app_id)],
                article =>
                  [qw(type title description url image image_alt site_name fb_app_id)],
                video => [
                    qw(type site_name url title image image_alt description player player_width player_height fb_app_id)
                ],
                product => [qw(type title image image_alt description url fb_app_id)]
            };
        }
    ],
);

validate_subs(
    create_thumbnail => {
        params => [ [ Str, sub { 'thumbnail' } ] ],
    },
    create_article => {
        params => [ [ Str, sub { 'article' } ] ],
    },
    create_video => {
        params => [ [ Str, sub { 'video' } ] ],
    },
    create_product => {
        params => [ [ Str, sub { 'product' } ] ],
    },
    provider_convert => {
        params => [ [Str] ],
    },
);

sub create_thumbnail {
    return $_[0]->build_meta_tags( $_[0]->type( $_[1] ) );
}

sub create_article {
    return $_[0]->build_meta_tags( $_[0]->type( $_[1] ) );
}

sub create_video {
    return $_[0]->build_meta_tags( $_[0]->type( $_[1] ) );
}

sub create_product {
    return $_[0]->build_meta_tags( $_[0]->type( $_[1] ) );
}

sub provider_convert {
    if ( $_[1] =~ s{^fb:}{}xms ) {
        $_[1] =~ s{:}{_}xms;
        return [ { field_type => $_[1], ignore_meta_namespace => 'fb' } ];
    }
    $_[1] =~ s{^player}{video}xms;
    $_[1] =~ m{^video$}xms and return [
        { field_type => $_[1] . ':url' },
        { field_type => $_[1] . ':secure_url' }
    ];
    return [ { field_type => $_[1] } ];
}

#
# The End
#
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

HTML::SocialMeta::OpenGraph

=head1 VERSION

Version 0.730004

=cut

=head1 DESCRIPTION

Base class for creating OpenGraph meta data

=head1 SYNOPSIS

   $opengraph_meta => HTML::Social::OpenGraph->new(
        card_type => 'summary',
        site => '@example_twitter',
        site_name => 'Example Site, anything',
        title => 'You can have any title you wish here',
        description => 'Description goes here may have to do a little validation',
        image => 'www.urltoimage.com/blah.jpg',
        url  => 'www.someurl.com',
        app_url_store => 'test',  - optional
        player      => 'www.urltovideo.com/blah.jpg',
        player_width => '500',
        player_height => '500',            
   );

    # 'summary', 'featured_image', 'app', 'player'
    $opengraph->create('summary featured_image app player');
   
    $opengraph->create_thumnail;
    $opengraph->create_article;
    $opengraph->create_product';
    $opengraph->create_video;


=head1 SUBROUTINES/METHODS

=head2 card_options

A Hash Reference of card options available for this meta provider, it is used to map the create function when create is called.

=cut

=head2 build_fields 
    
A Hash Reference of fields that are attached to the selected card:

=cut

=head2 create_thumbnail

Generate OpenGraph Thumbnail meta data

=cut

=head2 create_article

Generate OpenGraph Article meta data

=cut

=head2 create_product

Generate OpenGraph Product meta data

=cut

=head2 create_video

Generate OpenGraph Video meta data

=cut

=head1 AUTHOR

Robert Acock <ThisUsedToBeAnEmail@gmail.com>

With special thanks to:
Robert Haliday <robh@cpan.org>

=head1 TODO
 
    * Add support for more social Card Types / Meta Providers
 
=head1 BUGS AND LIMITATIONS
 
Most probably. Please report any bugs at http://rt.cpan.org/.

=head1 INCOMPATIBILITIES

=head1 DEPENDENCIES

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DIAGNOSTICS 

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



