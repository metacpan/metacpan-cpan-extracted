#!/usr/bin/perl -w
# Last modify Time-stamp: <Ye Wenbin 2007-11-11 00:08:13>
# Version: v 0.0 2007/11/02 08:25:10
# Author: Ye Wenbin <wenbinye@gmail.com>

use strict;
use warnings;

package Tetris::L18N;
use base qw(Locale::Maketext);

package Tetris::L18N::zh_cn;
use base qw(Tetris::L18N);
our %Lexicon = (
    'Scores' => '得分',
    'Lines' => '行数',
    'Level' => '级别',
    '_Rank' => '积分板(_R)',
    '_File' => '文件(_F)',
    '_Setting' => '设置(_S)',
    '_Help' => '帮助(_H)',
    "Cancel current game?" => '关闭当前运行的游戏吗？',
    'Start level' => '初始等级',
    'Ye Wenbin' => '叶文彬',
    '_AUTO' => 1,
);

package Tetris::L18N::en;
use base qw(Tetris::L18N);
our %Lexicon = (
    '_File' => '_File',
    '_Rank' => '_Rank',
    '_Setting' => '_Setting',
    '_Help' => '_Help',
    '_AUTO' => 1,
);

#{{{  package Cell
package Tetris::Cell;
use Gtk2;
use Goo::Canvas;
use constant SIZE => 16;

our @ISA = qw(Goo::Canvas::Image);

sub new {
    my $_class = shift;
    my $class = ref $_class || $_class;
    my ($root, $color, $x, $y, %options) = @_;
    my $pixbuf;
    unless ( ref $color ) {
        if ( $color =~ /^#/ ) {
            $color = hex2rgb($color);
        } else {
            $color = Gtk2::Gdk::Color->parse($color);
            $color = [ map {$_/257} $color->red, $color->green, $color->blue];
        }
    }
    if ( $options{-plan} ) {
        $pixbuf = xpm_data((rgb2hex(@$color)) x 3);
        delete $options{-plan};
    } else {
        $pixbuf = xpm_data(
            rgb2hex(map {0.6*$_} @$color),
            rgb2hex(map {0.8*$_} @$color),
            rgb2hex(@$color),
        );
    }
    $pixbuf = Gtk2::Gdk::Pixbuf->new_from_xpm_data(@$pixbuf);
    
    my $self = Goo::Canvas::Image->new($root, $pixbuf, $x, $y, %options);
    bless $self, $class;
}

sub rgb2hex {
    my ($r, $g, $b) = @_;
    return sprintf("#%02x%02x%02x", $r, $g, $b);
}

sub hex2rgb {
    my $hex = shift;
    map { hex } substr($hex, 1) =~ /(..)/g;
}

sub xpm_data {
    my ($col1, $col2, $col3) = @_;
    return [split /\n/, <<XPM];
16 16 3 1
+ c $col1
. c $col2
- c $col3
---------------+
--------------++
--............++
--............++
--............++
--............++
--............++
--............++
--............++
--............++
--............++
--............++
--............++
--............++
-+++++++++++++++
++++++++++++++++
XPM
}
#}}}

#{{{  package Table
package Tetris::Table;
use List::Util qw(max);
our @ISA = qw(Goo::Canvas::Group);

sub new {
    my $_class = shift;
    my $class = ref $_class || $_class;
    my ($root, $x, $y, %options) = @_;
    my $self = Goo::Canvas::Group->new($root);
    bless $self, $class;

    for ( qw/columns rows/ ) {
        $self->{$_} = $options{'-'.$_};
    }
    $self->{table} = [];
    $self->{bgcolor} = $options{-bgcolor} || 'black';
    if ( $options{-border} ) {
        $self->{border_color} = $options{-border_color} || 'grey50';
        $self->{offset} = [(Tetris::Cell::SIZE) x 2];
        $self->draw_border();
    }
    $self->draw_table();
    $self->translate($x, $y);
    return $self;
}

sub draw_border {
    my $self = shift;
    my ($rows, $cols) = ($self->{rows}, $self->{columns});
    my $color = $self->{border_color};
    foreach ( 1..($cols+2) ) {
        Tetris::Cell->new($self, $color, ($_-1)*Tetris::Cell::SIZE, 0);
        Tetris::Cell->new($self, $color, ($_-1)*Tetris::Cell::SIZE, ($rows+1)*Tetris::Cell::SIZE);
    }
    foreach ( 1..$rows ) {
        Tetris::Cell->new($self, $color, 0, $_*Tetris::Cell::SIZE);
        Tetris::Cell->new($self, $color, ($cols+1)*Tetris::Cell::SIZE, $_*Tetris::Cell::SIZE);
    }
}

