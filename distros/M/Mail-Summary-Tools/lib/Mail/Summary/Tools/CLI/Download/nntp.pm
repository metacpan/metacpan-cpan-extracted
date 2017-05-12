#!/usr/bin/perl

package Mail::Summary::Tools::CLI::Download::nntp;
use base qw/Mail::Summary::Tools::CLI::Command/;

use strict;
use warnings;

#use Class::Autouse (<<'#\'END_USE' =~ m!(\w+::[\w:]+)!g);
#\

use Net::NNTP;
use Mail::Box::Manager;
use Mail::Message;

use DateTime;
use DateTime::Format::DateManip;

use Mail::Summary::Tools::Downloader::NNTP;

#'END_USE

use constant options => (
	[ 'server|s=s'  => "The NNTP server to download from", { required => 1 } ],
	[ 'group|g=s@'  => "The groups to download", { required => 1 } ],
	[ 'output|o=s'  => "Output mailbox" ],
	[ 'from|f=s'    => "Something Date::Manip can parse" ],
	[ 'to|t=s'      => "Something Date::Manip can parse" ],
	[ 'recursive|r' => "Fetch `References` headers recursively", { default => 1 } ],
);

sub validate {
	my ( $self, $opt, $args ) = @_;
	@$args and $opt->{output} ||= shift @$args;

	my $mgr = Mail::Box::Manager->new;

	$opt->{output} = $mgr->open(
		folder => $opt->{output},
		create => 1,
		access => "rw",
	);

	foreach my $mbox ( @$args ) {
		$mbox = $mgr->open(
			folder => $mbox,
			create => 0,
			access => "r",
		)
	};

	$_ = $_ ? DateTime::Format::DateManip->parse_datetime($_) : DateTime::Infinite::Past->new for $opt->{from};
	$_ = $_ ? DateTime::Format::DateManip->parse_datetime($_) : DateTime::Infinite::Future->new for $opt->{to};

	$self->usage_error("You must provide an output mailbox.") unless $opt->{output};
}

sub run {
	my ( $self, $opt, $args ) = @_;


	my $nntp = Mail::Summary::Tools::Downloader::NNTP->new(
		server            => $opt->{server},
		fetch_recursively => $opt->{recursive},
		cache             => $self->app->context->nntp_overviews,
	);

	foreach my $group ( @{ $opt->{group} } ){
		$nntp->download(
			group           => $group,
			from            => $opt->{from},
			to              => $opt->{to},
			mailbox         => $opt->{output},
			extra_mailboxes => $args,
		);
	}
}


__PACKAGE__;

__END__

=pod

=head1 NAME

Mail::Summary::Tools::CLI::Download::nntp - Download threads from an NNTP server.

=head1 SYNOPSIS

	# see usage summary

=head1 DESCRIPTION

=cut


