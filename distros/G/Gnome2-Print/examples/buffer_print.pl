#!/usr/bin/perl
#
# This examples shows how to print a (lined) buffer, wrapping lines if they are
# too long for the page boundaries. (ebassi)

use strict;
use warnings;

use Gtk2 '-init';
use Gnome2::Print;

use constant FONT_NAME => 'Bitstream Vera Sans Roman';
use constant FONT_SIZE => 16.0;

use constant LEFT_BORDER => 100;
use constant BOTTOM_BORDER  => 100;

our $d = create_dialog();
$d->show;

Gtk2->main;

0;

sub render_job
{
	my $job = shift;
	my $conf = $job->get_config;
	my $pc = $job->get_context;
		
	my $buffer = [
		"Twinkle Twinkle",
		"Little Star",
		"Twinkle Twinkle",
		"Where You Are",
		"",
		"This is some text created just for testing purposes. It's longer than a single line, and it's wider than the page margin, in order to verify that the text wrapping mechanism is working properly.",
		"",
		"Hope it'll all go well.",
	];
	
	my $font = Gnome2::Print::Font->find_closest(FONT_NAME, FONT_SIZE);
	
	my $font_height = $font->get_descender + $font->get_ascender;
	my $line_spacing = 1.2 * $font->get_size;
	my @adv = $font->get_glyph_stadvance($font->lookup_default(ord(' ')));
	my $space_advance = $adv[0];
	
	my ($width, $height) = $job->get_page_size;
	
	my $font_name = $font->get_name;
	printf "Found: %s (%.1f)\n", $font_name, $font->get_size;
	
	# start cursor.
	my $cur_x = LEFT_BORDER;
	my $cur_y = $height - BOTTOM_BORDER;

	# begin page
	my $page_n = 1;
	print "(cur_x, cur_y) = $cur_x, $cur_y\n";
	
	# init
	$pc->beginpage(sprintf("%d", $page_n++));
	$pc->moveto($cur_x, $cur_y);
	$pc->setfont($font);
	
	foreach my $line (@$buffer)
	{
		# fetch line width
		my $line_width = $font->get_width_utf8($line);
		print "line width: $line_width\n";
		
		if ($line_width < ($width - 2 * LEFT_BORDER - 1))
		{
			# fastpath for lines smaller than page width
			$pc->show($line);
			$cur_y -= ($font_height + $line_spacing);
			
			# start a new page if we hit this page's bottom border
			if ($cur_y < BOTTOM_BORDER)
			{
				$cur_y = $height - BOTTOM_BORDER;
				$pc->showpage;
				$pc->beginpage(sprintf("%d", $page_n++));
				$pc->setfont($font);
			}
			
			print "(cur_x, cur_y) = $cur_x, $cur_y\n";
			$pc->moveto($cur_x, $cur_y);
		}
		else
		{
			# word wrapping at word boundaries.
			my @words = split /\s/, $line;
			foreach my $w (@words)
			{
				my $word_width = $font->get_width_utf8($w);
				printf "*** word (%s[%d]) width: %d\n", $w, length($w), $word_width;
				
				if ($cur_x < ($width - 2 * LEFT_BORDER - 1))
				{
					# word still inside page boundary; remember the space!
					$cur_x += ($word_width + $space_advance);
					$pc->show(sprintf("%s ", $w));
					$pc->moveto($cur_x, $cur_y);
				}
				else
				{
					# wrapping
					print "*** wrapping at '$w'!\n";
					$cur_x = LEFT_BORDER;
					$cur_y -= ($font_height + $line_spacing);
					
					# start a new page if we hit this page's bottom border
					if ($cur_y < BOTTOM_BORDER)
					{
						$cur_y = $height - BOTTOM_BORDER;
						$pc->showpage;
						$pc->beginpage(sprintf("%d", $page_n++));
						$pc->setfont($font);
					}
					
					$pc->show(sprintf("%s", $w));
					$pc->moveto($cur_x, $cur_y);
				}
				
				print "(cur_x, cur_y) = $cur_x, $cur_y\n";
			}
			
			# move to next line
			$cur_x = LEFT_BORDER;
			$cur_y -= ($font_height + $line_spacing);
			$pc->moveto($cur_x, $cur_y);
		}
	}
	
	$pc->showpage;
	$job->close;
}

sub create_dialog
{
	my $job = Gnome2::Print::Job->new;
	my $dialog = Gnome2::Print::Dialog->new($job, "Sample print dialog", 0);

	$dialog->signal_connect(delete_event => sub { $dialog->destroy; });
	$dialog->signal_connect(destroy      => sub { Gtk2->main_quit;  });

	$dialog->signal_connect(response     => sub {
			my ($d, $response_id, $job) = @_;
			my $conf = $d->get_config;
			my $j = Gnome2::Print::Job->new($conf);

			if    (1 eq $response_id)
			{
				render_job($j);

				my $pc = Gnome2::Print::Context->new($conf);
				$j->render($pc);
				$pc->close;

				$d->destroy;
			}
			elsif (2 eq $response_id)
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
