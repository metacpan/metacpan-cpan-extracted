#!/usr/bin/perl -w
# mine --- 
# Last modify Time-stamp: <Ye Wenbin 2007-11-22 08:37:29>
# Version: v 0.0 2007/11/04 12:35:20
# Author: Ye Wenbin <wenbinye@gmail.com>

use strict;
use warnings;

#{{{  Localization
package Mine::L18N;
use base qw(Locale::Maketext);

package Mine::L18N::zh_cn;
use base qw(Mine::L18N);
our %Lexicon = (
    'Rows' => '行数',
    'Columns' => '列数',
    'Mines' => '地雷数',
    '_Junior' => '初级(J)',
    '_Senior' => '中级(S)',
    '_Advance' => '高级(A)',
    '_Rank' => '积分板(_R)',
    '_File' => '文件(_F)',
    '_Setting' => '设置(_S)',
    '_Help' => '帮助(_H)',
    'Ye Wenbin' => '叶文彬',
    '_AUTO' => 1,
);

package Mine::L18N::en;
use base qw(Mine::L18N);
our %Lexicon = (
    '_Junior' => '_Junior',
    '_Senior' => '_Senior',
    '_Advance' =>'_Advance',
    '_Rank' => '_Rank',
    '_File' => '_File',
    '_Setting' => '_Setting',
    '_Help' => '_Help',
    '_AUTO' => 1,
);
#}}}

#{{{  package Cell
# 一个 mine 有这种状态：
#   - 按钮盖住 cover
#   - 盖住有旗标 flag
#   - 盖住有问号 question
#   - 打开爆炸  boom
#   - 打开错误 wrong
#   - 打开炸弹 mine
#   - 打开数字 number

# 游戏的状态如下：
#  waiting:
#    - 计时停止
#    - 点击进入 start 状态

#  start:
#   - 计时开始
#   - 当打开炸弹时进入 stop 状态
#   - 当未打开的格子数等于炸弹数时胜利，进入 stop 状态

#  stop:
#   - 计时停止
#   - 点击无效
#   - 单击开始按钮进入 waiting 状态

package Mine::Cell;
use Data::Dumper qw(Dumper); 
use Glib qw(TRUE FALSE);
our @ISA = qw(Goo::Canvas::Group);

our %pixbuf;
our @color =(
    undef, 'blue', 'green', ('red') x 5,
);
sub pixbuf {
    my ($name, $size) = @_;
    return $pixbuf{$name}{$size} if exists $pixbuf{$name}{$size};
    $pixbuf{$name}{$size} = Gtk2::Gdk::Pixbuf->new_from_file_at_scale(
        $main::image{$name}, $size, $size, 1
    );
}

sub new {
    my $_class = shift;
    my $class = ref $_class || $_class;
    my ($root, $color, $x, $y, %options) = @_;
    my %def_opts = (
        '-size' => 16,
        '-bgcolor' => 'grey90',
    );
    foreach ( keys %def_opts ) {
        if ( exists $options{$_} ) {
            $def_opts{$_} = $options{$_};
            delete $options{$_};
        }
    }
    my $size = $def_opts{-size};
    my $self = Goo::Canvas::Group->new($root);
    
    Goo::Canvas::Rect->new(
        $self, 0, 0, $size-1, $size-1,
        'line-width' => 0,
        'fill-color' => $def_opts{-bgcolor},
    );
    
    my $pixbuf;
    unless ( ref $color ) {
        if ( $color =~ /^#/ ) {
            $color = hex2rgb($color);
        } else {
            $color = Gtk2::Gdk::Color->parse($color);
            $color = [ map {$_/257} $color->red, $color->green, $color->blue];
        }
    }
    $pixbuf = Gtk2::Gdk::Pixbuf->new_from_xpm_data(
        @{xpm_data(
            rgb2hex(map {0.6*$_} @$color),
            rgb2hex(map {0.8*$_} @$color),
            rgb2hex(@$color),
        )}
    );
    $self->{background} = Goo::Canvas::Image->new(
        $self, $pixbuf, 0, 0, %options
    );
    $self->translate($x, $y);
    $self->{size} = $def_opts{-size};
    $self->{status} = 'cover';
    bless $self, $class;
}

