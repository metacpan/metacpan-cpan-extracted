# vi:filetype=perl:

package Games::RolePlay::MapGen::Editor;

# NOTE: I'm aware this is monolithic and heinous, please don't judge me.  I
# intend to split this up into manageable chunks (aka modules) later.  I'm new
# to GUI code and I'm surprised how big it gets.
#
# -Paul

use common::sense;
use GD;
use Glib qw(TRUE FALSE);
use Gtk2 -init; # -init tells import to ->init() your app
use Gtk2::Ex::Simple::Menu;
use Gtk2::Ex::Dialogs::ErrorMsg;
use Gtk2::Ex::Dialogs::Question;
use Gtk2::Ex::PodViewer;
use Gtk2::SimpleList;
use Games::RolePlay::MapGen;
use File::HomeDir;
use File::Spec;
use DB_File;
use Storable qw(freeze thaw);
use Data::Dump qw(dump);
use POSIX qw(ceil);
use MIME::Base64;

use POE::Component::Server::HTTP;
use POE::Kernel {loop => "Glib"};
use HTTP::Status;
use CGI qw(escapeHTML);

use Games::RolePlay::MapGen::MapQueue::Object;
use Games::RolePlay::MapGen::MapQueue;
use Games::RolePlay::MapGen::Editor::_MForm qw(make_form $default_restore_defaults);
use Games::RolePlay::MapGen::Tools qw( roll choice _door _group );

use version; our $VERSION = qv("1.0.0");

our $DEFAULT_GENERATOR         = 'Basic';
our @GENERATORS                = (qw( Basic Blank OneBigRoom Perfect SparseAndLoops ));
our @GENERATOR_PLUGINS         = (qw( BasicDoors FiveSplit ));
our @DEFAULT_GENERATOR_PLUGINS = (qw( BasicDoors ));
our @FILTERS                   = (qw( BasicDoors FiveSplit ClearDoors ));

use vars qw($x); # like our, but at compile time so these constants work
use constant {
    # the per-object index constants {{{
    MAP       => $x++, # the Games::RolePlay::MapGen object, the actual map arrays are in [MAP]{_the_map}
    MQ        => $x++, # the Games::RolePlay::MapGen::MapQueue object
    WINDOW    => $x++, # the Gtk2 window (Gtk2::Window)
    MENU      => $x++, # the main menubar (Gtk2::Ex::Simple::Menu)
    MAREA     => $x++, # the map area Gtk2::Image
    VP_DIM    => $x++, # the current dimensions (changes on resizes and things) of the Gtk2::Viewport holding the [MAREA]
    SETTINGS  => $x++, # a tied DB_File hashref full of settings
    FNAME     => $x++, # the current file name or undef
    STAT      => $x++, # the statusbar (Gtk2::Statusbar)
    MP        => $x++, # the current map pixbufs, cell size, and pixbuf dimensions
    RCCM      => $x++, # the right click context menus (there are two: [RCCM][0] for tiles and [RCCM][1] for closures)
    O_LT      => $x++, # the tile location currently moused-overed, O_ is for old, during the motion-notify, O_LT is the
                       #  old location and LT is the new one, although, LT isn't a constant
    SEL_S     => $x++, # the selection start, set to O_LT when a button is pressed
    SEL_E     => $x++, # set to the end of the selection being dragged during the selection handler. really only used in
                       #  the button release event to (possibly) select a single square when shift-clicking
    SEL_W     => $x++, # the currently "working" select rectangle, used to pop the end of SELECTION while *still* dragging
    SELECTION => $x++, # the current selection rectangles [ [x1,y1,x2,y2], [...], ... ]
    S_ARG     => $x++, # the status-bar arguments: the current tile location (LT), tile type, and door info
                       #  [\@lt, $tile->{type}, undef]; $sarg->[1] (type) is replaced with [$g->name, $g->desc] when
                       #  $tile has a group... door info starts out as undef and changes to [dir=>desc] when there is a door
                       #  moused-overed.  Perhaps the best way to describe it is this huge block of examples:
                       #    [[11, 9, "corridor"], undef, undef]
                       #    [[12, 9, "corridor"], undef, ["s", ["wall"]]]
                       #    [[6, 4, "room"], ["Room #1", "(4, 3) 10x8"], undef]
                       #    [[6, 3, "room"], ["Room #1", "(4, 3) 10x8"], ["w", ["opening"]]]
                       #    [[5, 5], ["Room #1", "(4, 3) 10x8"], undef]
                       #    [[5, 5], ["Room #1", "(4, 3) 10x8"], ["e", ["opening"]]]
                       #    [[6, 5, "room"], ["Room #1", "(4, 3) 10x8"], undef]
                       #    [[6, 6, "room"], ["Room #1", "(4, 3) 10x8"], undef]
                       #    [[6, 6], ["Room #1", "(4, 3) 10x8"], ["s", ["opening"]]]
                       #    [[6, 7, "room"], ["Room #1", "(4, 3) 10x8"], ["n", ["opening"]]]
                       #    [[6, 7], ["Room #1", "(4, 3) 10x8"], undef]
                       #    [[6, 7], ["Room #1", "(4, 3) 10x8"], ["s", ["wall"]]]
                       #    [[6, 8, "corridor"], undef, ["n", ["wall"]]]
                       #    [[7, 8], undef, ["n", ["ordinary", "door"]]]
                       #    [ [7, 7, "room"], ["Room #1", "(4, 3) 10x8"], ["s", ["ordinary", "door"]], ]
    O_DR      => $x++, # door info, [dir => desc], called O_DR since it's the "old" door.  really only used to invoke a 
                       #  reddraw of the cursors when there *was* a door (O_DR) and there *nolonger* is one
    SERVER    => $x++, # the map server (if applicable) [port, PoCo::HTTPD]
    # }}}
};

1;

# new {{{
sub new {
    my $class = shift;
    my $this  = bless [], $class;

    my $fname   = "GRM Editor";
    unless( File::Spec->case_tolerant ) {
        $fname = lc $fname;
        $fname =~ s/ /_/g;
        substr($fname,0,0) = ".";
    }

    my @homedir = File::HomeDir->my_home;
    push @homedir, "Application Data" if "@homedir" =~ m/Documents and Settings/i;

    $fname = File::Spec->catfile(@homedir, $fname);

    # warn "fname=$fname";
    my %o; tie %o, DB_File => $fname or die $!;

    $o{REMEMBER_SP} = 1 unless defined $o{REMEMBER_SP};

    $this->[SETTINGS] = \%o;

    my $vbox = new Gtk2::VBox;
    my $window = $this->[WINDOW] = new Gtk2::Window("toplevel");
       $window->signal_connect( delete_event => sub { $this->quit } );
       $window->set_size_request(700,475);
       $window->set_position('center');
       $window->add($vbox);
       $window->set_title("GRM Editor");

    my $menu_tree = [
        _File => {
            item_type => '<Branch>',
            children => [
                'Generate _New Map' => {
                    item_type   => '<StockItem>',
                    callback    => sub { $this->generate },
                    accelerator => '<ctrl>N',
                    extra_data  => 'gtk-new',
                },
                _Open => {
                    item_type   => '<StockItem>',
                    callback    => sub { $this->open_file },
                    accelerator => '<ctrl>O',
                    extra_data  => 'gtk-open',
                },
                _Save => {
                    item_type   => '<StockItem>',
                    callback    => sub { $this->save_file },
                    accelerator => '<ctrl>S',
                    extra_data  => 'gtk-save',
                },
                'Save As...' => {
                    item_type   => '<StockItem>',
                    callback    => sub { $this->save_file_as },
                    extra_data  => 'gtk-save-as',
                },
                '_Export' => {
                    item_type => '<Branch>',
                    children => [
                        "_Image..." => {
                            callback    => sub { $this->save_image_as },
                        },
                        "_Text File..." => {
                            callback    => sub { $this->save_text_as },
                        },
                    ],
                },
                _Close => {
                    item_type   => '<StockItem>',
                    callback    => sub { $this->blank_map },
                    accelerator => '<ctrl>W',
                    extra_data  => 'gtk-close',
                },
                _Quit => {
                    item_type   => '<StockItem>',
                    callback    => sub { $this->quit },
                    accelerator => '<ctrl>Q',
                    extra_data  => 'gtk-quit',
                },
            ],
        },
        _Edit => {
            item_type => '<Branch>',
            children => [
                '_Redraw' => {
                    callback    => sub { warn "forced redraw"; $this->draw_map; $this->draw_map_w_cursor },
                    accelerator => '<ctrl>R',
                },
                'R_ender Settings'=> {
                    callback    => sub { $this->render_settings },
                },
                'Server _Settings'=> {
                    callback    => sub { $this->server_settings },
                    accelerator => '<ctrl>T',
                },
                Separator => {
                    item_type => '<Separator>',
                },
                _Preferences => {
                    item_type   => '<StockItem>',
                    callback    => sub { $this->preferences },
                    accelerator => '<ctrl>P',
                    extra_data  => 'gtk-preferences',
                },
            ],
        },
        _Help => {
            item_type => '<LastBranch>',
            children => [
                _Help => {
                    item_type  => '<StockItem>',
                    callback   => sub { $this->help },
                    extra_data => 'gtk-help',
                },
                _About => {
                    item_type  => '<StockItem>',
                    callback   => sub { $this->about },
                    extra_data => 'gtk-about',
                },
            ],
        },
    ];

    my $menu = $this->[MENU] = Gtk2::Ex::Simple::Menu->new (
        menu_tree        => $menu_tree,
        default_callback => sub { $this->unknown_menu_callback },
    );

    $vbox->pack_start($menu->{widget}, 0,0,0);
    $window->add_accel_group($menu->{accel_group});

    my $marea = $this->[MAREA] = new Gtk2::Image;
    my $scwin = Gtk2::ScrolledWindow->new;
    my $vp    = Gtk2::Viewport->new(undef,undef);
    my $al    = Gtk2::Alignment->new(0.5,0.5,0,0);
    my $eb    = Gtk2::EventBox->new;

    $eb->set_has_tooltip(TRUE);
    $eb->signal_connect( query_tooltip => sub {
        my ($widget, $x, $y, $keyboard_mode, $tooltip) = @_;

        my @cs = split('x', $this->[MAP]{cell_size});
        my @tc = (int($x/$cs[0]), int($y/$cs[1]));

        return FALSE unless $this->[MQ]->_check_loc(\@tc);

        my @o  = $this->[MQ]->objects_at_location(@tc);

        return FALSE unless @o;

        $tooltip->set_text(
            join("\n",
             map { my $d = $_->[0]->desc; my $v = ($_->[1]=~ s/(\d+)$/ $1/ ? $_->[1] : "living"); "$v: $d" }
            sort {$a->[-1] <=> $b->[-1] || $a->[1] cmp $b->[1] }
             map {my $x= [$_, $_->attr('var')]; push @$x, ($x->[1]=~m/^l/?0:1); $x} @o) );

        return TRUE;
    });

    # This is so we can later determin the size of the viewport.
    $this->[VP_DIM] = my $dim = [];
    $vp->signal_connect( size_allocate => sub { my $r = $_[1]; $dim->[0] = $r->width; $dim->[1] = $r->height; 0; });

    my $sb = $this->[STAT] = new Gtk2::Statusbar; $sb->push(1,'');

    my $s_up = sub {
        $sb->pop(1); return unless @_;

        if( not ref $_[0] ) {
            my @c = caller;
            warn "caller=(@c)";
        }

        # @_ is just like $this->[S_ARG], but (stuff) instead of [stuff]

        my $loc   = shift; # so this is (x,y), not a tile object from the actual map
        my $type  = pop @$loc if @$loc == 3;
        my $group = shift;
        my $door  = shift;
        my $txt   = '';

        if( $loc ) {
            $txt .= "tile: " . ($type ? "$type " : ''). sprintf('[%d,%d]', @$loc);
            $txt .= ":$door->[0] (@{$door->[1]})" if $door;
            $txt .= " \x{2014} group: @$group" if $group;

        } else {
            $loc = $group = $door = undef;
        }

        $sb->push(1, $txt);
    };

    $this->[O_LT]=[];

    my $bpe = 0;

    $eb->add_events([qw(leave-notify-mask pointer-motion-mask pointer-motion-hint-mask)]);
    $eb->signal_connect( motion_notify_event => sub { $this->marea_motion_notify_event($s_up, @_); 0; });
    $eb->signal_connect(  leave_notify_event => sub {
        if( $bpe ) {
            $bpe = 0; # bpe prevents the leave_notify once

        } else {
            @{$this->[O_LT]} = (); $s_up->(); $this->draw_map_w_cursor;
        }
    });

    $eb->signal_connect( button_release_event => sub {
        my ($widget, $event) = @_;

        return FALSE if $event->button == 3;
        $this->marea_button_release_event(@_);
    });

    $eb->signal_connect ( button_press_event => sub {
        my ($widget, $event) = @_;

        if( $event->button == 3 ) {
            $bpe = 1; # bpe prevents the leave_notify_event once
            $this->right_click_map($event);

        } else {
            $this->marea_button_press_event(@_);
            $this->double_click_map(@_)
                if $event->type eq '2button-press';

                # tried using >= and * (see Glib under flags), but this
                # seems to return boring strings
        }

        return FALSE; # returning true prevents other events from firing
    });

    $scwin->set_policy('automatic', 'automatic');
    $scwin->add($vp);
    $al->add($eb);
    $vp->add($al);
    $eb->add($marea);
    $vbox->pack_start($scwin,1,1,0);
    $vbox->pack_end($sb,0,0,0);

    if( $ARGV[0] and -f $ARGV[0] ) {
        $this->read_file( $this->[SETTINGS]{LAST_FNAME} = $ARGV[0] );
    }
    $this->draw_map;

    return $this;
}
# }}}
# error {{{
sub error {
    my $this  = shift;
    my $error = shift;

    # The Ex dialogs use Pango Markup Language... pffft
    $error = Glib::Markup::escape_text( $error );

    Gtk2::Ex::Dialogs::ErrorMsg->new_and_run( parent_window=>$this->[WINDOW], text=>$error );
}
# }}}

