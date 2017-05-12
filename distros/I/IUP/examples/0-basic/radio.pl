# IUP::Radio example
#
# Creates a dialog for the user to select his/her gender.
# In this case, the radio element is essential to prevent the user from
# selecting both options.

use strict;
use warnings;

use IUP ':all';

my $male   = IUP::Toggle->new( TITLE=>"Male", TIP=>"Two state button - Exclusive - RADIO" );
my $female = IUP::Toggle->new( TITLE=>"Female", TIP=>"Two state button - Exclusive - RADIO" );

my $exclusive = IUP::Radio->new( child=>IUP::Vbox->new( [$male, $female] ), VALUE=>$female );

my $frame = IUP::Frame->new( child=>$exclusive, TITLE=>"Gender" );

my $dialog = IUP::Dialog->new( child=>IUP::Hbox->new( [ IUP::Fill->new(), $frame, IUP::Fill->new() ]),
                               TITLE=>"IUP::Radio",
                               SIZE=>140,
                               RESIZE=>"NO",
                               MINBOX=>"NO",
                               MAXBOX=>"NO"
);

$dialog->Show();

IUP->MainLoop;
