package Devel::ebug::Wx::View::Output;

use strict;
use base qw(Wx::Panel Devel::ebug::Wx::View::Base);
use Devel::ebug::Wx::Plugin qw(:plugin);

__PACKAGE__->mk_ro_accessors( qw(stdout stderr) );

use Wx qw(:textctrl :sizer);
use Wx::Event qw(EVT_BUTTON);

sub tag         { 'output' }
sub description { 'Console output' }

sub new : View {
    my( $class, $parent, $wxebug, $layout_state ) = @_;
    my $self = $class->SUPER::new( $parent, -1 );

    $self->wxebug( $wxebug );
    $self->{stdout} = Wx::TextCtrl->new( $self, -1, "", [-1,-1], [-1, -1],
                                         wxTE_MULTILINE|wxTE_READONLY );
    $self->{stderr} = Wx::TextCtrl->new( $self, -1, "", [-1,-1], [-1,-1],
                                         wxTE_MULTILINE|wxTE_READONLY );
    my $refresh = Wx::Button->new( $self, -1, 'Refresh' );

    my $sz = Wx::BoxSizer->new( wxVERTICAL );
    my $f  = Wx::BoxSizer->new( wxHORIZONTAL );
    my $s  = Wx::BoxSizer->new( wxHORIZONTAL );
    $f->Add( Wx::StaticText->new( $self, -1, 'Standard output' ), 0,
                                  wxALIGN_CENTER_VERTICAL | wxALL, 2 );
    $f->Add( $refresh, 0, wxALIGN_RIGHT, wxALL, 2 );
    $sz->Add( $f, 0, wxGROW );
    $sz->Add( $self->stdout, 1, wxGROW );
    $s->Add( Wx::StaticText->new( $self, -1, 'Standard error' ), 0,
                                  wxALIGN_CENTER_VERTICAL | wxALL, 2 );
    $sz->Add( $s, 0, wxGROW );
    $sz->Add( $self->stderr, 1, wxGROW );
    $self->SetSizer( $sz );

    $self->load_output if $wxebug->ebug->is_running;

    EVT_BUTTON( $self, $refresh, sub { $self->load_output } );

    $self->set_layout_state( $layout_state ) if $layout_state;
    $self->register_view;
    $self->SetSize( $self->default_size );

    return $self;
}

sub load_output {
    my( $self ) = @_;
    my( $stdout, $stderr ) = $self->wxebug->ebug->output;

    $self->stdout->SetValue( $stdout );
    $self->stderr->SetValue( $stderr );
}

1;
