#!/home/markt/bin/perl -w

use strict;
no strict 'subs';
use lib '../..';
use Java;

my $awt = "java.awt";
my $swing = "javax.swing";

my $java = new Java();

#my $frame = $java->create_object("java.awt.Frame","GUI Test");
#$frame->setSize(500,500);

my $msgLabel = $java->create_object("$swing.JLabel");
my $yesButton = $java->create_object("$swing.JButton");
my $noButton = $java->create_object("$swing.JButton");

$msgLabel->setText("Testing one two three");
$msgLabel->setBorder($java->create_object("$swing.border.EmptyBorder",10,10,10,10));

$yesButton->setText("Yes");
$noButton->setText("No");

my $win = $java->create_object("$swing.JFrame","Message");
my $buttonbox = $java->create_object("$swing.JPanel");

$win->getContentPane->setLayout($java->create_object("$awt.BorderLayout"));

$buttonbox->setLayout($java->create_object("$awt.FlowLayout"));

$buttonbox->add($yesButton);
$buttonbox->add($noButton);

$win->getContentPane->add($msgLabel,"Center");

$win->getContentPane->add($buttonbox,"South");

my $myTxtArea = $java->create_object("java.awt.TextArea","",15,60,1);
$myTxtArea->append("Hello World\n");
$myTxtArea->append("Check out these multi-lined paramter strings!\n");
$myTxtArea->append("Howdy!\n");

$win->getContentPane->add($myTxtArea,"East");

$java->do_event($yesButton,"addActionListener", \&event);
$java->do_event($noButton,"addActionListener", \&event);

#$win->pack;
$win->show;

## Roll my own event loop
#my $e_fh = $java->get_event_FH;
#my $READBITS = 0;
#vec($READBITS,$e_fh->fileno,1) = 1;
#while(1)
#{
	#my $nf = select(my $rb = $READBITS,undef,undef,undef);
	#if ($nf)
	#{
		#my $line = <$e_fh>;
		#$java->decipher_event($line);
	#}
#}


##
# Calling 'go' will BLOCK!
#	Let Java do event loop
##
while(1)
{
	my $b = $java->go;
	last if (!defined $b);
}

sub event
{
	my($object,$event) = @_;

	my $label = $object->getLabel->get_value;

	if ($object == $yesButton)
	{
		print "Yes Button!  Label: $label\n";
	}
	else
	{
		print "No Button!  Label: $label\n";
	}

	# Check out received multi-lined strings back...
	my $text = $myTxtArea->getText->get_value;
	print "Text is:\n$text\n";
}
