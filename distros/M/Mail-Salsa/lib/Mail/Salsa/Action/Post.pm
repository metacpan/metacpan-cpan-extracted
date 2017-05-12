#
# Mail/Salsa/Action/Post.pm
# Last Modification: Wed Mar 17 19:11:38 WET 2010
#
# Copyright (c) 2010 Henrique Dias <henrique.ribeiro.dias@gmail.com>.
# All rights reserved.
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
package Mail::Salsa::Action::Post;

use 5.008000;
use strict;
use warnings;

require Exporter;
#use AutoLoader qw(AUTOLOAD);
use SelfLoader;
use Mail::Salsa::Utils qw(file_path create_file generate_id);
use Mail::Salsa::Logs qw(logs debug);
use Mail::Salsa::Archive qw(archive_msg);
use MIME::QuotedPrint qw();

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mail::Salsa ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = '0.05';

SelfLoader->load_stubs();

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
	unless($self->check_restrict('restrict.txt', $self->{'headers'}->{'0.0'}->{'received'}, [])) {
		Mail::Salsa::Utils::tplsendmail(
			smtp_server => $self->{'smtp_server'},
			timeout     => $self->{'timeout'},
			label       => "PERMISSION_DENY",
			lang        => $self->{'config'}->{'language'},
			vars        => {
				from => "$name\-owner\@$domain",
				to   => $self->{'from'},
				list => $self->{'list'},
			}
		);
		$self->logs(join("", "[permission deny] from: ", $self->{'from'}), "list");
		return();
	}
	if($self->{'config'}->{'max_message_size'} && (((-s $self->{'message'})/1024) > $self->{'config'}->{'max_message_size'})) {
		Mail::Salsa::Utils::tplsendmail(
			smtp_server => $self->{'smtp_server'},
			timeout     => $self->{'timeout'},
			label       => "MAX_MESSAGE_SIZE",
			lang        => $self->{'config'}->{'language'},
			vars        => {
				from => "$name\-owner\@$domain",
				to   => $self->{'from'},
				list => $self->{'list'},
				size => $self->{'config'}->{'max_message_size'},
			}
		);
		$self->logs(join("", "[max message size exceed] from: ", $self->{'from'}), "list");
		return();
	}
	if(scalar(keys(%{$self->{'headers'}})) > 1) {
		my $attachfile = file_path($self->{'list'}, $self->{'list_dir'}, "attachments.txt");
		my $listfile = file_path($self->{'list'}, $self->{'list_dir'}, "list.txt");
		my ($code, $access, $mime_type) = ("", "allow", "");
		if(my $error = &generate_code($listfile, $attachfile, $self->{'from'}, $code)) {
			$self->logs("[file] $error", "errors");
			return();
		}
		eval($code);
		if($@) {
			$self->logs("[eval] $@", "errors");
			return();
		}
		if($access eq "deny") {
			Mail::Salsa::Utils::tplsendmail(
				smtp_server => $self->{'smtp_server'},
				timeout     => $self->{'timeout'},
				label       => "NO_ATTACHMENTS",
				lang        => $self->{'config'}->{'language'},
				vars        => {
					from      => "$name\-owner\@$domain",
					to        => $self->{'from'},
					list      => $self->{'list'},
					mime_type => $mime_type,
				}
			);
			$self->logs(join("", "[deny attachment] mime-type: $mime_type from: ", $self->{'from'}), "list");
			return();
		}
	}

	$self->setup_stamp() if($self->{'config'}->{'stamp'} eq "y");
	my $reply = ($self->{'headers'}->{'0.0'}->{'subject'}->{'value'} =~ /^Re: /i) ? 1 : 0;
	my $bounce = $self->check4bounces();
	my $human = $self->setup_msg();
	$human = 0 unless($self->{'stamp'});

	if($bounce == 2) {
		# debug and test
		$self->logs(join("", "[been-there] from: ", $self->{'from'}), "list");
	} elsif($bounce && $self->{'config'}->{'accept_bounces'} eq "n") {
		Mail::Salsa::Utils::tplsendmail(
			smtp_server => $self->{'smtp_server'},
			timeout     => $self->{'timeout'},
			label       => "DONT_BOUNCE",
			lang        => $self->{'config'}->{'language'},
			vars        => {
				from => "$name\-owner\@$domain",
				to   => $self->{'from'},
				list => $self->{'list'},
			}
		);
		$self->logs(join("", "[bounce] from: ", $self->{'from'}), "list");
	} elsif($self->{'stamp'} && !$human) {
		Mail::Salsa::Utils::tplsendmail(
			smtp_server => $self->{'smtp_server'},
			timeout     => $self->{'timeout'},
			label       => "MAILSTAMP",
			lang        => $self->{'config'}->{'language'},
			vars        => {
				from  => "$name\-owner\@$domain",
				to    => $self->{'from'},
				list  => $self->{'list'},
				stamp => $self->{'stamp'}
			}
		);
		$self->logs(join("", "[sent stamp] to: ", $self->{'from'}), "list");
	} else {
		$self->sendmail4all();
		$self->logs(join("", "[post message] from: ", $self->{'from'}), "list");
		$self->archive_msg() if($self->{'config'}->{'archive'} eq "y");
	}
	unlink($self->{'message'});
	return();
}

