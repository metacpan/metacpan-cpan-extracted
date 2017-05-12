#!/usr/bin/perl

package Mail::Summary::Tools::Downloader::NNTP;
use Moose;

use Net::NNTP;
use Mail::Message;
use List::MoreUtils qw/any/;

use Mail::Summary::Tools::ThreadFilter::Util;
use DateTime;
use DateTime::Infinite;
use DateTime::Format::Mail;
use DateTime::Format::DateManip;

has cache => (
	isa => "Object",
	is  => "rw",
	required => 1,
);

has server => (
	isa => "Str",
	is  => "ro",
	required => 1,
);

has overviews => (
	isa => "HashRef",
	is  => "ro",
	default => sub { return {} },
);

has connection => (
	isa => "Net::NNTP",
	is  => "ro",
	lazy    => 1,
	default => sub { $_[0]->connect },
);

has fetch_recursively => (
	isa => "Bool",
	is  => "rw",
	default => 1,
);

has _downloaded => (
	isa => "HashRef",
	is  => "ro",
	default => sub { return {} },
);

sub connect {
	my $self = shift;
	Net::NNTP->new( $self->server, Debug => 1 ) || die "couldn't connect to " . $self->server;
}

sub overviews_for_group {
	my ( $self, %params ) = @_;
	my ( $group, $to, $from ) = @params{qw/group to from/};

	my $cache  = $self->cache;
	my $server = $self->server;

	# effiency hack
	unless ( $self->overviews->{$group} ) {
		if ( $cache->isa("Mail::Summary::Tools::YAMLCache") ) {
			my $all_overviews_key = join(":", "overviews", $server, $group);
			return $self->overviews->{$group} = $self->cache->get( $all_overviews_key ) || do {
				my %overviews;
				$self->cache->set( $all_overviews_key, \%overviews );
				\%overviews;
			}
		} else {
			my %overviews;
			$self->overviews->{$group} = \%overviews;

			foreach my $article ( $from .. $to ) {
				next if $overviews{$article};
				my $cache_key = join(":", "overviews", $server, $group, $article);
				if ( my $article_overviews = $cache->get( $cache_key ) ) {
					$overviews{$article} = $article_overviews;
				}
			}

			return \%overviews;
		}
	}
}

sub split_ranges {
	my ( $self, @ranges ) = @_;

	# split the ranges up into smaller chunks... If xover gets a too big number it barfs sometimes.
	return map {
		my $start = $_->[0];
		my $end   = $_->[1];
		my $count = $end - $start;

		my $magic = 1000;

		my $div = int( $count / $magic );

		( $div
			? ( (map { [ $start + ( ($_-1) * $magic ), ($start + ( $_ * $magic ))-1 ] } 1 .. $div), [ $start + ( $div * $magic ), $end ] )
			: ( $_ ) )
	} @ranges;
}

sub determine_missing_header_ranges {
	my ( $self, %params ) = @_;
	my ( $overviews, $to, $from ) = @params{qw/overviews to from/};

	if ( ( my @got = sort { $a <=> $b } keys %$overviews ) > 10 ) {
		my @ranges;

		warn "previous articles exist";
		my $prev = shift @got;
		push @ranges, [ $from, $prev-1 ] unless $from == $prev;

		foreach my $article ( @got ) {
			if ( ($article - 1) != $prev ) {
				warn "adding range: $prev+1 .. $article-1";
				push @ranges, [ $prev+1, $article-1 ];
			}

			$prev = $article;
		}

		push @ranges, [ $prev+1, $to ] unless $to == $prev;

		return @ranges;
	} else {
		warn "getting everything";
		return [ $from, $to ];
	}
}

