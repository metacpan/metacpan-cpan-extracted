
package GTM;

our $VERSION = "0.6";

use common::sense;

use utf8;
use Gtk2;
use Gtk2::SimpleMenu ();
use AnyEvent;
use AnyEvent::Util;
use File::HomeDir       ();
use Gtk2::Ex::PodViewer ();
use POSIX qw(setsid _exit);

=head1 NAME

GTM - A gui frontend for the GT.M database

=head1 SYNOPSIS

   gtm 

run the gtm frontend

=head1 FILES

   ~/.gtmrc

preferences (you can source it).

=cut

BEGIN {
    use base 'Exporter';
    our @EXPORT_OK = qw(set_busy output %override save_prefs);
    our @EXPORT    = ();
}

use GTM::Run ();

our %override;

our ($gtm_version, $gtm_utf8);
our @gtm_variables = (qw/gtm_dist gtmroutines gtmgbldir gtm_log gtm_chset gtm_icu_version/);

our %win_size;

sub win_size ($$;$$) {
    my ($w, $n, $x, $y) = @_;

    unless (exists $win_size{$n}) {
        $win_size{$n} = [ $x || 960, $y || 600 ];

    }
    $w->signal_connect (
        size_allocate => sub {
            $win_size{$n} = [ $_[1]->width, $_[1]->height ];
        }
    );
    $w->resize (@{$win_size{$n}});

}

my $main_window;

sub error_dialog ($@) {
    my ($parent, @data) = @_;
    my $dialog = new Gtk2::Dialog ("Program Error, \$\@ exception raised.", $parent, 'modal', OK => 42);
    win_size ($dialog, "error_dialog", 670, 320);
    $dialog->set_default_response (42);
    my $sa = new_scrolled_textarea ();
    $sa->set_size_request (660, 300);
    scrollarea_output ($sa, join "", @data);
    $dialog->vbox->add ($sa);
    $dialog->show_all;
    $dialog->run;
    $dialog->destroy;
}

sub gtm_doc ($$) {
    my ($parent, $file) = @_;
    my $dialog = new Gtk2::Dialog ("Documentation", $parent, 'modal', OK => 42);
    $dialog->set_default_response (42);
    my $pod = new Gtk2::Ex::PodViewer;
    my $file = findfile ("GTM/$file");
    $pod->load ($file);
    $pod->set_size_request (660, 620);
    $dialog->vbox->add ($pod);
    $dialog->show_all;
    $dialog->run;
    $dialog->destroy;

}

sub new_scrolled_textarea () {
    my $tv = new Gtk2::TextView;
    my $s  = new Gtk2::ScrolledWindow;
    $s->add                 ($tv);
    $tv->set_editable       (0);
    $tv->set_cursor_visible (0);
    my $buffer = $tv->get_buffer;
    my $end_mark = $buffer->create_mark ('end', $buffer->get_end_iter, 0);
    $s->{end} = $end_mark;
    $s->{tv}  = $tv;
    $s->can_focus  (0);
    $tv->can_focus (0);
    my $font_desc = Gtk2::Pango::FontDescription->from_string ("monospace 10");
    $tv->modify_font ($font_desc);
    $s;
}

sub scrollarea_clear ($) {
    my $s = shift;
    $s->{tv}->set_buffer (new Gtk2::TextBuffer);
    my $buffer = $s->{tv}->get_buffer;
    my $end_mark = $buffer->create_mark ('end', $buffer->get_end_iter, 0);
    $s->{end} = $end_mark;
}

sub scrollarea_output ($@) {
    my ($sa, @d) = @_;
    my $tv    = $sa->{tv};
    my $lines = join "", @d;
    my $buf   = $tv->get_buffer;
    $buf->insert ($buf->get_end_iter, $lines);
    $tv->scroll_to_mark ($sa->{end}, 0, 1, 0, 1);

}

my $rcfile = my_home File::HomeDir . "/.gtmrc";

sub save_prefs () {
    open my $fh, ">", $rcfile
      or do { warn "can't create '$rcfile': $!"; return; };

    while (my ($k, $v) = each %win_size) {
        print $fh "# win=$k w=$v->[0] h=$v->[1]\n";
    }

    while (my ($k, $v) = each %override) {
        $v =~ s/"/\\"/g;
        print $fh "$k=\"$v\"\nexport $k\n\n";
    }
}

