package Devel::ebug::Wx::View::Eval;

use strict;
use base qw(Wx::Panel Devel::ebug::Wx::View::Base
            Devel::ebug::Wx::Plugin::Configurable::Base);
use Devel::ebug::Wx::Plugin qw(:plugin);

__PACKAGE__->mk_accessors( qw(display input display_mode) );

use Wx qw(:textctrl :sizer);
use Wx::Event qw(EVT_BUTTON);

sub tag         { 'eval' }
sub description { 'Eval' }

sub new : View {
    my( $class, $parent, $wxebug, $layout_state ) = @_;
    my $self = $class->SUPER::new( $parent, -1 );

    $self->wxebug( $wxebug );
    $self->{input} = Wx::TextCtrl->new( $self, -1, "", [-1,-1], [-1,-1],
                                        wxTE_MULTILINE );
    $self->{display} = Wx::TextCtrl->new( $self, -1, "", [-1,-1], [-1, -1],
                                        wxTE_MULTILINE );
    $self->{display_mode} = Wx::Choice->new( $self, -1 );

    $self->display_mode->Append( @$_ )
      foreach [ 'YAML', 'use YAML; Dump(%s)' ],
              [ 'Data::Dumper', 'use Data::Dumper; Dumper(%s)' ],
              [ 'Plain', '%s' ];
    $self->display_mode->SetSelection( 0 ); # FIXME save last
    my $eval = Wx::Button->new( $self, -1, 'Eval' );
    my $clear_eval = Wx::Button->new( $self, -1, 'Clear eval' );
    my $clear_result = Wx::Button->new( $self, -1, 'Clear result' );

    my $sz = Wx::BoxSizer->new( wxVERTICAL );
    my $b  = Wx::BoxSizer->new( wxHORIZONTAL );
    $sz->Add( $self->input, 1, wxGROW );
    $sz->Add( $self->display, 1, wxGROW );
    $b->Add( $eval, 0, wxALL, 2 );
    $b->Add( $clear_eval, 0, wxALL, 2 );
    $b->Add( $clear_result, 0, wxALL, 2 );
    $b->Add( $self->display_mode, 1, wxALL, 2 );
    $sz->Add( $b, 0, wxGROW );
    $self->SetSizer( $sz );

    $self->set_layout_state( $layout_state ) if $layout_state;
    $self->register_view;

    EVT_BUTTON( $self, $eval, sub { $self->_eval } );
    EVT_BUTTON( $self, $clear_eval, sub { $self->input->Clear } );
    EVT_BUTTON( $self, $clear_result, sub { $self->display->Clear } );

    $self->SetSize( $self->default_size );

    $self->register_configurable;
    $self->apply_configuration( $self->get_configuration
                                    ( $self->wxebug->service_manager ) );

    return $self;
}

sub _eval {
    my( $self ) = @_;

    my $mode = $self->display_mode->GetClientData
                   ( $self->display_mode->GetSelection );
    my $expr = $self->input->GetValue;
    my $v = $self->ebug->eval( sprintf $mode, $expr ) || "";
    $self->display->WriteText( $v );
}

sub configuration : Configurable {
    my( $class ) = @_;

    return { configurable => __PACKAGE__,
             configurator => 'configuration_simple',
             };
}

sub get_configuration_keys {
    my( $class ) = @_;

    return { label   => 'Eval view',
             section => 'eval_view',
             keys    => [ { key   => 'font',
                            type  => 'font',
                            label => 'Font',
                            },
                          ],
             };
}

sub apply_configuration {
    my( $self, $data ) = @_;

    if( $data->{keys}[0]{value} ) {
        my $font = Wx::Font->new( $data->{keys}[0]{value} );
        $self->input->SetFont( $font );
        $self->display->SetFont( $font );
    }
}

1;
