#
# Mail/Salsa/Sendmail.pm
# Last Modification: Wed Jun 23 17:11:01 WEST 2004
#
# Copyright (c) 2004 Henrique Dias <hdias@aesbuc.pt>. All rights reserved.
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
package Mail::Salsa::Sendmail;

use 5.008000;
use strict;
use warnings;
use IO::Socket;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mail::Salsa::Sendmail ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = '0.01';

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {
		'smtp_server' => ["localhost"],
		'smtp_port'   => 25,
		'timeout'     => 120,
		'mail_from'   => "",
		'rcpt_to'     => [],
		'list_file'   => "",
		'data'        => undef,
		'filehandle'  => undef,
		@_
	};
	bless ($self, $class);
	return($self->init() ? $self : undef);
}

sub send_data {
	my $handle = shift;
	my $data = shift;

	unless($data =~ /\n+$/) { $data = join("", $data, "\n"); }
	print $handle "$data";
	return(&get_answer($handle));
}

sub helo {
	my $self = shift;

	defined($self->{'filehandle'}) or return("Error");
	my $hostname = $self->{'smtp_server'}->[0];
	return(&send_data($self->{'filehandle'}, "HELO $hostname\n"));
}

sub mail_from {
	my $self = shift;
	my $mailfrom = shift || return("Error");

	defined($self->{'filehandle'}) or return("Error");
	return(&send_data($self->{'filehandle'}, "MAIL FROM: $mailfrom\n"));
}

sub rcpt_to {
	my $self = shift;
	my $param = {
		list_file => "",
		addresses => [],
		@_,
	};
	defined($self->{'filehandle'}) or return("Error");
	if($param->{'list_file'} && -e $param->{'list_file'} && -s $param->{'list_file'}) {
		open(LIST, "<", $param->{'list_file'}) or die("$!");
		while(<LIST>) {
			next if(/^\#/);
			chomp;
			my ($email) = (/\<?([^\@\<\>]+\@[^\@\<\>]+)\>?/);
			&send_data($self->{'filehandle'}, "RCPT TO: $email\n");
		}
		close(LIST);
	}
	if(scalar(@{$param->{'addresses'}})) {
		for my $email (@{$param->{'addresses'}}) {
			&send_data($self->{'filehandle'}, "RCPT TO: $email\n");
		}
	}
	return();
}

sub data {
	my $self = shift;
	my $code = shift || return("Error");

	defined($self->{'filehandle'}) or return("Error");
	&send_data($self->{'filehandle'}, "DATA\n");
	(ref($code) eq "CODE") or return("Error");
	$code->($self->{'filehandle'});
	return(&send_data($self->{'filehandle'}, ".\n"));
}

sub quit {
	my $self = shift;

	defined($self->{'filehandle'}) or return("Error");
	&send_data($self->{'filehandle'}, "QUIT\n");
        $self->{'filehandle'}->close();
	return();
}

sub everything {
	my $self = shift;
	my $param = {
		'mail_from' => $self->{'mail_from'},
		'rcpt_to'   => $self->{'rcpt_to'},
		'list_file' => $self->{'list_file'},
		'data'      => $self->{'data'},
		@_
	};
	$self->helo();
	$self->mail_from($param->{'mail_from'});
	$self->rcpt_to(
		list_file => $param->{'list_file'},
		addresses => $param->{'rcpt_to'}
	);
	$self->data($param->{'data'});
	$self->quit();
	return();
}

sub init {
	my $self = shift;

	my $handle;
	for my $host (@{$self->{'smtp_server'}}) {
		$handle = IO::Socket::INET->new(
			Timeout  => $self->{'timeout'},
			Proto    => "tcp",
			PeerAddr => $host,
			PeerPort => $self->{'smtp_port'}
		);
		$self->{'smtp_server'}->[0] = $host;
		last if(defined($handle));
	}

	defined($handle) or return();
	$handle->autoflush(1);
	&get_answer($handle);

	$self->{'filehandle'} = $handle;
	return(1);
}

sub get_answer {
	my $handle = shift;
	my $answer = <$handle>;
	my ($code) = ($answer =~ /^(\d\d\d) /);

##	&logs("SMTP ANSWER: $answer");
	($code < 500) or return($answer);
##	print "SMTP ANSWER: $answer\n";
	return();
}

sub logs {
	my $string = shift;
	open(LOGS, ">>", "/tmp/____logs.log") or die("$!");
	print LOGS "$string\n";
	close(LOGS);
	return();
}

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mail::Salsa::Sendmail - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Mail::Salsa::Sendmail;

  my $sm = Mail::Salsa::Sendmail->new(
    'smtp_server' => ["localhost"],
    'smtp_port'   => 25,
    'timeout'     => 120,
  );
  $sm->helo();
  $sm->mail_from("salsa\@aesbuc.pt");
  $sm->rcpt_to(
    'list_file' => "/usr/local/salsa/lists/mylist.txt",
    'addresses' => ["hdias\@aesbuc.pt"]
  );
  $sm->data(sub {
    my $handle = shift;
    print $handle "Hello!\n";
  });
  $sm->quit();

  * In one step

  my $sm = Mail::Salsa::Sendmail->new(
    'smtp_server' => ["localhost"],
    'smtp_port'   => 25,
    'timeout'     => 120,
  );
  $sm->everything(
    'mail_from' => "$name\-return\@$domain",
    'rcpt_to'   => ["hdias\@aesbuc.pt"],
    'list_file' => $listfile,
    'data'      => sub { my $handle = shift; print $handle "Hello!\n"; }
  );

=head1 DESCRIPTION

Stub documentation for Mail::Salsa, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

telnet 192.168.0.1 25
HELO mysmtp.server.org
MAIL FROM: hdias@aesbuc.pt
RCPT TO: test@aesbuc.pt
DATA
test
.
QUIT

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

Copyright (C) 2004 by Henrique M. Ribeiro Dias

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
