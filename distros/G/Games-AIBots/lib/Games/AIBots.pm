# $File: //member/autrijus/AIBots/lib/Games/AIBots.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 692 $ $DateTime: 2002/08/17 09:29:13 $

require 5.005;
package Games::AIBots;
$Games::AIBots::VERSION = '0.03';

use strict;
use integer;
use Games::AIBot;
use File::Glob;

=head1 NAME

Games::AIBots - An improved clone of A.I.Wars in Perl

=head1 VERSION

This document describes version 0.03 of Locale::Maketext::Fuzzy.

=head1 SYNOPSIS

In the command line:

    % aibots			# with Tk, displays the GUI
    % aibots map bot1 bot2... 	# run the game
    % aibots -h			# show help
    
Programatically:

    use Games::AIBots;
    Games::AIBots::init_sound($flag);
    Games::AIBots::init_console();
    # Games::AIBots::init_gui();	# requires Tk
    Games::AIBots::init_arg($map, @bots);
    Games::AIBots::init_map();
    Games::AIBots::do_loop($rounds);

=head1 DESCRIPTION

This module exists exclusively for the purpose of the F<aibots>
script bundled in the distribution.  Please see L<aibots> for
an explanation of the game's mechanics, rules and tips.

=cut

# =====================
# Constants Declaration
# =====================

# Global variables
my ($Console, @Flash, $Top, $Canvas, $DFrame1, $DFrame2, $UFrame,
    $Btn_play, $Btn_stop, $Btn_tempo, $Btn_watch, $Btn_sound, $Btn_about,
    $Lbl_info, $Dlg_about, @Snodes);
my (@Btn_arg, @Arg, @Bots, $Board, $Running, $Tick, $FirstBot, $Watch,
    %Buffer, %Wav, $Sound, $Music, %Mines, %Teamvar, $GUI, $MPlayer, %Flash,
    %Color, %UserCmd, $Continue, $Msglog);
my @Mnu_arg = map {''} (0..9);
use vars qw/$Mask/;

# Game Settings
my ($Max_ammo,     $Max_life,    $Max_fuel)    = (30, 10, 2500);
my ($Vault_ammo,   $Flag_ammo,   $Flag_fuel)   = (20, 30, 350);
my ($Cloak_fuel,   $Cloak_ammo,  $Score_adj)   = (10,  2, 20);
my ($Tick_delay,   $Scan_range,  $Scan_list)   = (
    160, 5, 'space wall fence flag mine vault friend enemy'
);
my ($Cols, $Rows,  $Tile_width,  $Tile_height) = (40, 25, 18, 18);
my $Path = $ENV{'Path_AIBots'} || (__FILE__ =~ /^(.+)\.pm$/ ? $1 : '.');

# Object list
my %Obj = (
    '1' => 'spawn', '2' => 'spawn', '3' => 'spawn', '4' => 'spawn',
    '5' => 'spawn', '6' => 'spawn', '7' => 'spawn', '8' => 'spawn',
    '9' => 'spawn', '@' => 'spawn', '.' => 'space', '#' => 'wall',
    '+' => 'fence', 'P' => 'flag',  'O' => 'mine',  'A' => 'vault',
    '^' => 'bot8',  'v' => 'bot2',  '<' => 'bot4',  '>' => 'bot6',
    'n' => 'bot8c', 'u' => 'bot2c', '[' => 'bot4c', ']' => 'bot6c',
    '*' => 'snode', '=' => 'wall', # '*' => 'marsh',
);

# Damage source table
my ($Verb, $DmgS, $DmgN, $BurnS, $BurnN, $ScrS, $ScrN, $CostF, $CostA) = (0..8);
my %Weapon = (
    'bazookah'  => ['scorched',  60, 90,  6,  9, 300,  500, 300, 10],
    'bazookas'  => ['splashed',  40, 70,  4,  7, 200,  400         ],
    'grenadeh'  => ['shredded',  40, 70,  9, 12, 300,  500, 200,  5],
    'grenades'  => ['splashed',  20, 50,  1,  4, 100,  200         ],
    'vaults'    => ['impacted',  30, 30,  3,  3, 200,  200         ],
    'energyh'   => ['zapped',    10, 10,  0,  0,   0,    0,   0,  0],
    'energys'   => ['zapped',    20, 20,  2,  2, 100,  100         ],
    'destructh' => ['shattered', -1, -1,  0,  0,   0,    0         ],
    'destructs' => ['zapped',    -1, -1,  1,  1,  50,   50         ],
    'mineh'     => ['trapped',   50, 50,  5,  5, 400,  400,   0,  2],
    'flagh'     => ['overloaded',50, 50,  0,  0,   0,    0         ],
    'laserh'    => ['burnt',     20, 50,  2,  5,  80,  200,   0,  1],
);

# Message template
my %Msg = (
    'damage' => "%s is %s by %s %s (%d dmg).",
    'death'  => "%s is killed %s!",
    'hit'    => "%s discovers a %s.",
    'end'    => "*** Game Over ***",
    'winner' => "*** Winner: %s | Team %s ***",
);

my @BG = ( map {substr($_, length($Path) + 6, -4) } <$Path/pics/background*.gif> );
my $BGidx = 0;

$SIG{__DIE__} = $SIG{INT} = sub {$MPlayer->Kill(0) if $MPlayer};

# =======================
# Initialization Routines
# =======================

# $success = init_console();
sub init_console {
    if ($^O eq 'MSWin32') {
        require Win32::Console;
        $Console = Win32::Console->new() or return;
    }
    else {
        require Term::ANSIScreen;
        $Console = Term::ANSIScreen->new() or return;
    }

    %Color = (
        '.' => $main::FG_BROWN,       '#' => $main::FG_LIGHTRED,
        '+' => $main::FG_RED,         'P' => $main::FG_LIGHTMAGENTA,
        'O' => $main::FG_LIGHTBLUE,   'A' => $main::FG_LIGHTGREEN,
        '*' => $main::FG_BLACK,       '=' => $main::FG_LIGHTRED,
    ); 
    $Console->Attr($main::FG_WHITE);
}

