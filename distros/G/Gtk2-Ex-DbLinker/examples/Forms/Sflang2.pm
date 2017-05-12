package Forms::Sflang2;
use strict;
use warnings;
use Gtk2::Ex::DbLinker::Form;
use Gtk2::Ex::DbLinker::Datasheet;
use Forms::Dnav2;
use Data::Dumper;

sub new {
    my ( $class, $href ) = @_;

    my $self = {
        gladefolder => $$href{gladefolder},
        data_broker      => $$href{data_broker},
        countryid   => $$href{countryid},
    };

    $self->{log} = Log::Log4perl->get_logger(__PACKAGE__);

    $self->{dnav} = Forms::Dnav2->new( ismain => 0 );


    $self->{builder} = $self->{dnav}->get_builder;

    $self->{builder}->add_from_file( $self->{gladefolder} . "/sflang2.bld" );
    $self->{builder}->connect_signals($self);

    #inclusion of the subform in his navigation tool
    my $w   = $self->{builder}->get_object('sflang_window');
    my $ctr = $self->{builder}->get_object('vbox1');
    $self->{dnav}->reparent( $ctr, $w );

  my $dman = $self->{data_broker}->get_DM_for('subform_data', [$self->{countryid}]);

    $self->{sform} = Gtk2::Ex::DbLinker::Form->new(
        data_manager    => $dman,
        builder         => $self->{builder},
        rec_spinner     => $self->{dnav}->get_object('RecordSpinner'),
        status_label    => $self->{dnav}->get_object('lbl_RecordStatus'),
        rec_count_label => $self->{dnav}->get_object("lbl_recordCount"),
        on_current => sub { $self->update_widgets_sensitivity },
    );

    my $combodata = $self->{data_broker}->get_DM_for('langue');
    $self->{sform}->add_combo(
        data_manager => $combodata,
        id           => 'langid',
        builder      => $self->{builder},
    );


    my $list = $self->{data_broker}->get_DM_for('grid_data', [$self->{langid}, $self->{countryid}]);

 $combodata = $self->{data_broker}->get_DM_for('mainform_data');

    $self->{dnav}->set_dataref( $self->{sform} );

    my $tree = Gtk2::TreeView->new();

    $self->{sf_list} = Gtk2::Ex::DbLinker::Datasheet->new(
        treeview     => $tree,
        data_manager => $list,
        fields       => [
            { name => "langid", renderer => "hidden" },
            {
                name         => "countryid",
                renderer     => "combo",
                data_manager => $combodata,
                fieldnames   => [ "countryid", "country" ],
            }
        ],
    );

    #set up the datasheet
    #
    $self->{sf_list}->{dnav} = Forms::Dnav2->new( ismain => 0 );
    
    my $scroll = Gtk2::ScrolledWindow->new;
    $scroll->add($tree);
    $self->{sf_list}->{dnav}->add_ctrl($scroll);
    $self->{sf_list}->{dnav}->set_dataref( $self->{sf_list} );

    $self->{sform}->add_childform( $self->{sf_list} );
    #place the grid in the subform
    #
    #vbox1_main is child object of the top level window in the nav tool
    my $ctrl_from = $self->{sf_list}->{dnav}->get_object('vbox1_main');
    #alignment1 is the control in the subform that will received vbox1_main
    my $ctrl_to   = $self->{builder}->get_object('alignment1');
    Gtk2::Widget::reparent( $ctrl_from, $ctrl_to );

      my  %connect_for = (
        'DataAccess::Sqla::Service' => {
            add    => \&on_add_clicked,
            del => \&on_delete_clicked,
            apply  => \&on_apply_clicked,
        },
        'DataAccess::Dbi::Service' => {
            add    => \&on_add_clicked,
            del => \&on_delete_clicked,
            apply  => \&on_apply_clicked,
        },
        'DataAccess::Rdb::Service' => {
            add    => \&on_add_clicked,
            apply  => \&on_apply_2_clicked,
        },
        'DataAccess::Dbc::Service' => {
            add    => \&on_add_clicked,
            apply  => \&on_apply_2_clicked,
        },
    );

    my $sign_ref = $connect_for{ ref $self->{data_broker} };

    for my $button ( keys %{$sign_ref} ) {
        $self->{dnav}
            ->connect_signal_for( $button, $sign_ref->{$button}, $self );
    }
  %connect_for =(
      'DataAccess::Sqla::Service' => {
          add => \&on_add_lst_clicked,
          apply => \&on_apply_lst_clicked,
      },
      'DataAccess::Dbi::Service' => {
           add => \&on_add_lst_clicked,          
       },
      'DataAccess::Rdb::Service' => {
           add => \&on_add_lst_clicked,   
      },
      'DataAccess::Dbc::Service' => {
           add => \&on_add_lst_clicked,   
      },
  );
   $sign_ref = $connect_for{ ref $self->{data_broker} };
 for my $button ( keys %{$sign_ref} ) {
        $self->{sf_list}->{dnav}->connect_signal_for( $button, $sign_ref->{$button}, $self );
    }


    bless $self, $class;

}

