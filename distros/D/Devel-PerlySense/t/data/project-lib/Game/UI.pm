=head1 NAME

Game::UI - UI for the Worm game.

=head1 SYNOPSIS

Nah...

=cut





package Game::UI;





use strict;
use Data::Dumper;
use Carp qw( confess );

use Win32::Console;            #Curses/GUI/other?
use Win32::Sound;
use Game::Location;
use Time::HiRes qw( time sleep );
use Game::Application;




=head1 PROPERTIES

=head2 oConsole

Screen console object

=cut

use Class::MethodMaker get_set => [ "oConsole" ];





=head2 oKeyboard

Keyboard console object

=cut

use Class::MethodMaker get_set => [ "oKeyboard" ];





=head2 offsetTop

Where on the screen to display the Lawn.

Default: 0

=cut

use Class::MethodMaker get_set => [ "offsetTop" ];





=head2 offsetLeft

Where on the screen to display the Lawn.

Default: 0

=cut

use Class::MethodMaker get_set => [ "offsetLeft" ];





=head2 oLocationScore

Location for the score output, or undef if none.

=cut

use Class::MethodMaker get_set => [ "oLocationScore" ];





=head2 soundsEnabled

Whether to play sounds or not.

Default: 0

=cut

use Class::MethodMaker get_set => [ "soundsEnabled" ];





=head1 METHODS

=head2 new()

Create new UI.

=cut
sub new { my $pkg = shift;

    my $self = {};
    bless $self, $pkg;

    $self->offsetLeft(0);
    $self->offsetTop(0);
    $self->oLocationScore(undef);
    $self->oConsole(Win32::Console->new(STD_OUTPUT_HANDLE));
    $self->oKeyboard(Win32::Console->new(STD_INPUT_HANDLE));
    $self->soundsEnabled(0);

    return($self);
}





=head2 displayLawn($oLawn)

Initialize the screen and display stuff on the $oLawn

Return 1 on success, else 0.

=cut
sub displayLawn { my $self = shift;
    my ($oLawn) = @_;

    $self->oConsole->Cls();
    for my $row (0 .. ($oLawn->height - 1)) {
        $self->oConsole->FillChar('.', $oLawn->width, 0 + $self->offsetLeft, $row + $self->offsetTop);
        }

    $self->showScore(undef);

    return(1);
}





=head2 runMainMenu($oApplication)

Show the menu and accept user input. Run whatever user
action is selected.

Return 1 on success, else 0.

=cut
sub runMainMenu { my $self = shift;
    my ($oApplication) = @_;

    my %hAction = (
        "P"        => sub {
            $oApplication->runGame();
            return(1);
            },
        "Q"        => sub {
            $self->oConsole->Cls();
            return(0);
            },
        );

    $self->showMainMenu() or return(0);

    while(1) {
        if(my $rcAction = $hAction{ uc($self->getKeyPressChar()) }) {
            $rcAction->() or return(1);
            $self->showMainMenu() or return(0);
            }

        sleep(0.05);
        }

    return(1);
}





=head2 showMainMenu()

Show the menu on the screen.

Return 1 on success, else 0.

=cut
sub showMainMenu { my $self = shift;

    $self->oConsole->Cls();

    my $text =  qq{

             .: MENU :.                       .: HOW TO PLAY :.

             P - Play                         - F - Turn LEFT
             Q - Quit                         - J - Turn RIGHT

                                              - You are the white worm


               Please enlarge the console window before playing
};

    print $text;

    return(1);
}





=head2 displayObjectAt($oObject)

Display the $oObject at it's Locaton.

Return 1 on success, else 0.

=cut
sub displayObjectAt { my $self = shift;
    my ($oObject) = @_;

    my $i = 0;
    for my $oLocation (@{$oObject->raBodyLocation}) {
        my $char = $oObject->raBodyChar->[$i];        #Refactor: Move to worm
        $self->displayObjectBodyPartAt($oLocation, $char, $oObject);
        $i++;
        }

    return(1);
}






=head2 displayObjectBodyPartAt($oLocation, [$char = '.'], [$oObject])

Display the $char at the $oLocation. If $oObject is passed, 
the style may be influenced by it.

Return 1 on success, else 0.

=cut
my %hColorAttr = (
    "white" => $::FG_WHITE,
    "gray" => $::FG_GRAY,
    "yellow" => $::FG_YELLOW,
    "blue" => $::FG_LIGHTBLUE,
    "green" => $::FG_LIGHTGREEN,
    "red" => $::FG_LIGHTRED,
    );
sub displayObjectBodyPartAt { my $self = shift;
    my ($oLocation, $char, $oObject) = @_;
    $char ||= ".";
    my $attr = $hColorAttr{"gray"};
    $oObject and $attr = $hColorAttr{ $oObject->color() || "gray" };
#    $char eq '$' and $attr = $hColorAttr{"yellow"};

    my ($left, $top) = ($oLocation->left + $self->offsetLeft, $oLocation->top + $self->offsetTop);
    $self->oConsole->FillAttr($attr, 1, $left, $top);
    $self->oConsole->FillChar($char, 1, $left, $top);

    return(1);
}





=head2 getUserAction()

Return logical user action:

    "turn left"
    "turn right"
    "quit"
    "pause"

Return "" if there is no user input pending.

=cut
my $rhKeyInput =  {
    "f" => "turn left",
    "j" => "turn right",
    "q" => "quit",
    "p" => "pause",
    };
sub getUserAction { my $self = shift;

    my $char = $self->getKeyPressChar() or return("");
    $char = lc($char);

    return( $rhKeyInput->{$char} || "" );
}





=head2 showScore([$score])

If there is a Location for the score, display it.

Return 1 on success, else 0.

=cut
sub showScore { my $self = shift;
    my ($score) = @_;
    defined($score) or $score = "";

    $self->oLocationScore or return(1);

    $self->oConsole->WriteChar("Score: $score", $self->oLocationScore->left, $self->oLocationScore->top);    #Or nothing

    return(1);
}





=head2 prizeWasClaimedBy($oPrize, $oObject)

The $oPrize was claimed by $oObject. Note this by playing a
sound (if available).

Return 1 on success, else 0.

=cut
sub prizeWasClaimedBy { my $self = shift;
    my ($oPrize, $oObject) = @_;

    $self->playSound("prize");

    return(1);
}





=head2 wormHasCrashed($oObject)

The worm $oObject has crashed.

Note this by playing a sound (if available).

Return 1 on success, else 0.

=cut
sub wormHasCrashed { my $self = shift;
    my ($oObject) = @_;

    $self->playSound("crash");

    return(1);
}





=head2 playSound($name)

If soundsEnabled(), play the sound $name if it's available.

Return 1 on success, else 0.

=cut
sub playSound { my $self = shift;
    my ($name) = @_;

    $self->soundsEnabled or return(1);

    my $file = "resource/sound/$name.wav";
    -r $file or return(0);

    Win32::Sound::Volume('40%');
    Win32::Sound::Play($file, SND_ASYNC | SND_NODEFAULT);

    return(1);
}





=head2 getKeyPressChar()

Check for keyboard key presses, and return the char of the
key pressed, or undef if no key was pressed (don't block).

=cut
sub getKeyPressChar { my $self = shift;

    $self->oKeyboard->GetEvents() or return(undef);        #Skip it if there is no input (it will block otherwise)

    my ($eventType, $keyDown, $repeat, $keycode, $scancode, $char, $control) = $self->oKeyboard->Input();
    $eventType and $eventType == 1 and $keyDown and $char or return(undef);

    return( chr($char) );
}





1;





#EOF