sub draw_table {
    my $self = shift;
    my ($sx, $sy) = $self->offset;
    my ($rows, $cols) = ($self->{rows}, $self->{columns});
    my $color = $self->{bgcolor};
    my @table;
    foreach my $i ( 1..$cols ) {
        foreach my $j ( 1..$rows ) {
            $table[$i-1][$j-1] = Tetris::Cell->new(
                $self, $color,
                $sx+($i-1)*Tetris::Cell::SIZE,
                $sy+($j-1)*Tetris::Cell::SIZE,
            );
        }
    }
    $self->{bgtable} = \@table;
}

sub check_pos {
    my $self = shift;
    my ($rows, $cols) = ($self->{rows}, $self->{columns});
    my ($row, $col) = @_;
    if ( $row < 1 || $row > $rows ) {
        return;
    }
    if ( $col < 1 || $col > $cols ) {
        return;
    }
    return 1;
}

sub put_cell {
    my $self = shift;
    my ($row, $col, %options) = @_;
    unless ( $self->check_pos($row, $col) ) {
        return;
    }
    for ( $row, $col ) {
        $_--;
    }
    my $table = $self->{table};
    my ($sx, $sy) = $self->offset();
    if ( $table->[$row][$col] ) {
        $self->remove_cell($row, $col);
    }
    my $color = $options{-color};
    delete $options{-color};
    return $table->[$row][$col] = Tetris::Cell->new(
        $self, $color,
        $sx+$col*Tetris::Cell::SIZE,
        $sy+$row*Tetris::Cell::SIZE,
        %options
    );
}

sub offset {
    my $self = shift;
    if ( exists $self->{offset} ) {
        return @{$self->{offset}};
    }
    else {
        return (0, 0);
    }
}

sub remove_cell {
    my $self = shift;
    my ($row, $col) = @_;
    unless ( $self->check_pos($row, $col) ) {
        return;
    }
    for ( $row, $col ) {
        $_--;
    }
    my $table = $self->{table};
    my $item = $table->[$row][$col];
    if ( $item ) {
        $self->remove_child($self->find_child($item));
        $table->[$row][$col] = undef;
        return 1;
    }
}

sub move_cell {
    my $self = shift;
    my ($row, $col, $newrow, $newcol) = @_;
    unless ( $self->check_pos($row, $col)
                 && $self->check_pos($newrow, $newcol) ) {
        return;
    }
    for ( $row, $col, $newrow, $newcol ) {
        $_--;
    }
    my ($rows, $cols) = ($self->{rows}, $self->{columns});
    my $table = $self->{table};
    my $item = $table->[$row][$col];
    if ( $item ) {
        if ( $self->{table}[$newrow][$newcol] ) {
            $self->remove_cell($newrow+1, $newcol+1);
        }
        # print "Move $item from $row $col to $newrow $newcol\n";
        $item->translate(
            ($newcol-$col)*Tetris::Cell::SIZE,
            ($newrow-$row)*Tetris::Cell::SIZE,
        );
        $table->[$newrow][$newcol] = $item;
        $table->[$row][$col] = undef;
    }
}

sub table {
    return shift->{table};
}

sub cell {
    my $self = shift;
    my ($row, $col) = @_;
    unless ( $self->check_pos($row, $col) ) {
        return;
    }
    return $self->{table}[$row-1][$col-1];
}

sub rows {
    return shift->{rows};
}
sub columns {
    return shift->{columns};
}

sub eliminate_line {
    my $self = shift;
    my %lines = map { $_=>1 } @_;
    return unless %lines;
    # print "eliminate_line @_\n";
    my $line = max(keys %lines);
    my $down = 0;
    my $cols = $self->columns;
    my $table = $self->table;
    while ( $line > 0 ) {
        if ( exists $lines{$line} ) {
            $self->remove_cell($line, $_) for 1..$cols;
            $down++;
        } elsif ( $down ) {
            $self->move_cell($line, $_, $line+$down, $_) for 1..$cols;
        }
        $line--;
    }
    return $down;
}

sub eliminate_line_maybe {
    my $self = shift;
    my @lines = @_;
    $self->eliminate_line(
        grep {
            $self->test_fill($_);
        } @lines
    );
}

sub test_fill {
    my $self = shift;
    my $line = shift;
    $line--;
    my $fill = 1;
    my $cols = $self->columns;
    my $table = $self->table;
    foreach ( 1..$cols ) {
        if ( !defined $table->[$line][$_-1] ) {
            $fill = 0;
            last;
        }
    }
    return $fill;
}

sub clear {
    my $self = shift;
    my $table = $self->{table};
    my ($rows, $cols) = ($self->{rows}, $self->{columns});
    foreach my $i( 1..$rows ) {
        foreach my $j( 1..$cols ) {
            $self->remove_cell($i, $j);
        }
    }
    $self->{table} = [];
}

