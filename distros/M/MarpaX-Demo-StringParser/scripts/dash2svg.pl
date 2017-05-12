#!/usr/bin/env perl

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use Capture::Tiny 'capture';

use File::Slurp; # For read_file().
use File::Spec;

use Log::Handler;

use MarpaX::Demo::StringParser;
use MarpaX::Demo::StringParser::Filer;
use MarpaX::Demo::StringParser::Renderer;

use Try::Tiny;

# -----------------------------------------------

my($logger) = Log::Handler -> new;

$logger -> add
	(
	 screen =>
	 {
		 maxlevel       => 'debug',
		 message_layout => '%m',
		 minlevel       => 'error',
	 }
	);

my($data_dir_name) = 'data';
my($html_dir_name) = 'html';
my(%dash_files)    = MarpaX::Demo::StringParser::Filer -> new -> get_files($data_dir_name, 'dash');
my($script)        = File::Spec -> catfile('scripts', 'parse.pl');

my(@dash_file);
my($expected_result);
my($gv_file);
my($image_file);
my($parser);
my($result, $renderer, @result);
my($stdout, $stderr);

for my $dash_name (sort values %dash_files)
{
	$dash_name       = File::Spec -> catfile($data_dir_name, $dash_name);
	($gv_file        = $dash_name) =~ s/dash$/gv/;
	($image_file     = $dash_name) =~ s/dash$/svg/;
	$image_file      =~ s/$data_dir_name/$html_dir_name/;
	@dash_file       = read_file($dash_name, binmode => ':raw', chomp => 1);
	$expected_result = ($1 || '') if ($dash_file[0] =~ /(Error|OK)\.$/);

	print "Processing: $dash_name => $gv_file => $image_file. \n";
	print "$dash_file[0]\n";

	if (! $expected_result)
	{
		die "Typo in $dash_name. First line must end in /(Error|OK)\.\$/. ";
	}

	$parser = MarpaX::Demo::StringParser -> new(input_file => $dash_name);
	$result = $parser -> run;

	if ($result == 0)
	{
		try
		{
			($stdout, $stderr, @result) = capture
			{
				$result = MarpaX::Demo::StringParser::Renderer -> new
							(
								dot_input_file => $gv_file,
								logger         => $logger,
								output_file    => $image_file,
								tree           => $parser -> tree,
							) -> run;
			};

			print "Wrote $image_file. \n";
		}
		catch
		{
			print "dot died: $_. \n";
		}
	}
}
