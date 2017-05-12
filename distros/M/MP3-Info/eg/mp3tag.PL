#!perl
use Config;
use File::Basename qw(&basename &dirname);
use Cwd;

$origdir = cwd;
chdir dirname($0);
$file = basename($0, '.PL');
$file .= '.com' if $^O eq 'VMS';

open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
$Config{startperl} -sw-
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';
#-----------------------------------------------------------------#
#  mp3tag.plx
#  pudge
#  
#
#  Created:       Chris Nandor (pudge@pobox.com)       22 Sep 1998
#  Last Modified: Chris Nandor (pudge@pobox.com)       30 Apr 1999
#-----------------------------------------------------------------#
# For obvious reasons, this script works only under MacPerl.
#-----------------------------------------------------------------#
use strict;
use MP3::Info;
use Mac::GetFile;
use Mac::Events;
#-----------------------------------------------------------------#
unless (@ARGV) {
    unless ($ARGV[0] = Mac::GetFile::get_file(
      'Get MP3 Audio File', 0, [qw(MPEG MPG3 SwaT)])) {
        MacPerl::Answer('No file selected.');
        exit;
    }
}

foreach my $file (@ARGV) {
    my($sdlg, $dlg, $win, $tag);
    $sdlg = MyDialog->new();
    $sdlg->start();
    $win = $sdlg->{WIN} = MyWindow->new();
    $tag = $sdlg->{TAG} = get_mp3tag($file) || {};
    $dlg = $sdlg->{DLG} = $sdlg->set_dialog($file);
    $sdlg->dlg_setup();

    while ($dlg->window()) {
        if (defined($win->{WIN})) {
            $win->check_value($dlg);
        }
        WaitNextEvent();
    }

    $win->{WIN}->dispose() if defined($win->{WIN});

    if ($tag->{_dialog_finished}) {
        set_mp3tag($file, $tag);
    }
}
#=================================================================#
package MyWindow;
use Mac::Dialogs;
use Mac::Events;
use Mac::Fonts;
use Mac::Lists;
use Mac::QuickDraw;
use Mac::Windows;
#-----------------------------------------------------------------#
sub new {bless {}, __PACKAGE__}
#-----------------------------------------------------------------#
sub DESTROY {
    my($ref) = @_;
    $ref->{WIN}->dispose() if defined($ref->{WIN});
}
#-----------------------------------------------------------------#
sub set_genre_window {
    my($self, $ref, @genres, $win, $list) = @_;
    @genres = sort @MP3::Info::mp3_genres;

    $win = $self->{WIN};
    $list = $self->{LIST};

    if ($win && $win->window()) {
        SendBehind($ref->{DLG}->window());
        return;
    }

    $win = MacWindow->new(
        Rect->new(500, 50, 650, 350), 'Genres', 1, floatProc(), 1
    );
    $win->sethook(redraw => sub {});
    SetPort($win->window);
    TextFont(3);
    TextSize(9);
    $list = $win->new_list(
        Rect->new(0, 0, 134, 300),
        Rect->new(0, 0, 1, scalar @genres),
        Point->new(0, 0), 0, 1, 1
    );

    $list->sethook(hit=>sub{SendBehind($win->window())});
    $list->sethook(key=>sub{
        my($mod) = $Mac::Events::CurrentEvent->modifiers();
        if ($_[2] == ord("\n")) {
            SendBehind($win->window());
            return;
        } elsif ($_[2] == ord('w') && (($mod & cmdKey()) == cmdKey())) {
            $win->dispose();
            return 1;
        }
        return;
    });

    for (my $c = 0; $c <= $#genres; $c++) {
        $list->set(0, $c, $genres[$c]);
    }

    $self->{WIN} = $win;
    $self->{LIST} = $list;
}
#-----------------------------------------------------------------#
sub check_value {
    my($ref, $dlg, $win, $list, $x, $y) = @_;
    $win = $ref->{WIN};
    $list = $ref->{LIST};
    return if ! defined $list->{'list'};
    $y = LGetSelect(1, Point->new(0,1), $list->{'list'});
    $x = $list->get($y) if defined $y;
    return if ref($x);
    if (defined($x) &&
        (!exists($list->{'_selectdata'}) || $x ne $list->{'_selectdata'})) {
        SetDialogItemText($dlg->window, 15, $list->{'_selectdata'} = $x);
    }
}
#=================================================================#
package MyDialog;
use File::Basename;
use Mac::Dialogs;
use Mac::Events;
use Mac::Fonts;
use Mac::QuickDraw;
use Mac::Menus;
use Mac::Windows;
#-----------------------------------------------------------------#
sub new {bless {}, __PACKAGE__}
#-----------------------------------------------------------------#
sub start {
    my($ref) = @_;
    $ref->do_menus();
}
#-----------------------------------------------------------------#
sub do_menus {
    my($ref, $bar) = @_;
    $ref->{_oldmenu} = GetMenuBar();
    DeleteMenu(130);
    DrawMenuBar();
}
#-----------------------------------------------------------------#
sub DESTROY {
    my($ref) = @_;
    $ref->{DLG}->dispose() if $ref->{DLG};
    SetDialogFont(systemFont());
    $ref->{_editmenu}->dipose() if $ref->{_editmenu};
    SetMenuBar($ref->{_oldmenu}) if $ref->{_oldmenu};
}
#-----------------------------------------------------------------#
sub dlg_setup {
    my($ref, $self) = @_;
    $self = $ref->{DLG};
    $self->sethook(key => sub{_dlg_handle_keys($ref, @_)});
    SetDialogCancelItem ($self->window(), 1);
    SetDialogDefaultItem($self->window(), 2);
    $self->item_hit(1  => \&dlg_cancel);
    $self->item_hit(2  => sub{dlg_ok($self, $ref->{TAG})});
    $self->item_hit(16 => sub{$ref->{WIN}->set_genre_window($ref)});
}
#-----------------------------------------------------------------#
sub _dlg_handle_keys {
    my($ref, $self, $v) = @_;
    my($mod) = $Mac::Events::CurrentEvent->modifiers();
    _dlg_key_handlers($ref, $self, $v, $mod) ? 1 : $self->_dialogselect($v);
}
#-----------------------------------------------------------------#
sub _dlg_key_handlers {
    my($ref, $self, $v, $mod) = @_;

    if (($mod & cmdKey()) == cmdKey()) {
        if ($v == ord('.')) {
            exit;
        } elsif ($v == ord('w')) {
            $self->dispose();
            return 1;
        } elsif ($v == ord('c')) {
            DialogCopy($self->window);
            return 1;
        } elsif ($v == ord('v')) {
            DialogPaste($self->window);
            return 1;
        } elsif ($v == ord('x')) {
            DialogCut($self->window);
            return 1;
        } elsif ($v == ord('a')) {
            SelectDialogItemText($self->window, $self->window->editField() + 1);
            return 1;
        } elsif ($v == ord('g')) {
            $ref->{WIN}->set_genre_window($ref);
            return 1;
        }
    }
    return 0;
}
#-----------------------------------------------------------------#
sub dlg_ok {
    my($self, $tag) = @_;
    my(%dlgs) = (
        TITLE => 5, ARTIST => 7, ALBUM => 9,
        COMMENT => 11, YEAR => 13, GENRE => 17,
        TRACKNUM => 15
    );
    foreach (keys %dlgs) {
        $tag->{$_} = GetDialogItemText($self->window(), $dlgs{$_});
    }
    $tag->{_dialog_finished} = 1;
    $self->dispose();
}
#-----------------------------------------------------------------#
sub dlg_cancel {
    my($self) = @_;
    $self->dispose();
}
#-----------------------------------------------------------------#
sub r ($$$$) {Rect->new(@_)}
#-----------------------------------------------------------------#
sub set_dialog {
    my($ref, $file, $tag) = @_;
    $tag = $ref->{TAG};
    SetDialogFont(geneva());
    MacDialog->new(
      r(50, 50, 460, 300),
      'Set MP3 Values', 1, movableDBoxProc(), 0,

      [kButtonDialogItem,     r(220, 220, 300, 240), 'Cancel'           ],
      [kButtonDialogItem,     r(310, 220, 390, 240), 'OK'               ],

      [kStaticTextDialogItem, r( 10,  10, 390,  25), basename($file)    ],

      [kStaticTextDialogItem, r( 10,  40,  70,  55), 'Title'            ],
      [kEditTextDialogItem,   r( 80,  40, 390,  55), $$tag{TITLE}||''   ],

      [kStaticTextDialogItem, r( 10,  70,  70,  85), 'Artist'           ],
      [kEditTextDialogItem,   r( 80,  70, 390,  85), $$tag{ARTIST}||''  ],

      [kStaticTextDialogItem, r( 10, 100,  70, 115), 'Album'            ],
      [kEditTextDialogItem,   r( 80, 100, 390, 115), $$tag{ALBUM}||''   ],

      [kStaticTextDialogItem, r( 10, 130,  70, 145), 'Comment'          ],
      [kEditTextDialogItem,   r( 80, 130, 390, 145), $$tag{COMMENT}||'' ],

      [kStaticTextDialogItem, r( 10, 160,  70, 175), 'Year'             ],
      [kEditTextDialogItem,   r( 80, 160, 120, 175), $$tag{YEAR}||''    ],

      [kStaticTextDialogItem, r(130, 160, 190, 175), 'Track #'          ],
      [kEditTextDialogItem,   r(200, 160, 240, 175), $$tag{TRACKNUM}||''],

      [kStaticTextDialogItem, r( 10, 190,  70, 205), 'Genre'            ],
      [kEditTextDialogItem,   r( 80, 190, 390, 205), $$tag{GENRE}||''   ],

      [kButtonDialogItem,     r(130, 220, 210, 240), 'Genres'           ],
    );
}
#-----------------------------------------------------------------#
__END__
!NO!SUBS!

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;
