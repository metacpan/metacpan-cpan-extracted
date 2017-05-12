#
# Mail/Salsa/Action/Admin.pm
# Last Modification: Fri May 28 19:23:49 WEST 2010
#
# Copyright (c) 2010 Henrique Dias <henrique.ribeiro.dias@gmail.com>.
# All rights reserved.
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
package Mail::Salsa::Action::Admin;

use 5.008000;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);
use MIME::Base64 qw(encode_base64);
use Mail::Salsa::Utils qw(file_path create_file generate_id);
use Mail::Salsa::Logs qw(logs);
use Mail::Salsa::Sendmail;
use Mail::Salsa::Template;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mail::Salsa ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = '0.06';

my @patterns = (
	'[^\<\>\@\(\)]+',
	'[^\000-\037\300-\377\@<>(),;:\s]+\@([\w\-]+\.)+[a-zA-Z]{2,4}',
	'(allow|deny) +(\S+) +to +(post|bounce|proceed) +from +(localnet|anywhere)(.+)?',
);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {@_};
	bless ($self, $class);
	$self->process_msg();
	return($self);
}

sub process_msg {
	my $self = shift;

	my ($name, $domain) = split(/\@/, $self->{'list'});
	my %files = ();
	for my $file ('stamp.txt', 'ticket.txt', 'configuration.txt', 'restrict.txt', 'attachments.txt', 'information.txt', 'header.txt', 'footer.txt', 'list.txt') {
		$files{$file} = file_path($self->{'list'}, $self->{'list_dir'}, $file);
	}
	if(-e (my $ticketkeyf = join("/", $self->{'tmp_dir'}, 'ticket.txt'))) {
		if(&check_ticket($ticketkeyf, $files{'ticket.txt'})) {
			my $result = &file_manager($self->{'tmp_dir'}, \%files);
			if(exists($result->{'error'})) {
				Mail::Salsa::Utils::tplsendmail(
					smtp_server => $self->{'smtp_server'},
					timeout     => $self->{'timeout'},
					label       => "UPDATE_ERROR",
					lang        => $self->{'config'}->{'language'},
					vars        => {
						from   => "$name\-master\@$domain",
						to     => "$name\-owner\@$domain",
						file   => $result->{'file'},
						errors => $result->{'error'},
					}
				);
				$self->logs(join("", "[update error] from: ", $self->{'from'}), "list");
			} elsif(exists($result->{'files'})) {
				Mail::Salsa::Utils::tplsendmail(
					smtp_server => $self->{'smtp_server'},
					timeout     => $self->{'timeout'},
					label       => "UPDATED_FILES",
					lang        => $self->{'config'}->{'language'},
					vars        => {
						from  => "$name\-master\@$domain",
						to    => "$name\-owner\@$domain",
						files => $result->{'files'},
					}
				);
				$self->logs(join("", "[updated files] from: ", $self->{'from'}), "list");
			} else {
				$self->logs(join("", "[no admin files] from: ", $self->{'from'}), "list");
			}
		} else {
			Mail::Salsa::Utils::tplsendmail(
				smtp_server => $self->{'smtp_server'},
				timeout     => $self->{'timeout'},
				label       => "ADMINTICKET",
				lang        => $self->{'config'}->{'language'},
				vars        => {
					from => "$name\-master\@$domain",
					to   => "$name\-owner\@$domain",
				}
			);
			$self->logs(join("", "[wrong ticket] from: ", $self->{'from'}), "list");
		}
	} else {
		my $dir = join("/", $self->{'list_dir'}, $domain, $name);
        	unless(-d $dir) {
			Mail::Salsa::Utils::make_dir_rec($dir, 0755);
			(-d $dir) or die("$!");
		}
		my $list = $self->{'list'};
		(-e $files{'stamp.txt'} && -s $files{'stamp.txt'}) or create_file($files{'stamp.txt'}, join("", uc(generate_id(32)), "\n"), 0600);
		(-e $files{'ticket.txt'} && -s $files{'ticket.txt'}) or create_file($files{'ticket.txt'}, join("", uc(generate_id(32)), "\n"), 0600);
		(-e $files{'configuration.txt'} && -s $files{'configuration.txt'}) or create_file($files{'configuration.txt'}, &make_config(), 0600);
		(-e $files{'restrict.txt'} && -s $files{'restrict.txt'}) or create_file($files{'restrict.txt'}, "\# Add here the rules\n\# [allow|deny] [address|subscribers|any] to [post|bounce|proceed] \\\n\# from [localnet|anywhere] with(out) stamp\n\#\n\nallow subscribers to post from anywhere without stamp\ndeny any to proceed from anywhere\n", 0600);
		(-e $files{'attachments.txt'} && -s $files{'attachments.txt'}) or create_file($files{'attachments.txt'}, "\# Insert here the acl rules.\n\#\n\# [allow|deny] mime/type from [address|domain|subscribers|any]\n\#\n\nallow any/any from any\n", 0600);
		(-e $files{'information.txt'} && -s $files{'information.txt'}) or create_file($files{'information.txt'}, "Please insert here the information about mailing list.\n", 0600);
		(-e $files{'header.txt'} && -s $files{'header.txt'}) or create_file($files{'header.txt'}, "Please remove this text and insert your own text header.\n", 0600);
		(-e $files{'footer.txt'} && -s $files{'footer.txt'}) or create_file($files{'footer.txt'}, "Please remove this text and insert your own text footer.\n", 0600);
		(-e $files{'list.txt'} && -s $files{'list.txt'}) or create_file($files{'list.txt'}, "\# Add here the addresses of the list\n", 0600);
		$self->sendmail(\%files);
		$self->logs(join("", "[send files to owner] from: ", $self->{'from'}), "list");
	}
	return();
}

