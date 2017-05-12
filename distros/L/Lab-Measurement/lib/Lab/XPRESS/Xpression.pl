use strict;

#use Win32::API;

#################################################
#
#
package MyApp;
#
#
#################################################
use strict;
use Wx;
use vars qw(@ISA);
@ISA = qw(Wx::App);

my $find = \&Wx::Window::FindWindowByName;

sub OnInit {
    my ($this) = @_;

    my $xrc = XRC->new('main_frame.xrc');
    $this->{frame} = Wx::Frame->new;
    $xrc->LoadFrame( $this->{frame}, undef, 'frame_Main' );

    $this->{frame}->{ID_ITERATOR} = 0;

    # add Plot instance:
    $this->{frame}->{Tabs} = &$find( 'tabs_main', $this->{frame} );
    main::AddPlotInstance( $this->{frame} );

    my $colums_container = &$find( 'panel_ColumnsContainer', $this->{frame} );
    $colums_container->EnableScrolling( 1, 1 );

    $this->{frame}->SetSize( Wx::Size->new( 800, 800 ) );
    $this->{frame}->CenterOnScreen;
    $this->{frame}->Show(1);
    $this->{frame}->SetIcon( Wx::GetWxPerlIcon() );

    $this->SetTopWindow( $this->{frame} );

    return $this;
}

#################################################
#
#
package MyPanel;
#
#
#################################################
use Wx;
use parent 'Wx::Panel';
use vars qw(@ISA);

@ISA = qw(Wx::Panel);

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();
    my $panel = $self->OnInit(@_);
    return $panel;
}

sub OnInit {
    my $self   = shift;
    my $parent = shift;
    my $xrc    = shift;
    my $name   = shift;

    my $xr = XRC->new($xrc);
    my $panel = $xr->LoadPanel( $parent, $name );

    return $panel;
}

#################################################
#
#
package XRC;
#
#
#################################################

use Wx qw (:everything);
use Wx::XRC;

#use Cava::Packager;
#Cava::Packager::SetResourcePath('./Xpression/res');
use Lab::XPRESS::Data::XPRESS_dataset;
use Lab::XPRESS::Xpression::PlotterGUI;

sub new {
    my $file = @_[1];

    #my $file = Cava::Packager::GetResource("XRC/$file");
    $file = "./Xpression/res/XRC/$file";
    my $xrc = Wx::XmlResource->new();
    $xrc->InitAllHandlers();
    $xrc->Load($file);

    return $xrc;
}

package main;

use Wx;
use Wx qw(:everything);

use Time::HiRes qw/usleep/, qw/time/;
use Storable qw(store retrieve freeze thaw dclone);
use File::Spec::Functions qw( abs2rel );
use Lab::XPRESS::Xpression::PlotterGUI;

my $find = \&Wx::Window::FindWindowByName;
my ($app) = MyApp->new();

if ( defined $ARGV[0] ) {
    print $ARGV[0] . "\n";
    my @filename = split( /\\/, $ARGV[0] );
    importFile( $app->{frame}, $ARGV[0], $filename[-1] );
}

#my $irgendwas = &$find('m_staticText19', $app->{frame}->{main_panel});
#my $irgendwas = $app->{frame}->{main_panel}->FindWindowByName('m_staticText19');
#print $irgendwas->SetLabel("Hallo Welt");

$app->MainLoop();

sub importFileDialog {
    my $frame = shift;
    my $path;
    my $filename;

    if ( show_OpenFileDialog( $frame, '*.dat', \$path, \$filename ) eq
        wxID_OK ) {
        importFile( $frame, $path, $filename );
    }

}

sub importFile {

    my $frame    = shift;
    my $path     = shift;
    my $filename = shift;

    my $current_page      = $frame->{Tabs}->GetCurrentPage();
    my $current_pageID    = $frame->{Tabs}->GetSelection();
    my $column_container  = &$find( 'panel_ColumnsContainer', $current_page );
    my $label_no_cols     = &$find( 'label_NoColumns', $column_container );
    my $info_fileName     = &$find( 'label_FileName', $current_page );
    my $info_columnNumber = &$find( 'label_NumberOfColumns', $current_page );
    my $info_blockNumber  = &$find( 'label_NumberOfBlocks', $current_page );
    my $info_lineNumber   = &$find( 'label_NumberOfLines', $current_page );
    my $column_container_sizer = $column_container->GetSizer();
    my $label_ID        = &$find( 'label_PlotID', @{ $frame->{plot} }[-1] );
    my $spin_PlotBlocks = &$find( 'spin_PlotBlocks', $current_page );
    my $spin_PlotLines  = &$find( 'spin_PlotLines', $current_page );

    my $plot_ID = $label_ID->GetLabel();

    $frame->{plots}->{$plot_ID}->{filename} = $filename;
    $frame->{plots}->{$plot_ID}->{path}     = $path;

    #prepare init Situation-----------------------

    $column_container->SetScrollbars( 10, 10, 1, 1 );

    #open FileDialog-----------

    # my $dlg = Wx::FileDialog->new($frame, 'Please select a File...', '', '', '*.dat', 'wxFD_OPEN');
    # my $result = $dlg->ShowModal();

    # if ($result == wxID_CANCEL) { return; }
    # my $filename = $dlg->GetFilename();
    # $frame->{plots}->{$plot_ID}->{filename} = $filename;

    # my $path = $dlg->GetPath();
    # $frame->{plots}->{$plot_ID}->{path} = $path;

    # $dlg->Destroy();

    #Read File-------------------------
    my $DataSet = new Lab::XPRESS::Data::XPRESS_dataset($path);

    if ( $DataSet == -1 ) {
        return -1;
    }
    else {
        $frame->{plots}->{$plot_ID}->{dataset} = $DataSet;
    }

    #Set File Info------------------------

    $info_fileName->SetLabel($filename);

    $info_blockNumber->SetLabel( $DataSet->{BLOCKS} );
    $frame->{plots}->{$plot_ID}->{number_of_blocks} = $DataSet->{BLOCKS};

    $info_columnNumber->SetLabel( $DataSet->{COLUMNS} );
    $frame->{plots}->{$plot_ID}->{number_of_columns} = $DataSet->{COLUMNS};

    $info_lineNumber->SetLabel( $DataSet->{LINES} );
    $frame->{plots}->{$plot_ID}->{number_of_lines} = $DataSet->{LINES};

    #my $page = $frame->{Tabs}->GetCurrentPage();
    $frame->{Tabs}->SetPageText( $current_pageID, "$filename" );

    $spin_PlotBlocks->SetRange( 0, $DataSet->{BLOCKS} - 1 );
    $spin_PlotLines->SetRange( 0, $DataSet->{LINES} - 1 );

    #Draw Columns-----------------------------------------

    $column_container_sizer->Clear(1);

    my $xrc = XRC->new('panel_column.xrc');

    my $i = 0;

    foreach my $column ( @{ $DataSet->{COL_NAMES} } ) {

        $frame->{plots}->{$plot_ID}->{column_names}->{$column} = $i;

        $frame->{plots}->{$plot_ID}->{column_panels}[$i]
            = $xrc->LoadPanel( $column_container, 'panel_Column' );

        $frame->{plots}->{$plot_ID}->{column_panels}[$i]
            ->SetName( 'panel_Column_' . $i );
        my $label_column_name = &$find(
            'label_ColumnName',
            $frame->{plots}->{$plot_ID}->{column_panels}[$i]
        );
        $label_column_name->SetLabel($column);

        if ( $i % 2 ) {
            $frame->{plots}->{$plot_ID}->{column_panels}[$i]
                ->SetBackgroundColour( Wx::Colour->new( 240, 240, 240 ) );
        }

        $column_container_sizer->Add(
            $frame->{plots}->{$plot_ID}->{column_panels}[$i],
            0, wxEXPAND
        );
        $column_container_sizer->Layout();
        $column_container->FitInside();

        $i++;
    }

}

