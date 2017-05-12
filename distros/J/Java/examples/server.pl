#!/home/markt/bin/perl -w
use strict;
no strict 'subs';
use lib qw(..);
use Java;

my $java = new Java();

my $ssocket = $java->create_object("java.net.ServerSocket",8000);
my $client = $ssocket->accept;
my $is = $client->getInputStream;
my $os = $client->getOutputStream;

my $isr = $java->create_object("java.io.InputStreamReader",$is);
my $osw = $java->create_object("java.io.OutputStreamWriter",$os);

my $buffered_reader = $java->create_object("java.io.BufferedReader",$isr);
my $print_writer = $java->create_object("java.io.PrintWriter",$osw,"true:b");

my $cont = 1;

while($cont)
{
	my $input_line = $buffered_reader->readLine;
	last if (!$input_line);
	$input_line = $input_line->get_value;
	chomp $input_line;
	print "Received: $input_line\n";
	$print_writer->println("You typed - $input_line");
	if ($print_writer->checkError->get_value eq 'true')
	{
		print "ERR: true!\n";
	}
	$cont = 0 if ($input_line =~ /^bye/i);
}