sub normalize {
	local $_ = shift;

	if(/^($patterns[0]) +<($patterns[1])>\s+/) { return([lc($2), $1]); }
	if(/^<?($patterns[1])>?\s+/) { return([lc($1), ""]); }
	return(["", ""]);
}

sub update_file {
	my $newfile = shift;
	my $oldfile = shift;

	open(NEW, "<", $newfile) or die("$!");
	open(OLD, ">", $oldfile) or die("$!");
	select(OLD);
	while(<NEW>) {
		s/\x0d//g;
		print OLD $_;
	}
	close(OLD);
	close(NEW);

	unlink($newfile) or die("$!");
	return();
}

sub list2hash {
	my $file = shift;

	my @error = ();
	my $n = 1;
	open(FILE, "<", $file) or die("$!");
	while(<FILE>) {
		my ($addr, $name) = @{&normalize($_)};
		$addr ? ($_[0]->{$addr} = $name) : push(@error, "line $n: $_");
		$n++;
	}
	close(FILE);
	unlink($file) or die("$!");

	return(\@error);
}

sub update_list {
	my $list = shift;
	my $hash = shift;

	open(OLDLIST, "<", $list) or die("$!");
	open(NEWLIST, ">", "$list\.new") or die("$!");
	select(NEWLIST);
	while(<OLDLIST>) {
		my ($addr, $name) = @{&normalize($_)};
		$addr or next;
		if(exists($hash->{'unsubscribe'}->{$addr})) {
			delete($hash->{'unsubscribe'}->{$addr});
			next;
		}
		next if(exists($hash->{'subscribe'}->{$addr}));
		print NEWLIST $name ? "$name \<$addr\>" : "$addr", "\n";
	}
	while(my ($addr, $name) = each(%{$hash->{'subscribe'}})) {
		print NEWLIST $name ? "$name \<$addr\>" : "$addr", "\n";
	}
	close(NEWLIST);
	close(OLDLIST);

	rename("$list\.new", $list);
	return();
}