sub openPlotDialog {
    my $frame = shift;
    my $path;
    my $filename;

    if ( show_OpenFileDialog( $frame, '*.plot', \$path, \$filename ) eq
        wxID_OK ) {

        openPlot( $frame, $path, $filename );
    }

}

sub openPlot {
    my $frame    = shift;
    my $path     = shift;
    my $filename = shift;

    print $path. "\n";

    my $plot = load_PlotConfig($path);
    $plot->{ID} = AddPlotInstance($frame);
    $frame->{plots}->{ $plot->{ID} }->{plotdetails} = $plot;

    my $plot_instance
        = $frame->{Tabs}->GetPage( $frame->{Tabs}->GetSelection() );

    my $plot_ID = &$find( 'label_PlotID', $plot_instance );
    $plot_ID->SetLabel( $plot->{ID} );

    importFile( $frame, $plot->{relative_path}, $plot->{filename} );

    my $ColumnsContainer = &$find( "panel_ColumnsContainer", $plot_instance );

    while ( my ( $axis_name, $axis ) = each %{$plot} ) {
        if ( $axis_name =~ /X|Y|Y2|CB|Z|none/ ) {
            foreach my $wave ( @{ $axis->{wave} } ) {
                my $panel = &$find(
                    "panel_Column_" . ( $wave->{column_number} - 1 ),
                    $ColumnsContainer
                );

                my $ColumnAxis = &$find( "combo_ColumnAxis", $panel );
                $ColumnAxis->SetValue($axis_name);

                my $ColumnLineStyle
                    = &$find( "combo_ColumnLineStyle", $panel );
                if ( $wave->{style} eq "lines" ) {
                    $ColumnLineStyle->SetValue('Line');
                }
                elsif ( $wave->{style} eq "points" ) {
                    $ColumnLineStyle->SetValue('Points');
                }
                elsif ( $wave->{style} eq "linespoints" ) {
                    $ColumnLineStyle->SetValue('Line + Points');
                }

                my $ColumnLineSize = &$find( "combo_ColumnLineSize", $panel );
                $ColumnLineSize = $ColumnLineSize->SetValue( $wave->{size} );

                my $ColumnColor = &$find( "color_Column", $panel );
                my $Color = new Wx::Colour( $wave->{color} );
                $ColumnColor->SetColour($Color);

                my $ColumnLabel = &$find( "input_ColumnLabel", $panel );
                $ColumnLabel->SetValue( $wave->{label} );
            }
        }

    }

    my $plot_type = &$find( "combo_PlotType", $plot_instance );
    $plot_type = $plot_type->SetValue( $plot->{type} );
    ChangePlotType($frame);

    my $plot_title = &$find( "input_PlotTitle", $plot_instance );
    $plot_title = $plot_title->SetValue( $plot->{title} );

    #my $plot_grid = &$find("input_PlotTitle",$plot_instance);
    #$plot_grid = $plot_grid->GetValue();
    $plot->{grid} = 1;

    my $plot_blocks = &$find( 'input_PlotBlocks', $plot_instance );
    $plot_blocks->SetValue(
        "$plot->{BlockFrom}:$plot->{BlockTo}:$plot->{BlockIncrement}");

    my $plot_lines = &$find( 'input_PlotLines', $plot_instance );
    $plot_lines = $plot_lines->SetValue(
        "$plot->{LineFrom}:$plot->{LineTo}:$plot->{LineIncrement}");

    my $plot_xlabel = &$find( "input_XLabel", $plot_instance );
    $plot_xlabel->SetValue( $plot->{X}->{label} );

    my $plot_ylabel = &$find( "input_YLabel", $plot_instance );
    $plot_ylabel->SetValue( $plot->{Y}->{label} );

    my $plot_y2label = &$find( "input_Y2Label", $plot_instance );
    $plot_y2label->SetValue( $plot->{Y2}->{label} );

    my $plot_cblabel = &$find( "input_CBLabel", $plot_instance );
    $plot_cblabel->SetValue( $plot->{CB}->{label} );

    my $plot_zlabel = &$find( "input_ZLabel", $plot_instance );
    $plot_zlabel->SetValue( $plot->{Z}->{label} );

    my $plot_XRange = &$find( "input_XRange", $plot_instance );
    $plot_XRange->SetValue( $plot->{X}->{range} );

    my $plot_YRange = &$find( "input_YRange", $plot_instance );
    $plot_YRange->SetValue( $plot->{Y}->{range} );

    my $plot_Y2Range = &$find( "input_Y2Range", $plot_instance );
    $plot_Y2Range->SetValue( $plot->{Y2}->{range} );

    my $plot_CBRange = &$find( "input_CBRange", $plot_instance );
    $plot_CBRange->SetValue( $plot->{CB}->{range} );

    my $plot_ZRange = &$find( "input_ZRange", $plot_instance );
    $plot_ZRange->SetValue( $plot->{Z}->{range} );

    my $plot_XFormat = &$find( "input_XFormat", $plot_instance );
    $plot_XFormat->SetValue( $plot->{X}->{format} );

    my $plot_YFormat = &$find( "input_YFormat", $plot_instance );
    $plot_YFormat->SetValue( $plot->{Y}->{format} );

    my $plot_Y2Format = &$find( "input_Y2Format", $plot_instance );
    $plot_Y2Format->SetValue( $plot->{Y2}->{format} );

    my $plot_CBFormat = &$find( "input_CBFormat", $plot_instance );
    $plot_CBFormat->SetValue( $plot->{CB}->{format} );

    my $plot_ZFormat = &$find( "input_ZFormat", $plot_instance );
    $plot_ZFormat->SetValue( $plot->{Z}->{format} );

}