# FILE MANIPULATION
# open_file {{{
sub open_file {
    my $this = shift;

    my $file_chooser =
        Gtk2::FileChooserDialog->new ('Open a Map File',
            $this->[WINDOW], 'open', 'gtk-cancel' => 'cancel', 'gtk-ok' => 'ok');

    $file_chooser->set_default_response('ok');

    if( $file_chooser->run eq 'ok' ) {
        my $filename = $file_chooser->get_filename;

        $file_chooser->destroy;
        $this->read_file($filename);
        return;
    }

    $file_chooser->destroy;
}
# }}}
# save_file {{{
sub save_file {
    my $this = shift;

    unless( $this->[FNAME] ) {
        $this->save_file_as;
        return;
    }

    my $file   = $this->[FNAME];
    my $pulser = $this->pulser( "Saving $file ...", "File I/O", 175 );
    my $map    = $this->[MAP];
    my %mqo    = (map {("@{$_->[0]}" => $_->[1])} $this->[MQ]->objects_with_locations);
    eval {
        $map->set_exporter( "XML" );
        $map->export( fname => $this->[FNAME], t_cb => sub {
            my (($x,$y), $h) = @_;

            local $" = ",";

            for my $o (@{$mqo{"$x $y"}}) {
                push @{$h->{contents}{item}}, {
                    name=> $o->{v}, unique => ($o->{u}?'true':'false'), qty=> $o->{q}, ($o->{c} ? (id=>$o->{c}) :()),
                    attr=>[
                        map  { {name=>$_->[0], value=>(ref($_->[1]) ? "@{$_->[1]}" : $_->[1])} }
                        map  { [$_, $o->{a}{$_}] }
                        keys %{$o->{a}}
                    ],
                };
            }

            $pulser->();
        });
    };
    $this->error($@) if $@;
    $pulser->('destroy');
}
# }}}
# save_file_as {{{
sub save_file_as {
    my $this = shift;

    my $file_chooser =
        Gtk2::FileChooserDialog->new ('Save a Map File',
            $this->[WINDOW], 'save', 'gtk-cancel' => 'cancel', 'gtk-ok' => 'ok');

    $file_chooser->set_default_response('ok');

    if ('ok' eq $file_chooser->run) {
        my $fname = $file_chooser->get_filename;
           $fname .= ".xml" unless $fname =~ m/\.xml\z/i;

        $this->[FNAME] = $fname;
        $this->[WINDOW]->set_title("GRM Editor: $fname");


        $file_chooser->destroy;
        $this->save_file;

        return;
    }

    $file_chooser->destroy;
}
# }}}
# save_image_as {{{
sub save_image_as {
    my $this = shift;

    my $file_chooser =
        Gtk2::FileChooserDialog->new ('Save a Map Image',
            $this->[WINDOW], 'save', 'gtk-cancel' => 'cancel', 'gtk-ok' => 'ok');

    $file_chooser->set_default_response('ok');

    if ('ok' eq $file_chooser->run) {
        my $fname = $file_chooser->get_filename;
           $fname .= ".png" unless $fname =~ m/\.png\z/i;

        $file_chooser->destroy;

        my $pulser = $this->pulser( "Saving $fname ...", "File I/O", 150 );
        my $map = $this->[MAP];
        eval {
            $map->set_exporter( "PNG" );
            $map->export( fname => $fname, t_cb => $pulser );
        };
        $this->error($@) if $@;
        $pulser->('destroy');

        return;
    }

    $file_chooser->destroy;
}
# }}}
# save_text_as {{{
sub save_text_as {
    my $this = shift;

    my $file_chooser =
        Gtk2::FileChooserDialog->new ('Save a Map Image',
            $this->[WINDOW], 'save', 'gtk-cancel' => 'cancel', 'gtk-ok' => 'ok');

    $file_chooser->set_default_response('ok');

    if ('ok' eq $file_chooser->run) {
        my $fname = $file_chooser->get_filename;
           $fname .= ".txt" unless $fname =~ m/\.txt\z/i;

        $file_chooser->destroy;

        my $pulser = $this->pulser( "Saving $fname ...", "File I/O", 75 );
        my $map = $this->[MAP];
        eval {
            $map->set_exporter( "Text" );
            $map->export( fname=>$fname, nocolor=>1 );
        };
        $this->error($@) if $@;
        $pulser->('destroy');

        return;
    }

    $file_chooser->destroy;
}
# }}}
# read_file (aka load_file) {{{
sub read_file {
    my $this = shift;
    my $file = shift;

    my $pulser = $this->pulser( "Reading $file ...", "File I/O" );
    eval {
        my %mqo;
        $this->[MAP] = my $map = Games::RolePlay::MapGen->import_xml( $file, t_cb => sub {
            if( my ($x,$y, $txp) = @_ ) {

                my $items = $txp->find('contents/item');
                for my $item ($items->get_nodelist) {
                    my $name = $item->findvalue( '@name'   )->value;
                    my $uniq = $item->findvalue( '@unique' )->value;
                    my $qty  = $item->findvalue( '@qty'    )->value;
                    my $id   = $item->findvalue( '@id'     )->value;

                    my $attrs = $item->find('attr');
                    my %a;
                    for my $attr ($attrs->get_nodelist) {
                        my $var = $attr->findvalue( '@name'  )->value;
                        my $val = $attr->findvalue( '@value' )->value;

                        $a{$var} = $val;
                    }

                    my $ob = new Games::RolePlay::MapGen::MapQueue::Object($name);
                       $ob->nonunique($id) unless $uniq and $uniq eq "true";
                       $ob->quantity($qty) if $qty;

                    for my $k (keys %a) {
                        my $v = $a{$k};
                           $v = [ split ",", $v ] if $k eq "color";

                        $ob->attr($k => $v);
                    }

                    push @{$mqo{$x}{$y}}, $ob;
                }
            }

            $pulser->();
        });

        $this->[MQ] = my $mq = new Games::RolePlay::MapGen::MapQueue( $map );
        for my $x (keys %mqo) {
        for my $y (keys %{ $mqo{$x} }) {
        for my $o (@{$mqo{$x}{$y}}) {
            $mq->replace( $o => ($x,$y) );
        }} }
    };
    $this->error($@) if $@;
    $pulser->('destroy');

    $this->[FNAME] = $file;
    $this->[WINDOW]->set_title("GRM Editor: $file");
    $this->draw_map;
}
# }}}
# pulser {{{
sub pulser {
    my $this = shift;
    my $op1  = shift || "Doing something";
    my $op2  = shift || "Something";
    my $cnt  = shift || 25;

    my $dialog = new Gtk2::Dialog;
    my $label  = new Gtk2::Label($op1);
    my $prog   = new Gtk2::ProgressBar;

    $dialog->set_title($op2);
    $dialog->vbox->pack_start( $label, TRUE, TRUE, 0 );
    $dialog->vbox->pack_start( $prog, TRUE, TRUE, 0 );
    $dialog->show_all;

    # NOTE: I'm not sure all these main_interations are necessary as written, 
    # but certainly just doing one isn't enough for some reason.
    Gtk2->main_iteration while Gtk2->events_pending;
    $prog->pulse;
    Gtk2->main_iteration while Gtk2->events_pending;
    Gtk2->main_iteration while Gtk2->events_pending;

    my $x = 0;
    return sub {
        if( ++$x >= $cnt ) {
            Gtk2->main_iteration while Gtk2->events_pending;
            $prog->pulse;
            Gtk2->main_iteration while Gtk2->events_pending;
            $x = 0;
        }

        if( @_ and $_[0] eq "destroy" ) {
            $dialog->destroy;
        }
    };
}
# }}}