sub replace_list {
	my $newfile = shift;
	my $oldfile = shift;

	my %inserted = ();
	open(NEW, "<", $newfile) or die("$!");
	open(OLD, ">", $oldfile) or die("$!");
	select(OLD);
	while(<NEW>) {
		if(/^\#/) { print OLD $_; next; }
		/[\x0d\x0a]+$/ or $_ .= "\n" if(eof(NEW));
		my ($addr, $name) = @{&normalize($_)};
		$addr or next;
		next if(exists($inserted{$addr}));
		print OLD $name ? "$name <$addr>" : $addr, "\n";
		$inserted{$addr} = "";
	}
	close(OLD);
	close(NEW);

	unlink($newfile) or die("$!");
	return();
}

sub check_confkeys {
	$_ = shift;

	/^title *\= *[^\=]{2,60}$/ and return(1);
	/^prefix *\= *[^\=]{2,30}$/ and return(1);
	/^language *\= *[a-z][a-z]$/ and return(1);
	/^max_message_size *\= *(\d{1,9})$/ and $1 > -1 and return(1);
	/^subscribe *\= *[yn]$/ and return(1);
	/^unsubscribe *\= *[yn]$/ and return(1);
	/^archive *\= *[yn]$/ and return(1);
	/^header *\= *[yn]$/ and return(1);
	/^footer *\= *[yn]$/ and return(1);
	/^localnet *\= *[\d\.\, ]+$/ and return(1);
	/^stamp_life *\= *(\d{1,9})[dwmy]$/ and $1 > -1 and return(1);

	return(0);
}

sub check_rules {
	my $file = shift;

	my @errors = ();
	my $n = 0;
	open(FILE, "<", $file) or die("$!");
	while(<FILE>) {
		$n++;
		next if(/^[\#\x0d\x0a]/);
		/^(allow|deny) +\w+\/\w+ +from +\S+[\x0d\x0a]+/ or push(@errors, "Line $n: $_");
	}
	close(FILE);
	return(\@errors);
}

sub check_config {
	my $file = shift;

	my @errors = ();
	my $n = 0;
	open(FILE, "<", $file) or die("$!");
	while(<FILE>) {
		$n++;
		next if(/^[\#\x0d\x0a]/);
		s/[ \t\x0d\x0a]+$//g;
		&check_confkeys($_) or push(@errors, "Line $n: $_");
	}
	close(FILE);
	return(\@errors);
}

sub check_restrict {
	my $file = shift;

	my @errors = ();
	my $n = 0;
	open(FILE, "<", $file) or die("$!");
	while(<FILE>) {
		$n++;
		next if(/^[\#\x0d\x0a]+/);
		if(/^$patterns[2]/) {
			unless($2 eq "any" || $2 =~ /\.[a-zA-Z]{2,4}$/) {
				push(@errors, "Line $n: $_");
				next;
			}
			if(defined($5) and ($5 !~ /^ with(out)? +stamp/)) {
				push(@errors, "Line $n: $_");
				next;
			}
		} else { push(@errors, "Line $n: $_"); }
	}
	close(FILE);
	return(\@errors);
}

sub check_address {
	my $file = shift;

	my $pattern = join("", "^", $patterns[1], "[ \t]*[\x0d\x0a]+");
	my @errors = ();
	my $n = 0;
	open(FILE, "<", $file) or die("$!");
	while(<FILE>) {
		$n++;
		next if(/^[\#\x0d\x0a]+/);
		/[\x0d\x0a]+$/ or $_ .= "\n" if(eof(FILE));
		/^$patterns[0] +<$patterns[1]>[ \t]*[\x0d\x0a]+/ or
			/^<$patterns[1]>[ \t]*[\x0d\x0a]+/ or 
				/$pattern/ or push(@errors, "Line $n: $_");
	}
	close(FILE);
	return(\@errors);
}

sub file_manager {
	my $tmpdir = shift;
	my $files = shift;

	my @filesok = ();
	my $file = join("/", $tmpdir, 'configuration.txt');
	if(-e $file && -s $file) {
		my $errors = &check_config($file);
		return({
			file  => 'configuration.txt',
			error => join("\n", @{$errors})
		}) if(scalar(@{$errors}));
		&update_file($file, $files->{'configuration.txt'});
		push(@filesok, 'configuration.txt');
	}

	$file = join("/", $tmpdir, 'information.txt');
	if(-e $file && -s $file) {
		&update_file($file, $files->{'information.txt'});
		push(@filesok, 'information.txt');
	}

	$file = join("/", $tmpdir, 'header.txt');
	if(-e $file && -s $file) {
		&update_file($file, $files->{'header.txt'});
		push(@filesok, 'header.txt');
	}

	$file = join("/", $tmpdir, 'footer.txt');
	if(-e $file && -s $file) {
		&update_file($file, $files->{'footer.txt'});
		push(@filesok, 'footer.txt');
	}

	$file = join("/", $tmpdir, 'restrict.txt');
	if(-e $file && -s $file) {
		my $errors = &check_restrict($file);
		return({
			file  => 'restrict.txt', 
			error => join("\n", @{$errors})
		}) if(scalar(@{$errors}));
		&update_file($file, $files->{'restrict.txt'});
		push(@filesok, 'restrict.txt');
	}

	$file = join("/", $tmpdir, 'list.txt');
	if(-e $file && -s $file) {
		my $errors = &check_address($file);
		return({
			file  => 'list.txt',
			error => join("\n", @{$errors})
		}) if(scalar(@{$errors}));
		&replace_list($file, $files->{'list.txt'});
		push(@filesok, 'list.txt');
	}

	$file = join("/", $tmpdir, 'attachments.txt');
	if(-e $file && -s $file) {
		my $errors = &check_rules($file);
		return({
			file  => 'attachments.txt',
			error => join("\n", @{$errors})
		}) if(scalar(@{$errors}));
		&update_file($file, $files->{'attachments.txt'});
		push(@filesok, 'attachments.txt');
	}

	my %hash = ();
	$file = join("/", $tmpdir, 'subscribe.txt');
	if(-e $file && -s $file) {
		my $errors = &list2hash($file, $hash{'subscribe'} = ());
		return({
			file  => 'subscribe.txt',
			error => join("\n", @{$errors})
		}) if(scalar(@{$errors}));
	}
	$file = join("/", $tmpdir, 'unsubscribe.txt');
	if(-e $file && -s $file) {
		my $errors = &list2hash($file, $hash{'unsubscribe'} = ());
		return({
			file  => 'unsubscribe.txt',
			error => join("\n", @{$errors})
		}) if(scalar(@{$errors}));
	}
	if(exists($hash{'subscribe'}) || exists($hash{'unsubscribe'})) {
		&update_list($files->{'list.txt'}, \%hash);
		push(@filesok, 'list.txt');
	}
	return(scalar(@filesok) ? { files => join("\n", @filesok) } : {});
}

sub check_ticket {
	my $outfile = shift;
	my $infile = shift;

	(my $keyout = &get_content($outfile)) =~ s/\s+//g;
	(my $keyin = &get_content($infile)) =~ s/\s+//g;
	(length($keyout) == 32 && length($keyin) == 32) or return(0);
	return(($keyout eq $keyin) ? 1 : 0);
}

sub get_content {
	my $file = shift;

	my $data = "";
	open(FILE, "<", $file) or die("$!");
	while(<FILE>) {
		s/\x0d//g;
		$data = join("", $data, $_);
	}
	close(FILE);
	return($data);
}

sub make_config {

	my $data =<<"EOF";
# Mailing List configuration file
# Please don't change any line that starts with "#" character.

# Set the title of mailing list.

title = My Mailing List Title

# Add a prefix to the subject.

prefix = [mylist]

# Allow/deny the users to subscribe the mailing list.
# Choose [y/n]

subscribe = y

# Allow/deny the users to unsubscribe the mailing list.
# Choose [y/n]

unsubscribe = y

# Set the maximum message size.

max_message_size = 0

# Specify how long the stamp should be valid.
# Stamp expires in n days/weeks/months/years
# Choose [number][d/w/m/y]

stamp_life = 1m

# Save the messages to the archive.
# Choose [y/n]

archive = n

# Set the language.

language = en

# Add a header information to the message
# Choose [y/n]

header = n

# Add a footer information to the message
# Choose [y/n]

footer = n

# Please enter the IP's for your local network.
# Example: 192.168.1., 192.168.2.
#          192.168.

localnet = 192.168.

EOF
	return($data);
}

sub attach_headers {
	my $filename = shift;
	my $description = shift;
	my $id = shift;

	my $hdr =<<"EOH";
Content-Type: TEXT/plain; name="$filename"
Content-Transfer-Encoding: BASE64
Content-Description: $description
Content-Disposition: attachment; filename="$filename"

EOH
	return($hdr);
}

sub sendmail {
	my $self = shift;
	my $files = shift;

	my ($name, $domain) = split(/\@/, $self->{'list'});
	my $boundary = join("_", "----=", "NextPart", generate_id(32));
	my $refsub = sub {
		my $handle = shift;

		my $tpl = Mail::Salsa::Template->new(
			lang  => $self->{'lang'},
			label => "ATTACH_FILES",
			outfh => $handle
		);
		$tpl->replace(
			from     => "salsa-master\@$domain",
			to       => "$name-owner\@$domain",
			admin    => "$name-admin\@$domain",
			boundary => $boundary,
			origin   => $self->{'from'},
			list     => $self->{'list'},
		);
		print $handle "\n--$boundary\n";
		print $handle &attach_headers('ticket.txt', "Mailing List Administrator Ticket file");
		print $handle join("", encode_base64(&get_content($files->{'ticket.txt'})), "\n", "--$boundary\n");

		print $handle &attach_headers('configuration.txt', "Mailing List Configuration file");
		print $handle join("", encode_base64(&get_content($files->{'configuration.txt'})), "\n", "--$boundary\n");

		print $handle &attach_headers('restrict.txt', "Restrict file");
		print $handle join("", encode_base64(&get_content($files->{'restrict.txt'})), "\n", "--$boundary\n");

		print $handle &attach_headers('attachments.txt', "Attachments ACL file");
		print $handle join("", encode_base64(&get_content($files->{'attachments.txt'})), "\n", "--$boundary\n");

		print $handle &attach_headers('information.txt', "Information file");
		print $handle join("", encode_base64(&get_content($files->{'information.txt'})), "\n", "--$boundary\n");

		print $handle &attach_headers('header.txt', "Header file");
		print $handle join("", encode_base64(&get_content($files->{'header.txt'})), "\n", "--$boundary\n");

		print $handle &attach_headers('footer.txt', "Footer file");
		print $handle join("", encode_base64(&get_content($files->{'footer.txt'})), "\n", "--$boundary\n");

		print $handle &attach_headers('list.txt', "Mailing List file");
		open(FILE, "<", $files->{'list.txt'}) or die("$!");
		my $buf = "";
		while(read(FILE, $buf, 60*57)) { print $handle encode_base64($buf); }
		close(FILE);
		print $handle join("", "\n", "--$boundary--\n");
	};
	my $sm = Mail::Salsa::Sendmail->new(
		smtp_server => $self->{'smtp_server'},
		timeout     => $self->{'timeout'},
	);
	$sm->everything(
		mail_from => "salsa-master\@$domain",
		rcpt_to   => ["$name-owner\@$domain"],
		data      => $refsub
	);
	return();
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mail::Salsa::Action::Admin - Perl extension for administrate the mailing 
lists.

=head1 SYNOPSIS

  use Mail::Salsa::Action::Admin;

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
