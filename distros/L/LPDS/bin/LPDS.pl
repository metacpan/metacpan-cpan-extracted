#!/usr/bin/perl

use common::sense;
use Carp qw/cluck confess/;
use Cwd;
use File::ShareDir qw/dist_file/;
use Glib qw/TRUE FALSE/;
use Gtk2 qw/-init/;
use Goo::Canvas;
use LPDS::Renderer;
use LPDS::Util;
use YAML qw/Load Dump LoadFile DumpFile/;

use LPDS::Model;

use constant {
    COL_NAME      => 0,
    COL_CPU_NAME  => 1,
    COL_GPU_NAME  => 2,
    COL_MEM_SZ    => 3,
    COL_MEM_FREQ  => 4,
    COL_DISK_SZ   => 5,
    COL_DISK_ROT  => 6,
    COL_SCREEN_SZ => 7,
    COL_PRICE     => 8,
    COL_COLOR     => 9
};

my @COL_NAMES;
$COL_NAMES[COL_NAME]      = 'name';
$COL_NAMES[COL_CPU_NAME]  = 'cpu_name';
$COL_NAMES[COL_GPU_NAME]  = 'gpu_name';
$COL_NAMES[COL_MEM_SZ]    = 'mem_sz';
$COL_NAMES[COL_MEM_FREQ]  = 'mem_freq';
$COL_NAMES[COL_DISK_SZ]   = 'disk_sz';
$COL_NAMES[COL_DISK_ROT]  = 'disk_rot';
$COL_NAMES[COL_SCREEN_SZ] = 'screen_sz';
$COL_NAMES[COL_PRICE]     = 'price';
$COL_NAMES[COL_COLOR]     = 'color';

my %NAME_COLS = (
    name      => COL_NAME,
    cpu_name  => COL_CPU_NAME,
    gpu_name  => COL_GPU_NAME,
    mem_sz    => COL_MEM_SZ,
    mem_freq  => COL_MEM_FREQ,
    disk_sz   => COL_DISK_SZ,
    disk_rot  => COL_DISK_ROT,
    screen_sz => COL_SCREEN_SZ,
    price     => COL_PRICE,
    color     => COL_COLOR
);

my $BUILDER;
my $CANVAS;
my $RENDERER;

my %cpu;
my %gpu;

main();

sub main {
    load_gui();
    init_resources();

    $BUILDER->get_object('CPUComboBox')->set_active(0);
    $BUILDER->get_object('GPUComboBox')->set_active(0);

    $RENDERER = LPDS::Renderer->new(
        table          => $BUILDER->get_object('ModelTable'),
        canvas         => $CANVAS,
        data           => $BUILDER->get_object('ModelListStore'),
        CPU            => \%cpu,
        GPU            => \%gpu,
        click_callback => \&on_curve_clicked
    );

    $BUILDER->get_object('MainWindow')->show_all;
    Gtk2->main;
}