sub is_full {
    my $self = shift;
    my $full = 0;
    my $table = $self->{table};
    foreach ( @{$table->[0]} ) {
        if ( $_ ) {
            $full = 1;
            last;
        }
    }
    return $full;
}
#}}}

#{{{  package Shape
package Tetris::Shape;
use List::Util qw(min max sum);
use Data::Dumper qw(Dumper);
sub new {
    my $_class = shift;
    my $class = ref $_class || $_class;
    my $self = {};
    bless $self, $class;
    my %options = @_;
    foreach ( keys %options ) {
        next unless /^-/;
        $self->{substr($_, 1)} = $options{$_};
    }
    return $self;
}

sub draw {
    my $self = shift;
    my $shape = $self->{shape}[$self->{type}];
    my $i = $#$shape;
    while ( $i>-1 && !grep {$_>0} @{$shape->[$i]} ) {
        $i--;
    }
    my $table = $self->{table};
    my $color = $self->{color};
    my ($row, $col) = ($self->{row}, $self->{col});
    if ( !defined $row ) {      # if no row give, put the shape visible
        my @r = map { sum(@{$_}) } @{$shape};
        my $i = $#r;
        while ( $i>-1 ) {
            last if $r[$i]>0;
            $i--;
        }
        $row = -$i+1;
        $self->{row} = $row;
    }
    my @cells;
    foreach my $r( @$shape ) {
        foreach ( 0..$#$r ) {
            if ( $r->[$_] > 0 ) {
                my $put = 0;
                if ( $row > 0 ) {
                    # print "$table $row, $col+$_, $color\n";
                    $table->put_cell($row, $col+$_, -color => $color);
                    $put = 1;
                }
                push @cells, [$row, $col+$_, $put];
            }
        }
        $row++;
    }
    $self->{cells} = \@cells;
}

sub move_down {
    my $self = shift;
    if ( $self->hit_test(1, 0) ) {
        return 1;
    }
    my $cells = $self->{cells};
    my $table = $self->{table};
    my $color = $self->{color};
    foreach ( sort { $b->[0]<=>$a->[0] } @$cells ) { # move the max row first
        my ($r, $c, $put) = @{$_};
        if ( $put ) {
            $table->move_cell($r, $c, $r+1, $c);
        } elsif ( $r >= 0 ) {
            $table->put_cell($r+1, $c, -color => $color);
            $_->[2] = 1;
        }
        $_->[0]++;
    }
    $self->{row}++;
    return 0;
}

sub move_left {
    my $self = shift;
    my $cells = $self->{cells};
    my $table = $self->{table};
    if ( $self->hit_test(0, -1) ) {
        return;
    }
    foreach ( sort {$a->[1] <=> $b->[1] }  @$cells ) {
        my ($r, $c, $put) = @{$_};
        if ( $put ) {
            $table->move_cell($r, $c, $r, $c-1);
        }
        $_->[1]--;
    }
    $self->{col}--;
}

sub move_right {
    my $self = shift;
    my $cells = $self->{cells};
    my $table = $self->{table};
    if ( $self->hit_test(0, 1) ) {
        return;
    }
    foreach ( sort {$b->[1]<=>$a->[1] } @$cells ) {
        my ($r, $c, $put) = @{$_};
        if ( $put ) {
            $table->move_cell($r, $c, $r, $c+1);
        }
        $_->[1]++;
    }
    $self->{col}++;
}

sub rotate {
    my $self = shift;
    my $cells = $self->{cells};
    my $shapes = $self->{shape};
    my $table = $self->{table};
    my $type = $self->{type};   # backup
    my $col = $self->{col};     # backup
    my $cols = $table->columns;
    $self->{type} = ($type+1) % scalar(@$shapes);
    my ($hit, $collide_cells) = $self->hit_test(0, 0);
    # print Dumper($hit, $collide_cells), "\n";
    if ( $hit ) {
        my $reason = 0;
        my @cols = sort {$a<=>$b} map {$_->[1]} @$collide_cells;
        if ( $cols[0] < 1 ) {
            $self->{col} = $self->{col} + (1-$cols[0]);
        } elsif ( $cols[-1] > $cols ) {
            $self->{col} = $col - ($cols[-1]-$cols);
        } else {
            $self->{type} = $type;
            $self->{col} = $col;
            return;
        }
        if ( $self->hit_test(0, 0) ) {
            $self->{type} = $type;
            $self->{col} = $col;
            return;
        }
    }
    # main::dump_table($table->{table});
    # print join("\n", map {join("\t", @{$_})} @$cells), "\n";
    foreach ( @$cells ) {
        $table->remove_cell($_->[0], $_->[1]) if $_->[2];
    }
    $self->draw();
    # main::dump_table($table->{table});
    # print join("\n", map {join("\t", @{$_})} @$cells), "\n";
}