sub load_prefs () {
    open my $fh, "<", $rcfile
      or do { warn "can't open '$rcfile': $!"; return; };
    while (my $line = <$fh>) {
        if ($line =~ /^#\s+win=(\w+)\s+w=(\d+)\s+h=(\d+)$/) {
            my ($window, $win_width, $win_height) = ($1, $2, $3);
            $win_size{$window} = [ $win_width, $win_height ];
        }
        if ($line =~ /^(gtm\w+)=\"(.*)\"$/) {
            my ($k, $v) = ($1, $2);
            $v =~ s/\\"/"/g;
            $override{$k} = $v;
        }
    }

}

# as you can see, i don't like xterm :)
#  run update-alternatives --config x-terminal-emulator
#  to set the default terminal type
sub run_console () {
    my $pid = fork;
    return unless $pid == 0;
    local %ENV = (%ENV, %override);
    setsid;
    exec ($_, "-e", "$ENV{gtm_dist}/mumps", "-direct")
      for (
           qw/x-terminal-emulator urxvt
           rxvt-unicode rxvt Eterm
           konsole xterm/
          );

    _exit (0);
}

sub ident_file ($) {
    my $f = shift;
    open my $fh, "<", $f or return;
    sysread $fh, my $buffer, 512;

    # dies ist der header comment UTF-8
    # GT.M 09-FEB-2010 10:17:47

    return ("gtm-globals", $1)
      if (
        $buffer =~ m/ ^ (.*)  \015? \012
                     GT\.M \s+ 
                     \d+ -  [A-Z]{3} - \d{4} \s+
                     \d+ : \d+ : \d+
                  /sx
         );

    # Cache for Windows NT^INT^dies ist die description^~Format=Cache.S~
    # %RO on 08 Feb 2010   4:19 PM

    return ("cac-routines", $1)
      if (
        $buffer =~ m/  ^Cache \s+ for \s+ .*?
                     \^ .*? \^ (.*?) \^
                     .*? \015? \012
                     \% RO \s+ on \s+ \d+
                  /sx
         );

    # dies ist die description~Format=5.S~
    # 08 Feb 2010   4:17 PM   Cache
    return ("cac-globals", $1)
      if (
        $buffer =~ m/(.*?) ~Format= .*? \015? \012 
          \d+ \s+ [A-Z][a-z]{2} \s+ \d{4} \s+
          \d+ : \d+ \s+ (?:AM|PM) \s+ Cache
                   /sx
         );

    return ("msm-globals", $1)
      if (
        $buffer =~ m/  ^\s? \d+ : \d+ \s+ (?:AM|PM)
                      \s+ \d+ \- [A-Z]{3} \- \d+
                      \s+ \(MSM \s+ format \)
                      \015? \012 (.*?) \015? \012
                  /sx
         );

    #  4:22 PM  8-FEB-10
    # dies ist der header comment
    return ("msm-routines", $1)
      if (
        $buffer =~ m/  ^\s? \d+ : \d+ \s+ (?:AM|PM)
                      \s+ \d+ \- [A-Z]{3} \- \d+
                      \015? \012 (.*?) \015? \012
                  /sx
         );

    return;
}

sub gtm_file_chooser ($$$$;$) {
    my ($title, $parent, $action, $cb, $fcb) = @_;

    my $fc =
      Gtk2::FileChooserDialog->new (
                                    $title, $parent, $action,
                                    'gtk-cancel' => 'cancel',
                                    'gtk-ok'     => 'ok',
                                   );
    if ($fcb) {
        my $ff = new Gtk2::FileFilter;
        $ff->add_custom (
            "filename",
            sub {
                my $f = shift->{filename};
                $fcb->($f);
            }
        );
        $fc->add_filter ($ff);
    }
    if ($fc->run eq 'ok') {
        $cb->($fc->get_filename);
    }
    $fc->destroy;

}

sub nice_globals (@) {
    my $line;
    my $o;
    for my $g (@_) {
        if (length ($line) + length ($g) > 78) {
            $o .= "$line\n";
            $line = "";
        }
        $line .= "^$g ";
        $line .= " " while (length ($line) % 10);
    }
    $o .= "$line\n" if length ($line);
    $o;

}

