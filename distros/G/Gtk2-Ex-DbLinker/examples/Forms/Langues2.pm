package Forms::Langues2;

use strict;
use warnings;
use Gtk2::Ex::DbLinker::Form;
use Gtk2::Ex::DbLinker::Datasheet;
use Log::Log4perl;
use Forms::Dnav2;
use Forms::Sflang2;
# use Data::Dumper;
use Scalar::Util qw(weaken);

sub new {

    my ( $class, $href ) = @_;
    my $self = {
        gladefolder => $$href{gladefolder},
        data_broker     => $$href{data_broker},
    };
    $self->{dnav} = Forms::Dnav2->new(
        dbh => $self->{data_broker}->get_dbh,
        sql =>
            'SELECT name FROM sqlite_master WHERE type = "table" AND name NOT LIKE "sqlite_%"',
        mibuilder => sub { $self->menuitem_builder(@_); },

    );


    $self->{log} = Log::Log4perl->get_logger(__PACKAGE__);
    $self->{log}->debug("new main form");
    my $builder = $self->{dnav}->get_builder;

    my $dman = $self->{data_broker}->get_DM_for('mainform_data');

    
    $builder->add_from_file( $self->{gladefolder} . "/langues2.bld" )
        or die "Couldn't read  langues2.bld";

    $builder->connect_signals($self);

    $self->{linker} = Gtk2::Ex::DbLinker::Form->new(
        data_manager    => $dman,
        builder         => $builder,
        rec_spinner     => $self->{dnav}->get_object('RecordSpinner'),
        status_label    => $self->{dnav}->get_object('lbl_RecordStatus'),
        rec_count_label => $self->{dnav}->get_object("lbl_recordCount"),
    );

    my $combodata = $self->{data_broker}->get_DM_for('langue');
    $self->{linker}->add_combo(
        data_manager => $combodata,
        id           => 'mainlangid',
    );
    #place the form in the first navigation form 
    #do not name the toplevel window of the form 'mainwindow', since
    # it's the name of the top level window in the navigation window
    # and we can't have two identical id in the same widgets tree.
    my $w   = $builder->get_object('mainform');
    my $ctr = $builder->get_object('vbox1');

    $self->{dnav}->reparent( $ctr, $w );

    $self->{sf} = Forms::Sflang2->new(
        {   gladefolder => $self->{gladefolder},
            data_broker      => $self->{data_broker},
            countryid   => $self->{countryid}
        }
    );

    $self->{linker}->add_childform( $self->{sf}->{sform} );
    #place the subform with it's navigation panel in the main form
    #
    #mainwindow is the top level window of the subform navigation tool
    my $subform = $self->{sf}->{dnav}->get_object('mainwindow');

    #vbox1_main is child object of this top level window in the nav tool
    my $vbox = $self->{sf}->{dnav}->get_object('vbox1_main');

    #alignment1 is the control in the main form that will received vbox1_main
    my $sfctrl = $builder->get_object('alignment1');
    
    Gtk2::Widget::reparent( $vbox, $sfctrl );
    $subform->destroy();
    
    $builder->get_object("vbox4")->show_all;

    #$sf->show_all_except(["mainwindow"]);

    $builder->get_object("mainwindow")
        ->signal_connect( "destroy", \&gtk_main_quit );

    $self->{linker}->update;

    $self->{dnav}->connect_signal_for( "add",   \&on_add_clicked,    $self );
    $self->{dnav}->connect_signal_for( "del",   \&on_delete_clicked, $self );
    $self->{dnav}->connect_signal_for( "apply", \&on_apply_clicked,  $self );

    $self->{dnav}->set_dataref( $self->{linker} );
    $self->{dnav}->show_all_except();
    $self->{sf}->{dnav}
        ->show_all_except( [ "mainwindow", "menubar1", "countryid" ] );

    $self->{sf}->{sf_list}->{dnav}->show_all_except( ["mainwindow"] );

    bless $self, $class;

}

sub on_countryid_changed {
    my $b    = shift;
    my $self = shift;
    $self->{log}->debug("countryid_changed called");
    my $value = $b->get_text();
    if ( defined $value) {
        $self->{dnav}->widgets_set_sensitivity(1);
        $self->{log}->debug("on_countryid_changed : $value");
        $self->{countryid} = $value;
        $self->{sf}->on_countryid_changed($value);
        my $rc = $self->{linker}->get_data_manager->row_count;
        $self->{log}->debug("rc ", $rc);
        if ( $rc == 0 ) {
            $self->{dnav}->widgets_set_sensitivity(0);
        }
        else {
            $self->{dnav}->widgets_set_sensitivity(1);
        }
        $self->{sf}->on_countryid_changed($value);
        weaken $self->{sf};
    }
    else {
        $self->{dnav}->widgets_set_sensitivity(0);
    }
}

sub on_delete_clicked {

    my ( $b, $self ) = @_;
    $self->{linker}->delete;

}

sub on_add_clicked {
    my ( $b, $self ) = @_;

    # print Dumper($self);
    $self->{linker}->insert;

}

sub on_apply_clicked {
    my $b    = shift;
    my $self = shift;

    $self->{linker}->apply;

}

sub menuitem_builder {
    my $self = shift;
    my $href = ( ref $_[0] eq "HASH" ? $_[0] : { (@_) } );
    my $data;
    if ( $href->{name} ) {
 
        $data = $self->{data_broker}->get_DM_for($href->{name});

    }
    else {
        $self->{log}->debug("Displaying select querries is not implemented");
    }

    return $data;

}

sub gtk_main_quit {
    my ($w) = @_;
    Gtk2->main_quit;
}

1;
