use warnings;
use strict;

package Jifty::Plugin::SiteNews::View::News;
use Jifty::View::Declare -base;
use base 'Jifty::View::Declare::CRUD';

=head1 NAME

Jifty::Plugin::SiteNews::View::News - /news pages for your app

=head1 DESCRIPTION

The /news pages for L<Jifty::Plugin::SiteNews>

=cut


=head2 object_type

News

=cut

sub object_type { 'News' }

template search_region => sub {''};

template sort_header => sub {''};

template 'index.html' => page {
    my $self = shift;
    title is  'Site news' ;
    form {
            render_region(
                name     => 'newslist',
                path     =>  $self->fragment_base_path.'/list');
    }

};

template 'view' => sub {
    my $self = shift;
    my ( $object_type, $id ) = ( $self->object_type, get('id') );
    my $update = new_action(
        class => 'Update' . $object_type,
        moniker => "update-" . Jifty->web->serial,
        record  => $self->_get_record( $id )
    );

    my $record = $self->_get_record($id);

    h1 { $record->title };
    span { {class is 'date'} $record->created };
    blockquote {$record->content};

    if ($record->current_user_can('update')) {
        hyperlink(
                label   => "Edit",
                class   => "editlink",
                onclick => {
                    replace_with => $self->fragment_for('update'),
                    args         => { object_type => $object_type, id => $id }
                },
        );
    }

};

template no_items_found => sub {
    div {
        { class is 'no_items' };
        outs( _("No news is good news!") );
    }
};

1;