sub load_gui {
    my $file_glade = dist_file( 'LPDS', 'LPDS.glade' );
    $BUILDER = Gtk2::Builder->new;
    $BUILDER->add_from_file($file_glade);
    $BUILDER->connect_signals;

    # set init path of file choosers to current
    my $cwd = getcwd();
    $BUILDER->get_object('AppendDialog')->set_current_folder($cwd);
    $BUILDER->get_object('SaveDialog')->set_current_folder($cwd);

    # exit on main window destroy
    my $mw = $BUILDER->get_object('MainWindow');

    $mw->signal_connect( destroy => sub { Gtk2->main_quit } );
    $mw->maximize;

    # update renderer on table selection change
    my $table = $BUILDER->get_object('ModelTable');
    $table->get_selection->signal_connect(
        changed => \&on_table_selection_changed );

    #
    # create canvas object
    #
    $CANVAS = Goo::Canvas->new();
    $CANVAS->set_size_request( 1000, 400 );
    $CANVAS->set_bounds( 0, 0, 1000, 400 );
    $BUILDER->get_object('CanvasParent')->add($CANVAS);

    #
    # renderer for combobox
    #
    my $data_func = sub {
        my ( undef, $cell, $data, $iter ) = @_;
        my $text = $data->get( $iter, 0 );
        say "set cell text: $text";
        $cell->set( text => $text );
    };

    my $cpu_combo    = $BUILDER->get_object('CPUComboBox');
    my $cpu_renderer = Gtk2::CellRendererText->new;
    $cpu_combo->pack_start( $cpu_renderer, TRUE );
    $cpu_combo->add_attribute( $cpu_renderer, text => 0 );

    #    $cpu_combo->set_active(0);
    #    $cpu_combo->set('entry-text-column', 0);
    #    $cpu_combo->set_cell_data_func($cpu_renderer,$data_func);

    my $gpu_combo    = $BUILDER->get_object('GPUComboBox');
    my $gpu_renderer = Gtk2::CellRendererText->new;
    $gpu_combo->pack_start( $gpu_renderer, TRUE );
    $gpu_combo->add_attribute( $gpu_renderer, text => 0 );

    #    $gpu_combo->set_active(0);
    #    $cpu_combo->set('entry-text-column', 0);
    #    $cpu_combo->set_cell_data_func($cpu_renderer,$data_func);

    #
    # renderer for table
    #

    # name
    my @columns;
    push @columns,
      Gtk2::TreeViewColumn->new_with_attributes( "Name",
        Gtk2::CellRendererText->new, 'text', COL_NAME );

    # CPU name
    push @columns,
      Gtk2::TreeViewColumn->new_with_attributes( "CPU",
        Gtk2::CellRendererText->new, 'text', COL_CPU_NAME );

    # GPU name
    push @columns,
      Gtk2::TreeViewColumn->new_with_attributes( "GPU",
        Gtk2::CellRendererText->new, 'text', COL_GPU_NAME );

    # memory
    my $renderer_col_mem_sz = Gtk2::CellRendererText->new;
    my $col_mem_sz          = Gtk2::TreeViewColumn->new();
    $col_mem_sz->set( title => 'Memory Size' );
    $col_mem_sz->pack_start( $renderer_col_mem_sz, TRUE );
    $col_mem_sz->set_cell_data_func(
        $renderer_col_mem_sz,
        sub {
            my ( $col, $cell, $store, $iter ) = @_;
            my $value = $store->get( $iter, COL_MEM_SZ );
            my $text;
            if ( !defined $value ) {
                $text = '';
            }
            elsif ( $value >= 1 ) {
                $text = sprintf( '%.01f', $value ) . ' GiB';
            }
            else {
                $text = int( $value * 1024 ) . 'MiB';
            }
            $cell->set( 'text' => $text );
        }
    );
    push @columns, $col_mem_sz;

    # memory frequency
    push @columns,
      Gtk2::TreeViewColumn->new_with_attributes( "Mem Freq.",
        Gtk2::CellRendererText->new, 'text', COL_MEM_FREQ );

    # disk size
    my $renderer_col_disk_sz = Gtk2::CellRendererText->new;
    my $col_disk_sz          = Gtk2::TreeViewColumn->new;
    $col_disk_sz->set( title => 'Disk Size' );
    $col_disk_sz->pack_start( $renderer_col_disk_sz, TRUE );
    $col_disk_sz->set_cell_data_func(
        $renderer_col_disk_sz,
        sub {
            my ( $col, $cell, $store, $iter ) = @_;
            my $value = $store->get( $iter, COL_DISK_SZ );
            $cell->set( text => int($value) . ' GiB' );
        }
    );
    push @columns, $col_disk_sz;

    # disk rotation speed
    push @columns,
      Gtk2::TreeViewColumn->new_with_attributes( "Disk Rot.",
        Gtk2::CellRendererText->new, 'text', COL_DISK_ROT );

    # screen size
    my $renderer_col_screen_sz = Gtk2::CellRendererText->new;
    my $col_screen_sz = Gtk2::TreeViewColumn->new;
    $col_screen_sz->set(title=>'Screen Size');
    $col_screen_sz->pack_start($renderer_col_screen_sz,TRUE);
    $col_screen_sz->set_cell_data_func($renderer_col_screen_sz,sub{
        my ( $col, $cell, $store, $iter ) = @_;
        my $value = $store->get( $iter, COL_SCREEN_SZ );
        $cell->set(text=>sprintf('%.01f',$value));
    });
    push @columns,$col_screen_sz;

    # price
    my $renderer_col_price = Gtk2::CellRendererText->new;
    my $col_price = Gtk2::TreeViewColumn->new;
    $col_price->set(title=>'Price');
    $col_price->pack_start($renderer_col_price,TRUE);
    $col_price->set_cell_data_func($renderer_col_price,sub{
        my ( $col, $cell, $store, $iter ) = @_;
        my $value = $store->get( $iter, COL_PRICE );
        $cell->set(text=>sprintf('%.02f',$value));
    });
    push @columns,$col_price;

    foreach my $col (@columns) {
        $col->set_resizable(TRUE);
        $col->set( expand => TRUE );
        $table->append_column($col);
    }
}

