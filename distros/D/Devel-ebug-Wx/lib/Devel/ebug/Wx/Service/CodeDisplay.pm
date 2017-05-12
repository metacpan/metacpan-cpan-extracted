package Devel::ebug::Wx::Service::CodeDisplay;

use strict;
use base qw(Devel::ebug::Wx::Service::Base);
use Devel::ebug::Wx::Plugin qw(:plugin);

use Devel::ebug::Wx::ServiceManager::Holder;
use Devel::ebug::Wx::View::Code::STC;

__PACKAGE__->mk_accessors( qw(code_display) );

sub service_name : Service { 'code_display' }

sub initialize {
    my( $self, $manager ) = @_;
    my $wxebug = $manager->get_service( 'ebug_wx' );

    # FIXME: event related to stepping/breakpointing should be
    #        handled here, to allow the view to be used in the eval window
    $self->{code_display} = Devel::ebug::Wx::View::Code::STC->new
                                ( $wxebug, $wxebug );
    $self->view_manager_service->create_pane
      ( $self->code_display, { name    => 'source_code',
                               caption => 'Code',
                               } );
}

# FIXME: implement here!
sub highlight_line { shift->code_display->highlight_line( @_ ) }
sub show_code_for_file { shift->code_display->show_code_for_file( @_ ) }

1;