sub savePlot {
    my $frame = shift;
    my $filename;
    my $path;

    my $dlg = Wx::FileDialog->new(
        $frame, 'Please select a File...',
        '', '', '*.plot', 'wxFD_Save, wxFD_OVERWRITE_PROMPT'
    );
    my $result = $dlg->ShowModal();

    if ( $result == wxID_OK ) {
        $filename = $dlg->GetFilename();

        $path = $dlg->GetPath();

        my $plot = get_PlotDetails($frame);

        save_PlotConfig( $plot, $path );
    }

    $dlg->Destroy();
}

sub AddPlotInstance {
    my $frame = shift;

    $frame->{ID_ITERATOR}++;

    #$frame->{Tabs} = &$find('tabs_main', $frame);
    my $xrc_plotInstance = XRC->new('panel_plotInstance.xrc');
    push(
        @{ $frame->{plot} },
        $xrc_plotInstance->LoadPanel( $frame->{Tabs}, 'panel_PlotInstance' )
    );
    $frame->{Tabs}->AddPage( @{ $frame->{plot} }[-1], "new plot", 1, 1 );

    my $label_ID = &$find( 'label_PlotID', @{ $frame->{plot} }[-1] );
    $label_ID->SetLabel( $frame->{ID_ITERATOR} );

    my $button_ImportFileDialog = &$find(
        'button_ImportFileDialoge',
        $frame->{Tabs}->GetPage( $frame->{Tabs}->GetSelection() )
    );
    Wx::Event::EVT_BUTTON(
        $frame, $button_ImportFileDialog,
        \&importFileDialog
    );

    my $button_AddPlotInstance = &$find(
        'button_AddPlotInstance',
        $frame->{Tabs}->GetPage( $frame->{Tabs}->GetSelection() )
    );
    Wx::Event::EVT_BUTTON(
        $frame, $button_AddPlotInstance,
        \&AddPlotInstance
    );

    my $button_OpenPlot = &$find(
        'button_OpenPlot',
        $frame->{Tabs}->GetPage( $frame->{Tabs}->GetSelection() )
    );
    Wx::Event::EVT_BUTTON( $frame, $button_OpenPlot, \&openPlotDialog );

    my $button_SavePlot = &$find(
        'button_SavePlot',
        $frame->{Tabs}->GetPage( $frame->{Tabs}->GetSelection() )
    );
    Wx::Event::EVT_BUTTON( $frame, $button_SavePlot, \&savePlot );

    my $button_ClosePlotInstance = &$find(
        'button_ClosePlotInstance',
        $frame->{Tabs}->GetPage( $frame->{Tabs}->GetSelection() )
    );
    Wx::Event::EVT_BUTTON(
        $frame, $button_ClosePlotInstance,
        \&ClosePlotInstance
    );

    my $combo_PlotType = &$find(
        'combo_PlotType',
        $frame->{Tabs}->GetPage( $frame->{Tabs}->GetSelection() )
    );
    Wx::Event::EVT_COMBOBOX( $frame, $combo_PlotType, \&ChangePlotType );

    my $button_Plot = &$find(
        'button_Plot',
        $frame->{Tabs}->GetPage( $frame->{Tabs}->GetSelection() )
    );
    Wx::Event::EVT_BUTTON( $frame, $button_Plot, \&Plot );

    my $button_ExtractData = &$find(
        'button_ExtractData',
        $frame->{Tabs}->GetPage( $frame->{Tabs}->GetSelection() )
    );
    Wx::Event::EVT_BUTTON( $frame, $button_ExtractData, \&export_Data );

    my $button_Export = &$find(
        'button_Export',
        $frame->{Tabs}->GetPage( $frame->{Tabs}->GetSelection() )
    );
    Wx::Event::EVT_BUTTON( $frame, $button_Export, \&export_Graph );

    my $button_PlotBlocks = &$find(
        'spin_PlotBlocks',
        $frame->{Tabs}->GetPage( $frame->{Tabs}->GetSelection() )
    );
    Wx::Event::EVT_SPINCTRL( $frame, $button_PlotBlocks, \&update_Plot );

    my $button_PlotBlocks = &$find(
        'spin_PlotLines',
        $frame->{Tabs}->GetPage( $frame->{Tabs}->GetSelection() )
    );
    Wx::Event::EVT_SPINCTRL( $frame, $button_PlotBlocks, \&update_Plot );

    return $frame->{ID_ITERATOR};

}

sub ClosePlotInstance {
    my $frame = shift;

    $frame->{Tabs} = &$find( 'tabs_main', $frame );
    if ( $frame->{Tabs}->GetPageCount() > 1 ) {
        $frame->{Tabs}->DeletePage( $frame->{Tabs}->GetSelection() );
    }
}

