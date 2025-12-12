# This code is part of Perl distribution Mail-Transport version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Transport;{
our $VERSION = '4.00';
}

use parent 'Mail::Reporter';

use strict;
use warnings;

use Log::Report   'mail-transport', import => [ qw/__x error panic/ ];

use File::Spec    ();

#--------------------

my %mailers = (
	exim     => '::Exim',
	imap     => '::IMAP4',
	imap4    => '::IMAP4',
	mail     => '::Mailx',
	mailx    => '::Mailx',
	pop      => '::POP3',
	pop3     => '::POP3',
	postfix  => '::Sendmail',
	qmail    => '::Qmail',
	sendmail => '::Sendmail',
	smtp     => '::SMTP'
);


sub new(@)
{	my $class = shift;

	$class eq __PACKAGE__ || $class eq "Mail::Transport::Send"
		or return $class->SUPER::new(@_);

	# auto restart by creating the right transporter.

	my %args = @_;
	my $via  = lc($args{via} // '') or panic "no transport protocol provided";

	$via     = 'Mail::Transport'.$mailers{$via} if exists $mailers{$via};
	eval "require $via";
	$@ ? undef : $via->new(@_);
}

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	$self->{MT_hostname} = $args->{hostname} // 'localhost';
	$self->{MT_port}     = $args->{port};
	$self->{MT_username} = $args->{username};
	$self->{MT_password} = $args->{password};
	$self->{MT_interval} = $args->{interval} || 30;
	$self->{MT_retry}    = $args->{retry}    || -1;
	$self->{MT_timeout}  = $args->{timeout}  || 120;
	$self->{MT_proxy}    = $args->{proxy};

	if(my $exec = $args->{executable} || $args->{proxy})
	{	$self->{MT_exec} = $exec;

		File::Spec->file_name_is_absolute($exec)
			or error __x"avoid program abuse: specify an absolute path for {program}.", program => $exec;

		-x $exec
			or error __x"executable {program} does not exist.", program => $exec;
	}

	$self;
}

#--------------------

sub remoteHost() { @{$_[0]}{ qw/MT_hostname MT_port MT_username MT_password/ } }


sub retry() { @{$_[0]}{ qw/MT_interval MT_retry MT_timeout/ } }


my @safe_directories = qw(/usr/local/bin /usr/bin /bin /sbin /usr/sbin /usr/lib);

sub findBinary($@)
{	my ($self, $name) = (shift, shift);

	return $self->{MT_exec}
		if exists $self->{MT_exec};

	foreach (@_, @safe_directories)
	{	my $fullname = File::Spec->catfile($_, $name);
		return $fullname if -x $fullname;
	}

	undef;
}

#--------------------

1;