sub hit_test {
    my $self = shift;
    my ($dx, $dy) = @_;
    my ($row, $col) = ($self->{row}, $self->{col});
    $row += $dx;
    $col += $dy;
    my @cells;
    my $collides = 0;
    my $table = $self->{table};
    my $shape = $self->{shape}[$self->{type}];
    my %cells;
    map { $cells{$_->[0]}{$_->[1]} = 1 } @{$self->{cells}};
    foreach my $r ( @$shape ) {
        foreach ( 0..$#$r ) {
            if ( $r->[$_] > 0 ) {
                next if exists $cells{$row}{$col+$_};
                if ($row>$table->rows || $col+$_ > $table->columns
                        || $col+$_ < 1 || $table->cell($row, $col+$_)) {
                    push @cells, [$row, $col+$_];
                    # print "$row, $col+$_\n";
                    $collides = 1;
                }
            }
        }
        $row++;
    }
    if ( wantarray ) {
        return ($collides, \@cells);
    } else {
        return $collides;
    }
}

sub cells {
    return shift->{cells};
}
#}}}

package main;
use List::Util qw(min max sum);
use Goo::Canvas;
use Gtk2 '-init';
use Glib qw(TRUE FALSE);
use FindBin qw($Bin);
use Data::Dumper qw(Dumper);

use Encode qw(encode decode);
our $lh = Tetris::L18N->get_handle() || Tetris::L18N->get_handle('en');
sub gettext { return decode('utf8', $lh->maketext(@_)) }

#{{{  Configuration
our $history;
our $shapes = parse_shapes();
our $next_shape;
our $timer;
our $timer_pause;
our $game_start;
our $after_load_function;
our %Config = (
    keybindings => {
        65361 => \&move_left,   # left
        65362 => \&rotate,      # up
        65363 => \&move_right,  # right
        65364 => \&move_down,   # down
        ord(' ') => \&down,     # space
        ord('p') => \&pause,    # p
        65293 => \&new_game,    # enter
    },
    rows => 20,
    cols => 10,
    style => [
        'blue', 'purple', 'yellow', 'magenta',  'cyan', 'green',
        'red', 'deeppink', 'hotpink', 'skyblue', 'gold',
    ],
    start_level => 0,
    down_step => 3,
    max_rank_list => 10,
);
my $default_conf_file = ".perltetris";
my $config_file;
my $home;
eval { require File::HomeDir };
if ( $@ ) {
    $home = $ENV{HOME} || $Bin;
}
else {
    $home = File::HomeDir->my_home;
}
if ( -e "$home/.tetris" ) {
    $config_file = "$home/$default_conf_file";
    eval { require "$home/$default_conf_file" };
    if ( $@ ) {
        print STDERR "Error when load config file $home/$default_conf_file: $@\n";
    }
}
else {
    eval { require Tetris::Config; };
    $config_file = $INC{'Tetris/Config.pm'};
}
our ($score, $lines, $level) = (0, 0, $Config{start_level});
#}}}

our $window = Gtk2::Window->new('toplevel');
$window->signal_connect('delete_event' => sub { Gtk2->main_quit; });

our $vbox = Gtk2::VBox->new();
our $menu = create_menu();
our $canvas = create_canvas();
$vbox->add($menu);
$vbox->add($canvas);
$window->add($vbox);
$window->show_all;

if ( defined $after_load_function
 && ref $after_load_function eq 'CODE' ) {
    $after_load_function->();
}

Gtk2->main;

sub END {
    write_history();
}

sub setting {
    return if $game_start;
    my $dia = Gtk2::Dialog->new(
        gettext('Setting'), $window,
        'modal', 'gtk-ok' => 'ok',
        'gtk-cancel' => 'cancel',
    );
    my $vbox = $dia->vbox;
    my $table = Gtk2::Table->new(2, 2);
    my $label = Gtk2::Label->new(gettext("Start level"));
    my $but = Gtk2::SpinButton->new_with_range(0, 10, 1);
    $but->set_value($Config{start_level});
    $table->attach_defaults($label, 0, 1, 0, 1);
    $table->attach_defaults($but, 1, 2, 0, 1);
    $vbox->add($table);
    $vbox->show_all();
    score(0);
    my $response = $dia->run;
    if ( $response eq 'ok' ) {
        $Config{start_level} = $but->get_value;
        $level = $Config{start_level};
        update_label();
    }
    $dia->destroy;
}

sub about {
    return if $game_start;
    my $dia = Gtk2::AboutDialog->new();
    $dia->set_authors(gettext('Ye Wenbin'));
    $dia->run;
    $dia->destroy;
}

sub stop_game {
    if ( $timer ) {
        Glib::Source->remove($timer);
    }
    remove_heading();
    ($score, $lines, $level) = (0, 0, $Config{start_level});
    update_label();
    $canvas->{table}->clear;
    $canvas->{preview}->clear;
    $game_start = 0;
}

