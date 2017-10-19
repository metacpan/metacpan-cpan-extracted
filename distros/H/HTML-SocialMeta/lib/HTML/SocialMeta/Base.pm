package HTML::SocialMeta::Base;
use Moo;
use Carp;

our $VERSION = '0.730004';

use MooX::LazierAttributes qw/rw ro lzy/;
use MooX::ValidateSubs;
use Coerce::Types::Standard qw/Str HashRef HTML/;

attributes(
    [qw(card_type card type name url)] => [ rw, HTML->by('encode_entity'), {lzy} ],
    [qw(site fb_app_id site_name title description image creator operatingSystem app_country
    app_name app_id app_url player player_height player_width)] => [HTML->by('encode_entity')],
    [qw(image_alt)] => [ Str, {lzy} ],
    [qw(card_options build_fields)] => [HashRef,{default => sub { {} }}],
    [qw(meta_attribute meta_namespace)] => [ro],
);

validate_subs(
    create => { params => [ [ Str, 'card_type' ] ] },
    build_meta_tags    => { params => [ [Str] ] },
    required_fields    => { params => [ [Str] ] },
    meta_option        => { params => [ [Str] ] },
    _generate_meta_tag => { params => [ [Str] ] },
    _build_field       => { params => [ [HashRef] ] },
    _convert_field     => { params => [ [Str] ] },
    _no_card_type      => { params => [ [Str] ] }
);

sub create {
    if ( my $option = $_[0]->card_options->{ $_[1] } ) {
        return $_[0]->$option;
    }
    return $_[0]->_no_card_type( $_[1] );
}

sub build_meta_tags {
    my @meta_tags;
    $_[0]->meta_attribute eq q{itemprop} and push @meta_tags, $_[0]->item_type;
    foreach ( $_[0]->required_fields( $_[1] ) ) {
        $_[0]->_validate_field_value($_);
        push @meta_tags, $_[0]->_generate_meta_tag($_);
    }
    return join "\n", @meta_tags;
}

sub required_fields {
    return
      defined $_[0]->build_fields->{ $_[1] }
      ? @{ $_[0]->build_fields->{ $_[1] } }
      : ();
}

sub meta_option {
    my $option = $_[0]->card_options->{$_[1]};
	$option =~ s{^create_}{}xms;
	return $option;
}

sub _validate_field_value {
    defined $_[0]->{ $_[1] } and return 1;
    croak sprintf q{you have not set this field value %s}, $_[1];
}

sub _generate_meta_tag {

    # fields that don't start with app, player, or image generate a single tag
    $_[1] !~ m{^app|player|fb|image}xms
      and return $_[0]->_build_field( { field => $_[1] } );
    return
      map { $_[0]->_build_field( { field => $_[1], %{$_} } ) }
      @{ $_[0]->_convert_field( $_[1] ) };
}

sub _build_field {
	return sprintf q{<meta %s="%s:%s" content="%s"/>}, $_[0]->meta_attribute,
      ( $_[1]->{ignore_meta_namespace} || $_[0]->meta_namespace ),
      ( defined $_[1]->{field_type} ? $_[1]->{field_type} : $_[1]->{field} ),
      $_[0]->{$_[1]->{field}};
}

sub _convert_field {
    (my $field = $_[1]) =~ s/_/:/g;
    return $_[0]->provider_convert( $field );
}

sub _no_card_type {
    return croak sprintf
q{this card type does not exist - %s try one of these summary, featured_image, app, player},
      $_[1];
}

#
# The End
#
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

HTML::SocialMeta::Base
 
=head1 DESCRIPTION

Base class for the different meta classes.

builds and returns the Meta Tags

=cut

=head1 VERSION

Version 0.730004

=cut

=head1 SYNOPSIS

    use HTML::SocialMeta;
    # summary or featured image
    my $social = HTML::SocialMeta->new(
        site => '',
        site_name => '',
        title => '',
        description => '',
        image   => '',
        image_alt => '',
        url  => '',  # optional
        ... => '',
        ... => '',
    );

    # returns meta tags for all providers
    # 'summary', 'featured_image', 'app', 'player'
    my $meta_tags = $social->create('summary');

    # returns meta tags specificly for a single provider
    my $twitter_tags = $social->twitter;
    my $opengraph_tags = $social->opengraph;

    # 'summary', 'featured_image', 'app', 'player'
    my $twitter->create('summary');


=head1 SUBROUTINES/METHODS

=head2 create

Generates meta tags for all providers, takes a card_type and converts it into a provider specific card

                        twitter                 opengraph          
    * summary           summary                 thumbnail         
    * featured_image    summary_large_image     article           
    * player            player                  video           
    * app               app                     product                         

=cut

=head2 build_meta_tags 

This builds the meta tags for the meta providers

It takes an array of fields, which loops through firstly checking 
that we have a value set and then actually building the specific tag
for that field.

=cut

=head2 required_fields

returns an array of the fields that are required to build a specific card

=cut

=head1 AUTHOR

Robert Acock <ThisUsedToBeAnEmail@gmail.com>
Robert Haliday <robh@cpan.org>

=head1 TODO
 
    * Improve tests
    * Add support for more social Card Types / Meta Providers
 
=head1 BUGS AND LIMITATIONS
 
Most probably. Please report any bugs at http://rt.cpan.org/.

=head1 INCOMPATIBILITIES

=head1 DEPENDENCIES

Moo 
List::MoreUtils - Version 0.413 

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