sub init_resources {

    # load global data
    my $file_cpu = dist_file( 'LPDS', 'cpu.yaml' );
    my $file_gpu = dist_file( 'LPDS', 'gpu.yaml' );

    my @cpu_list = LoadFile($file_cpu);
    my @gpu_list = LoadFile($file_gpu);

    %cpu = map { $_->{vendor} . ' ' . $_->{model}, $_ } @cpu_list;
    %gpu = map { $_->{vendor} . ' ' . $_->{model}, $_ } @gpu_list;

    # fill CPU and GPU data into data store
    my $cpu_store = $BUILDER->get_object('CPUListStore');
    foreach ( sort keys %cpu ) {
        my $iter = $cpu_store->append;
        $cpu_store->set( $iter, 0 => $_ );
    }

    my $gpu_store = $BUILDER->get_object('GPUListStore');
    foreach ( sort keys %gpu ) {
        my $iter = $gpu_store->append;
        $gpu_store->set( $iter, 0 => $_ );
    }
}

sub data_to_store {
    say "data_to_store";
    my $iter = shift;

    my $dialog = $BUILDER->get_object('ModelEditor');

    my $name      = $BUILDER->get_object('NameEntry')->get_text;
    my $cpu_iter  = $BUILDER->get_object('CPUComboBox')->get_active_iter;
    my $gpu_iter  = $BUILDER->get_object('GPUComboBox')->get_active_iter;
    my $mem_sz    = $BUILDER->get_object('MemSizeSpin')->get_value;
    my $mem_freq  = $BUILDER->get_object('MemFreqSpin')->get_value;
    my $disk_sz   = $BUILDER->get_object('DiskSizeSpin')->get_value;
    my $disk_rot  = $BUILDER->get_object('DiskRotSpin')->get_value;
    my $screen_sz = $BUILDER->get_object('ScreenSizeSpin')->get_value;
    my $price     = $BUILDER->get_object('PriceSpin')->get_value;
    my $color_obj = $BUILDER->get_object('ColorButton')->get_color;

    my ($cpu_name) =
      $BUILDER->get_object('CPUComboBox')->get_model->get( $cpu_iter, 0 );
    my ($gpu_name) =
      $BUILDER->get_object('GPUComboBox')->get_model->get( $gpu_iter, 0 );

    my $color = gdk_color_to_uint($color_obj);

    $BUILDER->get_object('ModelListStore')->set(
        $iter,      COL_NAME,     $name,     COL_CPU_NAME,
        $cpu_name,  COL_GPU_NAME, $gpu_name, COL_MEM_SZ,
        $mem_sz,    COL_MEM_FREQ, $mem_freq, COL_DISK_SZ,
        $disk_sz,   COL_DISK_ROT, $disk_rot, COL_SCREEN_SZ,
        $screen_sz, COL_PRICE,    $price,    COL_COLOR,
        $color
    );

    dump_store();
}

