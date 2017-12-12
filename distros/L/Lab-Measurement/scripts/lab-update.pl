use strict;
#use warnings;

use LWP::UserAgent;
use HTTP::Response;
use Archive::Tar;
use File::HomeDir;
use File::Path 'rmtree';
use File::Find;
use CPAN;

our $APPDATA_DIR;

init_program();
term_main();

sub init_program {
	
	my $homedir = File::HomeDir->my_data;

	if ( $^O eq 'MSWin32' or 'MacOS' ) {
		$APPDATA_DIR = $homedir."/lab";
		if (! -d $APPDATA_DIR) {
			mkdir($APPDATA_DIR) or die $!;
		}
		$APPDATA_DIR = $homedir."/lab/update";
		if (! -d $APPDATA_DIR) {
			mkdir($APPDATA_DIR);
		}
	}
	else {
		$APPDATA_DIR = $homedir."/.lab";
		if (! -d $APPDATA_DIR) {
			mkdir($APPDATA_DIR) or die $!;
		}
		$APPDATA_DIR = $homedir."/.lab/update";
		if (! -d $APPDATA_DIR) {
			mkdir($APPDATA_DIR);
		}
	}
	
	if (! -d $APPDATA_DIR."/ARCHIVE") {
		mkdir($APPDATA_DIR."/ARCHIVE");
	}
		
	chdir($APPDATA_DIR) or die $!;
	
} 

sub install_from_repository {
	
	if (-d "TEMP") {
		rmtree("TEMP");	
		}

	mkdir("TEMP");
	
	backup_Lab();
	
	my $url = 'https://www.labmeasurement.de/gitweb/?p=labmeasurement;a=snapshot;h=refs/heads/master;sf=tgz';

	my $filename = download($url, 'TEMP');
	install_archive($filename);
}

sub install_from_cpan {
	backup_Lab();
	CPAN::Shell->force('install', "Lab::Measurement");
}

