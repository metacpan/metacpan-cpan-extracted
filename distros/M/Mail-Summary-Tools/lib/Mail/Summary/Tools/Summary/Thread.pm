#!/usr/bin/perl

package Mail::Summary::Tools::Summary::Thread;
use Moose;

use Mail::Summary::Tools::ArchiveLink::Easy;
use Mail::Summary::Tools::ArchiveLink::Hardcoded;
use Mail::Address;

has subject => (
	isa => "Str",
	is  => "rw",
	required => 1,
);

has message_id => (
	isa => "Str",
	is  => "rw",
	required => 1,
);

has hidden => (
	isa => "Bool|Str",
	is  => "rw",
	required => 0,
);

has extra => (
	isa => "HashRef",
	is  => "rw",
	default => sub { return { } },
	required => 0,
);

has summary => (
	isa => "Str",
	is  => "rw",
	required => 0,
	default  => "",
);

has default_archive => (
	isa => "Str",
	is  => "rw",
	default => "google",
);

has archive_link => (
	isa  => "Mail::Summary::Tools::ArchiveLink",
	is   => "rw",
	lazy => 1,
	default => sub { $_[0]->make_archive_link },
);

has archive_link_params => (
	isa => "HashRef",
	is  => "rw",
	auto_deref => 1,
	default => sub { return {} },
);