sub coords {
    my $self = shift;
    if ( @_ ) {
        $self->{coords} = [@_];
    }
    return @{$self->{coords}};
}

sub get_status {
    return shift->{status};
}

sub remove {
    my $self = shift;
    my @item;
    if ( @_ ) {
        @item = @_;
    } else {
        @item = ( 'boom', 'flag', 'question', 'mine', 'wrong', 'number' );
    }
    foreach (@item) {
        if ( exists $self->{$_} && $self->{$_} ) {
            $self->remove_child(
                $self->find_child($self->{$_})
            );
            delete $self->{$_};
        }
    }
}

sub set_status {
    my $self = shift;
    my $status = shift;
    my $size = $self->{size};
    if ( $status eq 'cover' ) {
        $self->remove();
        $self->{background}->set('visibility'=>'visible');
    }
    elsif ( $status eq 'flag' ) {
        return FALSE if $self->{status} ne 'cover';
        $self->{flag} = Goo::Canvas::Image->new(
            $self, pixbuf('flag', $size), 0, 0,
        );
    }
    elsif ( $status eq 'question' ) {
        return FALSE if ($self->{status} ne 'flag');
        $self->remove('flag');
        $self->{question} = Goo::Canvas::Text->new(
            $self, "?", $self->{size}/2, $self->{size}/2,
            -1, 'center'
        );
    }
    elsif ( $status eq 'mine' ) {
        $self->remove();
        $self->{background}->set('visibility'=>'hidden');
        $self->{mine} = Goo::Canvas::Image->new(
            $self, pixbuf('mine', $size), 0, 0
        );
    }
    elsif ( $status eq 'boom' ) {
        return FALSE if $self->{status} ne 'mine';
        $self->{boom} = Goo::Canvas::Ellipse->new(
            $self, $size/2, $size/2, $size/4, $size/4,
            'line-width' => 0,
            'fill-color' => 'red',
        );
    }
    elsif ( $status eq 'wrong' ) {
        return FALSE if $self->{status} ne 'mine';
        my $item  = Goo::Canvas::Group->new($self);
        Goo::Canvas::Polyline->new_line(
            $item, 0, 0, $size, $size,
            'stroke-color' => 'red',
        );
        Goo::Canvas::Polyline->new_line(
            $item, 0, $size, $size, 0,
            'stroke-color' => 'red',
        );
        $self->{wrong} = $item;
    }
    elsif ( $status eq 'number' ) {
        return FALSE unless ($self->{status} eq 'cover'
                                 || $self->{status} eq 'question');
        my $num = shift(@_);
        $self->remove();
        $self->{background}->set('visibility'=>'hidden');
        $self->{number} = Goo::Canvas::Text->new(
            $self, $num, $self->{size}/2, $self->{size}/2,
            -1, 'center',
            'fill-color' => $color[$num],
        );
    }
    elsif ( $status eq 'open' ) {
        $self->remove();
        $self->{background}->set('visibility'=>'hidden');
    }
    else {
        print "Unknown status!\n";
        return FALSE;
    }
    $self->{status} = $status;
    return 1;
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
package Mine::Table;
use List::Util qw(min max shuffle);
use Glib qw(TRUE FALSE);
our @ISA = qw(Goo::Canvas::Group);
use Data::Dumper qw(Dumper); 
use constant SIZE => 16;
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
    $self->{bgcolor} = $options{-bgcolor} || 'grey90';
    $self->{gridcolor} = $options{-gridcolor} || 'grey60';
    $self->{color} = $options{-color} || 'white';
    $self->{mines} = $options{-mines} || int(0.1*$self->{rows}*$self->{columns});
    $self->{question} = ( exists $options{-question} ? $options{-question} : 1 );
    $self->{flag_count} = $self->{mines};
    $self->{unopen_count} = $self->{rows}*$self->{columns};
    $self->draw_table();
    $self->translate($x, $y);
    return $self;
}

sub flag_count {
    return shift->{flag_count};
}