sub create_menu {
    my $menu_bar = Gtk2::MenuBar->new;
    # File
    my $file_menu = Gtk2::Menu->new;
    # |- New
    my $new_menuitem = Gtk2::ImageMenuItem->new_from_stock('gtk-new', undef);
    $new_menuitem->signal_connect('activate' => \&new_game);
    $file_menu->append($new_menuitem);
    # |- Stop
    my $stop_menuitem = Gtk2::ImageMenuItem->new_from_stock('gtk-close', undef);
    $stop_menuitem->signal_connect('activate' => \&stop_game);
    $file_menu->append($stop_menuitem);
    # |- Rank
    my $rank_menuitem = Gtk2::MenuItem->new_with_mnemonic(gettext('_Rank'));
    $rank_menuitem->signal_connect( 'activate' => sub { rank_dia() } );
    $file_menu->append($rank_menuitem);
    # |- Exit
    my $exit_menuitem = Gtk2::ImageMenuItem->new_from_stock('gtk-quit', undef);
    $exit_menuitem->signal_connect('activate' => sub { Gtk2->main_quit });
    $file_menu->append($exit_menuitem);

    # Setting
    my $setting_menu = Gtk2::Menu->new;
    # |- Settings
    my $setting_menuitem = Gtk2::ImageMenuItem->new_from_stock('gtk-preferences', undef);
    $setting_menuitem->signal_connect('activate' => \&setting);
    $setting_menu->append($setting_menuitem);

    # Help
    my $help_menu = Gtk2::Menu->new;
    # |- About
    my $about_menuitem = Gtk2::ImageMenuItem->new_from_stock('gtk-about', undef);
    $about_menuitem->signal_connect('activate' => \&about);
    $help_menu->append($about_menuitem);

    my $file_menuitem = Gtk2::MenuItem->new(gettext("_File"));
    $file_menuitem->set_submenu($file_menu);
    $menu_bar->append( $file_menuitem );
    
    my $setting_menuitem2 = Gtk2::MenuItem->new(gettext("_Setting"));
    $setting_menuitem2->set_submenu($setting_menu);
    $menu_bar->append($setting_menuitem2);

    my $help_menuitem = Gtk2::MenuItem->new(gettext("_Help"));
    $help_menuitem->set_submenu($help_menu);
    $menu_bar->append($help_menuitem);
    return $menu_bar;
}

sub create_canvas {
    my $canvas = Goo::Canvas->new;
    $canvas->set_size_request(330, 400);
    my $root = $canvas->get_root_item;
    my ($rows, $cols) = ($Config{rows}, $Config{cols});
    my $offset = [ 10, 10 ];
    my $border = 1;
    my $padding = 16;
    
    $canvas->{table} = Tetris::Table->new(
        $root, $offset->[0], $offset->[1],
        -columns => $cols,
        -rows => $rows,
        -border => $border,
    );
    my $px = $offset->[0]+($cols+( $border ? 2 : 0) )*Tetris::Cell::SIZE + $padding;
    $canvas->{preview} = Tetris::Table->new(
        $root, $px, $offset->[1],
        -columns => 4,
        -rows => 4,
        -border => $border,
    );
    use_keymap( $window, $Config{keybindings} );
    my $text_group = Goo::Canvas::Group->new($root);
    $text_group->translate( $px, $offset->[1] + 7 * Tetris::Cell::SIZE );
    my $text_spacing = 20;
    my @label = (
        Gtk2::Label->new(make_string('Scores', $score)),
        Gtk2::Label->new(make_string('Lines', $lines)),
        Gtk2::Label->new(make_string('Level', $level)),
    );
    foreach ( 0..$#label ) {
        $label[$_]->set_alignment(0, 0);
        Goo::Canvas::Widget->new(
            $text_group, $label[$_], 0, $text_spacing*$_,
            100, 20,
        );
    }
    $canvas->{labels} = \@label;
    # $canvas->{labels} = [
    #     Goo::Canvas::Text->new(
    #         $text_group, make_string('Scores', $score), 0, 0, -1, 'nw',
    #     ),
    #     Goo::Canvas::Text->new(
    #         $text_group, make_string("Lines", $lines), 0, $text_spacing, -1, 'nw',
    #     ),
    #     Goo::Canvas::Text->new(
    #         $text_group, make_string("Level", $level), 0, $text_spacing*2, -1, 'nw',
    #     )
    #     ];
    return $canvas;
}

sub make_string {
    my ($text, $num) = @_;
    my $str =  gettext($text) . ": " . $num;
    return $str;
}

sub use_keymap {
    my ($wid, $keymap) = @_;
    if ( exists $wid->{keymap_sigid} ) {
        $wid->signal_handler_disconnect($wid->{keymap_sigid});
    }
    $wid->{keymap_sigid} = $wid->signal_connect(
        'key-press-event' => \&on_key_pressed, $keymap
    );
}