# DRAWING 
# draw_mapqueue_objects {{{
sub draw_mapqueue_objects {
    my ($this, $image) = @_;

    my $outline  = $image->colorAllocate(0, 0, 0);

    my @cs = split('x', $this->[MAP]{cell_size});
    my @hs = map {$_ / 2.555555555555} @cs; # humanoid size
    my @of = map {int($_/2)}           @cs; # humanoid offset
    my @is = map {$_ / 3.285714}       @cs; # item size
    my @if = map {$_ / 4.6}            @cs; # item offset

    my %colors;

    for my $owl ($this->[MQ]->objects_with_locations) {
        my ($x, $y, @o) = map {@$_} @$owl;

        $x = $cs[0]*$x + $of[0];
        $y = $cs[1]*$y + $of[1];

        for my $o (@o) {
            my $var = $o->attr('var');
            my $col = $o->attr('color');
            my $icl = $colors{"@$col"};

            unless( defined $icl ) {
                $icl = $colors{"@$col"} = $image->colorAllocate(@$col);
            }

            if( $var =~ m/^l/ ) {
                $image->filledEllipse ( $x, $y, @hs, $icl );
                $image->ellipse       ( $x, $y, @hs, $outline  );

            } elsif( my ($in) = $var =~ m/item(\d+)/ ) {
                my $c  = 2*3.1415926 * ($in/8);
                my $ax = $x + $if[0] * cos $c;
                my $ay = $y + $if[1] * sin $c;

                $image->filledEllipse ( $ax, $ay, @is, $icl );
                $image->ellipse       ( $ax, $ay, @is, $outline );
            }
        }
    }
}
# }}}
# draw_map (initial draw after a new mapload, sets up the MP pixbufs, etc) {{{
sub draw_map {
    my $this = shift;

    my $map = $this->[MAP];
       $map = $this->[MAP] = $this->blank_map unless $map;

    # clear out any selections or cursors that probably nolonger apply
    $this->[SEL_S] = $this->[SEL_E] = $this->[SELECTION] = $this->[O_DR] = $this->[S_ARG] = undef;
    @{$this->[O_LT]}=(); # this clears the pointer whole-tile highlight

    $map->set_exporter( "PNG" );
    my $image = $map->export( -retonly );

    $this->draw_mapqueue_objects( $image );

    my $loader = Gtk2::Gdk::PixbufLoader->new;
       $loader->write($image->png);
       $loader->close;

    my @cs = split('x', $this->[MAP]{cell_size});
    my $gd = new GD::Image(map {$_-1} @cs);
    my $g1 = $gd->colorAllocateAlpha(0x00, 0xbb, 0x00, 0.5*127);
    my $g2 = $gd->colorAllocateAlpha(0x00, 0xff, 0x00, 0.7*127);
    my @wh = $gd->getBounds;

    $gd->filledRectangle( 2,2 => (map {$_-4} @cs), $g2 );

    my $cursor = Gtk2::Gdk::PixbufLoader->new;
       $cursor->write($gd->png);
       $cursor->close;

    $this->[MP] = [ $loader->get_pixbuf, $cursor->get_pixbuf, @cs, @wh ];
    $this->draw_map_w_cursor;
}
# }}}
# draw_map_w_cursor {{{
sub draw_map_w_cursor {
    my $this = shift;
    my $pb = $this->[MP][0];

    if( my @o = (@{ $this->[O_LT] }) ) {
        my ($cb, ($cx,$cy), ($dw,$dh) ) = @{$this->[MP]}[1 .. $#{$this->[MP]}];
        my @ul = ($cx*$o[0]+1, $cy*$o[1]+1);

        my @pm = $pb->render_pixmap_and_mask(0);

        $cb->render_to_drawable_alpha($pm[0], 0,0, @ul, $dw,$dh, full=>255, max=>0,0);

        my ($gc, $cm);
        if( my $s2 = @{$this->[S_ARG]}[2] ) {
            my $cc = Gtk2::Gdk::Color->new( map {65535*($_/0xff)} (0x00, 0xff, 0x00) );

            $gc = Gtk2::Gdk::GC->new($pm[0]);
            ($cm = $gc->get_colormap)->alloc_color($cc, 0, 0);
            $gc->set_foreground($cc);

            my $d  = $s2->[0];
            if( $d eq 'n' ) {
                $pm[0]->draw_rectangle($gc, 1, $ul[0]+4,$ul[1]-2, $cx-9, 3);

            } elsif( $d eq 's' ) {
                $pm[0]->draw_rectangle($gc, 1, $ul[0]+4,$ul[1]+$cy-2, $cx-9, 3);

            } elsif( $d eq 'w' ) {
                $pm[0]->draw_rectangle($gc, 1, $ul[0]-2,$ul[1]+4, 3, $cy-9);

            } elsif( $d eq 'e' ) {
                $pm[0]->draw_rectangle($gc, 1, $ul[0]+$cx-2,$ul[1]+4, 3, $cy-9);
            }

        }

        if( my $sel = $this->[SELECTION] ) {
            my $sc = Gtk2::Gdk::Color->new( map {65535*($_/0xff)} (0x00, 0xff, 0x00) );
            unless( $gc and $cm ) {
                $gc = Gtk2::Gdk::GC->new($pm[0]);
                ($cm = $gc->get_colormap);
            }

            for my $s (@$sel) {
                # NOTE: when we have more than one selection area, we'll
                # probably want to prevent drawing the overlapping part of the
                # rectangles.

                $cm->alloc_color($sc, 0, 0);
                $gc->set_foreground($sc);

                my @s = ($cx*$s->[0], $cy*$s->[1]);
                my @e = ($cx*(1+$s->[2]-$s->[0]),$cy*(1+$s->[3]-$s->[1]));

                $pm[0]->draw_rectangle($gc, 0, @s, @e);
            }
        }

        $this->[MAREA]->set_from_pixmap(@pm);
        return;
    }

    $this->[MAREA]->set_from_pixbuf($pb);
}
# }}}
# double_click_map {{{
sub double_click_map {
    my ($this, $widget, $event) = @_;

    # For some reason, double clicking trips a selection.
    # rather than carefully figuring that out, we'll just clear it.
    $this->[SEL_S] = $this->[SEL_E] = $this->[SELECTION] = undef;

    my @o_lt = @{$this->[O_LT]};
    my $tile = $this->[MAP]{_the_map}[ $o_lt[1] ][ $o_lt[0] ];
    return unless defined $tile->{type};

    if( my $s2 = @{$this->[S_ARG]}[2] ) {
        my $d  = $s2->[0];
        my $od = $tile->{od}{$d};

        if( ref $od ) {
            $this->closure_door_properties( [$tile, $d] );

        } else {
            goto PFFT;
        }

    } else {
        PFFT: $this->edit_items_at_location( $tile, @o_lt );
    }
}
# }}}
# edit_items_at_location {{{
sub edit_items_at_location {
    my ($this, $tile, $x,$y ) = @_;

    my $options = [[ # column 1
        { mnemonic => "_Living: ",
          type     => "text",
          desc     => "the name of the living you wish to add to the map",
          name     => 'lname',
          default  => '' },

        (map(
            { mnemonic => "Item #_$_: ",
              type     => "text",
              desc     => "the name of an item at this location",
              name     => "item$_",
              default  => '' }, 1 .. 8)),
    ],[
        { mnemonic => "unique: ",
          type     => "bool",
          desc     => "whether this living is uniquely named",
          name     => 'ulname',
          disable  => { lname => sub { $_[0] =~ m/^(.+?)\s*\#\s*(\d+)\s*$/ } },
          default  => 1 },

        (map(
            { mnemonic => "unique: ",
              type     => "bool",
              desc     => "whether this living is uniquely named",
              name     => "uitem$_",
              disable  => { "item$_" => sub { $_[0] =~ m/^(.+?)\s*\#\s*(\d+)\s*$/ } },
              default  => 0 }, 1 .. 8)),
    ],[
        { mnemonic => "color: ",
          type     => "color",
          desc     => "the color of the living marker",
          name     => 'clname',
          default  => '#6464ff' },

        (map(
            { mnemonic => "color: ",
              type     => "color",
              desc     => "the color of the item #$_ marker",
              name     => "citem$_",
              default  => '#ffff00' }, 1 .. 8)),
    ]];

    my $i = {};
    my %o_i;
    for my $o ($this->[MQ]->objects_at_location($x,$y)) {
        my $k = $o->attr('var');
        my $c = $o->attr('color');
        my $C = sprintf('#%02x%02x%02x', @$c);

        push @{$o_i{$k}}, $o;
        $i->{$k} = $o->desc;
        $i->{'c' . $k} = $C;
    }

    my ($result, $o) = make_form($this->[WINDOW], $i, $options, "Objects at Location");
    if( $result eq "ok" ) {

        for my $k (grep {!m/^[uc]/} sort keys %$o) {
            if( my $k = delete $o_i{$k} ) {
                $this->[MQ]->remove( $_ ) for @$k;
            }

            my $v = $o->{$k};
            next unless $v =~ m/[\w\d]/;
            $v =~ s/^\s+//;
            $v =~ s/\s+$//;

            my ($n, $c) = $v =~ m/^(.+?)\s*\#\s*(\d+)\s*$/;

            $n = $v unless defined $n;

            my $color  = $o->{'c'.$k};
            my $unique = $o->{'u'.$k};
            my $qty    = $1 if $n =~ s/\s*\(\s*(\d+)\s*\)\s*$//;

            my $ob = new Games::RolePlay::MapGen::MapQueue::Object($n||$v);
               $ob->quantity($qty) if defined $qty;
               $ob->attr(var => $k);
               $ob->attr(color => [ map { hex $_ } $color =~ m/([\d\w]{2})/g ]);

            if( $c ) {
                $ob->nonunique($c);

            } elsif( not $unique ) {
                $ob->nonunique;
            }

            $this->[MQ]->replace( $ob => $x,$y );
        }

        $this->draw_map; # draw the map from scratch with the new objects
    }
}
# }}}
# marea_button_press_event {{{
sub marea_button_press_event {
    my ($this, $ebox, $ebut) = @_;

    my @o_lt = @{ $this->[O_LT] };

    $this->[SEL_S] = \@o_lt if @o_lt == 2;
}
# }}}
# marea_button_release_event {{{
sub marea_button_release_event {
    my ($this, $ebox, $ebut) = @_;

    unless( $this->[SEL_E] ) {
        my @state = $ebut->device->get_state( $this->[MAREA]->get_parent_window );
        my $shift = $state[0] * 'shift-mask'; # see Glib under flags for reasons this makes sense
        if( $shift ) {
            # NOTE: pretend we just selected this one tile with motion, so it adds to the current selection:
            $this->marea_selection_handler( $this->[O_LT], $this->[O_LT], $ebut );

        } else {
            $this->draw_map_w_cursor if delete $this->[SELECTION];
        }
    }

    delete $this->[SEL_S];
    delete $this->[SEL_E];
    delete $this->[SEL_W];

    if( my $s = $this->[SELECTION] ) {
        # NOTE: combine any rectangles that are combinable

        POINTLESS: {
            for my $j (0 .. $#$s) { my $l = $s->[$j];
            for my $i (0 .. $#$s) { my $r = $s->[$i];
                next if $i == $j;

                if( $r->[0]>=$l->[0] and $r->[2]<=$l->[2] ) {
                if( $r->[1]>=$l->[1] and $r->[3]<=$l->[3] ) {
                    splice @$s, $i, 1;
                    redo POINTLESS;
                }}
            }}
        }

        CONTIGUOUS: {
            for my $j (0 .. $#$s) { my $l = $s->[$j];
            for my $i (0 .. $#$s) { my $r = $s->[$i];
                next if $i == $j;

                if( $r->[0]==$l->[0] and $r->[2]==$l->[2] ) {
                    my ($max_min, $min_max) = $l->[1]<$r->[1] ? ($l->[3],$r->[1]) : ($r->[3],$l->[1]);

                    if( $max_min >= $min_max-1 ) {
                        my $min = $r->[1]; $min = $l->[1] if $l->[1] < $min;
                        my $max = $r->[3]; $max = $l->[3] if $l->[3] > $max;

                        splice @$s, $i, 1, [ $l->[0], $min, $l->[2], $max ];
                        splice @$s, $j, 1;

                        goto CONTIGUOUS;
                    }
                }

                if( $r->[1]==$l->[1] and $r->[3]==$l->[3] ) {
                    my ($max_min, $min_max) = $l->[0]<$r->[0] ? ($l->[2],$r->[0]) : ($r->[2],$l->[0]);

                    if( $max_min >= $min_max-1 ) {
                        my $min = $r->[0]; $min = $l->[0] if $l->[0] < $min;
                        my $max = $r->[2]; $max = $l->[2] if $l->[2] > $max;

                        splice @$s, $i, 1, [ $min, $l->[1], $max, $l->[3] ];
                        splice @$s, $j, 1;

                        goto CONTIGUOUS;
                    }
                }

            }}
        }
    }
}
# }}}
# marea_selection_handler {{{
sub marea_selection_handler {
    my ($this, $o_lt, $lt, $event) = @_;
    my $s_sel = $this->[SEL_S];

    my @state = $event->device->get_state( $this->[MAREA]->get_parent_window );
    my $shift = $state[0] * 'shift-mask'; # see Glib under flgas for reasons this makes sense

    $this->[SEL_E] = $lt;

    # 1. TODO: if we're holding control, we should subtract rectangles
    # 2. if we're hodling shift, we should add rectangles

    my $a = [@$s_sel, @$lt];
    my $w = $this->[SEL_W];
    $this->[SEL_W] = $a;

    ($a->[0],$a->[2]) = ($a->[2],$a->[0]) if $a->[2] < $a->[0];
    ($a->[1],$a->[3]) = ($a->[3],$a->[1]) if $a->[3] < $a->[1];

    if( $shift and (my $s = $this->[SELECTION]) ) {
        # NOTE: we don't combine any selections that form contiguous
        # rectangles here since at least one could change shape, destroying
        # the reasons for combining them.  We do it in the button release
        # instead.

        # If we're already working on a selection, take it back off the stack:
        pop @$s if $w and $w == $s->[-1];
        push @$s, $a;

    } else {
        $this->[SELECTION] = [$a];
    }
}
# }}}
# marea_motion_notify_event {{{
sub marea_motion_notify_event {
    my ($this,$s_up,$eb,$em) = @_;

    my ($x, $y) = ($em->x, $em->y);
    my @cs      = split 'x', $this->[MAP]{cell_size};
    my @lt      = (int($x/$cs[0]), int($y/$cs[1]));
    my @bb      = split 'x', $this->[MAP]{bounding_box};

    $lt[0] = $bb[0]-1 if $lt[0]>=$bb[0];
    $lt[1] = $bb[1]-1 if $lt[1]>=$bb[1];

    my $tile = $this->[MAP]{_the_map}[ $lt[1] ][ $lt[0] ];
    my $go   = 0;

    my $o_lt  = $this->[O_LT];
    my $s_arg = $this->[S_ARG];
    if( @$o_lt!=2 or ($lt[0] != $o_lt->[0] or $lt[1] != $o_lt->[1]) ) {
        $this->marea_selection_handler([@$o_lt], [@lt], $em) if $this->[SEL_S];

        @$o_lt = @lt;

        my @s_arg = ([@lt, $tile->{type}]);
           $s_arg = $this->[S_ARG] = \@s_arg;

        $this->[O_DR] = $s_arg->[2] = undef;

        if( my $g = $tile->{group} ) {
            $s_arg->[1] = [$g->name, $g->desc];
        }

        $go = 1;
    }
    
    my $d_x1 = ($x - $cs[0]*$lt[0]);
    my $d_x2 = ($cs[0]*($lt[0]+1) - $x);
    my $d_y1 = ($y - $cs[1]*$lt[1]);
    my $d_y2 = ($cs[1]*($lt[1]+1) - $y);

    my $X = ((my $x1 = $d_x1<=2) or (my $x2 = $d_x2<=2));
    my $Y = ((my $y1 = $d_y1<=2) or (my $y2 = $d_y2<=2));

    my $dr;
    my $o_dr = $this->[O_DR];
    if( $X and not $Y ) {
        if( $x1 ) {
            goto SKIP_DR if $o_dr and $o_dr->[0] eq "w";
            $this->[O_DR] = $dr = [w => $this->_od_desc($tile->{od}{w})];

        } else {
            goto SKIP_DR if $o_dr and $o_dr->[0] eq "e";
            $this->[O_DR] = $dr = [e => $this->_od_desc($tile->{od}{e})];
        }

    } elsif( $Y and not $X ) {
        if( $y1 ) {
            goto SKIP_DR if $o_dr and $o_dr->[0] eq "n";
            $this->[O_DR] = $dr = [n => $this->_od_desc($tile->{od}{n})];

        } else {
            goto SKIP_DR if $o_dr and $o_dr->[0] eq "s";
            $this->[O_DR] = $dr = [s => $this->_od_desc($tile->{od}{s})];
        }
    }

    if( $dr ) {
        $go = 1;
        $s_arg->[2] = $dr;

    } elsif( $o_dr ) {
        $go = 1;
        $this->[O_DR] = $s_arg->[2] = undef;
    }

    SKIP_DR:

    if( $go ) {
        $this->draw_map_w_cursor;
        $s_up->(@$s_arg);
    }
}

sub _od_desc {
    my $that = $_[1];

    if( ref $that ) {
        my $r = [ grep {$that->{$_}} qw(locked stuck secret) ];
        push @$r, "ordinary" unless @$r;
        push @$r, "door";

        return $r;
    }

    return ['opening'] if $that;
    return ['wall'];
}
# }}}

# EDITING COMMANDS
# tileconvert_to_wall_tiles {{{
sub tileconvert_to_wall_tiles {
    my $this = shift;

    # NOTE: The @_ passed to us is prefiltered by our {enable} from the context menu

    my $mq = $this->[MQ];

    for my $tile (@_) {
        $mq->remove( $_ ) for $mq->objects_at_location(@$tile{qw(x y)});

        delete $tile->{group};
        delete $tile->{type};

        for my $d (qw(n e s w)) {
            my $o = $Games::RolePlay::MapGen::opp{$d};

            if( my $n = $tile->{nb}{$d} ) {
                $tile->{od}{$d} = $n->{od}{$o} = 0;
            }
        }
    }

    $this->draw_map;
}
# }}}
# tileconvert_to_corridor_tiles {{{
sub tileconvert_to_corridor_tiles {
    my $this = shift;

    # NOTE: The @_ passed to us is prefiltered by our {enable} from the context menu

    for my $tile (@_) {
        $tile->{type} = "corridor";

        for my $d (qw(n e s w)) {
            my $o = $Games::RolePlay::MapGen::opp{$d};

            if( my $n = $tile->{nb}{$d} ) {
                my $t = $n->{type};

                # Arguably, this should use the map's door settings to drop doors
                # when appropriate... later maybe

                $tile->{od}{$d} = $n->{od}{$o} = 1 if $t and $t eq "corridor";
            }
        }
    }

    $this->draw_map;
}
# }}}

# closureconvert_to_wall {{{
sub closureconvert_to_wall {
    my $this = shift;

    for my $ca (@_) {
        my ($tile, $d) = @$ca;
        my $o = $Games::RolePlay::MapGen::opp{$d};

        $tile->{od}{$d} = $tile->{nb}{$d}{od}{$o} = 0;
    }

    $this->draw_map;
}
# }}}
# closureconvert_to_opening {{{
sub closureconvert_to_opening {
    my $this = shift;

    for my $ca (@_) {
        my ($tile, $d) = @$ca;
        my $o = $Games::RolePlay::MapGen::opp{$d};

        $tile->{od}{$d} = $tile->{nb}{$d}{od}{$o} = 1;
    }

    $this->draw_map;
}
# }}}
# closureconvert_to_door {{{
sub closureconvert_to_door {
    my $this = shift;

    my $minor_dirs = {
        n => [qw(e w)],
        s => [qw(e w)],

        e => [qw(n s)],
        w => [qw(n s)],
    };

    for my $ca (@_) {
        my ($t, $d) = @$ca;
        my $o = $Games::RolePlay::MapGen::opp{$d};
        my $n = $t->{nb}{$d};

        my ($ttype, $ntype) = ($t->{type}, $n->{type});

        if( $ttype eq "room" and $ntype eq "room" ) {
            $ntype = "corridor";
        }

        my $tkey  = ( $t->{od}{$d} ? "open" : "closed" );
           $tkey .= "_" . join("_", reverse sort( $ttype, $ntype ));
           $tkey .= "_door_percent";

        my $chances = $this->[MAP]->{$tkey};

        # NOTE this really only comes up on blank maps before we've loaded the BasicDoors plugin
        $chances = {locked=>0, stuck=>0, secret=>0} unless defined $chances;

        $t->{od}{$d} = $n->{od}{$o} = &_door(
            (map {$_ => ((roll(1, 10000) <= $chances->{$_}*100) ? 1:0) } qw(locked stuck secret)),

            open_dir => {
                major => &choice( $d, $o ),
                minor => &choice( @{$minor_dirs->{$d}} ),
            },
        );
    }

    $this->draw_map;
}
# }}}
# closure_door_properties {{{
sub closure_door_properties {
    my $this = shift;

    my $c = 0;
    for my $ca (@_) {
        my $od = $ca->[0]{od}{$ca->[1]};
        my $i = { %$od };

        $i->{_open_dir_major} = $od->{open_dir}{major};
        $i->{_open_dir_minor} = $od->{open_dir}{minor};

        my $maj = [$ca->[1], $Games::RolePlay::MapGen::opp{$ca->[1]}];
        my $min = {
            n => [qw(e w)],
            s => [qw(e w)],

            e => [qw(n s)],
            w => [qw(n s)],
        }->{$maj->[0]};

        my $options = [[ # column 1
            { mnemonic => "_Open: ",            type => "bool", desc => "is the door open?",   name => 'open' },
            { mnemonic => "_Locked: ",          type => "bool", desc => "is the door locked?", name => 'locked' },
            { mnemonic => "_Secret: ",          type => "bool", desc => "is the door secret?", name => 'secret' },
            { mnemonic => "St_uck: ",           type => "bool", desc => "is the door stuck?",  name => 'stuck'  },
            { mnemonic => "M_ajor Direction: ", type => "choice", choices => $maj, name => '_open_dir_major', desc => "The initial direction of the door swing.", },
            { mnemonic => "M_inor Direction: ", type => "choice", choices => $min, name => '_open_dir_minor', desc => "The final direction of the door swing.",   },
        ]];

        my ($result, $o) = make_form($this->[WINDOW], $i, $options, "Door Properties");
        next unless $result eq "ok";
        $c ++;
        $od->{$_} = $o->{$_} for qw(open locked secret stuck);
        $od->{open_dir}{major} = $o->{_open_dir_major};
        $od->{open_dir}{minor} = $o->{_open_dir_minor};
    }

    $this->draw_map if $c;
}
# }}}

# groupconvert_room_to_corridor {{{
sub groupconvert_room_to_corridor {
    my $this  = shift;
    my $group = shift;
    my $map   = $this->[MAP]{_the_map};

    for my $tilel ($group->enumerate_tiles) {
        my $tile = $map->[ $tilel->[1] ][ $tilel->[0] ];

        warn "WARNING: this group seems to include tiles that aren't in the group"
            unless $group == delete $tile->{group};

        $tile->{type} = "corridor";
    }

    my $groups = $this->[MAP]{_the_groups};
      @$groups = grep {$_!=$group} @$groups;
}
# }}}
# groupconvert_corridor_to_room {{{
sub groupconvert_corridor_to_room {
    my $this   = shift;
    my $map    = $this->[MAP]{_the_map};
    my $groups = $this->[MAP]{_the_groups};

    my $rn = 0;
    for my $g (@$groups) {
        my $n = $g->name;
        my ($x) = $n =~ m/Room #(\d+)/;

        $rn = $x if $x > $rn;
    }

    $rn ++;

    my $group = &_group();
       $group->name( "Room #$rn" );
       $group->type( "room" );

    for my $s (@{ $this->[SELECTION] }) {
        my $loc = [@$s[0,1]];
        my $siz = [1+$s->[2]-$s->[0], 1+$s->[3]-$s->[1]];

        $group->add_rectangle( $loc, $siz );
    }

    push @$groups, $group;

    for my $tile (map {$map->[ $_->[1] ][ $_->[0] ]} $group->enumerate_tiles) {
        $tile->{group} = $group;
        $tile->{type}  = "room";
    }
}
# }}}

# _build_rccm {{{
sub _build_rccm {
    my $this = shift;
    my $map  = $this->[MAP]{_the_map};

    $this->[RCCM][0] = $this->_build_context_menu(
        'convert to w_all tile' => {
            enable => sub { 
                grep { not $_->{group} and $_->{type} }
                map  { $map->[ $_->[1] ][ $_->[0] ] }
                @_
            },
            activate => sub { $this->tileconvert_to_wall_tiles(@{$_[1]{result}}) },
        },
        'convert to _corridor tile' => {
            enable => sub { 
                grep { not $_->{group} and not $_->{type} }
                map  { $map->[ $_->[1] ][ $_->[0] ] }
                @_
            },
            activate => sub { $this->tileconvert_to_corridor_tiles(@{$_[1]{result}}) },
        },
        'convert room to corridor' => {
            enable => sub {
                my @g = grep { $_ }
                         map { $map->[ $_->[1] ][ $_->[0] ]{group} }
                         @_;

                return unless @g == @_;

                my %unique;
                @g = grep { my $r = 0; $unique{0+$_} = $r = 1 unless $unique{0+$_}; $r } @g;

                return unless @g == 1;
                @g;
            },
            activate => sub { $this->groupconvert_room_to_corridor(@{$_[1]{result}}) },
        },
        'convert selection to room' => {
            enable => sub {
                return unless $this->[SELECTION];

                my @a = grep { not $_->{group} and $_->{type} }
                        map  { $map->[ $_->[1] ][ $_->[0] ] }
                        @_;

                @_ == @a ? 1 : 0 # we're not using the return value at all
            },
            activate => sub { $this->groupconvert_corridor_to_room(@{$this->[SELECTION]}) },
        },
        'convert _inside closures to openings' => {
            enable => sub { 
                my $min_x = $_[0][0]; my $max_x = $_[0][0];
                my $min_y = $_[0][1]; my $max_y = $_[0][1];

                grep { my $od = $_->[0]{od}{ $_->[1] };
                    $_->[0]{type} and $_->[0]{nb}{$_->[1]}{type} and (not($od) or ref($od)) }
                map  { [ $map->[ $_->[1] ][ $_->[0] ], $_->[2] ] }
                grep {
                    my $ret = 1;
                    $ret = 0 if $_->[0] == $min_x and $_->[2] eq "w"; # this amounts to check if there exists a {nb}{d}
                    $ret = 0 if $_->[0] == $max_x and $_->[2] eq "e";
                    $ret = 0 if $_->[1] == $min_y and $_->[2] eq "n";
                    $ret = 0 if $_->[1] == $max_y and $_->[2] eq "s";
                    $ret;
                }
                map  {
                    my $l = $_;

                    $min_x = $l->[0] if $l->[0] < $min_x; $max_x = $l->[0] if $l->[0] > $max_x;
                    $min_y = $l->[1] if $l->[1] < $min_y; $max_y = $l->[1] if $l->[1] > $max_y;

                    (map { [@$l, $_] } qw(n e s w))
                }
                @_
            },
            activate => sub { $this->closureconvert_to_opening(@{$_[1]{result}}) },
        },
        'convert _north edge of selection to walls' => {
            enable => sub { 
                return unless $this->[SELECTION];

                my $min_y = $_[0][1];

                grep { $_->[0]{od}{ $_->[1] } } # this amounts to check if there exists an {nb}{d}
                map  { [ $map->[ $_->[1] ][ $_->[0] ], $_->[2] ] }
                grep {
                    my $ret = 0;
                    $ret = 1 if $_->[1] == $min_y;
                    $ret;
                }
                map  {
                    $min_y = $_->[1] if $_->[1] < $min_y;

                    [@$_, 'n']
                }
                @_
            },
            activate => sub { $this->closureconvert_to_wall(@{$_[1]{result}}) },
        },
        'convert _east edge of selection to walls' => {
            enable => sub { 
                return unless $this->[SELECTION];

                my $max_x = $_[0][0];

                grep { $_->[0]{od}{ $_->[1] } }
                map  { [ $map->[ $_->[1] ][ $_->[0] ], $_->[2] ] }
                grep {
                    my $ret = 0;
                    $ret = 1 if $_->[0] == $max_x;
                    $ret;
                }
                map  {
                    $max_x = $_->[0] if $_->[0] > $max_x;

                    [@$_, 'e']
                }
                @_
            },
            activate => sub { $this->closureconvert_to_wall(@{$_[1]{result}}) },
        },
        'convert _south edge of selection to walls' => {
            enable => sub { 
                return unless $this->[SELECTION];

                my $max_y = $_[0][1];

                grep { $_->[0]{od}{ $_->[1] } }
                map  { [ $map->[ $_->[1] ][ $_->[0] ], $_->[2] ] }
                grep {
                    my $ret = 0;
                    $ret = 1 if $_->[1] == $max_y;
                    $ret;
                }
                map  {
                    $max_y = $_->[1] if $_->[1] > $max_y;

                    [@$_, 's']
                }
                @_
            },
            activate => sub { $this->closureconvert_to_wall(@{$_[1]{result}}) },
        },
        'convert _west edge of selection to walls' => {
            enable => sub { 
                return unless $this->[SELECTION];

                my $min_x = $_[0][0];

                grep { $_->[0]{od}{ $_->[1] } }
                map  { [ $map->[ $_->[1] ][ $_->[0] ], $_->[2] ] }
                grep {
                    my $ret = 0;
                    $ret = 1 if $_->[0] == $min_x;
                    $ret;
                }
                map  {
                    $min_x = $_->[0] if $_->[0] < $min_x;

                    [@$_, 'w']
                }
                @_
            },
            activate => sub { $this->closureconvert_to_wall(@{$_[1]{result}}) },
        },
    );

    # NOTE: I'm writing these to later take arrays of closures instead of just singles...
    # but for now, you can only select one closure at a time.
    $this->[RCCM][1] = $this->_build_context_menu(
        'convert to _wall' => {
            enable => sub { 
                map  { [ $_->[0], $_->[-1][-1] ] }
                grep { $_->[1] } # this amounts to checking if there exists an {nb}{d}
                map  { my $t = $map->[ $_->[1] ][ $_->[0] ]; [ $t, $t->{od}{$_->[2]}, $t->{nb}{$_->[2]}, $_ ] }
                grep { @$_ == 3 }
                @_
            },
            activate => sub { $this->closureconvert_to_wall(@{$_[1]{result}}) },
        },
        'convert to _opening' => {
            enable => sub { 
                map  { [ $_->[0], $_->[-1][-1] ] }
                grep { $_->[1] and $_->[0]{type} and $_->[1]{type} and (not($_->[2]) or ref($_->[2])) }
                map  { my $t = $map->[ $_->[1] ][ $_->[0] ]; [ $t, $t->{nb}{$_->[2]}, $t->{od}{$_->[2]}, $_ ] }
                grep { @$_ == 3 }
                @_
            },
            activate => sub { $this->closureconvert_to_opening(@{$_[1]{result}}) },
        },
        'convert to _door' => {
            enable => sub { 
                map  { [ $_->[0], $_->[-1][-1] ] }
                grep { $_->[1] and $_->[0]{type} and $_->[1]{type} and (not($_->[2]) or not ref($_->[2])) }
                map  { my $t = $map->[ $_->[1] ][ $_->[0] ]; [ $t, $t->{nb}{$_->[2]}, $t->{od}{$_->[2]}, $_ ] }
                grep { @$_ == 3 }
                @_
            },
            activate => sub { $this->closureconvert_to_door(@{$_[1]{result}}) },
        },
        'door _properties' => {
            enable => sub { 
                map  { [ $_->[0], $_->[-1][-1] ] }
                grep { ref $_->[1] }
                map  { my $t = $map->[ $_->[1] ][ $_->[0] ]; [ $t, $t->{od}{$_->[2]}, $_ ] }
                grep { @$_ == 3 }
                @_
            },
            activate => sub { $this->closure_door_properties(@{$_[1]{result}}) },
        },
    );
}
# }}}
# _build_context_menu {{{
sub _build_context_menu {
    my $this = shift;
    my $menu = new Gtk2::Menu->new;

    @_ = @{$_[0]} if ref $_[0];

    # TODO: this should become a module like _MForm.pm

    my @a;
    while( my($name, $opts) = splice @_, 0, 2 ) {
        my $item = Gtk2::MenuItem->new_with_mnemonic($name);

        push @a, sub { my @r =  $opts->{enable}->(@_); $item->set_sensitive( $r[-1] ? 1 : 0 ); $opts->{result} = \@r; } if $opts->{enable};
        push @a, sub { my @r = $opts->{disable}->(@_); $item->set_sensitive( $r[-1] ? 0 : 1 ); $opts->{result} = \@r; } if $opts->{disable};

        $item->signal_connect( activate => $opts->{activate}, $opts ) if exists $opts->{activate};
        $menu->append( $item );
    }

    $menu->{_a} = \@a;
    $menu->show_all;
    $menu;
}
# }}}
# right_click_map {{{
sub right_click_map {
    my ($this, $event) = @_;

    my @a;
    if( my $s = $this->[SELECTION] ) {
        my %already;
        for my $r (@$s) {
            for my $x ($r->[0] .. $r->[2]) {
            for my $y ($r->[1] .. $r->[3]) {
                next if $already{$x,$y};
                $already{$x,$y} = push @a, [$x,$y];
            }}
        }

    } else {
        my @b;
        if( my @o = (@{ $this->[O_LT] }) ) {
            if( my $s2 = @{$this->[S_ARG]}[2] ) {
                @b = (@o, $s2->[0]);

            } else {
                @b = @o;
            }

        } else {
            return FALSE;
        }
        @a = (\@b);
    }

    $this->_build_rccm unless $this->[RCCM];

    my @menus = @{ $this->[RCCM] };
    my $menu  = $menus[@{$a[0]}==3 ? 1:0];

    $_->(@a) for @{$menu->{_a}};

    $menu->popup(
            undef, # parent menu shell
            undef, # parent menu item
            undef, # menu pos func
            undef, # data
            $event->button,
            $event->time
    );
}
# }}}

# OPTS AND PREFS
# blank_map {{{
sub blank_map {
    my $this = shift;

    # NOTE: This is just the blank map generator, it has no settings.
    # Later, we'll have a generate_map() that has all kinds of configuations options.

    $this->[FNAME] = undef;
    $this->[WINDOW]->set_title("GRM Editor");

    my $map = $this->[MAP] = new Games::RolePlay::MapGen({
        tile_size    => 10,
        cell_size    => "23x23",
        bounding_box => "25x25",
    });

    $this->[MQ] = new Games::RolePlay::MapGen::MapQueue( $map );

    $map->set_generator("Blank");
    $map->generate; 

    $this->draw_map;

    $map;
}
# }}}
# get_generate_opts {{{
sub get_generate_opts {
    my $this = shift;

    my $i = $this->[SETTINGS]{GENERATE_OPTS};
       $i = thaw $i if $i;
       $i = {} unless $i;

    my $options = [[ # column 1

        { mnemonic => "_Tile Size: ",
          type     => "text",
          desc     => "The size of each tile (in Square Feet or Square Units or whatever)",
          name     => 'tile_size',
          default  => 10, # NOTE: fixes and matches must exist and must be arrrefs
          fixes    => [sub { $_[0] =~ s/\s+//g }],
          matches  => [qr/^\d+$/] },

        { mnemonic => "Cell Size: ",
          type     => "text",
          desc     => "The size of each tile in the image (in pixels)",
          name     => 'cell_size',
          default  => '23x23',
          fixes    => [sub { $_[0] =~ s/\s+//g }],
          matches  => [qr/^\d+x\d+$/] },

        { mnemonic => "Bounding Box: ",
          type     => "text",
          desc     => "The size of the whole map (in tiles)",
          name     => 'bounding_box',
          default  => '20x20',
          fixes    => [sub { $_[0] =~ s/\s+//g }],
          matches  => [qr/^\d+x\d+$/] },

        { mnemonic => "Number of Rooms: ",
          type     => "text",
          desc     => "The number of generated rooms, either a number or a roll (e.g., 2, 2d4, 2d4+2)",
          name     => 'num_rooms',
          default  => '2d4',
          disable  => { generator => sub { $_[0] ne "Basic" } },
          fixes    => [sub { $_[0] =~ s/\s+//g }],
          matches  => [qr/^(?:\d+|\d+d\d+|\d+d\d+[+-]\d+)$/] },

        { mnemonic => "Min Room Size: ",
          type     => "text",
          desc     => "The minimum size of generated rooms (in tiles)",
          name     => 'min_room_size',
          default  => '2x2',
          disable  => { generator => sub { $_[0] ne "Basic" } },
          fixes    => [sub { $_[0] =~ s/\s+//g }],
          matches  => [qr/^\d+x\d+$/] },

        { mnemonic => "Max Room Size: ",
          type     => "text",
          desc     => "The maximum size of generated rooms (in tiles)",
          name     => 'max_room_size',
          default  => '7x7',
          disable  => { generator => sub { $_[0] ne "Basic" } },
          fixes    => [sub { $_[0] =~ s/\s+//g }],
          matches  => [qr/^\d+x\d+$/] },

        { mnemonic => "Open Room-Corridor: ",
          type     => "text",
          desc     => "The %-chance of a door occuring between a room tile and a corridor tile where there is already an opening.  The percentages are listed as a four touple: door-chance, secret, stuck, locked (e.g., 95,2,25,50 means there's a 95% chance of dropping a door, but only 50% that it's locked if we do).",
          name     => 'open_room_corridor_door_percent',
          default  => '95, 2, 25, 50',
          disable  => { generator_plugins => sub { (grep {$_ eq "BasicDoors"} @{$_[0]}) ? 0:1 } },
          convert  => sub { my @a = split m/\D+/, $_[0]; { door=>$a[0], secret=>$a[1], stuck=>$a[2], locked=>$a[3] } },
          trevnoc  => sub { join(", ", @{$_[0]}{qw( door secret stuck locked )}) },
          matches  => [sub { (grep {$_ >= 0 and $_ <= 100} $_[0] =~ m/^(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)$/) == 4 }],
          fixes    => [sub { $_[0] =~ s/[^\d,\s]+//g }], },

        { mnemonic => "Closed Room-Corridor: ",
          type     => "text",
          desc     => "The %-chance of a door occuring between a room tile and a corridor tile where there isn't an opening.  The percentages are listed as a four touple: door-chance, secret, stuck, locked.",
          name     => 'closed_room_corridor_door_percent',
          default  => '5, 95, 10, 30',
          disable  => { generator_plugins => sub { (grep {$_ eq "BasicDoors"} @{$_[0]}) ? 0:1 } },
          convert  => sub { my @a = split m/\D+/, $_[0]; { door=>$a[0], secret=>$a[1], stuck=>$a[2], locked=>$a[3] } },
          trevnoc  => sub { join(", ", @{$_[0]}{qw( door secret stuck locked )}) },
          matches  => [sub { (grep {$_ >= 0 and $_ <= 100} $_[0] =~ m/^(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)$/) == 4 }],
          fixes    => [sub { $_[0] =~ s/[^\d,\s]+//g }], },

        { mnemonic => "Open Corridor-Corridor: ",
          type     => "text",
          desc     => "The %-chance of a door occuring between a corridor tile and a corridor tile where there is already an opening.  The percentages are listed as a four touple: door-chance, secret, stuck, locked.",
          name     => 'open_corridor_corridor_door_percent',
          default  => '1, 10, 25, 50',
          disable  => { generator_plugins => sub { (grep {$_ eq "BasicDoors"} @{$_[0]}) ? 0:1 } },
          convert  => sub { my @a = split m/\D+/, $_[0]; { door=>$a[0], secret=>$a[1], stuck=>$a[2], locked=>$a[3] } },
          trevnoc  => sub { join(", ", @{$_[0]}{qw( door secret stuck locked )}) },
          matches  => [sub { (grep {$_ >= 0 and $_ <= 100} $_[0] =~ m/^(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)$/) == 4 }],
          fixes    => [sub { $_[0] =~ s/[^\d,\s]+//g }], },

        { mnemonic => "Closed Corridor-Corridor: ",
          type     => "text",
          desc     => "The %-chance of a door occuring between a corridor tile and a corridor tile where there isn't an opening.  The percentages are listed as a four touple: door-chance, secret, stuck, locked.",
          name     => 'closed_corridor_corridor_door_percent',
          default  => '1, 95, 10, 30',
          disable  => { generator_plugins => sub { (grep {$_ eq "BasicDoors"} @{$_[0]}) ? 0:1 } },
          convert  => sub { my @a = split m/\D+/, $_[0]; { door=>$a[0], secret=>$a[1], stuck=>$a[2], locked=>$a[3] } },
          trevnoc  => sub { join(", ", @{$_[0]}{qw( door secret stuck locked )}) },
          matches  => [sub { (grep {$_ >= 0 and $_ <= 100} $_[0] =~ m/^(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)$/) == 4 }],
          fixes    => [sub { $_[0] =~ s/[^\d,\s]+//g }], },

        { mnemonic => "Max Span: ", 
          type     => "text",
          desc     => "The door dropper will close spans larger than a single tile in order to drop a door.  This is the maximum sized span that it will close.",
          name     => 'max_span',
          default  => '50',
          disable  => { generator_plugins => sub { (grep {$_ eq "BasicDoors"} @{$_[0]}) ? 0:1 } },
          fixes    => [sub { $_[0] =~ s/\D+//g }], },

    ], [ # column 2

        { mnemonic => "_Generator: ",
          type     => "choice",
          desc     => "The generator used to create the map.",
          descs    => {
              Basic          => 'The basic generator uses perfect/sparseandloops to make a map and then drops rooms onto the result.',
              Perfect        => 'The perfect maze generator James Buck designed.',
              SparseAndLoops => "Pretty much, this is same map generator on James Buck's site.",
              Blank          => "Generates a boring blank map according to your selected bounding box.",
              OneBigRoom     => "Generates a boring giant room the size of your bounding box.",
          },
          name     => 'generator',
          default  => $DEFAULT_GENERATOR,
          choices  => [@GENERATORS] },

        { mnemonic => "Generator _Plugins: ", z=>3,
          type     => "choices",
          desc     => "The plugins you wish to use after the map is created.",
          descs    => {
              BasicDoors => 'Adds doors using various strategies.',
              FiveSplit  => 'Divides map tiles with tiles larger than 5 units square into tiles precisely 5 units square.  E.g., if the tile size is set to 10, this will double the bounding box size of your map, but your hallways will be two tiles wide.',
          },
          name     => 'generator_plugins',
          disable  => { FiveSplit => {tile_size => sub { ($_[0]/5) =~ m/\./ }} },
          defaults => [@DEFAULT_GENERATOR_PLUGINS],
          choices  => [@GENERATOR_PLUGINS] },

        { mnemonic => "_Sparseness: ",
          type     => "text",
          desc     => "The number of times to repeat the remove-dead-end-tile step in James Buck's generator algorithm.",
          name     => 'sparseness',
          default  => 10,
          disable  => { generator => sub { not {Basic=>1, SparseAndLoops=>1}->{$_[0]} } },
          fixes    => [sub { $_[0] =~ s/\s+//g }],
          matches  => [qr/^(?:\d{1,2}|100)$/] },

        { mnemonic => "Same Way Percent:",
          type     => "text",
          desc     => "While digging out the perfect maze, this is the percent chance of digging in the same direction as last time each time we visit the node.",
          name     => 'same_way_percent',
          default  => 90,
          disable  => { generator => sub { not {Basic=>1, Perfect=>1, SparseAndLoops=>1}->{$_[0]} } },
          fixes    => [sub { $_[0] =~ s/\s+//g }],
          matches  => [qr/^(?:\d{1,2}|100)$/] },

        { mnemonic => "Same Node Percent:",
          type     => "text",
          desc     => "While digging out the perfect maze, this is the percent chance of restarting the digging in the same place on each iteration.",
          name     => 'same_node_percent',
          default  => 30,
          disable  => { generator => sub { not {Basic=>1, Perfect=>1, SparseAndLoops=>1}->{$_[0]} } },
          fixes    => [sub { $_[0] =~ s/\s+//g }],
          matches  => [qr/^(?:\d{1,2}|100)$/] },

        { mnemonic => "Remove Dead-End Percent:",
          type     => "text",
          desc     => "Like sparseness but tries harder to remove dead-end corridors completely.",
          name     => 'remove_deadend_percent',
          default  => 60,
          disable  => { generator => sub { not {Basic=>1, SparseAndLoops=>1}->{$_[0]} } },
          fixes    => [sub { $_[0] =~ s/\s+//g }],
          matches  => [qr/^(?:\d{1,2}|100)$/] },

    ]];

    $this->modify_generate_opts_form if $this->can("modify_generate_opts_form");

    my $extra_buttons = [
        ['Defaults', $default_restore_defaults, 'Restore default options'],
        ['Auto BB',  sub {
                my ($button, $reref) = @_;
                my $tile_size  = $reref->{tile_size}[0]{extract} or warn "no code ref?";
                my $cell_size  = $reref->{cell_size}[0]{extract} or warn "no code ref?";
                my $five_split = $reref->{generator_plugins}[0]{extract} or warn "no code ref?";
                my $vp_dim     = $this->[VP_DIM];

                $button->signal_connect( clicked => sub {
                    my $ts = $tile_size->();
                    my $cs = [ split "x", $cell_size->() ];
                    my $fs = grep {$_ eq "FiveSplit"} @{ $five_split->() };

                  # warn dump({
                  #     ts => $ts,
                  #     cs => $cs,
                  #     fs => $fs,
                  #     vp => $vp_dim,
                  # });

                    my $m = ( $fs ? $ts/5 : 1 );
                    my $x = int( $vp_dim->[0] / ($cs->[0]*$m) );
                    my $y = int( $vp_dim->[1] / ($cs->[1]*$m) );

                    $reref->{bounding_box}[1]->set_text( join("x", $x, $y) );
                });
            },
            'Generate a bounding box that will fit in the current window without scrolling.'
        ],
    ];

    my ($result, $o) = make_form($this->[WINDOW], $i, $options, "Generate Map", $extra_buttons);
    if( $result eq "ok" ) {
        # why?
        # $i->{$_} = $o->{$_} for keys %$o;
        # $this->[SETTINGS]{GENERATE_OPTS} = freeze $i;

        $this->[SETTINGS]{GENERATE_OPTS} = freeze $o;
    }

    return ($result, $o);
}
# }}}
# generate {{{
sub generate {
    my $this = shift;

    my ($result, $settings, $generator, @plugins) = $this->get_generate_opts;

    return unless $result eq "ok";

    $this->[FNAME] = undef;
    $this->[WINDOW]->set_title("GRM Editor");

    $generator = delete $settings->{generator};
    @plugins   = @{ delete $settings->{generator_plugins} };

    my $map;
    REDO: {
        my $pulser = $this->pulser( "Generating Map...", "Generating", 150 );
        eval {
            $map = $this->[MAP] = new Games::RolePlay::MapGen;
            $map->set_generator($generator);
            $map->add_generator_plugin( $_ ) for @plugins;
            $map->generate( %$settings, t_cb => $pulser ); 

            $this->[MQ] = new Games::RolePlay::MapGen::MapQueue( $map );
        };

        $pulser->('destroy');
        if( $@ ) {
            $this->error($@);
            return $this->blank_map;
        }

        $this->draw_map;
        Gtk2->main_iteration while Gtk2->events_pending;
        Gtk2->main_iteration while Gtk2->events_pending;
        redo REDO if ask Gtk2::Ex::Dialogs::Question(text=>"Re-generate?", default_yes=>TRUE, parent_window=>$this->[WINDOW]);
    }
    $map;
}
# }}}
# render_settings {{{
sub render_settings {
    my $this = shift;

    my $options = [[
        { mnemonic => "Cell Size: ",
          type     => "text",
          desc     => "The size of each tile in the image (in pixels)",
          name     => 'cell_size',
          default  => '23x23',
          fixes    => [sub { $_[0] =~ s/\s+//g }],
          matches  => [qr/^\d+x\d+$/] },
    ]];

    my $i = $this->[SETTINGS]{GENERATE_OPTS};
       $i = thaw $i if $i;
       $i = {} unless $i;

    my ($result, $o) = make_form($this->[WINDOW], $i, $options, "Render Settings");
    return unless $result eq "ok";

    if($o->{cell_size} ne $i->{cell_size}) {
        $i->{cell_size} = $o->{cell_size};
        $this->[SETTINGS]{GENERATE_OPTS} = freeze $i; # here, we freeze $i because it has many more options than $o
    }

    if($o->{cell_size} ne $this->[MAP]{cell_size}) {
        $this->[MAP]{$_} = $i->{$_} = $o->{$_} for keys %$o;
        $this->draw_map;
    }
}
# }}}
# server_settings {{{
sub server_settings {
    my $this = shift;

    my $options = [[
        { mnemonic => "Enabled: ",
          type     => "bool",
          desc     => "Whether to listen.",
          name     => 'listen',
          default  => $this->[SERVER] ? 1:0,
          matches  => [qr/^\d+$/] },
        { mnemonic => "Server Port: ",
          type     => "text",
          desc     => "The port on which your server runs.",
          name     => 'port',
          default  => '4000',
          matches  => [qr/^\d+$/] },

        # TODO: We'll eventually want the bind port and default url as options
    ]];

    my $i = $this->[SETTINGS]{SERVER_OPTIONS};
       $i = thaw $i if $i;
       $i = {} unless $i;

    my ($result, $o) = make_form($this->[WINDOW], $i, $options, "Server Settings");
    return unless $result eq "ok";

    my $diff = 0;
    for my $k (keys %$o) {
        next if $k eq "listen";
        $diff ++ if $o->{$k} ne $i->{$k};
    }
    my $listen = delete $o->{'listen'};

    $this->[SETTINGS]{SERVER_OPTIONS} = freeze $o if $diff;
    $this->server_control($listen, $o);
}
# }}}
# server_control {{{
sub server_control {
    my ($this, $listen, $o) = @_;

    if( $listen ) {
        my $to_start = 1;
        if( my $s = $this->[SERVER] ) {
            if( $s->[0] ne $o->{port} ) {
                POE::Kernel->call($s->[0]{httpd}, "shutdown");
                $s->[1]->destroy;
                delete $this->[SERVER];

            } else {
                $to_start = 0;
            }
        }

        unless( eval "require Games::RolePlay::MapGen::Editor::_jQuery; 1" ) {
            warn "ERROR loading jquery: $@";
            return;
        }

        if( $to_start ) {
            my $s; $s = $this->[SERVER] = [
                POE::Component::Server::HTTP->new(
                    Port => $o->{port},
                    Headers => { Server => 'GRM Server' },
                    ContentHandler => ({
                        '/'        => sub { $this->http_root_handler($s->[2], @_) },
                        '/jquery/' => sub { $this->http_jquery_handler($s->[2], @_) },
                        })
                ),
                my $w = Gtk2::Window->new('toplevel'),
            ];
          # $w->set_destroy_with_parent(TRUE);
          # $w->set_transient_for($this->[WINDOW]);
            $w->set_title("GRM Server");
            $w->set_size_request(500,200);
            $w->set_position('center');
            $w->add(my $vbox = Gtk2::VBox->new);
            $vbox->add(my $scwin = Gtk2::ScrolledWindow->new); # ($tv->get_focus_hadjustment, $tv->get_focus_vadjustment)
            $scwin->add(my $tv = Gtk2::TextView->new);
            $scwin->set_policy('automatic', 'automatic');

            $tv->set_editable(FALSE);
            $tv->set_wrap_mode("none");
            $tv->set_cursor_visible(FALSE);

            my $b = $tv->get_buffer;
            my $l = sub {
                my $ent = shift;
                   $ent =~ s/[\r\n]/ /g;
                   $ent =~ s/\s{2,}/ /g;
                   $ent .= "\n";

                $tv->scroll_to_iter($b->get_end_iter, FALSE,FALSE, 0,0);
                Gtk2->main_iteration while Gtk2->events_pending;
                $b->insert($b->get_end_iter, localtime() . ": $ent");
            };
            push @$s, $l;

            $l->("server started on port $o->{port}");

            $w->signal_connect( delete_event => sub {
                POE::Kernel->call($s->[0]{httpd}, "shutdown");
                delete $this->[SERVER];
                FALSE; # this apparently can't return true
            });

            my $adder = sub {
                $vbox->add( my $hbox = Gtk2::HBox->new );
                $hbox->add( my $ul = Gtk2::Label->new("Username: ") );
                $hbox->add( my $ue = Gtk2::Entry->new );
                $hbox->add( my $pl = Gtk2::Label->new("Password: ") );
                $hbox->add( my $pe = Gtk2::Entry->new );
                $hbox->add( my $nl = Gtk2::Label->new("Map Name: ") );
                $hbox->add( my $ne = Gtk2::Entry->new );

                $ul->set_tooltip_text( "The users login name." );
                $pl->set_tooltip_text( "The users password (leave blank to accept any string)." );
                $nl->set_tooltip_text( "The name of a unique item on the map to connect with." );
            };

            $adder->();

            $w->show_all;
        }

    } else {
        if( my $s = $this->[SERVER] ) {
            POE::Kernel->call($s->[0]{httpd}, "shutdown");
            $s->[1]->destroy;
            delete $this->[SERVER];
        }
    }
}
# }}}
# preferences {{{
sub preferences {
    my $this = shift;

    my $i = {
        REMEMBER_SP => $this->[SETTINGS]{REMEMBER_SP},
        LOAD_LAST   => $this->[SETTINGS]{LOAD_LAST},
    };

    my $options = [[
        { mnemonic => "Load Last: ",
          type     => "bool",
          desc     => "Re-load the last map when the GRM Editor opens?",
          name     => 'LOAD_LAST',
          default  => 0, },

        { mnemonic => "Remember Size: ",
          type     => "bool",
          desc     => "Remember the Size of your window from the last run?",
          name     => 'REMEMBER_SP',
          default  => 1 },
    ]];

    my ($result, $o) = make_form($this->[WINDOW], $i, $options, "Preferences");
    return unless $result eq "ok";
    $this->[SETTINGS]{$_} = $o->{$_} for keys %$o;
}
# }}}

# SERVER FUNCTIONS
# http_root_handler {{{
sub http_root_handler {
    my ($this, $l, $request, $response) = @_;

    my $uri  = $request->uri; # request is an HTTP::Request (and a little more)
    my $path = $uri->path;    # uri is an URI object

    my @o     = $this->[MQ]->objects;
    my $odump = escapeHTML(dump(\@o));
    my $auth  = $request->header("authorization");

    $l->("request for $path" . ($auth ? " (auth: $auth)" : ""));

    my ($u, $p);
    if( my ($mime) = $auth =~ m/Basic\s*(.+)/ ) {
        if( (my @r = split(/:/, decode_base64($mime), 2)) == 2 ) {
            ($u, $p) = @r;
        }
    }

    if( 0 and ($u and $p) ) {
        $response->code(RC_OK);
        $response->header( content_type => "text/html" );
        $response->content(qq
            <html>
                <head><title>MapGen Server</title><script src='/jquery/'></script></head>
                <body>
                    <p> Hi $u, you fetched $uri authenticated with $p.\n</p>
                    <pre>$odump</pre>
                </body>
            </html>
        );

    } else {
        $response->code(401);
        $response->header( content_type => "text/html", www_authenticate => 'Basic realm="MapGen Server"' );
        $response->content(qq
            <html>
                <head><title>MapGen Server</title>
                <body>
                    <p> 401 Authorization Required.
                    <p> Who are you?
                </body>
            </html>
        );
    }

    return RC_OK;   
}
# }}}
# http_jquery_handler {{{
sub http_jquery_handler {
    my ($this, $l, $request, $response) = @_;

    my $uri  = $request->uri; # request is an HTTP::Request (and a little more)
    my $path = $uri->path;    # uri is an URI object

    $l->("request for $path");

    $response->code(RC_OK);
    $response->header( content_type => "text/javascript" );
    $response->content( Games::RolePlay::MapGen::Editor::_jQuery::as_string() );

    return RC_OK;   
}
# }}}

# MISC
# help {{{
sub help {
    my $this = shift;

    my $search = Pod::Simple::Search->new;
       $search->inc(1);

    my $x = $search->find("Games::RolePlay::MapGen::Editor");
    my $s = { 'Games::RolePlay::MapGen::Editor' => $x };

## DEBUG ## warn "\e[33mINC=\e[m(\e[1;33m@INC\e[m) x=$x";

    my $viewer = Gtk2::Ex::PodViewer->new;
       $viewer->set_db($s); # cuz, do we really need to find THEM ALL?
       $viewer->load('Games::RolePlay::MapGen::Editor');
       $viewer->show;  # see, it's a widget!

    my $vp = Gtk2::Viewport->new(undef,undef);
       $vp->add($viewer);

    my $scwin = Gtk2::ScrolledWindow->new;
       $scwin->set_policy('automatic', 'automatic');
       $scwin->add($vp);

    my $dialog = Gtk2::Dialog->new("GRM Editor Help", $this->[WINDOW], 'destroy-with-parent', 'gtk-ok' => 'ok');
       $dialog->vbox->add($scwin);
       $dialog->set_size_request(600,450);
       $dialog->set_default_response('ok');
       $dialog->show_all;
       $dialog->run;
       $dialog->destroy;
}
# }}}
# about {{{
sub about {
    my $this = shift;

    my $license = "LGPL -- attached to the GRM distribution";
    eval 'use Software::License::LGPL_2_1; $license = (Software::License::LGPL_2_1->new({holder=>"Paul Miller"}))->fulltext';
    warn "error loading license: $@" if $@;

    my $ver = $Games::RolePlay::MapGen::Editor::VERSION;
    my $mer = $Games::RolePlay::MapGen::VERSION;

    Gtk2->show_about_dialog($this->[WINDOW],

        'program-name' => "GRM Editor",
        license        => $license,
        authors        => ['Paul Miller <jettero@cpan.org>'],
        copyright      => 'Copyright (c) 2008 Paul Miller',
        comments       =>
        "This editor is version v$ver.  It is part of the Games::RolePlay::MapGen (GRM)
        Distribution v$mer.  You can use it in your own projrects with few
        restrictions.  Use at your own risk.  Designed for fun.  Have fun.");
}
# }}}
# unknown_menu_callback {{{
sub unknown_menu_callback {
    my $this = shift;

    warn "unknown numeric callback: @_";
}
# }}}
# quit {{{
sub quit {
    my $this = shift;

    my ($w,$h) = $this->[WINDOW]->get_size;
    my ($x,$y) = $this->[WINDOW]->get_position;

    $this->[SETTINGS]{MAIN_SIZE_POS} = freeze [$w,$h,$x,$y];
    $this->[SETTINGS]{LAST_FNAME}    = $this->[FNAME];

    Gtk2->main_quit;
}
# }}}
# warning_handler {{{
sub warning_handler {
    my $this = shift;
    my $err  = shift;

    our $warnings_ignore;
    unless( $warnings_ignore ) {
        my @ignore = (
            qr(Use of uninitialized value in subtraction.*Glib.pm.*line),
        );

        $warnings_ignore = do { local $" = "|"; qr(@ignore) };
    }

    if( $err =~ m/(?:ERROR|WARNING)/ ) {
        $this->error($err);

    } elsif( $err =~ $warnings_ignore ) {
        # ignore

    } else {
       my ($package, $filename, $line, $subroutine, $hasargs,
           $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller 1;

        warn "$err at $filename line $line (in $subroutine)\n";
    }
}
# }}}
# run {{{
sub run {
    my $this = shift;

    local $SIG{__WARN__} = sub { $this->warning_handler(@_) };

    if( $this->[SETTINGS]{REMEMBER_SP} and my $sp = $this->[SETTINGS]{MAIN_SIZE_POS} ) {
        my ($w,$h,$x,$y) = @{thaw $sp};

      # warn "setting window params: ($w,$h,$x,$y)";

        $this->[WINDOW]->resize( $w,$h );
      # $this->[WINDOW]->set_position( $x,$y ); # TODO: this takes single scalars like "center" ... do we really want this anyway?
    }

    $this->[WINDOW]->show_all;

    if( $this->[SETTINGS]{LOAD_LAST} and my $f = $this->[SETTINGS]{LAST_FNAME} ) {
        $this->read_file($f) if -f $f;
    }

    # NOTE: is it smarter to let the POE::Kernel think it's finished and run
    # under Gtk2->main?  or is it smarter to leave the Kernel running and never
    # call the Gtk2->main?  Currently, we let the Kernel finish and run under
    # Gtk2.  So, we create a session that doesn't do anything, letting the
    # session finish, so the POE->run returns and we fall through to the
    # Gtk2->main;

    POE::Session->create(inline_states=>{_start=>sub{}});
    POE::Kernel->run;

    if( "@ARGV" =~ m/server\s*(\d+)?/ ) {
        my $port = $1 || 4000;

        # NOTE: curiously, the above means we let the Kernel finish before we start the server session.
        $this->server_control(1, {port=>$port});
    }

    Gtk2->main;
}
# }}}