sub unopen_count {
    return shift->{unopen_count};
}

sub mines {
    return shift->{mines};
}

sub draw_table {
    my $self = shift;
    my ($sx, $sy) = $self->offset;
    my ($rows, $cols) = ($self->{rows}, $self->{columns});
    my $color = $self->{color};
    Goo::Canvas::Rect->new(
        $self, $sx, $sy,
        $sx+SIZE*$cols, $sy+SIZE*$rows,
        'line-width' => 0,
        'fill-color' => $self->{gridcolor}
    );
    my @table;
    foreach my $c ( 1..$cols ) {
        foreach my $r ( 1..$rows ) {
            $table[$r-1][$c-1] = Mine::Cell->new(
                $self, $color,
                $sx+($c-1)*SIZE,
                $sy+($r-1)*SIZE,
                -size => SIZE,
            );
            $table[$r-1][$c-1]->coords($r, $c);
        }
    }
    $self->{table} = \@table;
}

sub set_visible {
    my $self = shift;
    my ($row, $col, $visible) = @_;
    $self->{table}[$row-1][$col-1]->set_visible($visible);
}

sub offset {
    my $self = shift;
    if ( exists $self->{offset} ) {
        return @{$self->{offset}};
    }
    else {
        return (1, 1);
    }
}

sub reset {
    my $self = shift;
    my $table = $self->{table};
    my ($rows, $cols) = ($self->{rows}, $self->{columns});
    my @mines = shuffle((1)x$self->{mines},
                         (0)x($rows*$cols-$self->{mines}));
    foreach my $i( 1..$rows ) {
        foreach my $j( 1..$cols ) {
            my $cell = $table->[$i-1][$j-1];
            $cell->{has_mine} = $mines[($i-1)*$cols+$j-1];
            $cell->set_status('cover');
        }
    }
    $self->{flag_count} = $self->{mines};
    $self->{unopen_count} = $rows*$cols;
}

sub open {
    my $self = shift;
    my ($row, $col) = @_;
    my $table = $self->{table};
    my @open;
    push @open,$self->cell($row, $col);
    while ( @open ) {
        my $cell = pop @open;
        unless ( $cell->get_status =~ /^(cover|question)$/ ) {
            next;
        }
        if ( $cell->{has_mine} ) {
            $cell->set_status('mine');
            $cell->set_status('boom');
            foreach ( @{$table} ) {
                foreach ( @{$_} ) {
                    next if $_->{status} eq 'boom';
                    if ( $_->{has_mine} ) {
                        if ($_->{status} ne 'flag') {
                            $_->set_status('mine');
                        }
                    } elsif ( $_->{status} eq 'flag' ) {
                        $_->set_status('mine');
                        $_->set_status('wrong');
                    }
                }
            }
            return TRUE;
        } else {
            my $adj = $self->neighbor($cell->coords);
            my $n = grep { $_->{has_mine} } @$adj;
            if ( $n ) {
                if ( $cell->set_status('number', $n) ) {
                    $self->{unopen_count}--;
                }
            } else {
                if ($cell->set_status('open') ) {
                    $self->{unopen_count}--;
                }
                push @open, grep {$_->{status} =~/^(cover|question)$/ } @$adj;
            
            }
        }
    }
    return FALSE;
}

sub set_flag {
    my $self = shift;
    my ($row, $col) = @_;
    my $cell = $self->cell($row, $col);
    my $s = $cell->get_status;
    return if $s =~ /open|number/;
    my @status = qw/flag cover/;
    if ( $self->{question} ) {
        unshift @status, 'question';
    }
    my $i = 0;
    while ( $i <= $#status ) {
        last if $s eq $status[$i];
        $i++;
    }
    return if $i > 2;
    $cell->set_status($status[$i-1]);
    if ( $status[$i-1] eq 'flag' ) {
        $self->{flag_count}--;
    }
    elsif ( $s eq 'flag' ) {
        $self->{flag_count}++;
    }
}

