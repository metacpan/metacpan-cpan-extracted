# IUP::Tabs example

use strict;
use warnings;

use IUP ':all';

my $edit1 = IUP::Text->new( MULTILINE=>"YES", EXPAND=>"YES", VALUE=>"Number 1", TABTITLE=>"First" );
my $edit2 = IUP::Text->new( MULTILINE=>"YES", EXPAND=>"YES", VALUE=>"Number 2", TABTITLE=>"Second" );

my $tabs = IUP::Tabs->new( child=>[$edit1,$edit2], EXPAND=>'YES' );

my $dlg = IUP::Dialog->new( child=>$tabs, TITLE=>'Tabs!', SIZE=>"QUARTERxQUARTER" );

$dlg->Show;
IUP->MainLoop;