sub on_key_pressed {
    my ($w, $ev, $keymap) = @_;
    my $key_nr = $ev->keyval;
    my $cb = $keymap->{$key_nr};
    $cb->($w) if $cb;
    return FALSE;
}

sub new_game {
    if ( $game_start ) {
        local $timer_pause = 1;
        my $stop = 1;
        my $dia = Gtk2::MessageDialog->new(
            $window, 'destroy-with-parent',
            'question',
            'yes-no',
            gettext("Cancel current game?"),
        );
        $dia->set_default_response('yes');
        my $response = $dia->run();
        $dia->destroy;
        if ( $response eq 'no' ) {
            return;
        }
    }
    remove_heading();
    $timer_pause = 0;
    $game_start = 1;
    ($score, $lines, $level) = (0, 0, $Config{start_level});
    update_label();
    if ( $timer ) {
        Glib::Source->remove($timer);
    }
    $timer = Glib::Timeout->add(speed(), \&update);
    $canvas->{table}->clear;
    my $s = int(rand(scalar(@$shapes)));
    my $t = int(rand(scalar(@{$shapes->[$s]})));
    $next_shape = [$s, $t];
    new_shape();
}

sub show_heading {
    my $text = shift;
    if ( exists $canvas->{heading} && $canvas->{heading} ) {
        $canvas->{heading}->set(
            'text' => $text
        );
    }
    else {
        $canvas->{heading} =
            Goo::Canvas::Text->new(
                $canvas->get_root_item, $text, 50, 200, -1, 'nw',
                'font' => 'Sans Bold 24',
                'fill-color' => 'red'
            );
    }
}

sub remove_heading {
    if ( exists $canvas->{heading} && $canvas->{heading} ) {
        my $root = $canvas->get_root_item;
        $root->remove_child($root->find_child($canvas->{heading}));
        $canvas->{heading} = undef;
    }
}

sub new_shape {
    my $shape  = Tetris::Shape->new(
        -shape => $shapes->[$next_shape->[0]],
        -type => $next_shape->[1],
        -color => $Config{style}[$next_shape->[0] % @{$Config{style}}],
        -col => int($Config{cols}/2)-2,
        -table => $canvas->{table},
    );
    $shape->draw();
    $canvas->{shape} = $shape;
    # Draw preview
    my $s = int(rand(scalar(@$shapes)));
    my $t = int(rand(scalar(@{$shapes->[$s]})));
    $next_shape = [$s, $t];
    $canvas->{preview}->clear;
    $shape = Tetris::Shape->new(
        -shape => $shapes->[$s],
        -type => $t,
        -color => $Config{style}[$s  % @{$Config{style}}],
        -row => 1,
        -col => 1,
        -table => $canvas->{preview},
    );
    $shape->draw();
}

sub update {
    # print "update $timer_pause\n";
    return TRUE if $timer_pause;
    my $shape  = $canvas->{shape};
    my $hit = $shape->move_down;
    if ( $hit ) {
        done();
    }
    return TRUE;
}

sub done {
    my $shape = $canvas->{shape};
    my $table = $canvas->{table};
    my %row = map { $_->[0] => 1 } @{$shape->cells};
    my $ln = $table->eliminate_line_maybe( keys %row );
    score($ln);
    if ( $table->is_full ) {
        game_over();
    }
    else {
        new_shape();
    }
}

sub score {
    my $ln = shift || 0;
    my $oldscore = $score;
    my @score = ( 0, 10, 20, 40, 60 );
    # my @score = ( 0, 20, 40, 70, 100 );    
    $score += $score[$ln];
    $lines += $ln;

    if ( int($score/100) > int($oldscore/100) ) {
        # print "levelup $level at $score\n";
        $level++;
        $level = $level % 11;   # level: 0-10
        Glib::Source->remove($timer);
        $timer = Glib::Timeout->add(speed(), \&update);
    }
    update_label();
}

sub update_label {
    my $labels = $canvas->{labels};
    $labels->[0]->set_label( make_string("Scores", $score));
    $labels->[1]->set_label( make_string("Lines", $lines));
    $labels->[2]->set_label( make_string("Level", $level));
}

sub speed {
    return int(500/($level*0.5+1));
}