sub dump_store {
    my $store = $BUILDER->get_object('ModelListStore');
    for (
        my $iter = $store->get_iter_first ;
        defined $iter ;
        $iter = $store->iter_next($iter)
      )
    {
        my @line = $store->get(
            $iter,         COL_NAME,     COL_CPU_NAME, COL_GPU_NAME,
            COL_MEM_SZ,    COL_MEM_FREQ, COL_DISK_SZ,  COL_DISK_ROT,
            COL_SCREEN_SZ, COL_PRICE,    COL_COLOR
        );
        say join "\t", @line;
    }
}

sub data_to_config_dialog {
    my $iter = shift;

    my $data = $BUILDER->get_object('ModelListStore');

    $BUILDER->get_object('NameEntry')
      ->set_text( $data->get( $iter, COL_NAME ) );
    $BUILDER->get_object('MemSizeSpin')
      ->set_value( $data->get( $iter, COL_MEM_SZ ) );
    $BUILDER->get_object('MemFreqSpin')
      ->set_value( $data->get( $iter, COL_MEM_FREQ ) );
    $BUILDER->get_object('DiskSizeSpin')
      ->set_value( $data->get( $iter, COL_DISK_SZ ) );
    $BUILDER->get_object('DiskRotSpin')
      ->set_value( $data->get( $iter, COL_DISK_ROT ) );
    $BUILDER->get_object('ScreenSizeSpin')
      ->set_value( $data->get( $iter, COL_SCREEN_SZ ) );
    $BUILDER->get_object('PriceSpin')
      ->set_value( $data->get( $iter, COL_PRICE ) );

    my $cpu_name  = $data->get( $iter, COL_CPU_NAME );
    my $store_cpu = $BUILDER->get_object('CPUListStore');
    my $iter_cpu  = search_list_store( $store_cpu, 0, $cpu_name );
    $BUILDER->get_object('CPUComboBox')->set_active_iter($iter_cpu);

    my $gpu_name  = $data->get( $iter, COL_GPU_NAME );
    my $store_gpu = $BUILDER->get_object('GPUListStore');
    my $iter_gpu  = search_list_store( $store_gpu, 0, $gpu_name );
    $BUILDER->get_object('GPUComboBox')->set_active_iter($iter_gpu);

    my $color_obj = uint_to_gdk_color( $data->get( $iter, COL_COLOR ) );
    $BUILDER->get_object('ColorButton')->set_color($color_obj);
}

sub load_file {
    my $file = shift;
    say "load $file";

    my $store = $BUILDER->get_object('ModelListStore');
    my @data  = LoadFile($file);

    foreach my $curr (@data) {
        say Dump $curr;
        my $iter = $store->append;
        foreach my $key ( keys %$curr ) {
            confess "$file contain invalid field: '$key'"
              if !exists $NAME_COLS{$key};
            my $col = $NAME_COLS{$key};
            $store->set( $iter, $col, $curr->{$key} );
        }
    }
}

sub save_file {
    my $file = shift;

    my @data;
    my $store = $BUILDER->get_object('ModelListStore');
    for (
        my $iter = $store->get_iter_first ;
        defined $iter ;
        $iter = $store->iter_next($iter)
      )
    {
        my %curr_data;

        for ( COL_NAME, COL_CPU_NAME, COL_GPU_NAME, COL_MEM_SZ,
            COL_MEM_FREQ, COL_DISK_SZ, COL_DISK_ROT, COL_SCREEN_SZ,
            COL_PRICE,    COL_COLOR
          )
        {
            my $key = $COL_NAMES[$_];
            my $val = $store->get( $iter, $_ );
            $curr_data{$key} = $val;
        }

        push @data, \%curr_data;
    }

    DumpFile( $file, @data );
}

sub warn_user {
    my $msg    = shift;
    my $dialog = $BUILDER->get_object('WarnDialog');
    $dialog->set( text => $msg );
    $dialog->run;
    $dialog->hide;
}