sub check4bounces {
	my $self = shift;

	my $bounce = 1;
	my $list = $self->{'list'};
	$bounce = 0 if(lc($self->{'headers'}->{'0.0'}->{'to'}) =~ /\b$list\b/);
	$bounce = 0 if(exists($self->{'headers'}->{'0.0'}->{'cc'}) && lc($self->{'headers'}->{'0.0'}->{'cc'}) =~ /\b$list\b/);
	$bounce = 2 if(exists($self->{'headers'}->{'0.0'}->{'x-been-there'}) && $self->{'headers'}->{'0.0'}->{'x-been-there'} eq $self->{'list'});

	return($bounce);
}

sub setup_stamp {
	my $self = shift;

	my $sfile = file_path($self->{'list'}, $self->{'list_dir'}, 'stamp.txt');
	my ($number, $letter) = ($self->{'config'}->{'stamp_life'} =~ /^(\d+)([dwmy])$/);

	my $days = int(-M $sfile);
	my $newstamp = 0;

	if($letter eq "d") {
		$newstamp = 1 if($days > $number);
	} elsif($letter eq "w") {
		$newstamp = 1 if(int($days/7) > $number);
	} elsif($letter eq "m") {
		$newstamp = 1 if(int($days/30) > $number);
	} elsif($letter eq "y") {
		$newstamp = 1 if(int($days/365) > $number);
	}
	if($newstamp) {
		$self->{'stamp'} = uc(generate_id(32));
		create_file($sfile, join("", $self->{'stamp'}, "\n"), 0600);
	} else { $self->{'stamp'} = Mail::Salsa::Utils::get_key($sfile); }

	return();
}