sub neighbor {
    my $self = shift;
    my ($row, $col) = @_;
    my ($rows, $cols) = ($self->{rows}, $self->{columns});
    my @r = max(1, $row-1) .. min($row+1, $rows);
    my @c = max(1, $col-1) .. min($col+1, $cols);
    my @ne;
    for my $r ( @r ) {
        for my $c ( @c ) {
            next if ($r==$row && $c == $col);
            push @ne, $self->cell($r, $c);
        }
    }
    return \@ne;
}

sub open_others {
    my $self = shift;
    my ($row, $col) = @_;
    my $cell = $self->cell($row, $col);
    return unless $cell->get_status eq 'number';
    my $ne = $self->neighbor($row, $col);
    my $n = grep { $_->get_status eq 'flag' } @$ne;
    my $b = grep { $_->{has_mine} } @$ne;
    return if $n != $b;
    my $boom;
    foreach ( @$ne ) {
        next if $_->get_status eq 'flag';
        $boom = $self->open($_->coords);
        last if $boom;
    }
    return $boom;
}

sub cell {
    my $self = shift;
    my ($row, $col) = @_;
    my ($rows, $cols) = ($self->{rows}, $self->{columns});
    if ( $row > $rows || $row < 1
     || $col > $cols || $col < 1 ) {
        die "row or col out of range ($row, $col) in ($rows, $cols)\n";
    }
    return $self->{table}[$row-1][$col-1];
}

#}}}

#{{{  package main
package main;
use Goo::Canvas;
use constant {
    START   => 0,
    WAITING => 1,
    STOP    => 2,
    MAXROWS   => 40,
    MAXCOLS   => 40,
    MAXMINES => 400,
};

use Gtk2 '-init';
use Glib qw(TRUE FALSE);
use FindBin qw($Bin);
use Data::Dumper qw(Dumper); 
use Encode qw(encode decode);
use File::Spec::Functions;

our $lh = Mine::L18N->get_handle() || Tetris::L18N->get_handle('en');
sub gettext { return decode('utf8', $lh->maketext(@_)) }

our %Config = (
    rows => 10,
    cols => 10,
    mines => 10,
    image_directory => '.',
    level => {
        'junior' => [10, 10, 10],
        'senior' => [15, 20, 45],
        'advance'=> [20, 30, 100],
    },
    'use_question_flag' => 0,
);
our $history;
our $DEBUG = 0;

my $config_file;
my $home;
my $default_conf_file = ".perlmine";
eval { require File::HomeDir };
if ( $@ ) {
    $home = $ENV{HOME} || $Bin;
}
else {
    $home = File::HomeDir->my_home;
}
if ( -e "$home/$default_conf_file" ) {
    $config_file = "$home/$default_conf_file";
    eval { require $config_file };
    if ( $@ ) {
        print STDERR "Error when load config file: $@!\n";
    }
}
else {
    eval { require Mine::Config; };
    $config_file = $INC{'Mine/Config.pm'};
}
if ( !$config_file ) {
    $config_file = "$home/$default_conf_file";
}

our $game_status;
our $elapse_time = 0;
our $timer;
$Data::Dumper::Indent = 1;
$| = 1;

our %image = (
    'smile' => catfile($Config{image_directory}, 'face-smile.png'),
    'win' => catfile($Config{image_directory}, 'face-win.png'),
    'sad' => catfile($Config{image_directory}, 'face-sad.png'),
    'mine' => catfile($Config{image_directory}, 'mine.svg'),
    'flag' => catfile($Config{image_directory}, 'flag.svg'),
);

my $window = Gtk2::Window->new('toplevel');
$window->signal_connect('delete_event' => sub { Gtk2->main_quit; });
my $vbox = Gtk2::VBox->new();
my $menu = create_menu();
# box for buttons and labels
my $btab = Gtk2::Table->new(1, 3, FALSE);
my $timer_label = Gtk2::Label->new();
$btab->attach_defaults($timer_label, 0, 1, 0, 1);
my $image_but = Gtk2::Button->new;
$image_but->signal_connect(
    'clicked' => \&start_game
);
$image_but->set('relief' => 'none'); 
$btab->attach_defaults($image_but, 1, 2, 0, 1);
my $count_label = Gtk2::Label->new();
$btab->attach_defaults($count_label, 2, 3, 0, 1);

