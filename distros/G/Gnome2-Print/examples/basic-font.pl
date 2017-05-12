#
# basic-font.pl: sample gnome-font code
#

use Gtk2;
use Gnome2::Print;

Gtk2->init;

$d = create_dialog();
$d->show;

Gtk2->main;

0;

sub render_job
{
	my $job = shift;
	my $conf = $job->get_config;
	my $pc = $job->get_context;
		
	my $font = Gnome2::Print::Font->find_closest("Sans Regular", 20.0);
	my $font_name = $font->get_name;
	print "Found: " . $font_name . "\n";

	$pc->beginpage("1");

	$pc->setfont($font);

	$pc->moveto(100, 700);
	$pc->show("Some text for testing.");

	$pc->moveto(100, 650);
	$pc->show("Some more text for testing.");

	$pc->showpage;

	$job->close;
}

sub create_dialog
{
	$job = Gnome2::Print::Job->new;
	$dialog = Gnome2::Print::Dialog->new($job, "Sample print dialog", 0);

	$dialog->signal_connect(delete_event => sub { $dialog->destroy; });
	$dialog->signal_connect(destroy      => sub { Gtk2->main_quit;  });

	$dialog->signal_connect(response     => sub {
			my ($d, $response_id, $job) = @_;
			my $conf = $d->get_config;
			my $j = Gnome2::Print::Job->new($conf);

			if    (1 == $response_id)
			{
				render_job($j);

				my $pc = Gnome2::Print::Context->new($conf);
				$j->render($pc);
				$pc->close;

				$dialog->destroy;
			}
			elsif (2 == $response_id)
			{
				render_job($j);

				my $preview = Gnome2::Print::JobPreview->new($j, "Sample preview dialog");
				$preview->set_property("allow-grow" => 1);
				$preview->set_property("allow-shrink" => 1);
				$preview->set_transient_for($d);
				$preview->show_all;
			}
			else
			{
				$d->destroy;
			}
		}, $job);

	return $dialog;
}