sub exist_subscriber {
	my $file = shift;
	my $string = shift || return(0);

	my $exist = 0;
	open(MLIST, "<", $file) or return("$!");
	while(<MLIST>) {
		next if(/^[\#\x0d\x0a]/);
		if(/\b$string\b/) { $exist = 1; last; }
	}
	close(MLIST);
	return($exist);
}

sub generate_code {
	my $listfile = shift;
	my $attachfile = shift;
	my $from_addr = shift;

	$_[0] .= <<ENDCODE;
for my \$part (keys(\%{\$self->{'headers'}})) {
	\$mime_type = \$self->{'headers'}->{\$part}->{'content-type'}->{'value'};
	local \$_ = \$mime_type;
	next if(index(\$_, \"multipart\/\") > -1);
ENDCODE
	my $subscriber = 0;
	open(ATTACHMENT, "<", $attachfile) or return("$!");
	while(<ATTACHMENT>) {
		next if(/^[\#\x0d\x0a]/);
		my ($policy, $mime, $addr) = /^(\w+) +(\w+\/[\w\.\-\+]+) +from +(\S+)[\x0d\x0a]+/;
		if($addr eq "subscribers") {
			unless($subscriber) {
				$subscriber = &exist_subscriber($listfile, $from_addr);
				$subscriber = -1 unless($subscriber);
			}
			if($subscriber > 0) { $addr = $from_addr; }
			else { next; }
		}
		$mime =~ s{any(?=\/)}{\[\\w\\+\\-\\.\]\+}g;
		$mime =~ s{(?<=\/)any}{\[\\w\\+\\-\\.\]\+}g;
		$mime =~ s{\/}{\\\/};
		$addr =~ s/\@/\\\@/g;
		$addr =~ s/\./\\\./g;
		my $part = ($addr eq "any") ? "" : " (\$self-\>{\'from\'} =~ /$addr\$/) and";
		my $keyword = $policy eq "deny" ? "last" : "next";
		$_[0] .= "\t/\^$mime\$/ and$part \$access = \"$policy\", $keyword;\n";
	}
	close(ATTACHMENT);
	$_[0] .= "}\n";
	return();
}

sub sendmail4all {
	my $self = shift;

	my ($name, $domain) = split(/\@/, $self->{'list'});
	my $listfile = file_path($self->{'list'}, $self->{'list_dir'}, "list.txt");
	(my $outfile = $self->{'message'}) =~ s/\.msg$/\.out/;

	my $refsub = sub {
		my $handle = shift;
		open(FILE, "<", $outfile) or die("$!");
		while(<FILE>) {
			s{^\.}{\.\.};
			print $handle $_;
		}
		close(FILE);
	};
	my $sm = Mail::Salsa::Sendmail->new(
		smtp_server => $self->{'smtp_server'},
		timeout     => $self->{'timeout'},
		smtp_port   => 25,
	);
	$sm->everything(
		mail_from => "$name\-return\@$domain",
		list_file => $listfile,
		data      => $refsub
	);
	unlink($outfile);

	return();
}

sub set_headers {
	my $list = shift;

	my ($name, $domain) = split(/\@/, $list);
	my $headers = <<"EOF";
X-Salsa-Version: 0.01
X-Been-There: $name\@$domain
Precedence: bulk
List-Help: <mailto:$name-help\@$domain?subject=help\>
List-Unsubscribe: <mailto:$name-unsubscribe\@$domain?subject=unsubscribe\>
List-Subscribe: <mailto:$name-subscribe\@$domain?subject=subscribe\>
List-Admin: <mailto:$name-admin\@$domain\>
List-Post: \<mailto:$name\@$domain\>
EOF
	return($headers);
}

sub insert_text {
	my $handle = shift;
	my $file = shift;
	my $encoding = shift;

	open(BANNER, "<", $file) or die("$!");
	while(local $_ = <BANNER>) {
		my $line = ($encoding eq "quoted-printable") ? MIME::QuotedPrint::encode($_) : $_;
		print $handle $line;
	}
	close(BANNER);
	print $handle "\n";

	return();
}

sub check_encoding {
	my $encoding = shift || return(1);

	return(length($encoding) == 0 ? 1 :
			$encoding eq "quoted-printable" ? 1 :
				$encoding eq "7bit" ? 1 :
					$encoding eq "8bit" ? 1 : 0);
}

sub setup_msg {
	my $self = shift;
	
	my ($name, $domain) = split(/\@/, $self->{'list'});
	(my $outfile = $self->{'message'}) =~ s/\.msg$/\.out/;	

	my ($headerfile, $footerfile, $encoding) = ("", "", "");
	if($self->{'config'}->{'header'} eq "y") {
		$headerfile = file_path($self->{'list'}, $self->{'list_dir'}, "header.txt");
		(-e $headerfile && -s $headerfile) or $headerfile = "";
	}
	if($self->{'config'}->{'footer'} eq "y") {
		$footerfile = file_path($self->{'list'}, $self->{'list_dir'}, "footer.txt");
		(-e $footerfile && -s $footerfile) or $footerfile = "";
	}
	my $boundary = exists($self->{'headers'}->{'0.0'}->{'content-type'}->{'boundary'}) ? $self->{'headers'}->{'0.0'}->{'content-type'}->{'boundary'} : "";
	my ($tree, $count) = $boundary ? ("0.0.0", 0) : ("0.0", 1);

	if($headerfile || $footerfile) {
		if(exists($self->{'headers'}->{$tree}->{'content-type'}->{'value'}) &&
				$self->{'headers'}->{$tree}->{'content-type'}->{'value'} eq "text/plain") {
			if(exists($self->{'headers'}->{$tree}->{'content-transfer-encoding'}->{'value'})) {
				$encoding = $self->{'headers'}->{$tree}->{'content-transfer-encoding'}->{'value'};
				$encoding = $footerfile = $headerfile = "" unless(&check_encoding($encoding));
			}
		} else { $footerfile = $headerfile = ""; }
	}

	my $stamp = $self->{'stamp'} || "";
	my $prefix = $self->{'config'}->{'prefix'};
	my ($exist, $received, $headers, $topheaders) = (0, 1, 1, 1);
	open(INFILE, "<", $self->{'message'}) or die("$!");
	open(OUTFILE, ">", $outfile) or die("$!");
	select(OUTFILE);
	while(<INFILE>) {
		if($headers) {
			if($topheaders) {
				next if(&check_headers($_));
				s/^Subject: (.+)/Subject: $prefix $1/o if($prefix && index($_, $prefix, 0) == -1);
				$received = 0 if($received == 1 && !(/^(X-)?Received: / || /^[ \t]+/));
				if($received == 0) {
					print OUTFILE &set_headers($self->{'list'});
					$received = -1;
				}
			}
			$headers = 0 if(/^[\n\r]$/o);
		} else {
			$topheaders = 0;
			$exist = 1 if(s/\b$stamp\b//og);
			if($headerfile || $footerfile) {
				if($headerfile && $count == 1) {
					&insert_text(\*OUTFILE, $headerfile, $encoding);
					$headerfile = "";
				}
				if($boundary && /^--$boundary/) {
					$headers = 1;
					$count++;
				}
				if($footerfile && $count == 2) {
					&insert_text(\*OUTFILE, $footerfile, $encoding);
					$footerfile = "";
				}
			}
		}
		print OUTFILE $_;
	}
	&insert_text(\*OUTFILE, $footerfile, $encoding) if($footerfile);
	close(OUTFILE);
	close(INFILE);

	select(STDOUT);
	return($exist);
}

sub check_restrict {
	my $self = shift;
	my $thisfile = shift;
	my $receiveds = shift;
	my $array = shift || [];

	my $file = file_path($self->{'list'}, $self->{'list_dir'}, $thisfile);
	(-s $file) or return(1);
	my $count = scalar(@{$array});
	### ["policy", "address", "action", "network", "stamp"] ###
	$array = ["", "", "", "", ""] unless($count);
	my $netok = 0;

	open(FILE, "<", $file) or return(1);
	while(<FILE>) {
		next if(/^[\#\n\r]+/);
		chomp;
		if($count) {
			my ($addr) = (/\<?([^\@\<\>]+\@[^\@\<\>]+)\>?/);
			$array->[1] = $addr;
		} else {
			(@{$array}) = (/^(allow|deny) +(\S+) +to +(post|bounce|proceed) +from +(localnet|anywhere)( +with(out)? +stamp)?/);
		}
		if($array->[1] eq "subscribers") {
			$array->[1] = "";
			$netok = $self->check_restrict('list.txt', $receiveds, $array);
		} else {
			$self->{'config'}->{'accept_bounces'} = ($self->{'config'}->{'stamp'} = "n");
			my $address = $array->[1];
			if($address eq "any") {
				last if($array->[0] eq "deny" and $array->[3] eq "anywhere");
				$address = "\.+";
			}
			if($self->{'from'} =~ /$address$/) {
				$netok = ($array->[3] eq "anywhere") ? 1 :
						($array->[3] eq "localnet") ? &check_network($receiveds, $self->{'config'}->{'localnet'}) : 0;
			}
			if(defined($array->[4]) && $array->[4]) {
				$self->{'config'}->{'stamp'} = ($array->[0] eq "allow") ?
					(($array->[4] =~ /^ +without +stamp/) ? "n" : "y") :
						(($array->[4] =~ /^ +without +stamp/) ? "y" : "n");
			}
			if($array->[2] eq "bounce" or $array->[2] eq "proceed") {
				$self->{'config'}->{'accept_bounces'} = ($array->[0] eq "allow") ? "y" : ($self->{'config'}->{'stamp'} eq "y") ? "y" : "n";
			}
		}
		last if($netok);
	}
	close(FILE);
	return($netok);
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__DATA__

sub check_headers {
	$_ = shift;

	/^List\-\w+\: / and return(1);
	/^Precedence\: / and return(1);
	/^X-Salsa-Version: \d+\.\d+/ and return(1);
	/^X-Been-There: \w+/ and return(1);
	return(0);
}

sub check_network {
	my $receiveds = shift;
	my $network = shift;

	my $netok = 0;
	RECEIVED: for my $r (@{$receiveds}) {
		for my $thisnet (@{$network}) {
			(my $net = $thisnet) =~ s{\.}{\\\.}g;
			if($r =~ / \(([^\] ]+ +)?\[$net[\.\d]*\]( \(may be forged\))?\) /) {
				$netok = 1;
				next RECEIVED;
			}
			$netok = 0;
		}
		$netok or return(0);
	}
	return($netok);
}

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mail::Salsa::Action::Post - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Mail::Salsa::Action::Post;

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

Henrique M. Ribeiro Dias, E<lt>henrique.ribeiro.dias@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Henrique M. Ribeiro Dias

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