sub ChangePlotType {
    my $frame = shift;

    my $combo_PlotType = &$find(
        'combo_PlotType',
        $frame->{Tabs}->GetPage( $frame->{Tabs}->GetSelection() )
    );
    my $panel_Y2Axis = &$find(
        'panel_Y2Axis',
        $frame->{Tabs}->GetPage( $frame->{Tabs}->GetSelection() )
    );
    my $panel_CBAxis = &$find(
        'panel_CBAxis',
        $frame->{Tabs}->GetPage( $frame->{Tabs}->GetSelection() )
    );

    my $panel_PlotSetup = &$find(
        'panel_PlotSetup',
        $frame->{Tabs}->GetPage( $frame->{Tabs}->GetSelection() )
    );
    my $sizer_PlotSetup = $panel_PlotSetup->GetSizer();

    my $static_PlotBlocks = &$find(
        'static_PlotBlocks',
        $frame->{Tabs}->GetPage( $frame->{Tabs}->GetSelection() )
    );
    my $input_PlotBlocks = &$find(
        'input_PlotBlocks',
        $frame->{Tabs}->GetPage( $frame->{Tabs}->GetSelection() )
    );
    my $spin_PlotBlocks = &$find(
        'spin_PlotBlocks',
        $frame->{Tabs}->GetPage( $frame->{Tabs}->GetSelection() )
    );
    my $static_PlotBlocksExample = &$find(
        'static_PlotBlocksExample',
        $frame->{Tabs}->GetPage( $frame->{Tabs}->GetSelection() )
    );

    my $static_PlotLines = &$find(
        'static_PlotLines',
        $frame->{Tabs}->GetPage( $frame->{Tabs}->GetSelection() )
    );
    my $input_PlotLines = &$find(
        'input_PlotLines',
        $frame->{Tabs}->GetPage( $frame->{Tabs}->GetSelection() )
    );
    my $spin_PlotLines = &$find(
        'spin_PlotLines',
        $frame->{Tabs}->GetPage( $frame->{Tabs}->GetSelection() )
    );
    my $static_PlotLinesExample = &$find(
        'static_PlotLinesExample',
        $frame->{Tabs}->GetPage( $frame->{Tabs}->GetSelection() )
    );

    if ( $combo_PlotType->GetValue() eq 'Color-Map' ) {
        $panel_Y2Axis->Hide();
        $panel_CBAxis->Show();

        $static_PlotLines->Show();
        $input_PlotLines->Show();
        $spin_PlotLines->Hide();
        $static_PlotLinesExample->Show();

        $static_PlotBlocks->Show();
        $input_PlotBlocks->Show();
        $spin_PlotBlocks->Hide();
        $static_PlotBlocksExample->Show();
    }
    elsif ( $combo_PlotType->GetValue() eq 'Standard' ) {
        $panel_CBAxis->Hide();
        $panel_Y2Axis->Show();

        $static_PlotLines->Show();
        $input_PlotLines->Show();
        $spin_PlotLines->Hide();
        $static_PlotLinesExample->Show();

        $static_PlotBlocks->Show();
        $input_PlotBlocks->Show();
        $spin_PlotBlocks->Hide();
        $static_PlotBlocksExample->Show();
    }
    elsif ( $combo_PlotType->GetValue() eq 'vertical Linetraces' ) {
        $panel_CBAxis->Show();
        $panel_Y2Axis->Hide();

        $static_PlotLines->Hide();
        $input_PlotLines->Hide();
        $spin_PlotLines->Hide();
        $static_PlotLinesExample->Hide();

        $static_PlotBlocks->Show();
        $input_PlotBlocks->Hide();
        $spin_PlotBlocks->Show();
        $static_PlotBlocksExample->Hide();
    }
    elsif ( $combo_PlotType->GetValue() eq 'horizontal Linetraces' ) {
        $panel_CBAxis->Show();
        $panel_Y2Axis->Hide();

        $static_PlotLines->Show();
        $input_PlotLines->Hide();
        $spin_PlotLines->Show();
        $static_PlotLinesExample->Hide();

        $static_PlotBlocks->Hide();
        $input_PlotBlocks->Hide();
        $spin_PlotBlocks->Hide();
        $static_PlotBlocksExample->Hide();
    }

    $sizer_PlotSetup->Layout();

}

sub Plot {
    my $frame = shift;

    my $plot = get_PlotDetails($frame);
    if ( $plot->{ok} == -1 ) {
        return;
    }
    $frame->{plots}->{ $plot->{ID} }->{plotdetails} = $plot;

    if (   not defined $frame->{plots}->{ $plot->{ID} }->{plotter}
        or not $frame->{plots}->{ $plot->{ID} }->{plotter}->available() ) {
        my $plotter = new Lab::XPRESS::Xpression::PlotterGUI($plot);
        $frame->{plots}->{ $plot->{ID} }->{plotter} = $plotter;
        $plotter->init_gnuplot();
    }
    else {
        $frame->{plots}->{ $plot->{ID} }->{plotter}->update_plot($plot);
        $frame->{plots}->{ $plot->{ID} }->{plotter}->init_gnuplot();
    }

    $frame->{plots}->{ $plot->{ID} }->{plotter}->plot();

}