sub gsel_pattern ($$$) {
    my ($ga, $gs, $pat) = @_;
    my %g;

    $g{$_} = 0 for (@$ga);
    $g{$_} = 1 for (@$gs);

    my $sel = 1 - $pat =~ s/^\-//s;

    if ($pat =~ /^([%A-Z][A-Z0-9]*) - ([%A-Z][A-Z0-9]*) /isx) {
        my ($from, $to) = ($1, $2);
        for my $g (@$ga) {
            $g{$g} = $sel if $g ge $from && $g le $to;
        }
    } elsif ($pat =~ m|^/|) {
        if ($pat =~ m|^/invert|) {
            $g{$_} = 1 - $g{$_} for (keys %g);
        }

    } else {
        $pat =~ s/\?/\./sg;
        $pat =~ s/\*/\.\*\?/sg;
        $pat =~ s/[+\{]//sg;
        $pat = "^$pat\$";
        eval {
            for my $g (@$ga)
            {
                $g{$g} = $sel if $g =~ m/$pat/ms;
            }
        };
        warn "invalid pattern: $@" if $@;

    }

    @$gs = ();
    for my $k (sort keys %g) {
        push @$gs, $k if $g{$k};
    }
}

sub gtm_gsel1 (&) {
    my $cb = shift;
    my $lines;
    my @ga;
    gtm_run (
        [qw[ mumps -direct ]],
        ">"  => \$lines,
        "2>" => \$lines,
        "<"  => \"s x=\"^\%\" F  H:x=\"\"  W:\$D(\@x) x,! s x=\$O(\@x)\nH\n",
        cb   => sub {
            push @ga, $1 while ($lines =~ m|^\^(.*)$|gm);
            $cb->(@ga);
        }
    );
}

sub gtm_gsel ($;$$) {
    my ($parent, $cb, $glb) = @_;
    my $on_entry;
    my $dialog = new Gtk2::Dialog (
                                   "Global selector", $parent, 'modal',
                                   'gtk-cancel' => 0,
                                   OK           => 42
                                  );
    win_size ($dialog, "global_selector", 680, 320);
    my ($f0, $f1) = (new Gtk2::Frame (), new Gtk2::Frame ("Selected Globals"));
    $f0->set_border_width (5);
    $f1->set_border_width (5);
    my ($s0, $s1) = (new_scrolled_textarea(), new_scrolled_textarea());
    $s0->set_size_request (660, 300);
    $s1->set_size_request (660, 300);
    my @globals;
    my @selected = @$glb;
    gtm_gsel1 (
        sub {
            @globals = @_;
            scrollarea_output ($s0, nice_globals (@globals));
            $f0->set_label (@globals . " globals available.");
        }
    );

    $f0->add ($s0);
    $f1->add ($s1);
    $dialog->vbox->add ($f0);
    $dialog->vbox->add ($f1);

    my $hb = new Gtk2::HBox;
    my $e  = new Gtk2::Entry;
    $e->signal_connect (
        'activate' => sub {
            $dialog->response (42) unless (length $e->get_text);
            gsel_pattern (\@globals, \@selected, $e->get_text);
            scrollarea_clear ($s1);
            scrollarea_output ($s1, nice_globals (@selected));
            $f1->set_label (@selected . " globals selected");
            $e->set_text   ("");
        }
    );

    if (!$on_entry++ && @selected) {
        scrollarea_output ($s1, nice_globals (@selected)) if @selected;
        $f1->set_label (@selected . " globals selected");
    }

    my $b = new Gtk2::Button ("Global ^");
    $b->signal_connect ('clicked' => sub { gtm_doc ($dialog, "global-selector.pod"); });

    $hb->pack_start ($b, 0, 0, 0);
    $hb->add ($e);

    $dialog->vbox->add ($hb);

    $dialog->set_default_response (42);
    $dialog->set_focus ($e);
    $dialog->show_all;
    if ($dialog->run == 42) {
        @$glb = @selected if $glb;
        $cb->(\@selected) if $cb;
    }
    $dialog->destroy;
}

sub gtm_go_run ($$$$) {
    my ($file, $mode, $hc, $globals) = @_;

    #$override{gtm_icu_version} = "";
    my $h = new GTM::Run ([qw[mumps -direct]]);
    $h->debug (0);
    $mode = "ZWR" unless $mode eq "GO";
    $h->expect (
        qr/GTM\>/,
        qr/^%.*/m,
        sub {
            die $_[1] if $_[2];
            shift->write ("D ^\%GO\n");
        },

        qr/ZGBLDIRACC/m,
        qr/^Global \^/m,
        sub {
            my ($hdl, $data, $idx) = @_;
            unless ($idx) {
                $hdl->write ("\nHalt\n");
                die "global selector $_[1]";
            }
            $hdl->write ("$_\n") for (@$globals);
            $hdl->write ("\n");
        },

        qr/^No globals selected/m,
        qr/^Header Label:/m,
        sub {
            my ($hdl, $data, $idx) = @_;
            if (!$idx) {
                $hdl->write ("\nHalt\n");
                die "no globals selected: $_[1]";
            }
            $hdl->write ("$hc\n");
        },

        qr/ZWR:/, sub { shift->write ("$mode\n"); },

        qr/<terminal>/,
        sub { shift->write ("$file\n"); },
               );

    $h->expect (
        qr/<terminal>/,
        qr/GTM>/,
        qr/.+(?=GTM>)/ms,
        sub {
            my ($hdl, $data, $idx) = @_;
            if (!$idx) {
                $hdl->write ("^\n\nHalt\n");
                die "can't open file \"$file\"";
            }
            if ($idx == 2) {
                output ($data);
            } else {
                $hdl->write ("\nHalt\n");
                $hdl->close;
                return;
            }
        },
    );

}

sub gtm_go ($) {
    my $parent = shift;
    my @g      = ();
    my $dialog = new Gtk2::Dialog (
                                   "Global Output (\%GO)", $parent, 'modal',
                                   'gtk-cancel' => 0,
                                   OK           => 42
                                  );
    $dialog->set_default_response (42);

    my $gsel = new Gtk2::Button ("Global Selector");
    $gsel->signal_connect (
        clicked => sub {
            gtm_gsel (
                $dialog,
                sub {
                    $gsel->set_label (sprintf "Global Selector - %d Globals selected", scalar @{$_[0]});
                },
                \@g
                     );
        }
    );
    my $fe = new Gtk2::Entry;
    my $prog = new Gtk2::Button ("File Selector");
    $prog->signal_connect (
        clicked => sub {
            gtm_file_chooser ("Select output file", $dialog, "save", sub { $fe->set_text ($_[0]); });
        }
    );
    my $box = new_text Gtk2::ComboBox;
    my $hc  = new Gtk2::Entry;
    $box->append_text ($_) for (qw/ZWR GO/);
    $box->set_active (0);

    my $hb0 = new Gtk2::HBox;
    $hb0->add ($fe);
    $hb0->add ($prog);
    my $hb1 = new Gtk2::HBox;
    my $l = new Gtk2::Label ("Header Label: ");
    $hb1->add ($l);
    $hb1->add ($hc);

    $dialog->vbox->add ($gsel);
    $dialog->vbox->add ($hb0);
    $dialog->vbox->add ($box);
    $dialog->vbox->add ($hb1);

    $dialog->show_all;
    if ($dialog->run == 42) {
        my $hc   = $hc->get_text;
        my $file = $fe->get_text;
        my $mode = $box->get_active_text;

        if (@g && length ($file)) {
            eval { gtm_go_run ($file, $mode, $hc, \@g); };
            error_dialog ($dialog, $@) if $@;
        }

    }
    $dialog->destroy;

}

sub gtm_backup () {
    my $dir;
    gtm_file_chooser (
        "Select a target directory",
        $main_window,
        'select-folder',
        sub {
            $dir = $_[0];
            return unless -d $dir;
            gtm_run_out ([ "mupip", "backup", '*', $dir ]);
        },
    );

}

sub rr_msm ($$) {
    my ($file, $dir) = @_;
    open my $fh, "<", $file or do { warn "opening $file: $!\n"; return; };

    my ($lines, $cnt);
    {
        local $/;
        $lines = <$fh>;
        $lines =~ s/\015\012/\012/g;
    }
    while (
        $lines =~ m/ ^ (\%?\w+) $
                    ( .*? \012 ) \012
                  /msgx
          )
    {
        my ($f, $body) = ($1, $2);
        $f =~ s/^\%/_/;
        open my $out, ">", "$dir/$f.m" or die "opening $f.m: $!";
        print $out $body;
        ++$cnt;
        output ("$f\n");
    }
    output ("Restored $cnt files...\n");
}

sub rr_cache ($$) {
    my ($file, $dir) = @_;
    open my $fh, "<", $file or do { warn "opening $file: $!\n"; return; };

    my ($lines, $cnt);
    {
        local $/;
        $lines = <$fh>;
        $lines =~ s/\015\012/\012/g;
    }
    while (
        $lines =~ m/ ^ (\%?\w+) \^ (?:INT|MAC|INC) \^ \d+ \^ \d+ , \d+ \^\d+ $
                  ( .*? \012 ) \012
       /msgx
          )
    {
        my ($f, $body) = ($1, $2);
        $f =~ s/^\%/_/;
        open my $out, ">", "$dir/$f.m" or die "opening $f.m: $!";
        print $out $body;
        ++$cnt;
        output ("$f\n");
    }
    output ("Restored $cnt files...\n");
}

sub gtm_rr ($$) {
    my ($file, $dir) = @_;
    if (!-d $dir) {
        warn "not a directory: \"$dir\"\n";
        return;
    }
    my ($type, $hc) = ident_file ($file);
    unless ($type =~ m/routines$/) {
        warn "$file: unsupported file format\n";
        return;
    }
    output ("Restoring Files from file \"$file\" to directory \"$dir\"\n");
    return $type eq "cac-routines"
      ? rr_cache ($file, $dir)
      : rr_msm ($file, $dir);

}

sub gtm_routine_restore () {

    my $dialog = new Gtk2::Dialog (
                                   "Routine restore", $main_window, 'modal',
                                   'gtk-cancel' => 0,
                                   OK           => 42
                                  );
    $dialog->set_default_response (42);
    my $h0 = new Gtk2::HBox;
    my $h1 = new Gtk2::HBox;
    my $e0 = new Gtk2::Entry;
    my $e1 = new Gtk2::Entry;
    my $b0 = new Gtk2::Button ("choose file");
    my $b1 = new Gtk2::Button ("choose output directory");
    $e0->set_size_request (300, -1);
    $e1->set_size_request (300, -1);
    $b0->set_size_request (200, -1);
    $b1->set_size_request (200, -1);

    $b0->signal_connect (
        "clicked" => sub {
            gtm_file_chooser (
                "Select a MSM \%GS or Cache \%GO file",
                $dialog, 'open',
                sub { $e0->set_text ($_[0]); },
                sub {
                    my ($i) = ident_file ($_[0]);
                    $i =~ m/routines$/;
                }
              ),
              ;
        }
    );
    $b1->signal_connect (
        "clicked" => sub {
            gtm_file_chooser ("Select a target directory", $dialog, 'select-folder', sub { $e1->set_text ($_[0]); },);
        }
    );
    $h0->add ($e0);
    $h1->add ($e1);
    $h0->add ($b0);
    $h1->add ($b1);

    $dialog->vbox->add ($h0);
    $dialog->vbox->add ($h1);
    $dialog->show_all;
    if ($dialog->run == 42) {
        my ($file, $dir) = ($e0->get_text, $e1->get_text);
        gtm_rr ($file, $dir);
    }
    $dialog->destroy;
}

sub filter_output (@) {
    my $lines = join "", @_;
    $lines =~ s/\nGTM\>\n//g;
    output ($lines);
}

sub gtm_gr ($) {
    my $file = shift;
    my ($type) = ident_file ($file);
    if ($type !~ /globals$/) {
        warn "$file: unsupported file format, terminating.\n";
        return;
    }
    open my $fh, "<", $file
      or do { warn "unable to open $file: $!\n"; return; };
    my ($l0, $l1) = (scalar <$fh>, scalar <$fh>);
    my $zwr = 0;
    $zwr = 1 if ($l1 =~ /ZWR$/);
    my $func = $zwr
      ? sub {
        my $l = <$fh>;
        return "Halt\n" if length $l < 3;
        "S $l";
      }
      : sub {
        my ($g, $d) = (scalar <$fh>, scalar <$fh>);
        $g =~ s/\015?\012//g;
        $d =~ s/\015?\012//g;
        $d =~ s/\"/\"\"/g;
        return "Halt\n" if length ($g) < 2 || $g eq "*";
        "S $g=\"$d\"\n";
      };
    gtm_run (
             [qw|mumps -direct|],
             ">"  => sub { filter_output (@_); },
             "2>" => sub { filter_output (@_); },
             "<"  => $func,
             "cb" => sub { output ("Global restore ended.\n"); },
            );

}

sub gtm_global_restore () {
    my $dialog = new Gtk2::Dialog (
                                   "Global restore", $main_window, 'modal',
                                   'gtk-cancel' => 0,
                                   OK           => 42
                                  );
    $dialog->set_default_response (42);
    my $h0 = new Gtk2::HBox;
    my $e0 = new Gtk2::Entry;
    my $b0 = new Gtk2::Button ("choose file");
    $e0->set_size_request (300, -1);
    $b0->set_size_request (200, -1);

    $b0->signal_connect (
        "clicked" => sub {
            gtm_file_chooser (
                "Select a MSM \%GS or Cache \%GO file",
                $dialog, 'open',
                sub { $e0->set_text ($_[0]); },
                sub {
                    my ($i) = ident_file ($_[0]);
                    $i =~ m/globals$/;
                },
            );
        }
    );
    $h0->add ($e0);
    $h0->add ($b0);

    $dialog->vbox->add ($h0);
    $dialog->show_all;
    if ($dialog->run == 42) {
        my $file = $e0->get_text;
        gtm_gr ($file);
    }
    $dialog->destroy;
}

sub about_dialog () {
    show_about_dialog Gtk2 (
        $main_window,
        "program-name" => 'GTM',
        authors        => [ 'Stefan Traby', ],
        license        => "This package is distributed under the same license as perl itself, i.e.\n"
          . "either the Artistic License (COPYING.Artistic) or the GPLv2 (COPYING.GNU).",
        copyright => "(c) 2010 by St.Traby <stefan\@hello-penguin.com>",
        website   => 'http://oesiman.de/gt.m/',
        version   => "v$VERSION",
        comments  => "",

        #                    artists   => [ "Stefan Traby" ],
                           );
    1;
}

sub edit_environment (@) {
    my $dialog = new Gtk2::Dialog (
                                   "Customize environment", $main_window, 'modal',
                                   'gtk-cancel' => 0,
                                   OK           => 42
                                  );
    $dialog->set_default_response (42);
    my @vars = @_;
    my $cnt  = @vars;
    my $t    = new Gtk2::Table ($cnt + 1, 3, 0);
    my $e0   = new Gtk2::Entry;
    my $e1   = new Gtk2::Entry;
    my $e2   = new Gtk2::Entry;
    my $l0   = new Gtk2::Label ("Environment Variable");
    my $l1   = new Gtk2::Label ("Environment Value");
    my $l2   = new Gtk2::Label ("Environment Override");
    $l1->set_size_request (400, -1);
    $l2->set_size_request (400, -1);

    $t->attach_defaults ($l0, 0, 1, 0, 1);
    $t->attach_defaults ($l1, 1, 2, 0, 1);
    $t->attach_defaults ($l2, 2, 3, 0, 1);
    my @entries;
    for my $i (0 .. $cnt - 1) {
        my $env = new Gtk2::Entry;
        $env->set_editable  (0);
        $env->set_text      ($vars[$i]);
        $env->can_focus     (0);
        $t->attach_defaults ($env, 0, 1, $i + 1, $i + 2);

        my $val = new Gtk2::Entry;
        $val->set_editable (0);
        $val->can_focus    (0);
        my $v = $ENV{$vars[$i]};
        unless (exists $ENV{$vars[$i]}) {
            $v = '<<<undef>>>';
            $val->modify_base ('GTK_STATE_NORMAL', new Gtk2::Gdk::Color (65535, 65535, 1000));
        }
        $val->set_text ($v);
        $t->attach_defaults ($val, 1, 2, $i + 1, $i + 2);

        my $e = new Gtk2::Entry;
        my $v = $override{$vars[$i]};
        $e->set_text ($v);
        $t->attach_defaults ($e, 2, 3, $i + 1, $i + 2);
        $entries[$i] = $e;

    }
    $dialog->vbox->add ($t);

    $dialog->show_all;
    if ($dialog->run == 42) {
        for (my $i = 0 ; $i < $cnt ; $i++) {
            my $k = $vars[$i];
            my $v = $entries[$i]->get_text;
            delete $override{$k};
            $override{$k} = $v if length $v;
        }

        get_gtm_version ();
        save_prefs;
    }
    $dialog->destroy;
}

my $menu_tree = [
    _File => {
        item_type => '<Branch>',
        children  => [
            "_Routine Restore" => {
                                   callback    => sub { gtm_routine_restore; },
                                   accelerator => 'F2',
                                  },
            "_Global Restore" => {
                                  callback    => sub { gtm_global_restore; },
                                  accelerator => 'F3',
                                 },
            'Global _Output (%GO)' => {callback => sub { gtm_go ($main_window); },},

            Separator  => {item_type => '<Separator>',},
            "_Console" => {
                           callback    => sub { run_console; },
                           accelerator => '<Alt>C',
                          },
            Separator => {item_type => '<Separator>',},
            E_xit     => {
                      callback    => sub { main_quit Gtk2; },
                      accelerator => '<Alt>X',
                     },
                    ],
             },

    _Variables => {
                   item_type => '<Branch>',
                   children  => [
                       '_Edit all variables' => {callback => sub { edit_environment (@gtm_variables) },},
                       '_Clear all overrides' => {callback => sub { %override = (); save_prefs(); },},
                       Separator => {item_type => '<Separator>',},
                               ],
                  },

    _Database => {
        item_type => '<Branch>',
        children  => [
            '_Integrity check' => {
                                   callback => sub { gtm_integ (); }
                                  },
            '_Rundown' => {
                callback => sub {
                    gtm_rundown ();
                },
                accelerator => '<Alt>R'
                          },
            Separator          => {item_type => '<Separator>',},
            '_Freeze Database' => {
                callback => sub {
                    gtm_freeze (1);
                  }
            },
            '_Thaw Database' => {
                callback => sub {
                    gtm_freeze (0);
                  }
            },
            Separator          => {item_type => '<Separator>',},
            '_Backup Database' => {
                callback => sub {
                    gtm_backup();
                  }
            },

        ],
    },

    _Locks => {
        item_type => '<Branch>',
        children  => [
            'Manage Locks' => {
                callback => sub {
                    gtm_locks ();
                  }
            },
        ],
    },
    _Journal => {
        item_type => '<Branch>',
        children  => [
            '_Enable\/switch Journal' => {
                callback => sub {
                    gtm_journal (1);
                  }
            },
            '_Disable Journal' => {
                callback => sub {
                    gtm_journal (0);
                  }
            }
        ],
    },

    "_?" => {
             item_type => '<Branch>',
             children  => [
                           _About => {
                                      callback    => sub { about_dialog; },
                                      accelerator => 'F1',
                                     }
                         ],
            },

];
for my $x (@gtm_variables) {
    my $y = $x;
    $y =~ s/_/__/g;
    push @{$menu_tree->[3]{children}}, $y => {
                                              callback => sub { edit_environment ($x); }
                                             };
}

#$buffer->signal_connect (insert_text => sub {
#                 $tv->scroll_to_mark($end_mark, 0, 1, 0, 1);
#       }
#       );

my $main_scroll;

sub output {
    my $lines = join "", @_;
    return unless length $lines;
    scrollarea_output ($main_scroll, $lines);
}

sub gtm_run ($@) {
    set_busy (1);
    local %ENV = (%ENV, %override);
    my ($cmd, %rest) = @_;
    if (ref $cmd eq "ARRAY") {
        $cmd->[0] = "$ENV{gtm_dist}/$cmd->[0]" unless $cmd->[0] =~ m@^/@;
    } else {
        $cmd = "$ENV{gtm_dist}/$cmd" unless $cmd =~ m@^/@;
    }
    output "#" x 78 . "\n";
    output "# running: ", ref $cmd eq "ARRAY" ? join " ", @$cmd : $cmd;
    output "\n" . "#" x 78 . "\n";
    my $cv = run_cmd ($cmd, %rest);
    $cv->cb (
        sub {
            shift->recv
              and do { warn "error running cmd: $!\n"; set_busy (0); return; };
            $rest{cb}->() if exists $rest{cb};
            set_busy (0);
        }
    );
}

sub gtm_run_out (@) {
    my ($cmd, %r) = (
                     shift,
                     ">"  => sub { output (@_); },
                     "2>" => sub { output (@_); },
                     @_
                    );
    gtm_run ($cmd, %r);
}

sub get_gtm_version () {
    my $lines;
    gtm_run (
        [qw[ mumps -direct ]],
        ">"  => \$lines,
        "2>" => \$lines,
        "<"  => \"Write \$C(26)_\$ZVersion_\$C(26)_\$ZCHset_\$C(26) Halt\n",
        cb   => sub {
            output ("$lines\n");
            if ($lines =~ m/\x1a([^\x1a]+)\x1a([^\x1a]+)\x1a/ms) {
                $gtm_version = $1;
                $gtm_utf8    = 1;
                $gtm_utf8    = 0 if $2 eq "M";
                $main_window->set_title ("GT.M GUI v$VERSION ($gtm_version) UTF-8=$gtm_utf8");
            }
        }
    );
}

sub gtm_integ () {

    # gtm_run_out ([ qw[ mupip integ -full -noonline -reg * ]]);
    gtm_run_out ([qw[ mupip integ -noonline -reg * ]]);
}

sub gtm_rundown () {
    gtm_run_out ([qw[ mupip rundown /REG=* ]]);
}

sub gtm_freeze ($) {
    if ($_[0]) {
        gtm_run_out ([qw[ mupip freeze -on * ]]);
    } else {
        gtm_run_out ([qw[ mupip freeze -off * ]]);
    }
}

sub gtm_journal ($) {
    if ($_[0]) {
        gtm_run_out ([qw[ mupip SET -JOURNAL=ON,BEFORE_IMAGES -REGION * ]]);
    } else {
        gtm_run_out ([qw[ mupip SET -JOURNAL=OFF -REGION * ]]);
    }
}

sub remove_lock($$$) {
    my ($ref, $pid, $cb) = @_;
    gtm_run (
             [ "lke", "clear", "-pid=$pid", "-lock=$ref", "-nointeractive" ],
             ">"  => sub { output (@_) },
             "2>" => sub { output (@_) },
             $cb ? (cb => $cb) : (),
            );
}

my @buttons;

sub update_locks ($) {
    my $box = shift;
    my $lines;
    my $cv = gtm_run (
        [qw/lke show -all/],
        ">"  => \$lines,
        "2>" => \$lines,
        cb   => sub {
            output ("$lines\n");
            $box->remove ($_) for (@buttons);
            @buttons = ();
            while ($lines =~ m/^(.*)\s+Owned\s+by\s+PID=\s*(\d+)/mg) {
                my ($ref, $pid) = ($1, $2);
                my $b = new Gtk2::Button ("ref=$ref pid=$pid");
                $b->signal_connect (
                    "clicked" => sub {
                        remove_lock ($ref, $pid, sub { update_locks ($box) });
                    }
                );
                push @buttons, $b;
                $box->pack_start ($b, 0, 0, 0);
                $b->show;
            }
        }
    );
}

sub gtm_locks() {
    @buttons = ();
    my $dialog = new Gtk2::Dialog ("Manage Locks", $main_window, 'modal', OK => 42);
    win_size ($dialog, "manage_locks", 200, 200);
    $dialog->set_default_response (42);
    my $button = new Gtk2::Button ("_Refresh");
    my $frame  = new Gtk2::Frame  ("Locks held");
    $frame->set_border_width (5);
    $frame->set_shadow_type  ("etched-out");
    my $vbox = new Gtk2::VBox;
    $frame->add ($vbox);
    $button->signal_connect (clicked => sub { update_locks ($vbox); });
    $dialog->vbox->pack_start ($button, 0, 0, 0);
    $dialog->vbox->pack_start ($frame,  0, 0, 0);
    update_locks ($vbox);
    $dialog->show_all;
    $dialog->run;
    $dialog->destroy;
}

$SIG{__WARN__} = sub { output @_; };

sub findfile {
    my @files = @_;
  file:
    for (@files) {
        for my $prefix (@INC, "/") {
            if (-f "$prefix/$_") {
                $_ = "$prefix/$_";
                next file;
            }
        }
        die "$_: file not found in \@INC\nINC=" . join ("\n", @INC);
    }
    wantarray ? @files : $files[0];
}

our $button;

sub new () {
    my $menu = new Gtk2::SimpleMenu (menu_tree => $menu_tree);
    $main_scroll = new_scrolled_textarea();
    $main_window = new Gtk2::Window ('toplevel');
    $main_window->signal_connect (destroy => sub { main_quit Gtk2; });
    win_size ($main_window, "main_window", 960, 600);
    my $v = new Gtk2::VBox;
    $v->pack_start ($menu->{widget}, 0, 0, 0);
    $v->pack_start ($button,         0, 0, 0);

    $v->add                       ($main_scroll);
    $main_window->add             ($v);
    $main_window->add_accel_group ($menu->{accel_group});
    load_prefs;
    set_busy (0);
    get_gtm_version();
    $main_window;
}

my $was_busy = 1;
my $timer;
my $counter = 0;
my ($red, $green, $off);
$button = new Gtk2::Button;
$green  = new_from_file Gtk2::Image (findfile ("GTM/images/ampel-green.png"));
$red    = new_from_file Gtk2::Image (findfile ("GTM/images/ampel-red.png"));
$off    = new_from_file Gtk2::Image (findfile ("GTM/images/ampel-off.png"));

sub set_busy ($) {
    my $busy = shift;
    return if $was_busy == $busy;
    if ($busy == 0) {
        undef $timer;
        $button->set_image ($green);
    } else {
        $counter = 0;
        $timer = AnyEvent->timer (
            after    => 0,
            interval => .25,
            cb       => sub {
                $button->set_image (++$counter % 2 ? $red : $off);
            }
        );
    }
    $was_busy = $busy;

}

=head1 SEE ALSO

L<GTM::Run>

=head1 AUTHOR

   Stefan Traby <stefan@hello-penguin.com>
   http://oesiman.de/gt.m/

=cut

1;