sub find_Lab_installation_path {
	eval "use Lab::Instrument;";
	return 0 if $@ != "";
	
	my $lab_inst_path = $INC{"Lab/Instrument.pm"};

	my @lab_inst_path = split(/\//, $lab_inst_path);
	pop(@lab_inst_path);
	pop(@lab_inst_path);
	my $lab_inst_path = join("/", @lab_inst_path);
	
	return $lab_inst_path;
	
}

sub backup_Lab {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	
	print "-"x20;
	print "\n";
	print "Backup old Lab Directory ... ";
	my $timestring = ($year + 1900)."-".($mon + 1)."-".$mday."_".$hour."-".$min;
	
	my $filename = 'Lab_Backup_'.$timestring;
	
	my $lab_inst_path = find_Lab_installation_path();
	
	if (!$lab_inst_path) { print " No Lab installation present. Will not perform a backup. \n"; return;}
	
	chdir($lab_inst_path);
	my @filelist = ();
	find (sub { push @filelist, $File::Find::name }, 'Lab');

	Archive::Tar->create_archive( $APPDATA_DIR.'/ARCHIVE/'.$filename.".tar.gz", COMPRESS_GZIP, @filelist );
	chdir($APPDATA_DIR);
	print "done \n";
	print "-"x20;
	print "\n";
}

sub install_archive {

	my ($filename) = @_;
	
	$filename =~ m/(.+).tar.gz$/;
	my $folder = $1;
	
	my $tar = Archive::Tar->new;
	$tar->read($filename);
	our $| = 0;
	
	my @path = split(/\/|\\/, $folder);
	pop @path;
	print "-"x20;
	print "\n";
	print "Extracting Archive ... ";
	foreach my $subdir (@path) {chdir($subdir) or die $!; }
	$tar->extract();
	chdir($APPDATA_DIR) or die $!;
	print "done \n";
	print "-"x20;
	print "\n";

	
	print "Installing Lab::Measurement (this might take a few minutes) ... \n\n";
	chdir($folder."/Measurement/") or die $!;
	my $output = "EXECUTING BUILD.PL \n";
	$output .= `perl Build.PL`;
	$output .= "\n";
	$output .= "-"x20;
	
	if ( $^O eq 'MSWin32' ) {
		$output .= `Build`;
		$output .= `Build install`;
	}
	else {
		$output .= `./Build`;
		$output .= `./Build install`;
	}
	print "done \n";
	
	chdir($APPDATA_DIR) or die $!;
}

sub download {
	
	my ($url, $folder) = @_;
	
	our $data_length = 0;
	
	print "Downloading $url :\n";
	
	my $ua = LWP::UserAgent->new;
	$ua->add_handler( response_data => 
	sub { 
		my($response, $ua, $h, $data) = @_;
		my $content_length = $response->header("content_length");
		$content_length = (defined $content_length) ? sprintf("%.2fMB",$response->header("content_length") / 1024 / 1024) : "--";
		$data_length += length($data) / 1024 / 1024;
		our $| = 0;
		printf ("Progress: %.2fMB / $content_length \r", $data_length, $content_length); 
		our $| = 1;
		} );
		
	my $filename = $ua->head($url)->header('content-disposition');
	$filename =~ m/filename="(.*)"/;
	$filename = $1;
	
	my $save = $folder."/".$filename;
	
	my $response = $ua->get($url,  ':content_file' => $save);
	print "\n"."finished download \n";
	
	return $save;
}

sub term_main {

	use Term::UI;
	use Term::ReadLine;
	
	my $term = Term::ReadLine->new('main_menu');
	
	my $banner = "\n\n";
	$banner .= "Welcome to Lab Measurement Update \n";
	$banner .= "-"x33;
	$banner .= "\n";
	$banner .= "What do you want to do?\n";
	
	print $banner;
	
	my $list=[
		'Install latest Lab Measurement Version from Repository',
		'Install latest stable Lab Measurement Version from CPAN',
		'Restore backup from older Lab Measurement installation',
		'Exit'
		];
	
	my $reply = $term->get_reply(
		prompt => "Please enter your choice: ",
		choices => $list,
		default => 'Install / Update newest Lab Measurement from Repository',
	);


	if ($reply eq @{$list}[0]) { install_from_repository(); } 
	if ($reply eq @{$list}[1]) { install_from_cpan(); } 
	if ($reply eq @{$list}[2]) { term_restore_backup($term); } 
	elsif ($reply eq @{$list}[3]) { exit; } 
}

sub term_restore_backup {
	use Term::UI;
	use Term::ReadLine;
	
	my $term = shift;
	
	opendir (DIR, "ARCHIVE");
	my @backups = readdir DIR;
	close DIR;
	
	shift(@backups);
	shift(@backups);
	
	if (@backups) {
		my $banner = "-"x33;
		$banner .= "\n";
		$banner .= "The following Backups are available: \n";
		print $banner;
	
		my $reply = $term->get_reply(
			prompt => "Please enter your choice: ",
			choices => \@backups
		);
	
		restore_backup($reply);
	}
	else {
		print "Sorry, there are no backups available!";
	}
}

sub restore_backup {
	
	my $backup = shift;
	
	backup_Lab();
	
	print "Restoring $backup ...";
	my $lab_inst_path = find_Lab_installation_path();
	if (!$lab_inst_path) { print " No Lab installation present. Please install Lab Measurement before restoring a backup. \n"; return;}
	chdir($lab_inst_path);
	
	my @filelist = ();
	find (sub { push @filelist, $File::Find::name }, 'Lab');
	
	chmod(0777, @filelist);
	
	my $tar = Archive::Tar->new;
	$tar->read($APPDATA_DIR."/ARCHIVE/".$backup);
	$tar->extract();
	
	print "done \n";
	
	chdir($APPDATA_DIR);
	
}
