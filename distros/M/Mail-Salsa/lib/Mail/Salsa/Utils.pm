#
# Mail/Salsa/Utils.pm
# Last Modification: Thu Nov 13 15:09:09 WET 2008
#
# Copyright (c) 2008 Henrique Dias <henrique.ribeiro.dias@gmail.com>.
# All rights reserved.
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
package Mail::Salsa::Utils;

use 5.008000;
use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use Mail::Salsa::Logs qw(logs);
use Mail::Salsa::Sendmail;
use Mail::Salsa::Template;
use Sys::Hostname;
use Socket;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mail::Salsa::Utils ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(&file_path &generate_id &string_date &host_addresses &create_file &email_components &make_dir_rec);

our $VERSION = '0.05';

my @patterns = (
	'[^\<\>\@\(\)]+',
	'[^\000-\037\300-\377\@<>(),;:\s]+\@([\w\-]+\.)+[a-zA-Z]{2,4}'
);

sub create_file {
	my $file = shift;
	my $data = shift;
	my $mode = shift || 0644;

	open(FILE, ">", $file) or die("$!");
	print FILE $data;
	close(FILE);

	chmod($mode, $file);
	return();
}

sub lookup4key {
	my $filename = shift;
	my $key = shift;

	my $exist = 0;
	open(FILE, "<", $filename) or die("$!");
	while(<FILE>) { if(/\b$key\b/) { $exist = 1; last; } }
	close(FILE);

	return($exist);
}

sub host_addresses {
	my $hostname = hostname();
	my $iaddr = gethostbyname($hostname);
	my $ip_addrs = inet_ntoa($iaddr);
	$hostname = gethostbyaddr($iaddr, AF_INET);
	return($ip_addrs, $hostname);
}

sub clean_dir {
	my $dir = shift;

	my @files = ();
	opendir(DIRECTORY, $dir) or return("Can't opendir $dir: $!\n");
	while(defined(my $file = readdir(DIRECTORY))) {
		next if($file =~ /^\.\.?$/);
		push(@files, "$dir/$file");
	}
	closedir(DIRECTORY);
	for my $file (@files) {
		if(my ($f) = ($file =~ /^(.+)$/)) {
			unlink($f) or return("Could not unlink $f: $!");
		}
	}
	rmdir($dir) or return("Couldn't remove dir $dir: $!");
	return();
}

sub make_dir_rec {
	my $path = shift;
	my $mode = shift || 0755;

	!index($path, "/") or die("Not full path to directory \"$path\"");
	my $tmp = "";
	for my $dir (split(/\//, $path)) {
		$dir or next;
		$tmp = join("/", $tmp, $dir);
		(-d $tmp) or &make_dir($tmp, $mode);
	}
	return();
}

sub make_dir {
	my $dir = shift;
	my $mode = shift || 0755;

	umask(0);
	mkdir($dir, $mode) or die("Failed to create directory \"$dir\" $!");
	return();
}

sub string_date {
	my ($sec,$min,$hour,$mday,$mon,$year) = localtime();
	return sprintf("%04d/%02d/%02d %02d:%02d:%02d",
		$year + 1900, $mon + 1, $mday, $hour, $min, $sec);
}

sub email_components {
	local $_ = shift;

	/^($patterns[0]) +<($patterns[1])>\s+/ and return({'username' => $1, 'address' => $2});
	/^<?($patterns[1])>?\s+/ and return({'address' => $1});
	return({});
}

sub only_addresses {
	for(my $i=0; $i < scalar(@{$_[0]}); $i++) {
		$_[0]->[$i] =~ /\<?($patterns[1])\>?/;
		$_[0]->[$i] = $1;
	}
	return();
}

sub check4email {
	my $array = shift;
	my $file = shift;

	my @emexist = ();
	my %hash = ();
	@hash{@{$array}} = (0 .. $#{$array});
	open(LIST, "<", $file) or die("$!");
	while(<LIST>) { 
		next if(/^\#/);
		s/[\r\n]+$//;
		/\<?($patterns[1])\>?/o;
		$1 or next;
		push(@emexist, $1) if(exists($hash{$1}));
	}
	close(LIST);
	return(\@emexist);
}

sub get_key {
	my $file = shift;

	open(KEY, "<", $file) or return("");
	chomp(my $key = <KEY>);
	close(KEY);
	return($key);
}

sub file_path {
	my $list = shift;
	my $list_dir = shift;
	my $file = shift;

	my ($name, $domain) = split(/\@/, $list);
	return(join("/", $list_dir, $domain, $name, $file));
}

sub generate_id {
	my $size = shift || 16;
	return(substr(md5_hex(time(). {}. rand(). $$. 'prelin'), 0, $size));
}

sub tplsendmail {
	my $param = {
		smtp_server => ["localhost"],
		label       => undef,
		lang        => "en",
		vars        => {},
		@_,
	};

	my $refsub = sub {
		my $handle = shift;
		my $tpl = Mail::Salsa::Template->new(
				lang  => $param->{'lang'},
				label => $param->{'label'},
				outfh => $handle,
		);
		$tpl->replace(%{$param->{'vars'}});
        };

	my $sm = Mail::Salsa::Sendmail->new(
		smtp_server => $param->{'smtp_server'} || ["localhost"],
		timeout     => $param->{'timeout'}
	);
	$sm->everything(
		mail_from => $param->{'vars'}->{'from'},
		rcpt_to   => [$param->{'vars'}->{'to'}],
		data      => $refsub
	);
	return();
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mail::Salsa::Utils - Utility functions used by some Mail::Salsa modules.

=head1 SYNOPSIS

  use Mail::Salsa::Utils;

=head1 DESCRIPTION

Stub documentation for Mail::Salsa, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Henrique M. Ribeiro Dias, E<lt>hdias@aesbuc.ptE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Henrique M. Ribeiro Dias

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
