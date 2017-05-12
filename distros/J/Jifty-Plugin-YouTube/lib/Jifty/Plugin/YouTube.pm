use strict;
use warnings;

package Jifty::Plugin::YouTube;
use base qw/Jifty::Plugin/;

our $VERSION = '0.1';

=head1 NAME

Jifty::Plugin::YouTube - YouTube Plugin

=head1 SYNOPSIS

To use YouTube plugin, insert the below config to your F<etc/config.yml>

  Plugins:
    - YouTube: {}

You can write render_as 'Jifty::Plugin::YouTube::Widget' in your model schema:
    
    column url =>
        type is 'varchar',
        render_as 'Jifty::Plugin::YouTube::Widget';

then render the action:
    
    my $foo = Jifty->web->new_action(
        class     => 'UpdateFoo',
        moniker   => "update-foo",
        record    => $record->id,
    );
    render_action( $foo => ['url'] );

If the column contains a youtube url or a hash code, then the video will be rendered.

Or you can just display a Youtube Widget in L<Template::Declare>:

    template 'index.html' => page {

        show '/youtube_widget','http://www.youtube.com/watch?v=4oWbzT_oAJ0';

        # or 

        show '/youtube_widget','4oWbzT_oAJ0';

    };

Or by given url:

    http://your.app/youtube/4oWbzT_oAJ0

You can override the page wrapper by declaring a template called C</_youtube>

    template '/_youtube' => page {
        my $self = shift;
        my $hash = get('hash');

        return unless( $hash ) ;

        h1 { { id is 'banner' };
            _('Your Page Wrapper');
        };

        div { { class is 'youtube-wrapper' };
            show '/youtube_widget', $hash;
        };

    };

=head1 DESCRIPTION


=head2 AUTHOR

Cornelius C<<cornelius.howl@gmail.com>>

=cut

1;