sub update_Plot {
    my $frame = shift;

    my $plot_instance
        = $frame->{Tabs}->GetPage( $frame->{Tabs}->GetSelection() );

    my $plot_ID = &$find( 'label_PlotID', $plot_instance );
    $plot_ID = $plot_ID->GetLabel();

    my $gp          = "";
    my $plot_blocks = &$find( 'spin_PlotBlocks', $plot_instance );
    my $plot_lines  = &$find( 'spin_PlotLines', $plot_instance );
    if ( $plot_blocks->IsShown() ) {
        my $Block = $plot_blocks->GetValue();
        $frame->{plots}->{$plot_ID}->{plotdetails}->{CurrentBlockValue} = @{
            $frame->{plots}->{$plot_ID}->{dataset}->{DATA}[
                @{ $frame->{plots}->{$plot_ID}->{plotdetails}->{X}->{wave} }
                [0]->{column_number} - 1
            ][$Block]
        }[0];
        if (
            abs(
                $frame->{plots}->{$plot_ID}->{plotdetails}
                    ->{CurrentBlockValue}
            ) < 1e-3
            or abs(
                $frame->{plots}->{$plot_ID}->{plotdetails}
                    ->{CurrentBlockValue}
            ) > 1e3
            ) {
            $frame->{plots}->{$plot_ID}->{plotdetails}->{CurrentBlockValue}
                = sprintf(
                "%1.2e",
                $frame->{plots}->{$plot_ID}->{plotdetails}
                    ->{CurrentBlockValue}
                );
        }
        else {
            $frame->{plots}->{$plot_ID}->{plotdetails}->{CurrentBlockValue}
                = sprintf(
                "%1.3f",
                $frame->{plots}->{$plot_ID}->{plotdetails}
                    ->{CurrentBlockValue}
                );
        }
        $gp
            .= "set label 1 '"
            . @{ $frame->{plots}->{$plot_ID}->{plotdetails}->{X}->{wave} }[0]
            ->{column_name} . " = "
            . $frame->{plots}->{$plot_ID}->{plotdetails}->{CurrentBlockValue}
            . "' at graph 0.5, graph 1.06 front center tc rgb 'white'; ";
        $gp .= "BlockFrom = $Block; ";
        $gp .= "BlockTo = $Block; ";
        $gp .= "BlockIncrement = 1; ";
    }
    elsif ( $plot_lines->IsShown() ) {
        my $Line = $plot_lines->GetValue();
        $frame->{plots}->{$plot_ID}->{plotdetails}->{CurrentLineValue} = @{
            $frame->{plots}->{$plot_ID}->{dataset}->{DATA}[
                @{ $frame->{plots}->{$plot_ID}->{plotdetails}->{Y}->{wave} }
                [0]->{column_number} - 1
            ][0]
        }[$Line];
        if (
            abs(
                $frame->{plots}->{$plot_ID}->{plotdetails}->{CurrentLineValue}
            ) < 1e-3
            or abs(
                $frame->{plots}->{$plot_ID}->{plotdetails}->{CurrentLineValue}
            ) > 1e3
            ) {
            $frame->{plots}->{$plot_ID}->{plotdetails}->{CurrentLineValue}
                = sprintf(
                "%1.2e",
                $frame->{plots}->{$plot_ID}->{plotdetails}->{CurrentLineValue}
                );
        }
        else {
            $frame->{plots}->{$plot_ID}->{plotdetails}->{CurrentLineValue}
                = sprintf(
                "%1.3f",
                $frame->{plots}->{$plot_ID}->{plotdetails}->{CurrentLineValue}
                );
        }
        $gp
            .= "set label 1 '"
            . @{ $frame->{plots}->{$plot_ID}->{plotdetails}->{Y}->{wave} }[0]
            ->{column_name} . " = "
            . $frame->{plots}->{$plot_ID}->{plotdetails}->{CurrentLineValue}
            . "' at graph 0.5, graph 1.06 front center tc rgb 'white'; ";
        $gp .= "LineFrom = $Line; ";
        $gp .= "LineTo = $Line; ";
        $gp .= "LineIncrement = 1; ";
    }

    if ( defined $frame->{plots}->{$plot_ID}->{plotter} ) {
        my $gpipe = $frame->{plots}->{$plot_ID}->{plotter}->{gpipe};

        $gp .= "replot; \n";

        print $gpipe $gp;

    }

}

