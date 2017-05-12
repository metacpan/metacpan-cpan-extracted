#
# Mail/Salsa/Action/Personalize
# Last Modification: Wed Apr  6 16:09:58 WEST 2005
#
# Copyright (c) 2005 Henrique Dias <hdias@aesbuc.pt>. All rights reserved.
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
package Mail::Salsa::Action::Personalize;

use 5.008000;
use strict;
use warnings;

require Exporter;
use Mail::Salsa::Utils qw(file_path create_file generate_id email_components);
use Mail::Salsa::Logs qw(logs debug);
use Mail::Salsa::Archive qw(archive_msg);
use Mail::Salsa::Action::Post;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mail::Salsa ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = '0.02';

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {@_};
	bless ($self, $class);
	$self->process_msg();
	return($self);
}

sub check_restrict {
	my $self = shift;
	$self->Mail::Salsa::Action::Post::check_restrict(@_);
}

sub process_msg {
	my $self = shift;

	my ($name, $domain) = split(/\@/, $self->{'list'});
	unless($self->Mail::Salsa::Action::Post::check_restrict('restrict.txt', $self->{'headers'}->{'0.0'}->{'received'}, [])) {
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
		if(my $error = Mail::Salsa::Action::Post::generate_code($listfile, $attachfile, $self->{'from'}, $code)) {
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
	$self->{'headers'}->{'0.0'}->{'to'} =~ s/\-personalize(?=\@)//;
	$self->Mail::Salsa::Action::Post::setup_stamp() if($self->{'config'}->{'stamp'} eq "y");
	my $reply = ($self->{'headers'}->{'0.0'}->{'subject'}->{'value'} =~ /^Re: /i) ? 1 : 0;
	my $bounce = $self->Mail::Salsa::Action::Post::check4bounces();
	my $human = $self->Mail::Salsa::Action::Post::setup_msg();
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
		$self->logs(join("", "[personalize message] from: ", $self->{'from'}), "list");
		$self->archive_msg() if($self->{'config'}->{'archive'} eq "y");
	}
	unlink($self->{'message'});
	return();
}

sub sendmail4all {
	my $self = shift;

	my ($name, $domain) = split(/\@/, $self->{'list'});
	my $listfile = file_path($self->{'list'}, $self->{'list_dir'}, "list.txt");

	(my $outfile = $self->{'message'}) =~ s/\.msg$/\.out/;
	open(LIST, "<", $listfile);
	while(<LIST>) {
		my $fullemail = email_components($_);
		exists($fullemail->{'address'}) or next;
		$fullemail->{'username'} = "Mailing List Subscriber" unless(exists($fullemail->{'username'}));
		my ($username, $email) = ($fullemail->{'username'}, $fullemail->{'address'});

		my $sm = Mail::Salsa::Sendmail->new(
			'smtp_server' => $self->{'smtp_server'},
			'smtp_port'   => 25,
			'timeout'     => $self->{'timeout'},
		);
		$sm->helo();
		$sm->mail_from("$name\-return\@$domain");
		$sm->rcpt_to('addresses' => [$email]);
		$sm->data(sub {
			my $handle = shift;
			open(SENDFILE, "<", $outfile) or die("$!");
			while(<SENDFILE>) {
				s/^To: +[^\n\r]+/To: $username \<$email\>/io;
				s/\$FULLNAME\b/$username/o;
				s/\$EMAIL\b/$email/o;
				print $handle $_;
			}
			close(SENDFILE);
		});
		$sm->quit();
	}
	close(LIST);
	unlink($outfile);

	return();
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mail::Salsa::Action::Personalize - Perl extension for send personalized
messages to the members of the mailing list.

=head1 SYNOPSIS

  use Mail::Salsa::Action::Personalize;

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

Copyright (C) 2005 by Henrique M. Ribeiro Dias

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