# $success = init_gui();
sub init_gui {
    my @lparam = (-background => '#8484ff', -foreground => 'black');

    # toplevel window
    $Top = MainWindow->new(
        -title  => "AI Bots v$Games::AIBots::VERSION",
        -width  => ($Cols + 1) * $Tile_width,
        -height => ($Rows + 1) * $Tile_height,
    );

    $Top->bind('<Destroy>', sub {
        $Running = 0; $MPlayer->Kill(0) if $MPlayer
    });

    $Top->bind('<KeyPress-w>', \&Games::AIBots::btn_watch);
    $Top->bind('<KeyPress-h>', \&Games::AIBots::btn_stop);
    $Top->bind('<KeyPress-s>', \&Games::AIBots::btn_sound);
    $Top->bind('<KeyPress-t>', \&Games::AIBots::btn_tempo);
    $Top->bind('<KeyPress-T>', sub {&Games::AIBots::btn_tempo for (1..2)});
    $Top->bind('<KeyPress-question>', \&Games::AIBots::btn_about);
    $Top->bind('<KeyPress-p>', \&Games::AIBots::btn_play);
    $Top->bind('<KeyPress-q>', sub { eval{ $Top->Close() }; exit });

    # cache pictures
    foreach (<$Path/pics/*.gif>) {
        my $pic = substr($_, length($Path) + 6, -4);
        $Obj{$pic} = $pic;
        $Top->Photo($pic, '-format' => 'gif', '-file' => $_);
    }

    $Dlg_about = $Top->DialogBox(
        @lparam,
        -title => 'Anarchistic Independent Robots',
        -default_button => 'Anarchy!',
        -buttons => ['Anarchy!'],
    );

    $Dlg_about->Label(
        @lparam,
        -text => "AI Bots v$Games::AIBots::VERSION",
        -font => ['helvetica', 32, 'bold']
    )->pack(-side => 'top', -fill => 'x', -expand => 'x');
    $Dlg_about->resizable(0, 0);

    my $frame = $Dlg_about->Frame(@lparam)->pack(-side => 'top', -fill => 'x');

    $frame->Label(
        @lparam,
        -font => ['helvetica', 12, 'bold'],
        -text => "Developed by Autrijus Tang (autrijus\@autrijus.org).\n".
                 "Idea from A.I.Wars (http://www.tacticalneurotics.com/).\n".
                 "This game is free software under the Perl License.\n"
    )->pack(-side => 'right', -expand => 'y');

    # window layout
    $Top->resizable(0, 0);
    $Top->Icon('-image' => 'aibots');

    $DFrame2 = $Top->Frame(@lparam, -bd => 3, -relief => 'ridge')->pack(-side => 'bottom', -fill => 'x');
    $DFrame1 = $Top->Frame(@lparam, -bd => 3, -relief => 'ridge')->pack(-side => 'bottom', -fill => 'x');
    $UFrame  = $Top->Frame(@lparam, -bd => 3, -relief => 'ridge')->pack(-side => 'top',    -fill => 'x');

    my @nparam = (-background => 'black', -foreground => '#8484ff', -activebackground => '#202050', -activeforeground => '#8484ff');

    $Btn_sound = $UFrame->Button(@nparam, -relief => 'ridge',  -image => ($Sound ? 'sound' : 'mute'), -command => \&Games::AIBots::btn_sound, -state => ($Sound ? 'normal' : 'disabled'))->pack(-side => 'right', -padx => 2);
    $Btn_tempo = $UFrame->Button(@nparam, -relief => 'ridge',  -image => 'normal', -command => \&Games::AIBots::btn_tempo)->pack(-side => 'right', -padx => 2);
    $Btn_stop  = $UFrame->Button(@nparam, -relief => 'groove', -image => 'stop',   -command => \&Games::AIBots::btn_stop,  -state => 'disabled')->pack(-side => 'right', -padx => 2);
    $Btn_play  = $UFrame->Button(@nparam, -relief => 'groove', -image => 'play',   -command => \&Games::AIBots::btn_play)->pack(-side => 'right', -padx => 2);

    $Btn_watch = $UFrame->Button(
        @nparam,
        -relief => 'ridge',
        -font => ['helvetica', 10, 'bold'],
        -disabledforeground => '#8484ff',
        -highlightthickness  => 0,
        -borderwidth => 0,
        -bd => 3, -width => 10,
        -command => \&Games::AIBots::btn_watch
    )->pack(-side => 'left', -padx => 2, -ipadx => 0, -ipady => 0);

    $Lbl_info  = $UFrame->Label(-foreground => 'black', -background => '#8484ff', -font => ['Courier', 9, 'bold'], -anchor => 'w')->pack(-side => 'left', -fill => 'x', -expand => 'x', -padx => 2);

    my @bparam = (-background => '#a04444', -font => ['helvetica', 8]);
    $Top->Balloon(@bparam)->attach($Btn_sound, -balloonmsg => "[S]ound");
    $Top->Balloon(@bparam)->attach($Btn_watch, -balloonmsg => "[W]atch");
    $Top->Balloon(@bparam)->attach($Btn_tempo, -balloonmsg => "[T]empo");
    $Top->Balloon(@bparam)->attach($Btn_stop,  -balloonmsg => "[H]alt");
    $Top->Balloon(@bparam)->attach($Btn_play,  -balloonmsg => "[P]lay/Pause");

    $Btn_arg[0] = $DFrame1->Button(
        @nparam,
        -image      => 'wall',
        -relief     => 'ridge',
        -state      => 'normal',
        -command    => sub {
            $BGidx = ($BGidx + 1) % scalar @BG;
            $Canvas->itemconfigure('background', -image => $BG[$BGidx]);
            # return unless $Board;
            # foreach my $y (1..$Rows) {
            #     print "\n", substr($Board, ($y - 1) * $Cols, $Cols);
            # }
            # print "\r";
        }
    )->pack(-side => 'left', -padx => 2);
    $Top->Balloon(@bparam)->attach($Btn_arg[0], -balloonmsg => "Change background");

    $Mnu_arg[0] = $DFrame1->Optionmenu(
        -font => ['helvetica', 9, 'bold'],
        -background => '#a04444',
        -foreground => '#8484ff',
        -variable   => \$Arg[0],
        -options    => ['', map {substr($_, length($Path) + 6, -4)} <$Path/maps/*.map>],
        -command    => sub {
            ding('select');
            init_map() if $GUI and not defined $Running;
            Games::AIBots::init_arg();
        },
    )->pack(-side => 'left');

    # $Mnu_arg[0]->bind('<Enter>', sub {
    #     $Mnu_arg[0]->configure(-options => ['', map {substr($_, length($Path) + 6, -4)} <$Path/maps/*.map>]);
    # });

    $Top->Balloon(@bparam)->attach($Mnu_arg[0], -balloonmsg => "Select Map");

    my @mparam = (-font => ['helvetica', 9],
        -background => '#a04444',
        -foreground => '#8484ff',
        -options => ['', map {substr($_, length($Path) + 6, -4)} <$Path/bots/*.bot>],
        -command => sub {Games::AIBots::init_arg()}
    );

    foreach my $arg (1..9) {
        $Btn_arg[$arg] = ($arg < 5 ? $DFrame1 : $DFrame2)->Button(
            @nparam,
            -image      => 'bot8',
            -relief     => 'ridge',
            -state      => 'disabled',
            -command    => sub {
                ding('select');
                $Watch->{'id'} = $arg;
                Games::AIBots::bot_watch($Bots[$arg-1]);
                ding('toggle');
            }
        )->pack(-side => 'left', -padx => 2);
        $Top->bind("<KeyPress-$arg>", sub {
            $Watch->{'id'} = $arg;
            Games::AIBots::bot_watch($Bots[$arg-1]);
            ding('toggle');
        });

        $Top->Balloon(@bparam)->attach($Btn_arg[$arg], -balloonmsg => "Watch #$arg");

        $Mnu_arg[$arg] = ($arg < 5 ? $DFrame1 : $DFrame2)->Optionmenu(@mparam, -variable => \$Arg[$arg])->pack(-side => 'left');
        $Mnu_arg[$arg]->bind('<Enter>', sub {
            $Mnu_arg[$arg]->configure(-options => ['', map {substr($_, length($Path) + 6, -4)} <$Path/bots/*.bot>]);
        });
        $Top->Balloon(@bparam)->attach($Mnu_arg[$arg], -balloonmsg => "Select #$arg");
    }

    $Btn_about = $DFrame2->Button(
        @nparam,
        -bd => 3, -font => ['helvetica', 10],
        -relief => 'ridge',
        -image => 'anarchy',
        -command => \&Games::AIBots::btn_about,
    )->pack(-side => 'right', -padx => 2);
    $Top->Balloon(@bparam)->attach($Btn_about, -balloonmsg => "About AIBots");

    # board canvas
    $Canvas = $Top->Canvas(
        -width  => ($Cols + 1) * $Tile_width - 6,
        -height => ($Rows + 1) * $Tile_height - 6,
        -relief => 'ridge',
    )->pack(-side => 'top');

    return $GUI = 1;
}

# $success = init_sound($music)
sub init_sound {
    no strict 'subs';
    $Sound = 1;
    return unless ($^O eq 'MSWin32');

    require Win32::Sound;
    require Win32::Process;

    # my $vol = Win32::Sound::Volume();
    # Win32::Sound::Volume("0%");

    foreach (<$Path/wavs/*.wav>) {
        $Wav{substr($_, length($Path) + 6, -4)} = $_;
        # Win32::Sound::Play($_, 1);
    }

    # Win32::Sound::Volume($vol);
    return unless $_[0];

    foreach my $path (split(/;+/, $ENV{'Path'})) {
        $path .= "\\" if substr($path, -1) ne "\\";
        if (-e $path.'mplay32.exe') {
                Win32::Process::Create($MPlayer,
                $path.'mplay32.exe', "mplay32 /play /rewind $Path\\wavs\\aibots.mid",
                0, (NORMAL_PRIORITY_CLASS | CREATE_NO_WINDOW), "."
            );
            $Music = 1;
        }
    }
}

sub init_arg {
    my $sum;

    if (@_) {
        $Arg[$_] = shift(@_) || '' for (0..(scalar @Mnu_arg));
        return;
    }

    for ((2..(scalar @Mnu_arg))) {
        if ($Arg[$_] and !$Arg[$_-1]) {
            $Arg[$_-1] = $Arg[$_];
            $Arg[$_] = '';
        }
    }

    for (1..(scalar @Mnu_arg)) {
        $sum++ if $Arg[$_];
    }

    $Btn_play->configure(-state => (($Arg[0] and ($sum >= 2)) ? 'normal' : 'disabled')) if $GUI;
}

# $botcount = init_game(@bots)
sub init_game {
    @Bots = %Buffer = %Mines = ();
    $Running = $Tick = 0;

    foreach my $file (@Arg[1..$#Arg]) {
        next unless $file;
        my $bot = Games::AIBot->new("$Path/bots/$file.bot");
        push @Bots, $bot;

        $bot->{'id'}       = scalar @Bots;
        $bot->{'name'}     = ucfirst($file);
        $bot->{'pic'}      = lc($file);
        $bot->{'burn'}     = 1;
        $bot->{'score'}    = 0;
        $bot->{'h'}        = int(rand(4) + 1) * 2;
        $bot->{'max_fuel'} = $bot->{'fuel'} = $Max_fuel;
        $bot->{'max_ammo'} = $bot->{'ammo'} = $Max_ammo;
        $bot->{'max_life'} = $bot->{'life'} = $Max_life;
        $bot->{'lastcmd'}  = '';

        @{$bot}{'shield', 'cloak', 'laymine'} = (0,0,0);

        do { @{$bot}{'x', 'y'} = (int(rand($Cols) + 1), int(rand($Rows) + 1)) }
            while (obj_at(@{$bot}{'x', 'y'}) ne ((index($Board, $bot->{'id'}) > -1) ? $bot->{'id'} : (index($Board, '@') > -1) ? '@' : '.'));

        bot_draw($bot);
    }

    if ($GUI) {
        $_->configure(-state => 'disabled', -background => '#8484ff') foreach @Mnu_arg;
        $Btn_watch->configure(-state => 'normal');
        $Btn_arg[$_]->configure(-state => ($Arg[$_] ? 'normal' : 'disabled')) for (1..$#Btn_arg);
    }

    $Board =~ s/[\@\*\d]/./g;
    $FirstBot = int(rand(scalar @Bots));

    @{$Watch}{'x', 'y', 'id'} = @{$Bots[$Mask ? $#Bots : $FirstBot]}{'x', 'y', 'id'};
    obj_draw(@{$Watch}{'x', 'y'}, 'watch', '_watch', 1);
    bot_watch($Bots[$Watch->{'id'}]);

    if ($Console) {
        $Console->Cursor(43, 22);
        $Console->Write('[h]alt [q]uit [s]ound [p]lay/pause');
        $Console->Attr($main::BG_BLUE);
        $Console->Attr($main::FG_YELLOW);
        $Console->Cursor(40, 23);
        $Console->Write('  Autrijus Tang <autrijus@autrijus.org> ');

        $Console->Attr($main::FG_WHITE);
    }
    return scalar @Bots;
}

# $map = init_map($mapname)
sub init_map {
    %Flash = @Snodes = ();
    $Board = '.' x ($Cols * $Rows);

    if ($GUI) {
        $Canvas->delete('all');
        $Canvas->createImage(
            ($Cols + 1) * $Tile_width  / 2,
            ($Rows + 1) * $Tile_height / 2,
            -image => $BG[$BGidx],
            -tag   => 'background',
        );
        $Btn_watch->configure(-state => 'disabled');
        $_->configure(-state => 'disabled') foreach @Btn_arg;
        $Btn_arg[0]->configure(-state => 'normal');
    }
    elsif ($Console) {
        $Console->Cls;
        $Console->Cursor(40, 0);
        $Console->Attr($main::BG_BLUE);
        $Console->Attr($main::FG_YELLOW);
        $Console->Write("           -=[AI Bots v$Games::AIBots::VERSION]=-           ");
        $Console->Attr($main::FG_WHITE);
    }

    return unless $Arg[0];
    init_rndmap($Arg[0]) if $Arg[0] eq 'random';

    open _, "$Path/maps/$Arg[0].map" or die "$!: $Path/maps/$Arg[0].map";
    my $y = 0;
    while (my $line = <_>) {
        chomp $line;
        next if substr($line, 0, 2) eq '# ';

        if ($line =~ /^=background[\s\t]+(.+)/) {
            $Canvas->itemconfigure('background', -image => $1) if $GUI;
        }
        elsif ($line =~ /^=bot(\d)[\s\t]+(.+)/) {
            $Arg[$1] = $2 if -e "$Path/bots/$2.bot";
        }
        elsif ($line =~ /^=snode[\s\t]+(\d+)[\s\t]*,[\s\t]*(\d+)/) {
            push @Snodes, {'x' => $1, 'y' => $2};
            obj_draw($1, $2, '*', '_snode');
        }
        elsif ($line =~ /^=sound[\s\t]+(.+)/) {
            ding($1);
        }
        elsif (length($line) eq $Cols) {
            $y++;
            foreach my $x (1 .. $Cols) {
                my $char = substr($line, $x-1, 1);
                obj_draw($x, $y, $char, ($Obj{$char} =~ /^(?:spawn|snode)/) ? "_$Obj{$char}" : '') if (exists($Obj{$char}));
                push @Snodes, {'x' => $x, 'y' => $y} if $Obj{$char} eq 'snode';
            }
        }
    }
    close _;

    return $Arg[0];
}

# init_rndmap($mapname)
sub init_rndmap {
    my $rnd = 'PAO####+++' . ('.' x 120);

    open _, ">$Path/maps/$_[0].map";
    foreach my $y (1 .. $Rows) {
        foreach my $x (1 .. $Cols) {
            print _ substr($rnd, int(rand(length($rnd))), 1);
        }
        print _ "\n";
    }
    close _;
}

# ===========================================================================
# Button callbacks
# ===========================================================================

sub btn_tempo {
    $Tick_delay = (((sqrt(sqrt($Tick_delay / 10)) + 1) % 3) + 1) ** 4 * 10;
    $Btn_tempo->configure(
        -image => ('slow', 'fast', 'normal')[
            sqrt(sqrt($Tick_delay / 10)) % 3
        ]
    ) if $GUI;

    ding('toggle');
}

sub btn_play {
    (ding('game_begin'), init_map(), init_game()) unless defined($Running);
    $Running = not $Running;

    if ($GUI) {
        $Btn_stop->configure(-state => 'normal');
        $Btn_play->configure(-image => $Running ? 'pause' : 'play');
        $Top->after($Tick_delay / (scalar @Bots), \&Games::AIBots::tick_bot) if $Running;
    }
}

sub btn_stop {
    $Running = 0;
    $Btn_stop->configure(-state => 'disabled') if $GUI;

    $_->{'fuel'} = 0 foreach (@Bots);
    btn_play();
}

sub btn_watch {
    $Watch->{'id'} = ($Watch->{'id'} % scalar @Bots) + 1;
    bot_watch($Bots[$Watch->{'id'}]);

    ding('toggle');
}

sub btn_sound {
    # return unless defined $Sound;

    $Sound = not $Sound;
    $Btn_sound->configure(-image => ($Sound ? 'sound' : 'mute')) if $GUI;

    if ($Sound) {
        init_sound($Music);
    }
    else {
        $MPlayer->Kill(0) if $MPlayer;
    }

    ding('toggle');
}

sub btn_about {
    my $tmp = $Running;

    $Running = 0;
    ding('anarchy');
    $Dlg_about->Show();
    if ($Running = $tmp) {
        $Running = 0;
        btn_play();
    }
}

# ===========================================================================
# Drawing routines
# ===========================================================================

sub obj_draw {
    my ($x, $y, $type, $tag, $flash, $step) = @_;

    if ($GUI) {
        $Canvas->createImage(
            ($x * $Tile_width), ($y * $Tile_height),
            '-image'  => $Obj{$type},
            '-tags'   => [$type.($step || ''), $tag || "$x:$y"],
        ) if (defined($Obj{$type}) and $Obj{$type} ne 'space' and $type ne '=');
    }

    obj_set($x, $y, $type, $flash);
}

sub obj_erase {
    my ($x, $y) = @_;

    $Canvas->delete("$x:$y") if $GUI;
    obj_set($x, $y, '.');
}

sub obj_at {
    my ($x, $y) = @_ or return;
    return '=' if $x < 1 or $y < 1 or $x > $Cols or $y > $Rows;
    return substr($Board, ($y - 1) * $Cols + $x - 1, 1);
}

sub obj_flash {
    my ($obj, $x, $y, $step) = @_;
    $obj .= $step if $step;

    ding('flash', $obj);

    if ($GUI and $Top->state eq 'normal') {
        if (exists($Flash{$obj})) {
            $Canvas->itemconfigure($obj, -state => 'normal');
            obj_move(@{$Flash{$obj}}, $x, $y, $_[0], $obj, 1);
        }
        else {
            obj_draw($x, $y, $_[0], '_flash', 1, $_[3]);
        }
        $Flash{$obj} = [$x, $y];
    }
}

sub obj_move {
    my ($ox, $oy, $nx, $ny, $obj, $tag, $flash, $onwatch) = @_;

    if (!$flash) {
        if ($Mask and $onwatch) {
            local $Mask;
            obj_set($ox, $oy, '.') unless obj_at($ox, $oy) eq 'O';
        }
        else {
            obj_set($ox, $oy, '.') unless obj_at($ox, $oy) eq 'O';
        }

        if ($Console and $onwatch) {
            $Console->Attr($main::FG_LIGHTCYAN);
            obj_set($nx, $ny, $obj);
            $Console->Attr($main::FG_WHITE);
        }
        else {
            bot_fill($Bots[-1]) unless !$Mask or $Bots[-1]{dead};
            obj_set($nx, $ny, $obj);
        }
    }

    $Canvas->move($tag, ($nx-$ox) * $Tile_width, ($ny-$oy) * $Tile_height)
        unless (!$GUI or $nx == $ox and $ny == $oy);

    if (!$Buffer{$tag} or $Buffer{$tag} ne $Obj{$obj}) {
        $Canvas->itemconfigure($tag, '-image'  => $Obj{$obj}) if $GUI;
        $Buffer{$tag} = $Obj{$obj};
    }
}

sub obj_set {
    my ($x, $y, $obj, $flash) = @_;

    if ($flash) {
        push @Flash, ($x, $y, obj_at($x, $y));
    }
    else {
        substr($Board, ($y - 1) * $Cols + $x - 1, 1) = $obj unless $flash;
    }

    if ($Console) {
        if ($Mask) {
            my $bot = $Bots[$Watch->{id}-1];
            return if $Obj{$obj} eq 'flag' or $Obj{$obj} eq 'mine';
            return unless 
            ($x == $bot->{x}        and $y == $bot->{y})        or
            ($x == $bot->{enemy_x}  and $y == $bot->{enemy_y})  or
            ($x == $bot->{friend_x} and $y == $bot->{friend_y}) or 
            ($x == $bot->{bumped_x} and $y == $bot->{bumped_y});
        }

        $Console->Cursor($x - 1, $y - 1, 0, 0);
        $Console->Attr($Color{$obj}) if exists($Color{$obj});
        $Console->Write($flash ? ' ' : $Obj{$obj} eq 'spawn' ? '.' : $obj);
        $Console->Attr($main::FG_WHITE) if exists($Color{$obj});
    }
}

# ============
# Bot Handling
# ============

sub bot_draw {
    my $bot = shift;

    obj_draw(@{$bot}{'x', 'y'}, bot_char($bot), "_bot$bot->{'id'}");
    obj_draw(@{$bot}{'x', 'y'}, ($bot->{'shield'} ? 'shield' : 'noshield'), "_bots$bot->{'id'}", 1);
}

sub bot_char {
    my $bot = shift;
    my $obj = $bot->{'h'} . ($bot->{'cloak'} ? 'c' : '');
    my $char = ($bot->{'cloak'} ? qw/n ] u [/ : qw/^ > v </)[index('8624', $bot->{'h'})];
    $Obj{$char} = $Obj{$bot->{'pic'}.$obj} || "bot$obj";

    return $char;
}

sub bot_at {
    my ($x, $y) = @_;

    foreach my $bot (@Bots) {
        next if $bot->{'dead'};
        return $bot if ($bot->{'x'} == $x and $bot->{'y'} == $y);
    }
}

sub bot_id {
    my $bot = shift or return;
    return join('-', @{$bot}{'name', 'id'});
}

sub bot_watch {
    my $bot = shift;
    return unless $bot and ($bot->{'id'} == $Watch->{'id'} or $Console);

    obj_move(@{$Watch}{'x', 'y'}, @{$bot}{'x', 'y'}, 'watch', '_watch', 1);

    my $msg = sprintf("Score:%d Ammo:%d Life:%d Fuel:%d [%s]", @{$bot}{qw/score ammo life fuel lastcmd/});

    if ($GUI and !@_) {
        $Btn_watch->configure(-text => bot_id($bot));
        $Lbl_info->configure(-text => $msg);
    }
    else {
        $msg = '{'.bot_id($bot).'} '.$msg;
        if ($Console) {
            return if $Mask;

            if ($bot->{'id'} == $Watch->{'id'}) {
                $Console->Attr($main::FG_LIGHTCYAN);
            }

            $Console->Cursor(40, $bot->{'id'} * (4 - int((scalar @Bots) / 3)));
            $Console->Write(substr($msg, 0, index($msg, ' Fuel')).(' ' x
            (40 - index($msg, ' Fuel'))));
            $Console->Cursor(42, 1 + $bot->{'id'} * (4 - int((scalar @Bots) / 3)));
            $Console->Write(substr($msg, index($msg, 'Fuel')).(' ' x (70 - length($msg))));
            $Console->Attr($main::FG_WHITE);
        }
        else {
            print $msg, (' ' x (79 - length($msg))), "\r";
        }
    }

    @{$Watch}{'x', 'y'} = @{$bot}{'x', 'y'};
}

sub bot_fill {
    my $bot = shift;

    @{$bot}{qw/enemy_x  enemy_y  enemy_h  enemy_l
               snode_x  snode_y
               friend_x friend_y friend_h friend_l botcount/} = ();

    foreach my $other (@Bots) {
        next if $other->{'dead'};
        $bot->{'botcount'}++;
        next if $other->{'id'} == $bot->{'id'} or $other->{'cloak'};

        my $rel = bot_scan($bot, @{$other}{'x', 'y'});

        if ($bot->_nearst($rel) > $bot->_distance(@{$other}{'x', 'y'})) {
            @{$bot}{"${rel}_x", "${rel}_y", "${rel}_h", "${rel}_l"}
                = @{$other}{qw/x y h life/};
        }
    }

    foreach my $snode (@Snodes) {
        if ($bot->_nearst('snode') > $bot->_distance(@{$snode}{'x', 'y'})) {
            @{$bot}{'snode_x', 'snode_y'} = @{$snode}{'x', 'y'};
        }
    }

    if ($bot->_onnode()) {
        $bot->{'fuel'}++ if $bot->{'fuel'} < $Max_fuel and !(($Tick / scalar @Bots) % 5);
        $bot->{'ammo'}++ if $bot->{'ammo'} < $Max_ammo and !(($Tick / scalar @Bots) % 10);
        $bot->{'life'}++ if $bot->{'life'} < $Max_life and !(($Tick / scalar @Bots) % 15);
    }

    return $bot;
}

sub bot_damage {
    my ($bot, $type, $owner, $adj) = @_;
    return if $bot->{'dead'}; # no good whipping a dead horse

    $type .= 'h' unless exists($Weapon{$type});
    my $dmg = $Weapon{$type}[$bot->{'shield'} ? $DmgS : $DmgN] * $Max_life / 100 + ($adj || 0);

    return unless $dmg > 0;

    display('damage', bot_id($bot), $Weapon{$type}[$Verb], ($owner ? bot_id($owner)."'s" : 'a'), substr($type, 0, -1), $dmg);

    $bot->{'life'}    -= $dmg;
    $bot->{'burn'}    += $Weapon{$type}[$bot->{'shield'} ? $BurnS : $BurnN];
    $owner->{'score'} += $Weapon{$type}[$bot->{'shield'} ? $ScrS : $ScrN] -
                         (($adj || 0) * $Weapon{$type}[$bot->{'shield'} ? $ScrS : $ScrN]
                                      / $Weapon{$type}[$bot->{'shield'} ? $DmgS : $DmgN])
        if ($owner and $owner->{'id'} != $bot->{'id'} and !$owner->{'team'} or $owner->{'team'} ne $bot->{'team'});

    if ($bot->{'life'} <= 0) {
        $bot->{'dead'} = 1;
        $bot->{'lastcmd'} = '** Dead **';
        display('death', bot_id($bot), ($owner ? ('by '. ($owner == $bot ? 'itself' : bot_id($owner))) : ''));

        $Canvas->delete("_bot$bot->{'id'}") if $GUI;
        $Canvas->delete("_bots$bot->{'id'}") if $GUI;
        obj_draw(@{$bot}{'x', 'y'}, ($type eq 'destructh') ? '.' : 'P');
    }

    return $dmg;
}

sub bot_hit {
    my ($bot, $obj) = @_;

    obj_erase(@{$bot}{'x', 'y'});
    display('hit', bot_id($bot), $obj);

    if ($obj eq 'mine') {
        obj_flash('explode', @{$bot}{'x', 'y'});
        bot_damage($bot, $obj, $Mines{join(':', @{$bot}{'x', 'y'})});
    }
    elsif ($obj eq 'flag') {
        if ($bot->{'life'} == $Max_life) {
            obj_flash('explode', @{$bot}{'x', 'y'});
            bot_damage($bot, $obj);
        }
        else {
            $bot->{'life'} = $Max_life;
            $bot->{'ammo'} += $Flag_ammo;
            $bot->{'fuel'} += $Flag_fuel;
            ding('hit', $obj);
        }
    }
    elsif ($obj eq 'vault') {
        $bot->{'ammo'} += $Vault_ammo;
        ding('hit', $obj);
    }
}

sub bot_ready {
    my ($bot, $type) = @_;
    $type .= 'h' unless exists($Weapon{$type});

    return ($bot->{'fuel'} >= $Weapon{$type}[$CostF]
        and $bot->{'ammo'} >= $Weapon{$type}[$CostA]);
}

sub bot_pay {
    my ($bot, $type, $amount) = @_;
    $amount *= $bot->{'burn'} if $type eq 'fuel';

    return if $amount > $bot->{$type};
    return $bot->{$type} -= $amount;
}

sub bot_scan {
    my ($bot, $x, $y) = @_;

    if (my $other = bot_at($x, $y)) {
        return (($bot->{'team'} and $other->{'team'} eq $bot->{'team'}) ? 'friend' : 'enemy');
    }
    else {
        return $Obj{obj_at($x, $y)};
    }
}


# ===========================================================================
# Movement Handling
# ===========================================================================

sub tick_bot {
    no strict;
    my $bot = $Bots[($FirstBot + $Tick++) % scalar @Bots];

    if ($GUI) {
        $Top or exit;
        $Canvas->itemconfigure('_flash', -state => 'hidden');
        $Top->configure('-title' => "AI Bots v$Games::AIBots::VERSION (Tick: $Tick)") if $Running;
    }
    elsif ($Console) {
        no integer;
        $Console->Cursor(43, 21);
        $Console->Write(sprintf("[1-%1d][w]atch [t]empo: %4s [%5d]", 
            scalar @Bots,
            ('slow', 'fast', 'norm')[
                sqrt(sqrt($Tick_delay / 10)) % 3
            ]
        , $Tick));

        select(undef, undef, undef, 
            ((sqrt($Tick_delay / 10)) / (scalar @Bots) / 12)
        ) unless $Mask;
    }

    tick_check() or return;

    tick_missile($_) foreach (@{$bot->{'missiles'}});

    if ($bot->{'dead'}) {
        bot_watch($bot) unless $Continue;
        goto &tick_bot;
    }

    $bot->{'fuel'}-- if $bot->{'fuel'} > 0 and !(($Tick / scalar @Bots) % 10);

    my $old = { %{bot_fill($bot)} };

    unless (@{$bot->{'queue'}}) {
        my @cmds;
        
        if ($Console and $Mask and $bot->{'id'} == $Watch->{'id'}) {
            @cmds = user_tick($bot);
        } 
        else {
            @cmds = $bot->tick();
        }

        my @passable = qw/pic stack state var queue author team name line/;

        @{$old}{@passable} = @{$bot}{@passable};
        %{$bot} = %{$old};
        # $bot->{'var'}{'teamvar'} = $Teamvar{$bot->{'team'}};
        $bot->{'bumped'} = '';
        $bot->{'bumped_x'} = 0;
        $bot->{'bumped_y'} = 0;
        $bot->{'found'}  = '';

        push @{$bot->{'queue'}}, @cmds if @cmds;
    }

    $_ = lc(shift @{$bot->{'queue'}});
    # print $bot->{'id'},": $_\n";

    if (/^(scan)[\s\t]+(longrange|front|right|left|perimeter|cross|corner)$/
     || /^(turn)[\s\t]+(left|right)$/
     || /^(move)[\s\t]+(forward|backward)$/
     || /^(fire)[\s\t]+(laser|bazooka|energy)$/
     || /^(fire)[\s\t]+(grenade)([\s\t]+[\d\'\"]+)?$/
     || /^(scan)[\s\t]+(gps)[\s\t]+(\d+)[\s\t]*,[\s\t]*(\d+)$/
     || /^(scan)[\s\t]+(position|relative) ([12346789])$/
     || /^(disable)[\s\t]+(shield|laymine|cloak)$/
     || /^(enable)[\s\t]+(shield|laymine|cloak)$/
     || /^(attempt)[\s\t]+(repair|destruct)$/
     || /^(beam)[\s\t]+(command|fuel|ammo)\s+(.+)$/
     || /^(toggle)[\s\t]+(shield|laymine|cloak)$/
    ) {
        $bot->{'lastcmd'} = join(' ', ucfirst($1), substr($_, $-[2]));
        &{"cmd_$1"}($bot, $2, $3, $4) or @{$bot->{'queue'}} = grep {$_ eq $bot->{'lastcmd'}} @{$bot->{'queue'}};;
        bot_watch($bot) unless $Continue;;
    }
    elsif ($_) {
        warn "Malformed command $_ from ".$bot->{'id'}.", state ".$bot->{'state'};
    }

    $bot->{'dead'} = 1 if $bot->{'life'} <= 0;
    unless ($bot->{'dead'}) {
        tick_cloak($bot);
        obj_move(@{$old}{'x', 'y'}, @{$bot}{'x', 'y'}, bot_char($bot), "_bot$bot->{'id'}", 0, ($bot->{'id'} eq $Watch->{'id'}));
        obj_move(@{$old}{'x', 'y'}, @{$bot}{'x', 'y'}, $bot->{'shield'} ? 'shield' : 'noshield', "_bots$bot->{'id'}", 1);
    }

    $Top->after($Tick_delay / (scalar @Bots), \&Games::AIBots::tick_bot) if $GUI and $Running;
}

sub tick_missile {
    my $missile = shift;
    return if $missile->{'dead'};

    my $bot       = $missile->{'bot'};
    my ($dx, $dy) = delta($missile->{'h'}, 'front');
    my $tag       = "_missile$bot->{'id'}:$missile->{'id'}";

    if (bot_at(@{$missile}{'x', 'y'}) and $missile->{'age'}
        or obj_at($missile->{'x'} += $dx, $missile->{'y'} += $dy) ne '.'
        or ++$missile->{'age'} >= $missile->{'range'})
    {
        detonate($bot, $missile->{'type'}, @{$missile}{'x', 'y'});
        $missile->{'dead'}++;
        $Canvas->delete($tag) if $GUI;
    }
    elsif ($missile->{'age'} > 1) {
        obj_move($missile->{'x'} - $dx, $missile->{'y'} - $dy,
                 @{$missile}{'x', 'y'}, $missile->{'type'}.$missile->{'h'}, $tag, 1);
    }
    else {
        obj_draw(@{$missile}{'x', 'y'}, $missile->{'type'}.$missile->{'h'}, $tag, 1);
    }
}

sub tick_cloak {
    my $bot = shift;
    return unless $bot->{'cloak'};

    if ($bot->{'fuel'} >= $Cloak_fuel and bot_pay($bot, ammo => $Cloak_ammo)) {
        $bot->{'fuel'} -= $Cloak_fuel;
    }
    else {
        $bot->{'cloak'} = 0;
    }
}

sub tick_check {
    my (%alive, $hasfuel, $missiles);
    return if !$Running;

    foreach my $bot (@Bots) {
        $alive{$bot->{'team'} || bot_id($bot)}++ unless $bot->{'dead'};
        $hasfuel++ unless $bot->{'dead'} or $bot->{'fuel'} <= 0;
        foreach my $missile (@{$bot->{'missiles'}}) {
            $missiles++ unless $missile->{'dead'};
        }
    }

    if (!$missiles and (scalar keys(%alive) <= 1) or !$hasfuel) {
        # Game Over
        display('end');

        my %TScore;
        foreach my $bot (@Bots) {
            $bot->{'score'}  += 50 * $bot->{'life'};
            $bot->{'score'}  -= $bot->{'burn'};
            $bot->{'score'}  += 500 / $alive{$bot->{'team'} || bot_id($bot)}
                unless $bot->{'dead'} or (scalar keys(%alive) > 1);
            $TScore{$bot->{'team'} || bot_id($bot)} += $bot->{'score'} || 0;
            $bot->{'lastcmd'} = '**End**';
        }

        my @BScore = sort {$b->{'score'} <=> $a->{'score'}} @Bots;
        my @TScore = sort {$TScore{$b} <=> $TScore{$a}} keys(%TScore);

        if ($GUI) {
            $Btn_stop->configure(-state => 'disabled');
            $Btn_play->configure(-image => 'play');
            $_->configure(-state => 'normal', -background => '#a04444') foreach @Mnu_arg;
            $Top->configure('-title' => "AI Bots v$Games::AIBots::VERSION [Winner:".bot_id($BScore[0])." | Team ".$TScore[0]."] (Tick: $Tick)");
            $Watch->{'id'} = $BScore[0]->{'id'};
            bot_watch($BScore[0]);
        }

        foreach my $bot (@BScore) {
            $Watch->{'id'} = $bot->{'id'};
            bot_watch($bot, 1);
            print "\n" unless $Console and $^O ne 'MSWin32';
        }

        $Running = undef;
        ding('game_over');
        display('winner', bot_id($BScore[0]), $TScore[0]);
    }

    return $Running;
}

# ===========================================================================
# Bot Commands
# ===========================================================================

sub cmd_attempt {
    my ($bot, $action) = @_;

    if ($action eq 'repair') {
        return if $bot->{'shield'} or $bot->{'life'} >= $Max_life;

        if (!int(rand(10))) {
            $bot->{'life'}++;
            obj_flash('repair', @{$bot}{'x', 'y'});
        }
        elsif (!int(rand(20))) {
            $bot->{'burn'}++;
            obj_flash('explode', @{$bot}{'x', 'y'});
        }
    }
    elsif ($action eq 'destruct') {
        my $dmg = $bot->{'life'} * 100 / $Max_life;
        @{$Weapon{'destructh'}}[$DmgS, $DmgN, $BurnS, $BurnN]
            = ($dmg, $dmg, $dmg / 10, $dmg / 10);
        @{$Weapon{'destructs'}}[$DmgS, $DmgN, $BurnS, $BurnN, $ScrS, $ScrN]
            = ($dmg, $dmg, $dmg / 10, $dmg / 10, $dmg * 5, $dmg * 5);
        detonate($bot, 'destruct', @{$bot}{'x', 'y'});
    }

    return 1;
}

sub cmd_beam {
    my ($bot, $type, $param) = @_;
    my ($x, $y) = delta($bot->{'h'}, 'back');

    $x += $bot->{'x'}; $y += $bot->{'y'};

    if (my $other = bot_at($x, $y)) {
        return unless $other->{'h'} + $bot->{'h'} == 10;

        ding('beam');

        if ($type eq 'command') {
            unshift(@{$other->{'queue'}}, $param);
        }
        elsif ($type eq 'fuel' or $type eq 'ammo') {
            $param = -($other->{$type}) if $param < -($other->{$type});
            $param = $bot->{$type}      if $param > $bot->{$type};

            $bot->{$type}   += $param;
            $other->{$type} -= $param;
        }
    }

    return 1;
}

sub cmd_disable {
    my ($bot, $switch) = @_;
    $bot->{$switch} = 0;
    return 1;
}

sub cmd_enable {
    my ($bot, $switch) = @_;
    $bot->{$switch} = 1;
    return 1;
}

sub cmd_toggle {
    my ($bot, $switch) = @_;
    $bot->{$switch} = 1 - $bot->{$switch};
    return 1;
}
 
sub cmd_fire {
    my ($bot, $type, $range) = @_;

    # check ammo & fuel requisites
    return if (not bot_ready($bot, $type));

    bot_pay($bot, ammo => $Weapon{$type.'h'}[$CostA]);
    $bot->{'fuel'} -= $Weapon{$type.'h'}[$CostF];

    ding('fire', $type);

    if ($type eq 'energy') {
        detonate($bot, $type, @{$bot}{'x', 'y'});
    }
    elsif ($type eq 'bazooka' or $type eq 'grenade') {
        if ($bot->{'shield'}) {
            # self explode!
            $bot->{'shield'} = 0;
            detonate($bot, $type, @{$bot}{'x', 'y'});
            $bot->{'shield'} = 1;
        }
        else {
            # new missile
            my $missile = {
                'x'     => $bot->{'x'},
                'y'     => $bot->{'y'},
                'h'     => $bot->{'h'},
                'range' => $range || (($Cols > $Rows) ? $Cols : $Rows),
                'type'  => $type,
                'bot'   => $bot,
            };
            push @{$bot->{'missiles'}}, $missile;

            $missile->{'id'} = $#{$bot->{'missiles'}};
            tick_missile($missile);
        }
    }
    elsif ($type eq 'laser') {
        my ($x, $y)   = @{$bot}{'x', 'y'};
        my ($dx, $dy) = delta($bot->{'h'}, 'front');
        my $dir = ($bot->{'h'} == 8 or $bot->{'h'} == 2) ? 'v' : 'h';

        foreach my $step (1 .. $Weapon{$type.'h'}[$DmgN] / 10) {
            my $obj = $Obj{obj_at($x += $dx, $y += $dy)};

            (obj_flash($type.$dir, $x, $y), next) if ($obj eq 'space');

            obj_flash($type, $x, $y);
            obj_erase($x, $y) if ($obj eq 'fence');
            (detonate($bot, $obj, $x, $y), obj_erase($x, $y)) if ($obj eq 'vault');

            my $other = bot_at($x, $y) or last;
            ding('dmg', $type) if bot_damage($other, $type, $bot, 1 - $step);

            last;
        }
    }
    elsif ($type eq 'mine') {
        $Mines{join(':', @{$bot}{'x', 'y'})} = $bot;
        obj_draw(@{$bot}{'x', 'y'}, 'O');
    }

    return 1;
}

sub cmd_move {
    my ($bot, $dir) = @_;
    my ($x, $y)     = delta($bot->{'h'}, ($dir eq 'forward') ? 'front' : 'back');

    $x += $bot->{'x'}; $y += $bot->{'y'};

    if (obj_at($x, $y) =~ /^[.OPA]$/) {
        bot_pay($bot, fuel => 1) or return;

        substr($Board, ($bot->{'y'} - 1) * $Cols + $bot->{'x'} - 1, 1) = '.';
        cmd_fire($bot, 'mine') if ($bot->{'laymine'});

        @{$bot}{'x', 'y'} = ($x, $y);
        bot_hit($bot, $Obj{obj_at($x, $y)}) if (obj_at($x, $y) ne '.');
    }
    else {
        $bot->{'bumped'} = bot_scan($bot, $x, $y);
        @{$bot}{'bumped_x', 'bumped_y'} = ($x, $y);
        return;
    }

    return 1;
}

sub cmd_scan {
    my ($bot, $type) = splice(@_, 0, 2);
    my ($x, $y)      = @{$bot}{'x', 'y'};

    if ($type eq 'gps') {
        obj_flash('scang', @_);

        $bot->{'found'} = bot_scan($bot, @_);
    }
    elsif ($type eq 'perimeter') {
        obj_flash('scanp', $x, $y);
        $bot->{'found'} = (sort
            {index($Scan_list, $b) <=> index($Scan_list, $a)}
            bot_scan($bot, $x-1, $y-1), bot_scan($bot, $x-1, $y), bot_scan($bot, $x-1, $y+1),
            bot_scan($bot, $x,   $y-1),                           bot_scan($bot, $x  , $y+1),
            bot_scan($bot, $x+1, $y-1), bot_scan($bot, $x+1, $y), bot_scan($bot, $x+1, $y+1),
        )[0];
    }
    elsif ($type eq 'cross') {
        obj_flash('scancr', $x, $y);
        $bot->{'found'} = (sort
            {index($Scan_list, $b) <=> index($Scan_list, $a)}
            bot_scan($bot, $x-1, $y), bot_scan($bot, $x, $y-1),
            bot_scan($bot, $x+1, $y), bot_scan($bot, $x, $y+1),
        )[0];
    }
    elsif ($type eq 'corner') {
        obj_flash('scanco', $x, $y);
        $bot->{'found'} = (sort
            {index($Scan_list, $b) <=> index($Scan_list, $a)}
            bot_scan($bot, $x-1, $y-1), bot_scan($bot, $x-1, $y+1),
            bot_scan($bot, $x+1, $y-1), bot_scan($bot, $x+1, $y+1),
        )[0];
    }
    elsif ($type eq 'position' or $type eq 'relative') {
        my $pos = shift;

        if ($type eq 'relative') {
            $pos =~ tr/12346789/74182963/ if ($bot->{'h'} eq '6');
            $pos =~ tr/12346789/98764321/ if ($bot->{'h'} eq '2');
            $pos =~ tr/12346789/36928147/ if ($bot->{'h'} eq '4');
        }

        $x += 1 - ((9 - $pos) % 3),
        $y += 1 - int(($pos-1) / 3),

        $bot->{'found'} = bot_scan($bot, $x, $y);
        obj_flash('scang', $x, $y);
    }
    elsif ($type eq 'longrange') {
        cmd_scandir($bot, 'front', ($Cols > $Rows) ? $Cols : $Rows);
    }
    else {
        cmd_scandir($bot, $type, $Scan_range);
    }

    return 1; # scan could be used as no-op
}

sub cmd_scandir {
    my ($bot, $dir, $range) = @_;
    my ($x, $y)             = @{$bot}{'x', 'y'};
    my ($dx, $dy)           = delta($bot->{'h'}, $dir);

    foreach my $step (1 .. $range) {
        obj_flash($step == 1 ? 'scan'.$bot->{'h'} : 'scan', $x += $dx, $y += $dy, $step);
        return 1 unless ($bot->{'found'} = bot_scan($bot, $x, $y)) eq 'space';
    }

    return;
}

sub cmd_turn {
    my ($bot, $dir) = @_;

    return unless bot_pay($bot, fuel => 1);

    $bot->{'h'} = (qw/8 6 2 4/)[(index('8624', $bot->{'h'}) +
                  (($dir eq 'left') ? 3 : 1)) % 4];

    return 1;
}

# ===========================================================================
# Utilities
# ===========================================================================

sub detonate {
    my ($bot, $type, $x, $y) = @_;
    obj_flash($Obj{$type}, $x, $y) unless $Obj{$type} and $Obj{$type} eq 'vault';

    # detonation on spot
    if (my $other = bot_at($x, $y)) {
        bot_damage($other, $type, $bot);
    }
    elsif (my $obj = $Obj{obj_at($x, $y)}) {
        if ($obj eq 'fence') {
            obj_erase($x, $y);
        }
        elsif ($obj eq 'vault') {
            obj_erase($x, $y);
            detonate($bot, $obj, $x, $y);
        }
    }

    # splash damage
    $type .= 's';
    foreach my $dx (-1 .. 1) {
        foreach my $dy (-1 .. 1) {
            next if $dx == 0 and $dy == 0;

            my $obj = $Obj{obj_at($x + $dx, $y + $dy)} or next;

            $x += $dx; $y += $dy;

            if (my $other = bot_at($x, $y)) {
                bot_damage($other, $type, $bot);
            }
            elsif ($obj eq 'vault') {
                obj_erase($x, $y);
                obj_flash('explode', $x, $y);
                detonate($bot, 'vault', $x, $y);
            }
            elsif ($type eq 'destructs') {
                obj_erase($x, $y) if ($obj eq 'flag' or $obj eq 'mine' or $obj eq 'fence');
            }
            elsif ($type eq 'energys') {
                obj_erase($x, $y) if ($obj eq 'flag' or $obj eq 'mine');
            }
            else {
                obj_erase($x, $y) if ($obj eq 'fence');
            }

            $x -= $dx; $y -= $dy;
        }
    }
}

sub delta {
    my ($head, $dir) = @_;
    $dir ||= 'front';

    $head =~ tr/8624/0123/ if $dir eq 'front';
    $head =~ tr/8624/1230/ if $dir eq 'right';
    $head =~ tr/8624/2301/ if $dir eq 'back';
    $head =~ tr/8624/3012/ if $dir eq 'left';

    return ($head % 2) * (2 - $head),
           (($head + 1) % 2) * ($head - 1);
}

sub display {
    return if $Continue;
    my $msg = shift;
    $msg = sprintf "[%5s] $Msg{$msg}", $Tick, @_;
    $msg .= (' ' x (79 - length($msg)));

    if ($Console and (!$Mask or $Bots[-1]{dead})) {
        $Console->Cursor(0, 24);
        $Console->Write($msg . (' ' x (79 - length($msg))));
    }

    if ($Console and $^O ne 'MSWin32') {
        $Msglog .= "$msg\n";
    }
    else {
        print $msg, "\n";
    }
}

sub ding {
    return unless $Sound;

    if (exists($Wav{join('_', @_)})) {
        Win32::Sound::Play($Wav{join('_', @_)}, 1);
    }
    elsif ($Console and ($_[1] eq 'destruct' or $_[0] eq 'hit' or $_[0] eq
    'fire')) {
        print chr(7);
    }
}

sub do_loop {
    $Continue = shift;

    if ($GUI) {
        $Top->focusForce;
        Tk::MainLoop();
    }
    else {
        require Term::ReadKey;

        ding('game_begin');
        # init_map();
        init_game();
        $Running = 1;
        Term::ReadKey::ReadMode(4);

        while (1) {
            while (my($x, $y, $obj) = splice(@Flash, 0, 3)) {
                obj_set($x, $y, $obj);
            }
            tick_bot() if $Running;
            $Console->Display() if $Console;
            next if $Mask and $Running and not $Bots[-1]{dead};
            my $key = Term::ReadKey::ReadKey(
		($Running or $Continue) ? -1 : 10
	    ) or $Continue or next;
            if ($key eq 'h') {
                $_->{'fuel'} = 0 foreach (@Bots);
                tick_check();
            }
            elsif ($key ge '0' and $key le '9') {
                $Watch->{'id'} = $key;
                Games::AIBots::bot_watch($Bots[$key-1]);
                ding('toggle');
            }
            elsif ($key eq 'q') {
                $Console->Cursor(0, 24) if $Console;
                print $Msglog;
                exit;
            }
            elsif ($key eq 's') {
                btn_sound();
            }
            elsif ($key eq 'w') {
                btn_watch();
            }
            elsif ($key eq 't') {
                btn_tempo();
            }
            elsif ($key eq 'T') {
                btn_tempo();
                btn_tempo();
            }
            elsif ($key eq ' ' or $key eq 'p' or !$Running and $Continue) {
                # $Continue--;
                btn_play();
            }
        }
    }
}


%UserCmd = (
    k => 'move forward',
    j => 'move backward',
    h => 'turn left',
    l => 'turn right',
    b => 'fire bazooka',
    g => 'fire grenade',
    G => sub  { 'fire grenade '.int(Term::ReadKey::ReadKey(0)) },
    z => 'fire energy',
    x => 'fire laser',
    c => 'toggle cloak',
    s => 'toggle shield',
    m => 'toggle laymine',
    K => 'scan front',
    H => 'scan left',
    L => 'scan right',
    J => 'scan perimeter',
    I => 'scan longrange',
    U => 'scan cross',
    O => 'scan corner',
    P => sub  { 'scan position '.int(Term::ReadKey::ReadKey(0)) },
    R => sub  { 'scan relative '.int(Term::ReadKey::ReadKey(0)) },
    r => 'attempt repair',
    d => 'attempt destruct',
    q => sub  {
        $Console->Cursor(0, 24) if $Console;
        print $Msglog;
        exit;
    }
);

sub user_tick {
    die "User tick support for non-console mode: Not Yet." unless $Console;
    my $bot = shift;
    my $msg = sprintf(
	"Score:%d Ammo:%d Life:%d Fuel:%d [%s]",
	@{$bot}{qw/score ammo life fuel lastcmd/}
    );
    
    if ($bot->{bumped}) {
        obj_set(@{$bot}{'bumped_x', 'bumped_y'}, obj_at(@{$bot}{'bumped_x',
        'bumped_y'}));
    }
    $Console->Attr($main::FG_LIGHTCYAN);
    $Console->Cursor(40, 4);
    $Console->Write(substr($msg, 0, index($msg, ' Fuel')).(' ' x
    (40 - index($msg, ' Fuel'))));
    $Console->Cursor(42, 5);
    $Console->Write(substr($msg, index($msg, 'Fuel')).(' ' x (70 - length($msg))));
    $msg = $bot->{shield} ? '[S]' : '[s]';
    $msg .= $bot->{laymine} ? '[M]' : '[m]';
    $msg .= $bot->{cloak} ? '[C]' : '[c]';
    $msg .= " Bump:$bot->{bumped}" if $bot->{bumped};
    $msg .= " Scan:$bot->{found}" if $bot->{found};
    $msg .= " Enem:$bot->{enemy_l}" if $bot->{enemy_l};
    $msg .= " Frnd:$bot->{friend_l}" if $bot->{friend_l};
    $Console->Cursor(42, 6);
    $Console->Write($msg . (' ' x (38 - length($msg))));
    $Console->Attr($main::FG_WHITE);

    $Console->Cursor(0, 0);
    my $key;
    while (not defined $key or not exists $UserCmd{$key}) {
        $key = Term::ReadKey::ReadKey(0);
    }

    my $cmd = $UserCmd{$key};
    if ($bot->{enemy_x} and $Console) {
        $Console->Cursor($bot->{enemy_x} - 1, $bot->{enemy_y} - 1, 0, 0);
        $Console->Write(' ');
    }

    return ref($cmd) eq 'CODE' ? &{$cmd} : $cmd;
}

1;

=head1 SEE ALSO

L<aibots>, L<Games::AIBot>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

Files under the F<bots/> directory was contributed by students in
the autonomous learning experimnetal class, Bei'zheng junior high
school, Taipei, Taiwan.

=head1 COPYRIGHT

Copyright 2001, 2002 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
