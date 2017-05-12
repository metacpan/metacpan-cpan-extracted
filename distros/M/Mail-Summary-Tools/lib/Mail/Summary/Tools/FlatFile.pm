#!/usr/bin/perl

package Mail::Summary::Tools::FlatFile;
use Moose;

use File::Slurp ();
use YAML::Syck ();

use Mail::Summary::Tools::ArchiveLink::Hardcoded;

has summary => (
	isa => "Mail::Summary::Tools::Summary",
	is  => "rw",
	required => 1,
);

has uri_type => (
	isa => "Str",
	is  => "rw",
	default => "thread_uri",
);

has skip_summarized => (
	isa => "Bool",
	is  => "rw",
	default => 0,
);

has include_hidden => (
	isa => "Bool",
	is  => "rw",
	default => 0,
);

has list_posters => (
	isa => "Bool",
	is  => "rw",
	default => 0,
);

has add_links => (
	isa => "Bool",
	is  => "rw",
	default => 0,
);

has list_dates => (
    isa => "Bool",
    is  => "rw",
    default => 0,
);

has list_misc => (
    isa => "Bool",
    is  => "rw",
    default => 0,
);

has extra_fields => (
	isa => "ArrayRef",
	is  => "rw",
	auto_deref => 1,
	default => sub { [] },
);

has patterns => (
	isa => "ArrayRef",
	is  => "rw",
	auto_deref => 1,
	default => sub { [] },
);

sub save {
	my ( $self, $file ) = @_;

	my $text = $self->emit_summary( $self->summary );

	if ( $file ) {
		File::Slurp::write_file( $file, $text );
	}

	$text;
}

sub load {
	my ( $self, $text ) = @_;

	$text = File::Slurp::read_file($text) unless $text =~ qr/---/;

	foreach my $thread ( grep { length($_) } split /\s*\n---\n\s*/s, $text ) {
		$self->load_thread( $thread );
	}

	return 1;
}

sub load_thread {
	my ( $self, $text ) = @_;

	my ( $head, $junk, $summary_text ) = split /\n\n\s*/, $text, 3;

	# filter out comments
	($_||='') =~ s/^#.*$//mg for $head, $junk, $summary_text;
	return unless $head =~ /\S/;

	local $YAML::Syck::ImplicitTyping = 1;
	my $meta_data = eval { YAML::Syck::Load($head) };
	die "Error parsing YAML header: $@\n$head\n" if $@;

	my ( $id, $list ) = delete @{ $meta_data }{qw/message_id list/};

	die "No message id in header:\n$head\n" unless $id;

	# FIXME - autovivify?.
	my $thread = $self->summary->get_thread_by_id($id)
		|| die "There is no thread with the message ID <$id> in the current summary.\n$text";

	my ( $thread_uri, $message_uri ) = delete @{ $meta_data }{qw/thread_uri message_uri/};

	if ( defined($thread_uri) || defined($message_uri) ) {
		$meta_data->{archive_link} = Mail::Summary::Tools::ArchiveLink::Hardcoded->new(
			thread_uri  => $thread_uri,
			message_uri => $message_uri,
		);
	}

	my $out_of_date = delete $meta_data->{out_of_date};

	if ( $out_of_date ) {
		$thread->extra->{out_of_date} = 1;
	} else {
		delete $thread->extra->{out_of_date};
	}

	$meta_data->{summary} = $summary_text;

	foreach my $field ( keys %$meta_data ) {
		if ( $thread->can($field) ) {
			$thread->$field( $meta_data->{$field} );
		} else {
			$thread->extra->{$field} = $meta_data->{$field};
		}
	}

	foreach my $field ( $self->extra_fields ) {
		next if exists $meta_data->{$field};

		if ( $thread->can($field) ) {
			$thread->$field( undef );
		} else {
			delete $thread->extra->{$field};
		}
	}

	$self->set_list( $list, $thread );
}

sub set_list {
	my ( $self, $list, $thread ) = @_;

	return;

	$list = $self->get_list_by_name( $list ) unless ref $list;
}