sub rank_dia {
    my $score = shift;
    my ($idx, $new_iter, $new_entry);
    my $max = $Config{max_rank_list}-1;
    if ( defined $score ) {
        if ( !defined $history ) {
            $history = [ $new_entry ];
            $idx = 0;
        } else {
            $new_entry = [$Config{name} || getlogin || getpwuid($<) || 'Nobody', $score];
            $history = [ sort {$b->[1] <=> $a->[1]} @$history ];
            $idx = 0;
            while ( $idx <= $#$history ) {
                last if $score >= $history->[$idx][1];
                $idx++;
            }
            if ( $idx > $max && $idx > $#$history ) {
                return;
            } else {
                splice(@$history, $idx, 0, $new_entry);
                if ( $#$history > $max ) {
                    $#$history = $max;
                }
            }
        }
    }
    if ( @$history == 0 ) {
        my $dia = Gtk2::MessageDialog->new(
            $window, 'destroy-with-parent',
            'info',
            'ok',
            "No rank list yet!",
        );
        $dia->run;
        $dia->destroy;
        return FALSE;
    }
    my $dia = Gtk2::Dialog->new(
        'Rank', $window,
        ['modal', 'destroy-with-parent'],
        'gtk-ok' => 'ok',
    );
    my $vbox = $dia->vbox;
    my $store = Gtk2::ListStore->new( qw/Glib::String Glib::Int/ );
    foreach ( 0..$#$history ) {
        my $iter = $store->append();
        $store->set($iter,
                    0, $history->[$_][0],
                    1, $history->[$_][1],
                );
        if ( defined $idx && $idx == $_ ) {
            $new_iter  = $iter;
        }
    }
    my $treeview = Gtk2::TreeView->new($store);
    my $col = Gtk2::TreeViewColumn->new();
    $col->set_title('name');
    my $ren = Gtk2::CellRendererText->new;
    if ( defined $score ) {
        $ren->set_property('editable' => TRUE);
        $ren->{'renderer_number'} = 0;
        $ren->signal_connect(
            edited => sub {
                my ($cell, $path_string, $new_text) = @_;
                $new_entry->[0] = $new_text;
                $store->set($new_iter, 0, $new_text);
                $cell->set_property('editable' => FALSE);
                return FALSE;
            }
        );
    }
    $col->pack_start($ren, FALSE);
    $col->add_attribute($ren, text=>0);
    $treeview->append_column($col);

    my $col2 = Gtk2::TreeViewColumn->new();
    $col2->set_title('score');
    my $ren2 = Gtk2::CellRendererText->new;
    $col2->pack_start($ren2, FALSE);
    $col2->add_attribute($ren2, text=>1);
    $treeview->append_column($col2);

    $vbox->pack_start($treeview, FALSE, FALSE, 0);
    $dia->show_all;
    if ( defined $score ) {
        $treeview->set_cursor($store->get_path($new_iter), $col, TRUE);
    }
    $dia->signal_connect(
        response => sub {
            $dia->destroy;
            return FALSE;
        }
    );
}

sub game_over {
    Glib::Source->remove($timer);
    show_heading('Game Over');
    $game_start = 0;

    rank_dia($score);
}

sub rotate {
    return unless $game_start;
    # print "rotate\n";
    $canvas->{shape}->rotate;
}

sub down {
    return unless $game_start;
    my $shape = $canvas->{shape};
    while ( !$shape->move_down ) { }
    done();
}

sub move_down {
    return unless $game_start;
    # print "down\n";
    foreach ( 1..$Config{down_step} ) {
        $canvas->{shape}->move_down;
    }
}

sub move_right {
    return unless $game_start;
    # print "right\n";
    $canvas->{shape}->move_right;
}

sub move_left {
    return unless $game_start;
    # print "left\n";
    $canvas->{shape}->move_left;
}

sub pause {
    # print "pause $timer_pause\n";
    $timer_pause = !$timer_pause;
    if ( $timer_pause ) {
        show_heading('Pause');
    } else {
        remove_heading();
    }
    return FALSE;
}

sub parse_shapes {
    my $str;
    while ( <DATA> ) {
        next if /^#/;
        last if /^__END__/;
        $str .= $_;
    }
    my @shapes = grep {defined $_} map { shape_from_string($_) }
        ( split /\n\n/, $str );
    return \@shapes;
}

