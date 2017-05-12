use Gtk;
use Gnome;
use Getopt::Long;

#TITLE: Druid example
#REQUIRES: Gtk GdkImlib Gnome
@options = (
	# argspec => description
	# argspec = long_arg_name[|single_char_name][=s|i|f] (see Getopt::Long)
	"message|m=s", "Message to display in the druid",
	"burp=i", "Just a different argument type",
	"yadda|y", "Yet another one for testing",
	"urka!", "Urka option",
	"verbose+", "Be verbose",
);

$message = "This is a test";
Gnome->init('druid', 0.1, {
	callback => \&options,
	remove => 1, #remove options from the command line
	options => [@options]
	});
# same as above without callback and remove=0
#Gnome->init('druid', 0.1, [@options ]);

sub options {
	my ($name, $val) = @_;
	$val = '' unless defined $val;
	$message = $val if $name eq 'message';
}

# you could use Getopt::Long here if you didn't set a callback in Gnome::init
print "Remaining args: @ARGV\n";

GetOptions(undef, Gnome->getopt_options,
	# should get the arg names from the options array to avoid duplication
	"message|m=s", \$message, 
	"burp=i", \$dummy,
	"yadda|y", \$dummy,
	"urka!", \$dummy,
	"verbose+", \$dummy,
) || die "Wrong options: ";

$logo = load_image Gtk::Gdk::ImlibImage ('../../Gtk/samples/xpm/3DRings.xpm');
#$logo2 = load_image Gtk::Gdk::ImlibImage ('../../Gtk/samples/xpm/Modeller.xpm');
$logo2 = load_image Gtk::Gdk::ImlibImage ('save.xpm');

my $win = new Gtk::Window("toplevel");
  $win->signal_connect( "destroy", \&Gtk::main_quit );
  my $vbox = new Gtk::VBox( 0, 2 );
  $win->add($vbox);
  $vbox->show;
  my $druid = new Gnome::Druid;
  $druid->signal_connect("cancel", \&Gtk::main_quit);
  $vbox->pack_start($druid,0,0,0);
  $druid_start = new Gnome::DruidPageStart();
  $druid_start->set_title("test");
  $druid_start->set_text($message);
  $druid_start->set_watermark($logo);
  $druid_start->show;
  $druid->append_page($druid_start);
  $druid_finish = new Gnome::DruidPageFinish();
  $druid_finish->set_title("Test Finished.");
  $druid_finish->set_text("This test is over.");
  $druid_finish->set_logo($logo2);
  $druid_finish->signal_connect("finish", \&Gtk::main_quit);
  $druid_finish->show;
  $druid->append_page($druid_finish);
  $druid->show;
  $win->show;

main Gtk;