sub fetch_overviews_in_ranges {
	my ( $self, %params ) = @_;
	my ( $overviews, $ranges, $group ) = @params{qw/overviews ranges group/};

	my @important_headers = qw/Date References Message-ID/;

	my $connection = $self->connection;
	my $cache  = $self->cache;
	my $server = $self->server;

	my @overview_headers = map { my $header = $_; $header =~ s/:$//; $header } @{ $connection->overview_fmt };
	my %header_indices; @header_indices{@overview_headers} = 0 .. $#overview_headers;
	my @keep_headers; @keep_headers[map { $header_indices{$_} } @important_headers] = ( (1) x scalar(@important_headers) );

	foreach my $range ( @$ranges ) {
		my $raw_overviews = $connection->xover($range);

		foreach my $overview ( values %$raw_overviews ) {
			$overview = {
				map { $overview_headers[$_] => $overview->[$_] }
				grep { $keep_headers[$_] } 0 .. $#overview_headers
			};
		}

		@{ $overviews }{ keys %$raw_overviews } = values %$raw_overviews;

		unless ( $cache->isa("Mail::Summary::Tools::YAMLCache") ) {
			# this is not necessary for the yaml cache, because of our hack.
			# the hash is shared that way and just gets updated in place
			foreach my $article ( keys %$overviews ) {
				my $cache_key = join(":", "overviews", $server, $group, $article);
				$cache->set( $cache_key, $overviews->{$article} );
			}
		}
	}
}

sub fetch_overviews_for_group {
	my ( $self, %params ) = @_;

	my $overviews = $self->overviews_for_group(%params);

	my @ranges = $self->split_ranges(
		$self->determine_missing_header_ranges(
			%params,
			overviews => $overviews,
		),
	);

	$self->fetch_overviews_in_ranges(
		ranges    => \@ranges,
		overviews => $overviews,
	);

	delete @{ $overviews }{ 1 .. $params{from}-1 }; # FIXME cache this in non YAML cache too

	return $overviews;
}

sub set_group {
	my ( $self, $group ) = @_;

	my ( $to, $from ) = $self->connection->group($group) or die "$group doesn't exist";

	my $overviews = $self->fetch_overviews_for_group(
		group => $group,
		from  => $from,
		to    => $to,
	);

	return (
		overviews => $overviews,
		from => $from,
		to   => $to,
	);
}

sub download {
	my ( $self, %params ) = @_;

	my ( $from_date, $to_date ) = delete @params{qw/from to/};

	my $range = Date::Range::Forgiving->new( $from_date, $to_date ); # ACKCKKK Fixme

	%params = ( $self->set_group($params{group}), %params );

	my $overviews = $params{overviews};

	$self->for_articles_in_date_range(
		sub {
			my $article = shift;
			
			$self->get_article(
				%params,
				article  => $article,
				overview => $overviews->{$article},
			);
		},
		%params,
		date_range => $range,
	);

}

sub for_articles_in_date_range {
	my ( $self, $body, %params ) = @_;
	my ( $overviews, $from, $to, $range ) = @params{qw/overviews from to date_range/};

	foreach my $article ( $from .. $to ) {
		next unless my $overview = $overviews->{$article};
		my $date_header = $overview->{Date};
		my $date;

		my @errors;
		$date = eval { DateTime::Format::Mail->new->loose->parse_datetime( $date_header ) };
		push @errors, $@ if $@;
		$date ||= eval { DateTime::Format::DateManip->parse_datetime( $date_header ) };
		push @errors, $@ if $@;

		warn "Error parsing date '$date_header': @errors" unless defined $date;

		$date ||= DateTime->now;

		$body->($article) if $range->includes( $date );
	}
}

sub get_article {
	my ( $self, %params ) = @_;
	my ( $overview, $article ) = delete @params{qw/overview article/};

	if ( $self->fetch_recursively ) {
		foreach my $message_id ( $overview->{'References'} =~ / ( < \S+ \@ \S+ > ) /gx ) {
			warn "additional thread root: $message_id";
			$self->get_message_if_needed(
				%params,
				message_id => $message_id,
			);
		}
	}

	$self->get_message_if_needed(
		%params,
		article => $article,
		message_id => $overview->{'Message-ID'},
	);
}

sub get_message_if_needed {
	my ( $self, %params ) = @_;	
	my ( $message_id, $mbox, $extra ) = @params{qw/message_id mailbox extra_mailboxes/};

	return if $self->_downloaded->{$message_id}++;

	return if any { $_->find($message_id) } $mbox, @$extra;

	$self->fetch_message_id( %params );
}

sub fetch_message_id {
	my ( $self, %params ) = @_;
	my ( $article, $message_id, $mbox ) = @params{qw/article message_id mailbox/};

	if ( my $article = $self->connection->article( $article || $message_id )  ) {
		my $message = Mail::Message->read( $article );
		$mbox->addMessage( $message );
	} else {
		warn "couldn't fetch article: " . ($article || $message_id);
	}
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Mail::Summary::Tools::Downloader::NNTP - Get NNTP articles and their thread roots.

=head1 SYNOPSIS

	use Mail::Summary::Tools::Downloader::NNTP;

	my $downloader = Mail::Summary::Tools::Downloader::NNTP->new(
		server => "nntp.perl.org",
		cache  => $article_cache,
		fetch_recursively => 0,
	);

	my $mgr = Mail::Box::Manager->new;
	my $mbox = $mgr->open( "foo" );

	$downloader->download(
		group   => "perl.perl6.language",
		from    => 10000,
		to      => 11000,
		mailbox => $mbox,
		extra_mailboxes => \@extra,
	);

=head1 DESCRIPTION

This utility makes downloading mailing list archives from an nntp server
into a mailbox trivial.

Messages whose message ID is already in any of the mailboxes are not
downloaded.

Additionally, message IDs listed in the C<References> header will also be
fetched if C<fetch_recursively> is on (the default).

Since L<Mail::Box::Thread::Manager> can thread messages from multiple mailboxes
this one can download the next batch of articles with C<fetch_recursively>
enabled, and using a log-rotation like mechanism delete older mailboxes without
fear of breaking the threads, at the cost of some redundant downloads.

=cut