sub get_PlotDetails {
    my $frame = shift;

    my $plot;

    my $plot_instance
        = $frame->{Tabs}->GetPage( $frame->{Tabs}->GetSelection() );

    my $plot_ID = &$find( 'label_PlotID', $plot_instance );
    $plot_ID = $plot_ID->GetLabel();
    $plot->{ID} = $plot_ID;

    $plot->{filename}     = $frame->{plots}->{$plot_ID}->{filename};
    $plot->{path}         = $frame->{plots}->{$plot_ID}->{path};
    $plot->{column_names} = $frame->{plots}->{$plot_ID}->{column_names};
    $plot->{number_of_blocks}
        = $frame->{plots}->{$plot_ID}->{number_of_blocks};
    $plot->{number_of_columns}
        = $frame->{plots}->{$plot_ID}->{number_of_columns};
    $plot->{number_of_lines} = $frame->{plots}->{$plot_ID}->{number_of_lines};

    my $ColumnsContainer = &$find( "panel_ColumnsContainer", $plot_instance );
    my $ColumnsContainerSizer    = $ColumnsContainer->GetSizer();
    my @ColumnsContainerChildren = $ColumnsContainerSizer->GetChildren();
    my $i                        = 1;
    foreach my $item (@ColumnsContainerChildren) {
        my $window = $item->GetWindow();

        my $ColumnAxis = &$find( "combo_ColumnAxis", $window );
        $ColumnAxis = $ColumnAxis->GetValue();

        # append new wave:
        push( @{ $plot->{$ColumnAxis}->{wave} }, {} );

        @{ $plot->{$ColumnAxis}->{wave} }[-1]->{filename}
            = $frame->{plots}->{$plot_ID}->{path};

        my $ColumnName = &$find( "label_ColumnName", $window );
        $ColumnName = $ColumnName->GetLabel();
        @{ $plot->{$ColumnAxis}->{wave} }[-1]->{column_name}   = $ColumnName;
        @{ $plot->{$ColumnAxis}->{wave} }[-1]->{column_number} = $i;

        my $ColumnLineStyle = &$find( "combo_ColumnLineStyle", $window );
        $ColumnLineStyle = $ColumnLineStyle->GetValue();
        if ( $ColumnLineStyle eq "Line" ) {
            $ColumnLineStyle = 'lines';
        }
        elsif ( $ColumnLineStyle eq "Points" ) {
            $ColumnLineStyle = 'points';
        }
        elsif ( $ColumnLineStyle eq "Line + Points" ) {
            $ColumnLineStyle = 'linespoints';
        }
        @{ $plot->{$ColumnAxis}->{wave} }[-1]->{style} = $ColumnLineStyle;

        my $ColumnLineSize = &$find( "combo_ColumnLineSize", $window );
        $ColumnLineSize = $ColumnLineSize->GetValue();
        @{ $plot->{$ColumnAxis}->{wave} }[-1]->{size} = $ColumnLineSize;

        my $ColumnColor = &$find( "color_Column", $window );
        $ColumnColor = $ColumnColor->GetColour();
        $ColumnColor = $ColumnColor->GetAsString(wxC2S_HTML_SYNTAX);
        @{ $plot->{$ColumnAxis}->{wave} }[-1]->{color} = $ColumnColor;

        my $ColumnLabel = &$find( "input_ColumnLabel", $window );
        $ColumnLabel = $ColumnLabel->GetValue();
        @{ $plot->{$ColumnAxis}->{wave} }[-1]->{label} = $ColumnLabel;

        $i++;

    }

    my $plot_type = &$find( "combo_PlotType", $plot_instance );
    $plot_type = $plot_type->GetValue();
    $plot->{type} = $plot_type;

    my $plot_title = &$find( "input_PlotTitle", $plot_instance );
    $plot_title = $plot_title->GetValue();
    $plot->{title} = $plot_title;

    #my $plot_grid = &$find("input_PlotTitle",$plot_instance);
    #$plot_grid = $plot_grid->GetValue();
    $plot->{grid} = 1;

    my @blocks       = ();
    my $plot_blocks  = &$find( 'input_PlotBlocks', $plot_instance );
    my $plot_blocks2 = &$find( 'spin_PlotBlocks', $plot_instance );
    if ( $plot_blocks->IsShown() ) {
        $plot_blocks = $plot_blocks->GetValue();
        @blocks = split( ':', $plot_blocks );
    }
    elsif ( $plot_blocks2->IsShown() ) {
        $plot_blocks = $plot_blocks2->GetValue();
        @blocks[0] = $plot_blocks;
    }

    $plot->{BlockFrom}      = $blocks[0];
    $plot->{BlockTo}        = $blocks[1];
    $plot->{BlockIncrement} = $blocks[2];

    if ( not defined $plot->{BlockFrom} ) {
        my $FileInfoBlocks = &$find( 'label_NumberOfBlocks', $plot_instance );
        $plot->{BlockFrom}      = 0;
        $plot->{BlockTo}        = $plot->{number_of_blocks};
        $plot->{BlockIncrement} = 1;
    }
    elsif ( not defined $plot->{BlockTo} ) {
        $plot->{BlockTo}        = $plot->{BlockFrom};
        $plot->{BlockIncrement} = 1;
    }
    elsif ( not defined $plot->{BlockIncrement} ) {
        $plot->{BlockIncrement} = 1;
    }

    my @lines       = ();
    my $plot_lines  = &$find( 'input_PlotLines', $plot_instance );
    my $plot_lines2 = &$find( 'spin_PlotLines', $plot_instance );
    if ( $plot_lines->IsShown() ) {
        $plot_lines = $plot_lines->GetValue();
        @lines      = split( ':', $plot_lines );
        @lines[0]   = $plot_lines;
    }
    elsif ( $plot_lines2->IsShown() ) {
        $plot_lines = $plot_lines2->GetValue();
    }

    $plot->{LineFrom}      = $lines[0];
    $plot->{LineTo}        = $lines[1];
    $plot->{LineIncrement} = $lines[2];

    if ( not defined $plot->{LineFrom} ) {
        my $FileInfoLines = &$find( 'label_NumberOfLines', $plot_instance );
        $plot->{LineFrom}      = 0;
        $plot->{LineTo}        = $plot->{number_of_lines};
        $plot->{LineIncrement} = 1;
    }
    elsif ( not defined $plot->{LineTo} ) {
        $plot->{LineTo}        = $plot->{LineFrom};
        $plot->{LineIncrement} = 1;
    }
    elsif ( not defined $plot->{LineIncrement} ) {
        $plot->{LineIncrement} = 1;
    }

    foreach my $item ( $plot->{Y}, $plot->{Y2}, $plot->{CB}, $plot->{Z} ) {
        if ( ref($item) eq "HASH" ) {
            foreach my $wave ( @{ $item->{wave} } ) {
                $wave->{LineFrom}      = $plot->{LineFrom};
                $wave->{LineTo}        = $plot->{LineTo};
                $wave->{LineIncrement} = $plot->{LineIncrement};

                $wave->{BlockFrom}      = $plot->{BlockFrom};
                $wave->{BlockTo}        = $plot->{BlockTo};
                $wave->{BlockIncrement} = $plot->{BlockIncrement};
            }
        }
    }

    my $plot_xlabel = &$find( "input_XLabel", $plot_instance );
    $plot_xlabel = $plot_xlabel->GetValue();
    $plot->{X}->{label} = $plot_xlabel;

    my $plot_ylabel = &$find( "input_YLabel", $plot_instance );
    $plot_ylabel = $plot_ylabel->GetValue();
    $plot->{Y}->{label} = $plot_ylabel;

    my $plot_y2label = &$find( "input_Y2Label", $plot_instance );
    $plot_y2label = $plot_y2label->GetValue();
    $plot->{Y2}->{label} = $plot_y2label;

    my $plot_cblabel = &$find( "input_CBLabel", $plot_instance );
    $plot_cblabel = $plot_cblabel->GetValue();
    $plot->{CB}->{label} = $plot_cblabel;

    my $plot_zlabel = &$find( "input_ZLabel", $plot_instance );
    $plot_zlabel = $plot_zlabel->GetValue();
    $plot->{Z}->{label} = $plot_zlabel;

    my $plot_XRange = &$find( "input_XRange", $plot_instance );
    $plot_XRange = $plot_XRange->GetValue();
    $plot->{X}->{range} = $plot_XRange;

    my $plot_YRange = &$find( "input_YRange", $plot_instance );
    $plot_YRange = $plot_YRange->GetValue();
    $plot->{Y}->{range} = $plot_YRange;

    my $plot_Y2Range = &$find( "input_Y2Range", $plot_instance );
    $plot_Y2Range = $plot_Y2Range->GetValue();
    $plot->{Y2}->{range} = $plot_Y2Range;

    my $plot_CBRange = &$find( "input_CBRange", $plot_instance );
    $plot_CBRange = $plot_CBRange->GetValue();
    $plot->{CB}->{range} = $plot_CBRange;

    my $plot_ZRange = &$find( "input_ZRange", $plot_instance );
    $plot_ZRange = $plot_ZRange->GetValue();
    $plot->{Z}->{range} = $plot_ZRange;

    my $plot_XFormat = &$find( "input_XFormat", $plot_instance );
    $plot_XFormat = $plot_XFormat->GetValue();
    $plot->{X}->{format} = $plot_XFormat;

    my $plot_YFormat = &$find( "input_YFormat", $plot_instance );
    $plot_YFormat = $plot_YFormat->GetValue();
    $plot->{Y}->{format} = $plot_YFormat;

    my $plot_Y2Format = &$find( "input_Y2Format", $plot_instance );
    $plot_Y2Format = $plot_Y2Format->GetValue();
    $plot->{Y2}->{format} = $plot_Y2Format;

    my $plot_CBFormat = &$find( "input_CBFormat", $plot_instance );
    $plot_CBFormat = $plot_CBFormat->GetValue();
    $plot->{CB}->{format} = $plot_CBFormat;

    my $plot_ZFormat = &$find( "input_ZFormat", $plot_instance );
    $plot_ZFormat = $plot_ZFormat->GetValue();
    $plot->{Z}->{format} = $plot_ZFormat;

    # check if X and Y axis are defined:
    if ( not defined $plot->{X}->{wave} ) {
        $plot->{ok} = -1;
    }
    elsif ( not defined @{ $plot->{X}->{wave} }[0]->{column_name} ) {
        $plot->{ok} = -1;
    }
    if ( $plot->{type} eq 'Standard' ) {

        if (    not defined @{ $plot->{Y}->{wave} }[0]
            and not defined @{ $plot->{Y2}->{wave} }[0] ) {
            $plot->{ok} = -1;
        }
    }
    elsif ( $plot->{type} eq 'Color-Map' ) {
        if (   not defined @{ $plot->{Y}->{wave} }[0]
            or not defined @{ $plot->{CB}->{wave} }[0] ) {

            $plot->{ok} = -1;
        }
    }
    elsif ( $plot->{type} eq 'vertical Linetraces' ) {
        if (   not defined @{ $plot->{Y}->{wave} }[0]
            or not defined @{ $plot->{CB}->{wave} }[0] ) {
            $plot->{ok} = -1;
        }
    }
    elsif ( $plot->{type} eq 'horizontal Linetraces' ) {
        if (   not defined @{ $plot->{Y}->{wave} }[0]
            or not defined @{ $plot->{CB}->{wave} }[0] ) {
            $plot->{ok} = -1;
        }
    }

    return $plot;

}

