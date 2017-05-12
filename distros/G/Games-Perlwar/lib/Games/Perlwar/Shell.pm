package Games::Perlwar::Shell;

use strict;
use warnings;

our $VERSION = '0.03';

use Cwd;
use Games::Perlwar;
use XML::Simple;
use File::Copy;
use IO::Prompt;
use Term::ShellUI;
use IO::Prompt;


my $pw;
# TODO: add color entry for players and default colors
my @colors = qw( pink lightblue yellow lime maroon purple 
                 olive pink gold red aqua );

my $shell = Term::ShellUI->new(
    commands => {
        load => {
            desc => "load a Perlwar game",
            maxargs => 2,
            proc => \&do_load,
        },
        save => {
            desc => "save the current Perlwar game",
            maxargs => 1,
            proc => \&do_save,
        },
        quit => {
            desc => "exit the shell",
            method => sub { shift->exit_requested(1) },
        },
        q => { syn => 'quit', exclude_from_completion => 1 },
    }
);

### help 
$shell->add_commands({ 
    help => {
        desc => "print list of commands",
        args => sub { shift->help_args(undef, @_); },
        method => sub { shift->help_call(undef, @_); },
    },
    h => { syn => "help", exclude_from_completion=>1},
});

### create
$shell->add_commands({ 
    create => {
        desc => "create a new game",
        proc => \&do_create,
    },
});

### cd, pwd
$shell->add_commands({
    cd => {
        desc => "change working directory",
        proc => \&do_cd,
    },
    pwd => {
        desc => "print current working directory",
        proc => \&do_pwd,
    },
});

### run
$shell->add_commands({
    run => {
        desc => 'run iterations of the game',
        proc => \&do_run,
    }
});

### exec, info
$shell->add_commands({ 
    eval => {
        desc => 'execute arbitrary perl code',
        proc => sub { print eval( join ' ', @_ ), "\n" },
    },
    e => { syn => 'eval', exclude_from_completion => 1 },
    info => { 
        desc => 'game stats',
        proc => \&do_info,
    },
});


$shell->prompt( 'pw> ' );

sub run { $shell->run; }

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub do_info {
    die "no game loaded\n" unless $pw;

    print 'iteration ', $pw->{round}, ' of ', $pw->{conf}{gameLength}, "\n",
          'game status: ', ( $pw->get_game_status || 'ongoing' ), "\n",
          'players', "\n";

    for my $p ( keys %{$pw->{conf}{player}} ) {
        print "\t$p : ", $pw->{conf}{player}{$p}{agents}, "\n";
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub do_create {
    if ( $pw ) {
        my $r = prompt -yes, -d => 'y', 
                 "creating a new game will discard any unsaved information to "
                ."the currently loaded game. do it? [Yn] ";
        return unless $r;
    }

    my $game_name = shift || 'perlwar';
    my $game_dir = "./$game_name";

    print "creating game directories $game_dir..\n";

    mkdir $game_dir or die "couldn't create directory $game_dir: $!\n";
    chdir $game_dir or die "can't chdir to $game_dir: $!\n";

    mkdir "history" or die "couldn't create directory history:$!\n";
    mkdir 'mobil' or die "couldn't create directory mobil:$!\n";

    print "\n\ngame configuration\n";

    my $config_file = IO::File->new( '>configuration.xml' )
        or die "can't create configuration file: $!\n";

    my $conf = XML::Writer->new( OUTPUT => $config_file, 
                                 NEWLINES => 1 );

    $conf->startTag( 'configuration' );

    $game_name =~ s#^.*/##;  # remove path if any
    $conf->dataElement( title =>
        prompt "game title [$game_name]: ", -d => $game_name );

    $conf->dataElement( gameLength => 
        my $gameLength = prompt -integer, 
                            "game length (0 = open-ended game) [100]: ", 
                            -d => 100                                    );

    $conf->dataElement( theArraySize =>
        prompt -integer, "size of the Array [100]: ", -d => 100 );

    $conf->dataElement( agentMaxSize =>
        prompt -integer, "agent max. size [100]: ", -d => 100 );

    if ( prompt -y => "blitzkrieg? [yN]: ", -d => 0 ) {
        $conf->dataElement( 'gameVariant', 'blitzkrieg' );
    }

    if( prompt -y => "mambo war? [n]: ", -d => 0 ) {
        $conf->emptyTag( 'mambo', decrement =>
            prompt "decrement per iteration [1]: ", -d => 1
        );
    }

    my $player_list_type = 
        prompt -menu => [ qw/ adhoc predefined / ], "type of player list: ";

    if ( $player_list_type eq 'adhoc' ) {
        $conf->emptyTag( 'players', 
                            list => $player_list_type,
                            community =>
                                prompt "community file [h4x00rs.xml]: ",
                                        -d => 'h4x00rs.xml' 
        );
    }
    else {
        $conf->startTag( 'players', list => $player_list_type );

        while(1) {
            my $line = prompt "enter a player (name password [color]), or nothing if done: ";
            my( $name, $password, $color ) = split ' ', $line, 3;
            
            last unless $name;

            $color ||= shift @colors;

            $conf->emptyTag( 'player', name => $name, 
                                       password => $password,
                                       color => $color );
        }

        $conf->endTag( 'players' );
    }

    print "notes (CTL-D to terminate):\n";
    my $note;
    $note .= $_ while <>;

    $conf->dataElement( notes => $note ) if $note;

    $conf->endTag( 'configuration' );
    $conf->end;
    $config_file->close;

    print "creating round 0.. \n";

    for my $filename ( qw/ round_current.xml round_00000.xml / )
    {
        my $fh;
        open $fh, ">$filename" or die "can't create file $game_dir/$filename: $!\n";
        print $fh "<iteration nbr='0'>",
                    "<summary><status>not started yet</status></summary><theArray/><log/></iteration>\n";
        close $fh;
    }

    print "\ngame '$game_name' created\n";

    $pw = Games::Perlwar->new( '.' );
    $pw->load;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub do_load {
    my $dir = shift || '.';
    my $iteration = shift;

    if ( $pw ) {
        my $r = prompt -yes, -d => 'y', 
                 "loading a new game will discard any unsaved information to "
                ."the currently loaded game. do it? [Yn] ";
        return unless $r;
    }

    $pw = Games::Perlwar->new( $dir );
    $pw->load( $iteration );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub do_save {
    die "no game to save" unless $pw;

    $pw->save;

    print "game saved\n";
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub do_run {
    die "no game loaded" unless $pw;

    return print "game is already over\n" if $pw->get_game_status eq 'over';

    if ( my $turns = shift ) {
        $pw->play_round while $turns-- and $pw->get_game_status ne 'over';
    }
    else {
        $pw->play_round until $pw->get_game_status eq 'over';
    }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub do_cd {
    my $dir = shift;
    unless( -d $dir ) {
        print "ERROR: can't change directory, $dir doesn't exist\n";
        return;
    }

    chdir $dir or print "ERROR: couldn't change to directory: $!\n";
    
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub do_pwd {
    print "current directory: ", getcwd, "\n";
}

__END__



