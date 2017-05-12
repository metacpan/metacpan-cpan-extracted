#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::Output qw();
use Meta::Baseline::Aegis qw();
use Meta::Utils::File::File qw();

my($do_log,$use_aegis,$logfile);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_bool("do_log","write a log file ?",1,\$do_log);
$opts->def_bool("use_aegis","use aegis to determine directories ?",0,\$use_aegis);
$opts->def_newf("logfile","what file to log to","/var/log/httpd/rewrite_script.log",\$logfile);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

sub log_text($) {
	my($text)=@_;
	if($do_log) {
		open(FILE,">> ".$logfile) || die("unable to open logfile [".$logfile."]");
		print FILE $text;
		close(FILE);
	}
}

#value to be returned if file does not exist
my($noval)="NULL";
log_text("log started\n");

my($path)=[
	"/local/development/changes/meta/meta.C211",
	"/local/development/projects/meta/baseline"
];

my($file);
while($file=<STDIN>) {
	chop($file);
	log_text("got [".$file."]\n");
	#Meta::Utils::Output::print("file is [".$file."]\n");
	my($res);
	if($use_aegis) {
		$res=Meta::Baseline::Aegis::which_nodie($file);
		if(!defined($res)) {
			$res=$noval;
		}
	} else {
		$res=$noval;
		my($stop)=0;
		for(my($i)=0;$i<=$#$path && !$stop;$i++) {
			my($curr_dir)=$path->[$i];
			my($examine)=$curr_dir."/".$file;
			if(Meta::Utils::File::File::exist($examine)) {
				$res=$examine;
				$stop=1;
			}
		}
	}
	#Meta::Utils::Output::print(Meta::Baseline::Aegis::which($file)."\n");
	Meta::Utils::Output::print($res."\n");
	log_text("returning [".$res."]\n");
	#Meta::Utils::Output::print("/index.html"."\n");
}

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

development_apache_dir.pl - translate aegis path names for apache.

=head1 COPYRIGHT

Copyright (C) 2001, 2002 Mark Veltzer;
All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111, USA.

=head1 DETAILS

	MANIFEST: development_apache_dir.pl
	PROJECT: meta
	VERSION: 0.04

=head1 SYNOPSIS

	development_apache_dir.pl [options]

=head1 DESCRIPTION

This script is intended for use with apache in order to enbable a developer to have a location
in his web site where he can look at html development either from the baselines point of view or
from any changes point of view.

The semantics are as follows:
	[project]-[change]/path: presents the [change] changes point of view for project [project].
	or
	[project]: presents the baselines point of view for project [project].

The module reads a single line from the standard input and translates it to a real file name.
After each line it flushes to output since apache uses a single instance of the program to do
all translations.

There is a thread which I participated on on the Aegis development list about these issues.
Search for "html" and "apache".

=head1 OPTIONS

=over 4

=item B<help> (type: bool, default: 0)

display help message

=item B<pod> (type: bool, default: 0)

display pod options snipplet

=item B<man> (type: bool, default: 0)

display manual page

=item B<quit> (type: bool, default: 0)

quit without doing anything

=item B<gtk> (type: bool, default: 0)

run a gtk ui to get the parameters

=item B<license> (type: bool, default: 0)

show license and exit

=item B<copyright> (type: bool, default: 0)

show copyright and exit

=item B<description> (type: bool, default: 0)

show description and exit

=item B<history> (type: bool, default: 0)

show history and exit

=item B<do_log> (type: bool, default: 1)

write a log file ?

=item B<use_aegis> (type: bool, default: 0)

use aegis to determine directories ?

=item B<logfile> (type: newf, default: /var/log/httpd/rewrite_script.log)

what file to log to

=back

no free arguments are allowed

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV more web page stuff
	0.01 MV web site automation
	0.02 MV SEE ALSO section fix
	0.03 MV move tests to modules
	0.04 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Utils::File::File(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.