sub export_Data {
    my $frame = shift;

    my $plotdetails = get_PlotDetails($frame);
    $frame->{plots}->{ $plotdetails->{ID} }->{plotdetails} = $plotdetails;

    my $label_ID = &$find(
        'label_PlotID',
        $frame->{Tabs}->GetPage( $frame->{Tabs}->GetSelection() )
    );
    my $plot_ID = $label_ID->GetLabel();
    my $plot    = $frame->{plots}->{$plot_ID};

    $plot->{ExtractColumns}   = 0;
    $plot->{ExtractDataStyle} = 0;
    $plot->{ExtractFilename}  = "./undefined";

    if ( not defined $plot->{dataset} ) {
        return 0;
    }

    my $result = show_ExtractDataDialog($plot);
    if ( not $result ) {
        return 0;
    }

    my $data        = $plot->{dataset};
    my $plotdetails = $plot->{plotdetails};
    my $extracted_data;

    if ( $plot->{ExtractColumns} == 1 ) {
        my @columns = ();

        #push(@columns, $plotdetails->{X}->{column_name});
        foreach my $axis (
            $plotdetails->{X},  $plotdetails->{Y}, $plotdetails->{Y2},
            $plotdetails->{CB}, $plotdetails->{Z}
            ) {
            foreach my $wave ( @{ $axis->{wave} } ) {
                push( @columns, $wave->{column_name} );
            }
        }
        $extracted_data = $data->extract_col(@columns);
    }
    else {
        $extracted_data = $data->copy();
    }

    my @blocks = ();
    for (
        my $block = $plotdetails->{BlockFrom};
        $block <= $plotdetails->{BlockTo};
        $block += $plotdetails->{BlockIncrement}
        ) {
        push( @blocks, $block );
    }

    #$extracted_data = $extracted_data->extract_block(@blocks);
    print "@{$plot->{ExtractBlocks}}\n";
    $extracted_data
        = $extracted_data->extract_block( @{ $plot->{ExtractBlocks} } );

    my @lines = ();
    for (
        my $line = $plotdetails->{LineFrom};
        $line <= $plotdetails->{LineTo};
        $line += $plotdetails->{LineIncrement}
        ) {
        push( @lines, $line );
    }

    #$extracted_data = $extracted_data->extract_line(@lines);
    $extracted_data
        = $extracted_data->extract_line( @{ $plot->{ExtractLines} } );
    $extracted_data->print('C');

    if ( $plot->{ExtractDataStyle} == 0 ) {
        $extracted_data->LOG( $plot->{ExtractFilename}, 'Gnuplot' );
    }
    elsif ( $plot->{ExtractDataStyle} == 1 ) {
        $extracted_data->LOG( $plot->{ExtractFilename}, 'Origin' );
    }

    print "done\n";
    return $extracted_data;

}