sub emit_summary {
	my ( $self, $summary ) = @_;
	return join("", map { "$_\n\n---\n" } <<'PRE', map { $self->emit_list($_) } $summary->lists );
# Threads are separated with the sequence "\n---\n"
# Every thread is composed of three chunks, separated by "\n\n"
# The first chunk is YAML meta data. You may edit it. The second
# chunk is comments, ignored by the parser. The third contains the
# summary which should be written in the Markdown language.

# the -s option skips threads that have already been summarized
# the -H option forces inclusion of hidden threads
# the -e option dumps additional fields in the YAML (e.g. -e my_header -e my_other_header )
# the -P option skips threads not matching the specified patterns (e.g. -P todo -P EvilUser )
PRE
}

sub emit_list {
	my ( $self, $list ) = @_;
	map { $self->emit_thread($_, $list) } $list->threads;
}

sub emit_thread {
	my ( $self, $thread, $list ) = @_;

	return if $self->skip_summarized and $thread->summary and !$thread->extra->{out_of_date};
	return if $thread->hidden and !$self->include_hidden;

	my $formatted = join("\n\n",
		$self->emit_head($thread, $list),
		$self->emit_junk($thread, $list),
		$self->emit_body($thread, $list),
	);

	if ( my @patterns = $self->patterns ) {
		foreach my $pattern ( @patterns ) {
			return $formatted if $formatted =~ $pattern;
		}

		return;
	} else {
		return $formatted;
	}
}

sub emit_head {
	my ( $self, $thread, $list ) = @_;

	local $YAML::Syck::Headless = 1;

	# FIXME YAML::Syck doesn't work well with Headless... is it OK now?
	#local $YAML::UseHeader = 0;
	#require YAML;

	my %extra_fields;

	foreach my $field ( $self->extra_fields ) {
		if ( defined( my $value = ($thread->can($field) ? $thread->$field : $thread->extra->{$field}) ) ) {
			$extra_fields{$field} = $value;
		}
	}

	my $yaml = YAML::Syck::Dump({
		list => $list->name,
		message_id => $thread->message_id,
		subject => $thread->subject,
		( $thread->hidden ? ( hidden => $thread->hidden ) : () ),
		( $thread->extra->{out_of_date} ? ( out_of_date => 1 ) : () ),
		%extra_fields,
	});
	chomp($yaml);
	return $yaml;
}

sub emit_body {
	my ( $self, $thread, $list ) = @_;

	return $thread->summary || "";
}

sub emit_junk {
	my ( $self, $thread, $list ) = @_;

	my $uri_type = $self->uri_type;

	my @lines = (
		"# these lines are ignored",
	);

    if ( $self->add_links ) {
		my $uri = $thread->archive_link->$uri_type;
        push @lines, "<$uri>";
    }

	if ( $self->list_dates ) {
	   push @lines, sprintf "Start date: %s", scalar(localtime($thread->extra->{date_from})) if $thread->extra->{date_from};
	   push @lines, sprintf "End date: %s",   scalar(localtime($thread->extra->{date_to}))   if $thread->extra->{date_to};
    }
    
    if ( $self->list_misc ) {
		if ( my $ticket = $thread->extra->{rt_ticket} ) {
			#push @lines, sprintf 'RT-Ticket: %s', $ticket;
			push @lines, sprintf '<rt://%s/%s>', ( $ticket =~ /^(\w+?) \#(\d+)$/ );
		}
    }

	if ( $self->list_posters and my $extra = $thread->extra ) {
		if ( my $posters = $extra->{posters} ) {
			push @lines, grep { defined } map { $_->{name} } @$posters;
		}
	}

	join("\n", @lines );
}


__PACKAGE__;

__END__

=pod

=head1 NAME

Mail::Summary::Tools::FlatFile - 

=head1 SYNOPSIS

	use Mail::Summary::Tools::FlatFile;

=head1 DESCRIPTION

=cut