my $canvas = Goo::Canvas->new;
setup_canvas();
for ( $menu, $btab, $canvas ) {
    $vbox->pack_start($_, FALSE, FALSE, 0);
}
$window->add($vbox);
$window->show_all;
start_game();
Gtk2->main;

sub END {
    write_history();
}
#}}}

#{{{  create menu and canvas
sub create_menu {
    my $menu_bar = Gtk2::MenuBar->new;
    # File
    my $file_menu = Gtk2::Menu->new;
    # |- junior
    my $junior_menuitem = Gtk2::MenuItem->new_with_label( gettext('_Junior') );
    $junior_menuitem->signal_connect('activate' => \&set_level,
                                     $Config{level}{junior} );
    $file_menu->append($junior_menuitem);
    # |- senior
    my $senior_menuitem = Gtk2::MenuItem->new_with_label( gettext('_Senior') );
    $senior_menuitem->signal_connect('activate' => \&set_level,
                                     $Config{level}{senior} );
    $file_menu->append($senior_menuitem);
    # |- advance
    my $advance_menuitem = Gtk2::MenuItem->new_with_label( gettext('_Advance') );
    $advance_menuitem->signal_connect('activate' => \&set_level,
                                     $Config{level}{advance} );
    $file_menu->append($advance_menuitem);
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

sub about {
    my $dia = Gtk2::AboutDialog->new();
    $dia->set_authors(gettext('Ye Wenbin'));
    $dia->run;
    $dia->destroy;
}

sub setup_canvas {
    my $root = Goo::Canvas::Group->new;
    my ($rows, $cols) = ($Config{rows}, $Config{cols});
    my ($xpad, $ypad) = ( 10, 10 );
    my $border = 1;
    
    $canvas->{table} = Mine::Table->new(
        $root, $xpad, $ypad,
        -columns => $cols,
        -rows => $rows,
        -border => $border,
        -mines => $Config{mines},
        -question => $Config{use_question_flag},
    );
    foreach ( @{$canvas->{table}{table}} ) {
        foreach ( @{$_} ) {
            $_->signal_connect(
                'button-press-event' => \&open_cell
            );
        }
    }
    $canvas->set_root_item($root);
    $canvas->set_size_request( $xpad * 2 + Mine::Table::SIZE * $cols,
                               $ypad * 2 + Mine::Table::SIZE * $rows);
}

sub setting {
    my $dia = Gtk2::Dialog->new(
        gettext('Setting'), $window,
        'modal', 'gtk-ok' => 'ok',
        'gtk-cancel' => 'cancel',
    );
    my $vbox = $dia->vbox;
    my $table = Gtk2::Table->new(2, 2);
    my ($label, $row_but, $col_but, $mines_but);

    $label = Gtk2::Label->new(gettext("Rows"));
    $row_but = Gtk2::SpinButton->new_with_range(1, MAXROWS, 1);
    $row_but->set_value($Config{rows});
    $table->attach_defaults($label, 0, 1, 0, 1);
    $table->attach_defaults($row_but, 1, 2, 0, 1);

    $label = Gtk2::Label->new(gettext("Columns"));
    $col_but = Gtk2::SpinButton->new_with_range(1, MAXROWS, 1);
    $col_but->set_value($Config{cols});
    $table->attach_defaults($label, 0, 1, 1, 2);
    $table->attach_defaults($col_but, 1, 2, 1, 2);
    
    $label = Gtk2::Label->new(gettext("Mines"));
    $mines_but = Gtk2::SpinButton->new_with_range(1, MAXMINES, 1);
    $mines_but->set_value($Config{mines});
    $table->attach_defaults($label, 0, 1, 2, 3);
    $table->attach_defaults($mines_but, 1, 2, 2, 3);

    $vbox->add($table);
    $vbox->show_all();
    my $response = $dia->run;
    if ( $response eq 'ok' ) {
        set_level(undef, [$row_but->get_value, $col_but->get_value, $mines_but->get_value]);
    }
    $dia->destroy;
}

#}}}

sub start_game {
    $game_status = WAITING;
    if ( $timer ) {
        Glib::Source->remove($timer);
        $elapse_time = 0;
    }
    setup_canvas();
    my $table = $canvas->{table};
    $table->reset;
    set_count_label( $table->flag_count );
    set_timer_label();
    $image_but->set_image(Gtk2::Image->new_from_file($image{'smile'}));
    return FALSE;
}

sub update_label {
    $elapse_time++;
    set_timer_label();
    return TRUE;
}

sub open_cell {
    return FALSE if $game_status == STOP;
    if ( $game_status == WAITING ) {
        $game_status = START;
        $elapse_time = 0;
        $timer = Glib::Timeout->add(1000, \&update_label);
    }
    my ($cell, $target, $ev ) = @_;
    if ( $DEBUG ) {
        # print "x, y: (", join(', ', $ev->x, $ev->y), ")\n";
        print "row, col: (", join(", ", $cell->coords), ")\n";
    }
    my $boom;
    my $table = $canvas->{table};
    if ( $ev->button == 1 ) {   # left button
        $boom = $table->open($cell->coords);
    }
    elsif ( $ev->button == 2) { # middle button
        $boom = $table->open_others($cell->coords);
    } elsif ( $ev->button == 3 ) { # right button
        $table->set_flag($cell->coords);
        set_count_label($table->flag_count);
    }
    if ( $boom ) {
        stop_game();
    }
    if ( $table->unopen_count == $table->mines ) {
        win();
    }
    return FALSE;
}

sub set_count_label {
    my ($cnt) = @_;
    $count_label->set_markup(sprintf("<span weight=\"bold\" size=\"large\" foreground=\"blue\">%3d/%d</span>", $cnt, $Config{mines}));
}

sub set_timer_label {
    $timer_label->set_markup(sprintf("<span weight=\"bold\" size=\"large\" foreground=\"red\">%3d</span>", $elapse_time));
}

sub set_level {
    my ($wid, $data) = @_;
    $Config{rows}  = $data->[0];
    $Config{cols} = $data->[1];
    $Config{mines} = $data->[2];
    if ( $Config{mines} > $Config{rows} * $Config{cols} ) {
        warn "Mines more than cells of the table!\n";
        $Config{mines} = 0.1 * $Config{rows} * $Config{cols};
    }
    setup_canvas();
    start_game();
    return FALSE;
}

sub stop_game {
    $game_status = STOP;
    Glib::Source->remove($timer);
    $image_but->set_image(Gtk2::Image->new_from_file($image{'sad'}));
}

sub win {
    if ( $DEBUG ) {
        print "You win!\n";
    }
    $game_status = STOP;
    Glib::Source->remove($timer);
    $image_but->set_image(Gtk2::Image->new_from_file($image{'win'}));
    return;

    my $new_entry = [$Config{name} || getlogin || getpwuid($<) || 'Nobody', $elapse_time];
    my ($idx, $new_iter);
    if ( $#$history > 8 ) {
        $#$history = 8;
    }
    push @$history, $new_entry;
    $idx = $#$history;
    my $dia = Gtk2::Dialog->new(
        'Rank', undef, # $window,
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
        if ( $idx == $_ ) {
            $new_iter  = $iter;
        }
    }

    my $treeview = Gtk2::TreeView->new($store);
    my $col = Gtk2::TreeViewColumn->new();
    $col->set_title('name');
    my $ren = Gtk2::CellRendererText->new;
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
    $treeview->set_cursor($store->get_path($new_iter), $col, TRUE);
    $dia->signal_connect(
        response => sub {
            $dia->destroy;
            return FALSE;
        }
    );
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

__END__

=head1 NAME

perlmine -  A game to clear hidden mines from a minefield

=head1 SYNOPSIS

perl perlmine.pl

=head1 DESCRIPTION

An example of config file:
   
   # -*- perl -*-
   # ~/.perlmine
   use utf8;
   %Config = (
       %Config,
       rows => 10,
       cols => 10,
       mines => 10,
       image_directory => '/usr/share/pixmaps/gnomine',
       name => '叶文彬',
   );
   
=cut