sub on_AddModelButton_clicked {
    my $dialog = $BUILDER->get_object('ModelEditor');

    my $re = $dialog->run;

    if ( $re == 0 ) {
        say "add model:";
        my $store = $BUILDER->get_object('ModelListStore');
        my $table = $BUILDER->get_object('ModelTable');
        my $iter  = $store->append;
        data_to_store($iter);

        my $path = $RENDERER->data->get_path($iter);
        $table->scroll_to_cell( $path, undef, FALSE, 0.0, 1.0 );
        $table->get_selection->select_iter($iter);

    }
    $dialog->hide;

}

sub on_DelModelButton_clicked {
    my $store = $BUILDER->get_object('ModelListStore');
    my $table = $BUILDER->get_object('ModelTable');
    my $sel   = $table->get_selection;
    my $iter  = $sel->get_selected;

    return undef if !defined $iter;

    $store->remove($iter);
    $RENDERER->render_model_if_needed;
}

sub on_ConfigModelButton_clicked {
    my $store = $BUILDER->get_object('ModelListStore');
    my $table = $BUILDER->get_object('ModelTable');
    my $sel   = $table->get_selection;
    my $iter  = $sel->get_selected;
    return undef if !defined $iter;

    data_to_config_dialog($iter);

    my $re = $BUILDER->get_object('ModelEditor')->run;

    if ( $re == 0 ) {
        data_to_store($iter);
    }

    $BUILDER->get_object('ModelEditor')->hide;
}

sub clear_current {
    $BUILDER->get_object('ModelListStore')->clear;
}

sub on_ClearButton_clicked {
    my $dialog = $BUILDER->get_object('ClearDialog');
    my $re     = $dialog->run;

    if ( $re eq 'no' ) {

    }
    elsif ( $re eq 'yes' ) {
        clear_current();
    }
    else {
        confess "invalid return from clear dialog: '$re'";
    }

    $dialog->hide;
}

sub on_AppendButton_clicked {
    my $dialog = $BUILDER->get_object('AppendDialog');
    my $re     = $dialog->run;

    if ( $re == 0 ) {
        load_file( $dialog->get_filename );
    }

    $dialog->hide;
}

sub on_SaveButton_clicked {
    my $dialog = $BUILDER->get_object('SaveDialog');
    my $re     = $dialog->run;
    $dialog->hide;

    if ( $re == 0 ) {
        my $file = $dialog->get_filename;
        say "SaveDialog: $file";

        if ( -f $file ) {
            my $over_dialog = $BUILDER->get_object('OverwriteDialog');
            $over_dialog->set( 'secondary-text', $file );

            my $re_over = $over_dialog->run();
            $over_dialog->hide;

            if ( $re_over =~ /yes/i ) {
                save_file($file);
            }
        }
        else {
            save_file($file);
        }
    }
}

sub on_AppendDialog_file_activated {
    my $dialog = shift;
    say "on_AppendDialog_file_activated";

    #    load_file($dialog->get_filename);
    $dialog->hide;
}

sub on_SaveDialog_file_activated {
    my $dialog = shift;
    say "SaveDialog file activated";
    say "file: ", $dialog->get_filename;
    $dialog->hide;
}

sub renderer_click_callback {
    my ( undef, undef, undef, $model ) = @_;

    # find iter
    my $data = $model->row->get_model;
    my $path = $model->row->get_path;
    my $iter = $data->get_iter($path);

    # alter table selection
    my $table = $BUILDER->get_object('ModelTable');
    $table->get_selection->select_iter($iter);

}

sub on_table_selection_changed {
    say "# on selection changed #";
    my $sel = shift;
    my ( $store, $iter ) = $sel->get_selected;
    $RENDERER->select_model($iter);
}

sub on_curve_clicked {
    my ( undef, undef, undef, $model ) = @_;
    my $path = $model->row->get_path;

    my $table = $BUILDER->get_object('ModelTable');
    $table->get_selection->select_path($path);
}