sub _extract_name {
	# this is a slightly less eager _extract_name from Mail::Address
	# that version was mean to chromatic, making him turn out as Chromatic
	# the case changing logic has been removed
	my ( $self, $name ) = @_;
	local $_ = $name;

	# trim whitespace
	s/^\s+//;
	s/\s+$//;
	s/\s+/ /;

	# Disregard numeric names (e.g. 123456.1234@compuserve.com)
	return "" if /^[\d ]+$/;

	# remove outermost parenthesis
	s/^\((.*)\)$/$1/;

	# remove outer quotation marks
	s/^"(.*)"$/$1/;

	# remove minimal embedded comments
	s/\(.*?\)//g;

	# remove all escapes
	s/\\//g;

	# remove internal quotation marks
	s/^"(.*)"$/$1/;

	# reverse "Last, First M." if applicable
	s/^([^\s]+) ?, ?(.*)$/$2 $1/;
	s/,.*//;

	# some cleanup
	s/\[[^\]]*\]//g;
	s/(^[\s'"]+|[\s'"]+$)//g;
	s/\s{2,}/ /g;

	return $_;
}

sub from_mailbox_thread {
	my ( $class, $thread, %options ) = @_;

	my @messages = $thread->threadMessages;

	my $root = $messages[0];

	my $subject = $root->subject;
	$subject = $options{process_subject}->($subject) if $options{process_subject};

	my %extra;

	if ( $options{collect_posters} ) {
		my @from_fields = map { $_->head->get('From')->study } @messages;

		my %seen_email;
		my @addresses = grep { !$seen_email{$_->address}++ }
			map { Mail::Address->parse($_->decodedBody) } @from_fields;

		my @posters = map {{
			name  => $class->_extract_name($_->phrase) || $class->_extract_name($_->comment) || $_->user,
			email => $_->address,
		}} @addresses;

		$extra{posters} = \@posters;
	}

    if ( $options{collect_dates} ) {
        $extra{date_from} = $thread->startTimeEstimate;
        $extra{date_to}   = $thread->endTimeEstimate;
    }

    if ( $options{collect_rt} ) {
        eval { $extra{rt_ticket} = $root->head->get('RT-Ticket')->unfoldedBody };
    }

	my @message_ids = grep { $_ ne $root->messageId } map { $_->messageId } @messages;
	$extra{messages} = \@message_ids if @message_ids;

	$class->new(
		subject    => $subject,
		message_id => $root->messageId,
		extra => \%extra,
	);
}

sub load {
	my ( $class, $hash, %options ) = @_;

	my @good_keys = qw/summary message_id subject hidden/;

	my %hash = %$hash;

	my %good_values;
	@good_values{@good_keys} = delete @hash{@good_keys};

	my ( $thread_uri, $message_uri ) = delete @hash{qw/thread_uri message_uri/};

	if ( defined($thread_uri) || defined($message_uri) ) {
		$good_values{archive_link} = Mail::Summary::Tools::ArchiveLink::Hardcoded->new(
			thread_uri  => $thread_uri,
			message_uri => $message_uri,
		);
	}

	$class->new(
		%{ $options{thread} },
		%good_values,
		extra => \%hash,
	);
}

sub to_hash {
	my $self = shift;
	
	my @link_info;
	if ( exists $self->{archive_link} ) { # FIXME $self->meta->get_attribute_by_name("archive_link)->is_initialized( $self )
		if ( (my $link = $self->archive_link)->isa("Mail::Summary::Tools::ArchiveLink::Hardcoded") ) {
			@link_info = (
				eval { thread_uri  => $link->thread_uri->as_string },
				eval { message_uri => $link->message_uri->as_string },
			);
		}
	}

	return {
		subject    => $self->subject,
		message_id => $self->message_id,	
		summary    => $self->summary,
		hidden     => $self->hidden,
		@link_info,
		%{ $self->extra },
	};
}

sub make_archive_link {
	my $self = shift;

	my $constructor = $self->default_archive;
	Mail::Summary::Tools::ArchiveLink::Easy->$constructor( $self->message_id, $self->archive_link_params );
}

# FIXME
# redo with an attribute grammar

sub merge {
	my ( $self, $thread ) = @_;

	$self->merge_extra( $thread );
	$self->merge_summary( $thread );
	$self->merge_subject( $thread );
	$self->merge_hidden( $thread );
	$self->merge_archive_link( $thread );
}

sub merge_hidden {
	my ( $self, $thread ) = @_;
	$self->hidden( $self->hidden || $thread->hidden );
}

sub merge_summary {
	my ( $self, $thread ) = @_;
	$self->summary( $self->summary || $thread->summary );
}

sub merge_subject {
	my ( $self, $thread ) = @_;
	# noop
}

sub merge_archive_link {
	my ( $self, $thread ) = @_;

	my @hard_coded = grep { $_->isa("Mail::Summary::Tools::ArchiveLink::Hardcoded") } $self->archive_link, $thread->archive_link;

	if ( @hard_coded ) {
		$self->archive_link( $hard_coded[0] );
	}
}

sub merge_extra {
	my ( $self, $thread ) = @_;

	$self->extra({
		%{ $thread->extra },
		%{ $self->extra },
		$self->merge_dates( $thread ),
		$self->merge_posters( $thread ),
	});
}

sub merge_dates {
	my ( $self, $thread ) = @_;

	return (
		$self->merge_date_from($thread),
		$self->merge_date_to($thread),
		$self->merge_out_of_date($thread),
	);
}

sub merge_out_of_date {
	my ( $self, $thread ) = @_;
	# it can't be out of date if there's no summary
	return unless $self->summary or $thread->summary or $self->hidden or $thread->hidden;

	# if any thread is out of date then this one becomes out of date

	my $prev_out_of_date = $self->extra->{out_of_date};
   	my $out_of_date = $prev_out_of_date || $thread->extra->{out_of_date};

	my $earliest = $self->earlier_thread( $thread );
	my $latest   = $self->later_thread( $thread );

	if ( $self->summary || $self->hidden ) {
		# we keep the existing summary, and if the other thread extends beyond
		# our range it's out of date
		$out_of_date = 1 if $earliest != $self or $latest != $self;
	} elsif ( $thread->summary || $thread->hidden ) {
		# we take the new summary, and if we extend beyond the other range then
		# it's out of date
		$out_of_date = 1 if $earliest != $thread or $latest != $thread;
	} else {
		$out_of_date = 0;
	}

	if ( $out_of_date xor $prev_out_of_date ) {
		return out_of_date => $out_of_date;
	} else {
		return;
	}
}

sub earlier_thread {
	my ( $self, $thread ) = @_;

	my $date_from = $self->extra->{date_from};
	my $other_date_from = $thread->extra->{date_from};

	if ( $date_from and $other_date_from ) {
		return $date_from <= $other_date_from ? $self : $thread;
	} elsif( $date_from || $other_date_from ) {
		return $date_from ? $self : $thread;
	} else {
		return $self;
	}
}

sub later_thread {
	my ( $self, $thread ) = @_;

	my $date_to = $self->extra->{date_to};
	my $other_date_to = $thread->extra->{date_to};

	if ( $date_to and $other_date_to ) {
		return $date_to >= $other_date_to ? $self : $thread;
	} elsif ( $date_to || $other_date_to ) {
		return $date_to ? $self : $thread;
	} else {
		return $self;
	}
}

sub merge_date_from {
	my ( $self, $thread ) = @_;

	# earliest

	my $min = ( $self->earlier_thread( $thread ) )->extra->{date_from};
	no warnings 'uninitialized';
	unless ( $min == $self->extra->{date_from} ) {
		return ( date_from => $min );
	} else {
		return;
	}
}

sub merge_date_to {
	my ( $self, $thread ) = @_;

	my $max = ( $self->later_thread( $thread ) )->extra->{date_to};
	no warnings 'uninitialized';
	unless ( $max == $self->extra->{date_to} ) {
		return ( date_to => $max );
	} else {
		return;
	}
}

sub merge_posters {
	my ( $self, $thread ) = @_;	

	my %seen;
	my @posters = grep { !$seen{$_->{name}}++ }
		@{ $self->extra->{posters} || [] },
		@{ $thread->extra->{posters} || [] };

	return ( @posters ? (posters => \@posters) : () );
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Mail::Summary::Tools::Summary::Thread - 

=head1 SYNOPSIS

	use Mail::Summary::Tools::Summary::Thread;

=head1 DESCRIPTION

=cut


