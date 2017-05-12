#
# A simple gnomeprint dialog
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
	my ($width, $height) = $conf->get_page_size;
	my $pc = $job->get_context;
	
	$pc->beginpage("1");
	
	$x1 = $width * .1;
	$x2 = $width * .9;
	$y1 = $width * .1;
	$y2 = $width * .9;
	
	$pc->setlinewidth(3.0);
	$pc->rect_stroked($x1, $y1, $x2 - $x1, $y2 - $y1);
	$pc->line_stroked($x1, $y1, $x2, $y2);
	$pc->line_stroked($x2, $y1, $x1, $y2);
	$pc->showpage;

	$job->close;
}

sub create_dialog 
{
	$job = Gnome2::Print::Job->new;
	$dialog = Gnome2::Print::Dialog->new($job, "Sample print dialog", 0);
	$gpc = $job->get_context;
	$config = $job->get_config;
	
	$dialog->signal_connect(delete_event => sub { $dialog->destroy; });
	$dialog->signal_connect(destroy      => sub { Gtk2->main_quit; });
	$dialog->signal_connect(response     => sub
	{
		my ($d, $response, $job) = @_;
		print "response := " . $response . "\n";
		
		my $conf = $d->get_config;
		my $j = Gnome2::Print::Job->new($conf);
		
		if    (1 == $response)		# user hit 'Print'
		{	
			render_job($j);
			
			my $pc = Gnome2::Print::Context->new($conf);
			$j->render($pc);
			$pc->close;
			
			$dialog->destroy;
		}
		elsif (2 == $response)		# user hit 'Preview'
		{
			render_job($j);
			
			my $preview = Gnome2::Print::JobPreview->new($j, "Sample preview dialog");
			$preview->set_property("allow-grow", 1);
			$preview->set_property("allow-shrink", 1);
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
