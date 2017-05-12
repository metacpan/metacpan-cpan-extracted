#!/usr/bin/perl

package Mail::Summary::Tools::CLI::Create;
use base qw/Mail::Summary::Tools::CLI::Command/;

use strict;
use warnings;

use DateTime::Format::DateManip;
use DateTime::Infinite;

use Class::Autouse (<<'#\'END_USE' =~ m!(\w+::[\w:]+)!g);
#\

use Mail::Box::Manager;

use Mail::Summary::Tools::Summary;
use Mail::Summary::Tools::Summary::List;
use Mail::Summary::Tools::Summary::Thread;
use Mail::Summary::Tools::ThreadFilter;

#'END_USE

use Mail::Summary::Tools::ThreadFilter::Util qw/
	get_root_message guess_mailing_list
	thread_root last_in_thread any_in_thread all_in_thread
	negate
	mailing_list_is in_date_range
/; # subject_matches

sub usage_desc {
	"%c create %o summary.yaml mailbox [mailbox2]\n".
	"%c create \%o -o summary.yaml -i mailbox -i mailbox2"
}

use constant options => (
	[ 'input|i=s@'   => "Mailboxes to read from (can be used several times)" ],
	[ 'output|o=s'   => "Summary file to write" ],
	[ 'update|u!'    => "Update an existing summary" ],
	[ 'from|f=s'     => "From date (any string Date::Manip can parse)" ],
	[ 'to|t=s'       => "To date (any string Date::Manip can parse)" ],
	[ 'list|l=s@'    => "Only posts in this list (can be used several times)" ],
	#[ 'subject|s=s' => "subject" ], # TODO
	[ 'posters|p!'   => "Collect information about posters (defaults to true)", { default => 1 } ],
	[ 'dates|d!'     => "Collect information about dates (defaults to true)", { default => 1 } ],
	#[ 'm|match=s'   => "match" ], # TODO
	[ 'clean|c!'     => "Scrub the thread subjects" ],
	[ 'rt|r!'        => "Collect information about RT tickets (defaults to true)", { default => 1 } ],
);

sub construct_filters {
	my $self = shift;

	return (
		$self->construct_date_filter,
		$self->construct_list_filter,
		$self->construct_subject_filter,
	);
}

sub construct_date_filter {
	my $self = shift;
	my $opt = $self->{opt};

	my $from = DateTime::Format::DateManip->parse_datetime( $opt->{from} || return );
	my $to   = DateTime::Format::DateManip->parse_datetime( $opt->{to} || return );

	if ( defined($from) || defined($to) ) {
		$from = DateTime::Infinite::Past->new   unless defined($from);
		$to   = DateTime::Infinite::Future->new unless defined($to);

		return $self->comb_filter( in_date_range( $from, $to ) );
	} else {
		die "From or to date specification is invalid\n";
	}
}

sub construct_list_filter {
	my $self = shift;

	if ( my $list = $self->{opt}{list} ) {
		return $self->comb_filter( mailing_list_is($list) );
	} else {
		return;
	}
}

sub construct_subject_filter {
	return;
}

sub comb_filter {
	my ( $self, $filter ) = @_;
	any_in_thread( $filter );
}

sub filter {
	my ( $self, @params ) = @_;

	my $f = Mail::Summary::Tools::ThreadFilter->new(
		filters => [ $self->construct_filters ],
	);

	return $f->filter(@params);
}

sub clean_subject {
	my ( $self, $subject ) = @_;

	return $subject unless $self->{opt}{clean};

	$subject =~ s/^\s*(?:Re|Fwd):\s*//i;
	$subject =~ s/^\s*\[[\w-]+\]\s*//; # remove [Listname] munging
	$subject =~ s/^\s*|\s*$//g; # strip whitespace

	return $subject;
}

sub validate {
	my ( $self, $opt, $args ) = @_;
	$self->{opt} = $opt;

	@$args and $opt->{$_} ||= shift @$args for qw/output/;
	push @{ $opt->{input} ||= [] }, @$args; @$args = ();

	unless ( $opt->{output} and @{ $opt->{input} } ) {
		$self->usage_error("Please specify a summary output file and at least one mail box for input.");
	}
}

sub run {
	my ( $self, $opt, $args ) = @_;

	my @folders     = @{ $opt->{input} };
	my $summary_out = $opt->{output};

	if ( -f $summary_out and !$opt->{update} ) {
		die "The output file '$summary_out' exists. Either remove it or specify the --update option\n";
	}
	
	my $summary = -f $summary_out
		? Mail::Summary::Tools::Summary->load( $summary_out )
		: Mail::Summary::Tools::Summary->new;

	$self->diag("loading and threading mailboxes: @folders");

	my $mgr = Mail::Box::Manager->new;
	my $threads = $mgr->threads(
		folders  => [ map { $mgr->open( folder => $_ ) } @folders ],
		timespan => 'EVER',
		window   => 'ALL',
		( $self->app->global_options->{verbose} ? (trace => "PROGRESS") : ()),
	);

	my %lists = map { $_->name => $_ } $summary->lists;
	my %seen;

	$self->filter( threads => $threads, callback => sub {
		my $thread = shift;
		
		my $root = get_root_message($thread);
		return if $seen{$root->messageId}++;

		my $list_name = eval { guess_mailing_list($root)->listname };
		my $list_key = $list_name || "unknown";

		my $list = $lists{$list_key} ||= do {	
			my $list = Mail::Summary::Tools::Summary::List->new( $list_name ? (name => $list_name) : () );
			$summary->add_lists( $list );
			$list;
		};

		my $summarized_thread = Mail::Summary::Tools::Summary::Thread->from_mailbox_thread( $thread,
			collect_posters => $opt->{posters},
			collect_dates   => $opt->{dates},
			collect_rt      => $opt->{dates},
			process_subject => sub { $self->clean_subject(shift) },
		);

		#$summarized_thread->extra->{ .... } = { ... }

		if ( my $existing = $summary->get_thread_by_id( $summarized_thread->message_id ) ) {
			my $was_out_of_date = $existing->extra->{out_of_date};
			$existing->merge( $summarized_thread );
			$self->diag($summarized_thread->message_id . " is now out of date") if !$was_out_of_date and $existing->extra->{out_of_date};
		} else {
			$self->diag($summarized_thread->message_id . " has been added to the summary");
			$list->add_threads( $summarized_thread );
		}
	});

	$self->diag( "found threads in the mailing lists: @{[ map { $_->name || '<unknown>' } values %lists ]}" );

	$summary->save( $summary_out );
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Mail::Summary::Tools::CLI::Create - Create or update a summary file from mailboxes

=head1 SYNOPSIS

	# see command line usage

=head1 DESCRIPTION

=cut