sub on_countryid_changed {
    my ( $self, $value ) = @_;
    $self->{log}->debug("sf_langues: countryid_changed $value");
    $self->{countryid} = $value;

    $self->{data_broker}->query_DM( $self->{sform}->get_data_manager,'subform_data', [$value]);
    $self->{sform}->update;
    $value = $self->{sform}->get_widget_value("langid");
    $self->{log}->debug("sf_langues: langid changed $value");

   $self->{data_broker}->query_DM( $self->{sf_list}->get_data_manager, 'grid_data', [$value, $self->{countryid}]);

    $self->{sf_list}->update;

}

sub update_widgets_sensitivity {
     my $self = shift;
     my $rc = $self->{sform}->get_data_manager->row_count;
        $self->{log}->debug("rc ", $rc);
        if ( $rc == 0 ) {
            $self->{dnav}->widgets_set_sensitivity(0);
        }
        else {
            $self->{dnav}->widgets_set_sensitivity(1);
        }


}


sub on_langid_changed {
    my ( $b, $self ) = @_;
    my $value = $self->{sform}->get_widget_value('langid');
    if ($value) {
        $self->{log}->debug("sf_langues: langid_changed $value");
        $self->{langid} = $value;

        $self->{data_broker}->query_DM( $self->{sf_list}->get_data_manager, 'grid_data', [$value, $self->{countryid}]);
        $self->{sf_list}->update;
    }
}

sub on_delete_clicked {
    my $b    = shift;
    my $self = shift;
     $self->{deleting} = 1;
    $self->{sform}->delete;
}

sub on_add_clicked {
    my $b    = shift;
    my $self = shift;
    $self->{sform}->insert;
    $self->{sform}->set_widget_value( "countryid", $self->{countryid} );
    
    $self->{dnav}->set_sensitivity_for('langid');
    $self->{dnav}->set_sensitivity_for('apply');
     #$self->{sf_list}->{dnav}->widgets_set_sensitivity(0);

}

sub on_apply_2_clicked {
    my $b    = shift;
    my $self = shift;
    $self->{log}->debug( "sform_apply country : "
          . $self->{countryid}
          . " langue : "
          . $self->{langid} );
    $self->{sform}->apply;

    $self->{data_broker}->query_DM( $self->{sform}->get_data_manager, 'subform_data', [$self->{countryid}] );
    $self->{sform}->update;
}

sub on_apply_clicked {
    my $b    = shift;
    my $self = shift;
    if ( $self->{deleting} ) {
        $self->{sform}->apply;
        $self->{deleting} = 0;
        return;
    }

    $self->{log}->debug( "sform_apply country : "
          . $self->{countryid}
          . " langue : "
          . $self->{langid} );
    my %h = ( countryid => $self->{countryid}, langid => $self->{langid} );

#since the only values displayed are primary keys values, they are not saved when calling
# DataManager->save
# They have to be pass as an argument
# And to prevent from save to being called a second time when Form->apply runs
# the pk names is passed as to apply
    $self->{sform}->get_data_manager->save(%h);
    my @pks = $self->{sform}->get_data_manager->get_primarykeys;

    #print Dumper $self->{sform}->get_data_manager->get_autoinc_primarykeys;
    #print Dumper @pks;

    $self->{sform}->apply( \@pks );
    #  $self->{sform}->get_data_manager->query(-where => { countryid => $self->{countryid} } );
    $self->{data_broker}->query_DM($self->{sform}->get_data_manager, 'subform_data', [$self->{countryid}]);
    $self->{sform}->update;
}

sub on_apply_lst_clicked {
    my ( $b, $self ) = @_;
    $self->{log}->debug("apply lst");
    if ( $self->{lst_deleting} ) {
        $self->{sf_list}->apply;
        $self->{lst_deleting} = 0;
        return;
    }

    my $dman = $self->{sf_list}->get_data_manager;
    my %old  = (
        countryid => $dman->get_field('countryid'),
        langid    => $dman->get_field('langid')
    );

    my %h = (
        langid    => $self->{langid},
        countryid => $self->{sf_list}->get_column_value('countryid')
    );
    $self->{log}->debug( "old values", sub{ Dumper %old } );
    $self->{log}->debug( "new values", sub {Dumper %h });
    my @pks = $dman->get_primarykeys;

#a new row is created in Datasheet->apply  and the inserting flag is turn to 1 (not in Datasheet->insert)
#so to instert a new row: calls Datasheet->aplly before saving in the new row with SqlADM->save
#passing the pk names to apply excludes these from being saved here
#since they are saved with the hashref  pass to DM->save
    $self->{sf_list}->apply( \@pks );
 my $row = $self->{sf_list}->get_current_row;
    $self->{log}->debug("row pos from grid: ", $row);
 # set dman to this row before saving, since dman is now positionned on the last row
    $dman->set_row_pos($row);

    $dman->save(%h);

    # $self->{sf_list}->apply(\@pks);

}

sub on_add_lst_clicked {
    my ( $b, $self ) = @_;

    #ajoute une ligne vide qu'il faut completer avec le pays
    $self->{sf_list}
      ->insert( $self->{sf_list}->colnumber_from_name("langid") =>
          $self->{sform}->get_widget_value("langid") );

}

sub on_delete_lst_clicked {
    my $b    = shift;
    my $self = shift;
    $self->{lst_deleting} = 1;
    $self->{sf_list}->delete;
}

1;
