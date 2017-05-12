package Devel::ebug::Wx::Service::ConfigurationManager;

use strict;
use base qw(Devel::ebug::Wx::Service::Base);
use Devel::ebug::Wx::Plugin qw(:plugin);
use Devel::ebug::Wx::ServiceManager::Holder;

__PACKAGE__->mk_accessors( qw(_configurations) );

sub service_name : Service { 'configuration_manager' }

my %configurators;

sub initialize {
    my( $self, $manager ) = @_;

    foreach my $class ( Devel::ebug::Wx::Plugin->configuration_classes ) {
        $configurators{$class->tag} = $class;
    }
    my @configurations;
    foreach my $configurable ( Devel::ebug::Wx::Plugin->configurables ) {
        my $cfg = $configurable->();
        $cfg->{configurator_class} = $configurators{$cfg->{configurator}};
        push @configurations, $cfg;
    }
    $self->_configurations( \@configurations );
}

sub show_configuration {
    my( $self, $parent ) = @_;

    my $dlg = Devel::ebug::Wx::Service::ConfigurationManager::Dialog
      ->new( $parent, $self );
    $dlg->Show;
}

sub command : Command {
    my( $class, $wxebug ) = @_;

    return ( 'configure',
             { sub         => \&_configure,
               menu        => 'view',
               label       => 'Configure',
               priority    => 600,
               },
             );
}

sub _configure {
    my( $wx ) = @_;
    my $cm = $wx->configuration_manager_service;
    $cm->show_configuration( $wx );
}

package Devel::ebug::Wx::Service::ConfigurationManager::Dialog;

use strict;
use base qw(Wx::Frame Class::Accessor::Fast);

use Wx qw(:id :sizer);
use Wx::Event qw(EVT_BUTTON EVT_CLOSE);

sub new {
    my( $class, $parent, $cm ) = @_;
    my $self = $class->SUPER::new( $parent, -1, 'Configuration' );

    my $nb = Wx::Notebook->new( $self, -1 );
    my $sm = $cm->service_manager;
    my $configurations = $cm->_configurations;
    foreach my $configuration ( @$configurations ) {
        my $attrs = $configuration->{configurable}
          ->get_configuration( $sm );
        my $view = $configuration->{configurator_class}->new( $nb, $attrs );
        $configuration->{view} = $view;
        $nb->AddPage( $view, $attrs->{label} );
    }

    my $sz = Wx::BoxSizer->new( wxVERTICAL );
    my $btnsz = Wx::StdDialogButtonSizer->new;

    my $ok     = Wx::Button->new( $self, wxID_OK, 'Ok' );
    my $cancel = Wx::Button->new( $self, wxID_CANCEL, 'Cancel' );
    my $apply  = Wx::Button->new( $self, wxID_APPLY, 'Apply' );

    $btnsz->AddButton( $ok );
    $btnsz->AddButton( $cancel );
    $btnsz->AddButton( $apply );
    $btnsz->Realize;

    $sz->Add( $nb, 1, wxGROW );
    $sz->Add( $btnsz, 0, wxGROW );

    $self->SetSizerAndFit( $sz );

    EVT_CLOSE( $self,
               sub {
                   undef $_->{view} foreach @$configurations;
                   $self->Destroy;
               } );
    EVT_BUTTON( $self, $ok, sub {
                    $self->apply_configuration( $cm );
                    $self->Close;
                } );
    EVT_BUTTON( $self, $apply, sub {
                    $self->apply_configuration( $cm );
                } );
    EVT_BUTTON( $self, $cancel, sub {
                    $self->Close;
                } );

    return $self;
}

sub apply_configuration {
    my( $self, $cm ) = @_;

    my $configurations = $cm->_configurations;
    my $sm = $cm->service_manager;
    foreach my $configuration ( @$configurations ) {
        $configuration->{view}->retrieve_data;
        $configuration->{configurable}
          ->set_configuration( $sm, $configuration->{view}->attributes );
    }
}

1;
