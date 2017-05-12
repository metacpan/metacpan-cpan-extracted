package Devel::ebug::Wx::Command::Views;

use strict;
use Devel::ebug::Wx::Plugin qw(:plugin);

sub commands : Command {
    my( $class, $wxebug ) = @_;
    my @commands;

    my $viewmanager = $wxebug->view_manager_service;
    foreach my $view ( $viewmanager->views ) {
        my $tag = $view->tag;
        my $cmd = sub {
            my( $wx ) = @_;

            # show if present, recreate if not present
            if( $viewmanager->has_view( $tag ) ) {
                if( $viewmanager->is_shown( $tag ) ) {
                    $viewmanager->hide_view( $tag );
                } else {
                    $viewmanager->show_view( $tag );
                }
            } else {
                my $instance = $view->new( $wx, $wx );
                $viewmanager->create_pane_and_update
                  ( $instance, { name    => $instance->tag, # for multiviews
                                 float   => 1,
                                 caption => $instance->description,
                                 } );
            }
        };
        my $update_ui = sub {
            my( $wx, $event ) = @_;

            $event->Check( $viewmanager->is_shown( $tag ) );
        };
        push @commands, 'show_' . $tag,
             { sub         => $cmd,
               menu        => 'view',
               update_menu => $update_ui,
               checkable   => 1,
               label       => sprintf( "Show %s", $view->description ),
               priority    => 200,
               };
    }

    return @commands;
}

1;