sub shape_from_string {
    my $str = shift;
    my @lines = grep {$_} split /\n/, $str;
    return if grep {/^#/} @lines;
    return if $#lines != 3;
    my @shape;
    foreach ( 0..$#lines ) {
        my @p = map {[split / /]} split /  +/, $lines[$_];
        map { push @{$shape[$_]}, $p[$_] } 0..$#p;
    }
    return \@shape;
}
    
sub dump_table {
    my $table = shift;
    for my $i( 1..$Config{rows} ) {
        for my $j( 1..$Config{cols} ) {
            if ( $table->[$i-1][$j-1] ) {
                print "$i, $j\n";
            }
        }
    }
}

sub write_history {
    my $str;
    my $found_mark;
    open(my $out, ">", \$str) or die "Can't write to string: $!\n";
    my $start_mark = "# HISTORY: Don't edit from this line to the line marked with END HISTORY.";
    my $end_mark = "# END HISTORY";
    my $conf =  $start_mark . "\n" .
        Data::Dumper->Dump([$history], ['history']) .
                $end_mark . "\n";
    if ( -e $config_file ) {
        open(my $fh, $config_file) or die "Can't open file $config_file: $!";
        while ( <$fh> ) {
            if ( /\Q$start_mark/ ) {
                $found_mark = 1;
                while ( <$fh>) {
                    last if /\Q$end_mark/;
                }
                print $out $conf;
            } else {
                print $out $_;
            }
        }
        close($fh);
    }
    if ( !$found_mark ) {
        print $out $conf;
        print $out "1;\n";
    }
    close($out);
    open(my $fh, ">$config_file") or die "Can't create file $config_file: $!";
    print $fh $str;
    close($fh);
}

1;

__DATA__
0 0 0 0
0 1 1 0
0 1 1 0
0 0 0 0

0 0 0 0   0 0 7 0
7 7 7 7   0 0 7 0
0 0 0 0   0 0 7 0
0 0 0 0   0 0 7 0

0 0 0 0   0 0 0 4
0 4 4 0   0 0 4 4
0 0 4 4   0 0 4 0
0 0 0 0   0 0 0 0

0 0 0 0   0 0 5 0
0 0 5 5   0 0 5 5
0 5 5 0   0 0 0 5
0 0 0 0   0 0 0 0

0 0 0 0   0 0 2 0   0 2 0 0   0 0 2 2
0 2 2 2   0 0 2 0   0 2 2 2   0 0 2 0
0 0 0 2   0 2 2 0   0 0 0 0   0 0 2 0
0 0 0 0   0 0 0 0   0 0 0 0   0 0 0 0

0 0 0 0   0 3 3 0   0 0 0 0   0 0 3 0
0 3 3 3   0 0 3 0   0 0 0 3   0 0 3 0
0 3 0 0   0 0 3 0   0 3 3 3   0 0 3 3
0 0 0 0   0 0 0 0   0 0 0 0   0 0 0 0

0 0 6 0   0 0 6 0   0 0 0 0   0 0 6 0
0 6 6 6   0 0 6 6   0 6 6 6   0 6 6 0
0 0 0 0   0 0 6 0   0 0 6 0   0 0 6 0
0 0 0 0   0 0 0 0   0 0 0 0   0 0 0 0
__END__

=head1 NAME

tetris -  A tetris game

=head1 SYNOPSIS

perl tetris.pl

=head1 CONFIGURATION

The configuration file should be the file with name ".tetris" under
HOME directory. Another option is using Tetris/Config.pm in any
directory of @INC.

Here is an example of configuration:
    # -*- perl -*-
    %Config = (
        %Config,
        'start_level' => 3,
        'down_step' => 2,
        'keybindings' => {
            %{$Config{keybindings}},
            ord('j') => \&move_left,
            ord('l') => \&move_right,
            ord('k') => \&rotate,
            ord('n') => \&new_game,
        }
    );
    push @$shapes, shape_from_string(<<SHAPE);
    0 0 8 0   0 8 0 0   0 8 8 8   0 0 0 8
    0 0 8 0   0 8 8 8   0 0 8 0   0 8 8 8
    0 8 8 8   0 8 0 0   0 0 8 0   0 0 0 8
    0 0 0 0   0 0 0 0   0 0 0 0   0 0 0 0
    SHAPE
    
    push @$shapes, shape_from_string(<<SHAPE);
    0 0 9 0   0 0 0 0   0 0 0 0   0 0 9 0
    0 0 9 9   0 0 9 9   0 9 9 0   0 9 9 0
    0 0 0 0   0 0 9 0   0 0 9 0   0 0 0 0
    0 0 0 0   0 0 0 0   0 0 0 0   0 0 0 0
    SHAPE
         
The key specification can get from this script:

    use Gtk2::Gdk::Keysyms;
    use Glib qw/TRUE FALSE/;
    use Gtk2 -init;
    
    my $window = Gtk2::Window->new ('toplevel');
    $window->signal_connect (delete_event => sub { Gtk2->main_quit });
    $window->signal_connect('key-press-event' => \&show_key);
    	
  	my $label = Gtk2::Label->new();
   	$label->set_markup("<span foreground=\"blue\" size=\"x-large\">Type something on the keyboard!</span>");
    	
    $window->add ($label);
    $window->show_all;
    $window->set_position ('center-always');
    
    Gtk2->main;

    sub show_key {
        my ($widget,$event,$parameter)= @_;
        my $key_nr = $event->keyval();
    	foreach my $key (keys %Gtk2::Gdk::Keysyms) {
    		my $key_compare = $Gtk2::Gdk::Keysyms{$key};
    		if ($key_compare == $key_nr) {
                print "'$key' => $key_nr,\n";
            }
        }
    	return FALSE;
    }

Code to run after the GUI setup, add to code ref $after_load_function.

=cut