sub show_ExtractDataDialog {
    my $plot = shift;

    my $xrc = XRC->new('dialog_ExtractData.xrc');
    my $Dialog = $xrc->LoadDialog( undef, 'dialog_ExtractData' );

    my $button_SelectFile = &$find( 'button_SelectFile', $Dialog );
    Wx::Event::EVT_BUTTON( $Dialog, $button_SelectFile, \&FileDialogExtract );

    my $radiobutton_SelectColumns
        = &$find( 'radiobox_ExtractColumns', $Dialog );
    Wx::Event::EVT_RADIOBOX(
        $Dialog, $radiobutton_SelectColumns,
        \&ExtractDataDialog_SelectColumns
    );

    # fill CheckBoxList with Columns:
    my $checklist_Columns = &$find( 'checklist_ExtractColumns', $Dialog );
    my $items = $plot->{dataset}->{COL_NAMES};
    $plot->{SelectedColumns} = $checklist_Columns->InsertItems( $items, 0 );

    if ( $Dialog->ShowModal() == wxID_OK ) {

        # get selection for lines:
        my $input_ExtractSelectionLines
            = &$find( "input_ExtractSelectionLines", $Dialog );
        $plot->{ExtractLines} = $input_ExtractSelectionLines->GetValue();
        $plot->{ExtractLines} =~ s/\s//g;
        my @parts = split( ",", $plot->{ExtractLines} );
        my $parts = @parts;
        if ( $parts <= 1 ) {
            my $a;
            my $b;
            my $c;
            @parts = split( ":", $plot->{ExtractLines} );
            if ( defined $parts[0] ) {
                $a = $parts[0];
            }
            else {
                $a = 0;
            }
            if ( defined $parts[1] and $parts[1] >= $a ) {
                $b = $parts[1];
            }
            else {
                $b = $plot->{number_of_lines};
            }
            if ( defined $parts[2] and $parts[2] >= 1 ) {
                $c = $parts[2];
            }
            else {
                $c = 1;
            }
            @parts = ();
            for ( my $i = $a; $i <= $b; $i += $c ) {
                push( @parts, $i );
            }
            $parts = @parts;
        }
        $plot->{ExtractLines} = ();
        foreach (@parts) {
            push( @{ $plot->{ExtractLines} }, $_ );
        }

        # get selection for blocks:
        my $input_ExtractSelectionBlocks
            = &$find( "input_ExtractSelectionBlocks", $Dialog );
        $plot->{ExtractBlocks} = $input_ExtractSelectionBlocks->GetValue();
        $plot->{ExtractBlocks} =~ s/\s//g;
        my @parts = split( ",", $plot->{ExtractBlocks} );
        my $parts = @parts;
        if ( $parts <= 1 ) {
            my $a;
            my $b;
            my $c;
            @parts = split( ":", $plot->{ExtractBlocks} );
            if ( defined $parts[0] ) {
                $a = $parts[0];
            }
            else {
                $a = 0;
            }
            if ( defined $parts[1] and $parts[1] >= $a ) {
                $b = $parts[1];
            }
            else {
                $b = $plot->{number_of_blocks};
            }
            if ( defined $parts[2] and $parts[2] >= 1 ) {
                $c = $parts[2];
            }
            else {
                $c = 1;
            }
            @parts = ();
            for ( my $i = $a; $i <= $b; $i += $c ) {
                push( @parts, $i );
            }
            $parts = @parts;
        }
        $plot->{ExtractBlocks} = ();
        foreach (@parts) {
            push( @{ $plot->{ExtractBlocks} }, $_ );
        }

        my $radioboxExtractColumns
            = &$find( "radiobox_ExtractColumns", $Dialog );
        $plot->{ExtractColumns} = $radioboxExtractColumns->GetSelection();

        # get selected columns:
        my $checklist_Columns = &$find( 'checklist_ExtractColumns', $Dialog );
        foreach ( 0 .. ( my $itemsl = @{$items} ) ) {
            if ( $checklist_Columns->IsChecked($_) ) {
                push(
                    @{ $plot->{SelectedColumns} },
                    @{ $plot->{dataset}->{COL_NAMES} }[$_]
                );
            }
        }

        my $radioboxDataStyle
            = &$find( "radiobox_ExtractDataStyle", $Dialog );
        $plot->{ExtractDataStyle} = $radioboxDataStyle->GetSelection();

        my $inputExtractFilename = &$find( "input_ExtractFilename", $Dialog );
        $plot->{ExtractFilename} = $inputExtractFilename->GetValue();
        if ( $plot->{ExtractFilename} eq "" ) {
            $plot->{ExtractFilename} = "./undefined";
        }

        $Dialog->Destroy();
        return 1;
    }
    else {
        $Dialog->Destroy();
        return 0;
    }

}

sub ExtractDataDialog_SelectColumns {
    my $frame = shift;

    my $Radiobutton_SelectColumns
        = &$find( "radiobox_ExtractColumns", $frame );
    my $mode = $Radiobutton_SelectColumns->GetSelection();

    my $Checklist_SelectColumns
        = &$find( "checklist_ExtractColumns", $frame );
    if ( $mode == 0 ) {
        $Checklist_SelectColumns->Enable(0);
    }
    else {
        $Checklist_SelectColumns->Enable(1);
    }

}

sub FileDialogExtract {

    my $frame = shift;
    my $path;
    my $filename;
    my $result = show_OpenFileDialog( $frame, '*.dat', \$path, \$filename );
    if ( $result == wxID_OK ) {
        my $inputExtractFilename = &$find( "input_ExtractFilename", $frame );
        $inputExtractFilename->SetValue($path);
    }

    return;

}

sub show_OpenFileDialog {
    my $frame    = shift;
    my $wildcard = shift;
    my $path     = shift;
    my $filename = shift;

    #open FileDialog-----------

    my $dlg = Wx::FileDialog->new(
        $frame, 'Please select a File...',
        '', '', $wildcard, 'wxFD_OPEN, wxFD_FILE_MUST_EXIST'
    );
    my $result = $dlg->ShowModal();

    if ( $result == wxID_OK ) {
        $$filename = $dlg->GetFilename();

        $$path = $dlg->GetPath();
    }

    $dlg->Destroy();

    return $result;

}

sub export_Graph {
    my $frame   = shift;
    my $plot    = get_PlotDetails($frame);
    my $plotter = $frame->{plots}->{ $plot->{ID} }->{plotter};

    # open File dialog:
    my $dlg = Wx::FileDialog->new(
        $frame, 'Please select a File...',
        '', '', '(*.png)|*.png|(*.dat)|*.dat|(all)|*.*', 'wxFD_OPEN'
    );
    my $result = $dlg->ShowModal();

    if ( $result == wxID_CANCEL ) { return; }
    my $filename = $dlg->GetFilename();
    if ( $filename =~ /(_\d+\.[a-z]+)/ ) {
        $filename = $`;
    }

    my $path = $dlg->GetPath();
    my @pathparts = split( /\\/, $path );
    if ( $pathparts[-1] =~ /\.[a-z]/ ) {
        pop(@pathparts);
        $path = join( '\\', @pathparts );
    }

    # look for existing files:
    opendir( DIR, $path );
    my @files     = readdir(DIR);
    my $max_index = 0;
    foreach my $file (@files) {
        if ( $file =~ /($filename)_(\d+)(\.png)\b/ ) {
            if ( $2 > $max_index ) {
                $max_index = $2;
            }
        }
    }
    closedir(DIR);
    $max_index++;
    $filename .= "_$max_index.png";
    $path .= "\\" . $filename;

    $plotter->save_png($path);

}

sub save_PlotConfig {
    my $plotdetails = shift;
    my $filename    = shift;

    my @path = split( /\\/, $filename );
    pop(@path);
    my $path = join( '\\', @path );
    print "\n\n$path\n";
    $plotdetails->{relative_path} = abs2rel( $plotdetails->{path}, $path );

    $plotdetails->{relative_path} = "$path\\" . $plotdetails->{relative_path};
    print "\n\n" . $plotdetails->{relative_path} . "\n";

    store( $plotdetails, "$filename" );

}

sub load_PlotConfig {
    my $filename = shift;

    return retrieve("$filename");

}
