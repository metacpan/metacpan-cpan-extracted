package Log::Saftpresse::CountersOutput::Pflogsumm;

use Moose;

# ABSTRACT: plugin to output counters in pflogsumm style output
our $VERSION = '1.6'; # VERSION

extends 'Log::Saftpresse::CountersOutput';

use Log::Saftpresse::Utils qw( adj_int_units get_smh);

use Time::Piece;

has 'problems_first' => ( is => 'rw', isa => 'Bool', default => 0 );

has 'reject_detail' => ( is => 'rw', isa => 'Int', default => 0 );
has 'bounce_detail' => ( is => 'rw', isa => 'Int', default => 0 );
has 'deferral_detail' => ( is => 'rw', isa => 'Int', default => 0 );

has 'smtp_detail' => ( is => 'rw', isa => 'Int', default => 0 );
has 'smtpd_warn_detail' => ( is => 'rw', isa => 'Int', default => 0 );

has 'quiet' => ( is => 'rw', isa => 'Bool', default => 0 );

has 'top_domains_cnt' => ( is => 'rw', isa => 'Int', default => 20 );
has 'top_users_cnt' => ( is => 'rw', isa => 'Int', default => 20 );

sub output {
	my ( $self, $cnt ) = @_;
	my $pf_cnt = $cnt->{'Postfix'};

	$self->print_totals( $cnt );

	if( defined $pf_cnt->get_node('conn') ) {
		$self->print_smtpd_stats( $pf_cnt );
	}
	if( $self->problems_first ) {
		$self->print_problems_reports( $pf_cnt );
	}

	$self->print_traffic_summaries( $cnt );

	if( $self->top_domains_cnt != 0 ) {
		$self->print_domain_summaries( $cnt );
	}

	if( defined $pf_cnt->get_node('conn') ) {
		$self->print_smtpd_summaries( $pf_cnt );
	}

	$self->print_user_summaries( $cnt );

#	print_hash_by_key(\%noMsgSize, "Messages with no size data", 0, 1);

	if( ! $self->problems_first ) {
		$self->print_problems_reports( $pf_cnt );
	}

#	print_detailed_msg_data(\%msgDetail, "Message detail", $opts{'q'}) if($opts{'e'});

	if( defined $pf_cnt->{'tls_conn'} ) {
		$self->print_tls_stats( $pf_cnt );
	}
	if( defined $cnt->{'PostfixGeoStats'} ) {
		$self->print_geo_stats( $cnt->{'PostfixGeoStats'} );
	}

	return;
}

sub print_user_summaries {
	my ( $self, $cnt ) = @_;
	my $pf_cnt = $cnt->{'Postfix'};
	my $quiet = $self->quiet;

	$self->print_hash_by_cnt_vals(
		$pf_cnt->get_node('recieved', 'by_sender'),
		"Senders by message count", 0, $quiet );

	$self->print_hash_by_cnt_vals(
		$pf_cnt->get_node('sent', 'by_rcpt'),
		"Recipients by message count", 0, $quiet );

	$self->print_hash_by_cnt_vals(
		$pf_cnt->get_node('recieved', 'size', 'by_sender'),
		"Senders by message size", 0, $quiet );

	$self->print_hash_by_cnt_vals(
		$pf_cnt->get_node('sent', 'size', 'by_rcpt'),
		"Recipients by message size", 0, $quiet );

	return;
}

sub hash_calc_avg {
	my ( $self, $precision, $total, $count ) = @_;
	my %avg;
	my %uniq = map { $_ => 1 } ( keys %$total, keys %$count );
	my @keys = keys %uniq;
	foreach my $key ( @keys ) {
		my $value;
		if( defined $total->{$key} && $total->{$key} > 0
				&& defined $count->{$key} && $count->{$key} > 0 ) { 
			$value = $total->{$key} / $count->{$key};
		}
		if( defined $total->{$key} && $total->{$key} eq 0 ) {
			$value = 0;
		}
		if( defined $value ) {
			$avg{$key} = sprintf('%.'.$precision.'f', $value);
		} else {
			$avg{$key} = undef;
		}
	}
	return \%avg;
}

sub print_table_from_hashes {
	my ( $self, $legend, $sort, $lw, $cw, @rows ) = @_;
	my @headers = map { $_->[0] } @rows;
	my @hashes = map { $_->[1] } @rows;
	my @yaxis;

	$self->print_table_header( $legend, $lw, $cw, @headers );

	if( ref($sort) eq 'ARRAY' ) { # sort by a column value
		my ( $sortby, $alg, $limit ) = @$sort;
		my ( $row ) = grep { $_->[0] eq $sortby } @rows;
		$row = $row->[1];
		if( ! defined $row ) { confess('cant find row '.$sortby.' for sorting'); }
		if( $alg eq 'decimal' ) {
			@yaxis = sort { $row->{$b} <=> $row->{$a} } keys %$row;
		} else { # string
			@yaxis = sort { $row->{$b} cmp $row->{$a} } keys %$row;
		}
		if( $limit > 0 && scalar @yaxis > $limit ) { @yaxis = @yaxis[0 .. ($limit-1) ] };
	} else { # simple sort by key
		my @all_keys = map { keys %$_ } @hashes;
		my %uniq = map { $_ => 1 } @all_keys;
		if( $sort eq 'decimal' ) {
			@yaxis = sort { $a <=> $b } keys %uniq;
		} else { # string
			@yaxis = sort { $a cmp $b } keys %uniq;
		}
	}

	foreach my $row ( @yaxis ) {
		$self->print_table_row( $row, $lw, $cw,
			map { $_->{$row} } @hashes );
	}
	print "\n";

	return;
}

sub print_table_row {
	my ( $self, $ylabel, $lw, $cw, @values ) = @_;

	printf("%".$lw."s", $ylabel);
	foreach my $value ( @values ) {
		if( ! defined $value ) { $value = '-'; }
		printf(" %".$cw."s", $value);
	}
	print "\n";

	return;
}

sub print_table_header {
	my ( $self, $legend, $lw, $cw, @headers ) = @_;

	$self->print_table_row( $legend, $lw, $cw, @headers);

	my $width = $lw + (( $cw + 1 ) * scalar @headers);
	print( ("-" x $width)."\n");

	return;
}

sub print_domain_summaries {
	my ( $self, $cnt ) = @_;
	my $top_cnt = $self->top_domains_cnt;
	my $pf_cnt = $cnt->{'Postfix'};

	foreach my $table ( 'sent', 'recieved' ) {
		print_subsect_title("Host/Domain Summary: Message Delivery (top $top_cnt $table)");
		$self->print_table_from_hashes( 'host/domain',
			[ 'sent cnt', 'decimal', $top_cnt ], 25, 10,
			[ 'sent cnt', $pf_cnt->get_node($table, 'by_domain') ],
			[ 'bytes', $pf_cnt->get_node($table, 'size', 'by_domain') ],
			$table eq 'sent' ? (
				# TODO
				#[ 'defers', $delivered->get_node('busy', 'per_day') ],
				[ 'avg delay', $self->hash_calc_avg( 2,
						$pf_cnt->get_node('sent', $table, 'delay', 'by_domain'),
						$pf_cnt->get_node('sent', $table, 'by_domain'),
					), ],
				[ 'max. delay', $pf_cnt->get_node('sent', $table, 'max_delay', 'by_domain'), ],
			) : (),
		);
	}

	return;
}

sub print_smtpd_summaries {
	my ( $self, $cnt ) = @_;
	my $params = {
		'day' => [ 'Per-Day', 'per_day', 'string', 15 ],
		'hour' => [ 'Per-Hour', 'per_hr', 'decimal', 15 ],
		'domain' => [ 'Per-Hour', 'per_domain', [ 'connections', 'decimal', 20 ], 25 ],
	};

	foreach my $table ( 'day', 'hour', 'domain' ) {
		my ( $title, $key, $sort, $len ) = @{$params->{ $table }};
		print_subsect_title("$title SMTPD Connection Summary");
		$self->print_table_from_hashes( $table, $sort, $len, 10,
			[ 'connections', $cnt->get_node('conn', $key) ],
			[ 'time conn.', $cnt->get_node('conn', 'busy', $key) ],
			[ 'avg./conn.', $self->hash_calc_avg( 2,
					$cnt->get_node('conn', 'busy', $key),
					$cnt->get_node('conn', $key),
				), ],
			[ 'max. time', $cnt->get_node('conn', 'busy', 'max_'.$key ), ],
		);
	}
	return;
}

sub print_traffic_summaries {
	my ( $self, $cnt ) = @_;
	my $pf_cnt = $cnt->{'Postfix'};
	my $params = {
		'day' => [ 'Per-Day', 'per_day', 'string' ],
		'hour' => [ 'Per-Hour', 'per_hr', 'decimal' ],
	};

	foreach my $table ('day', 'hour') {
		my ( $title, $key, $sort ) = @{$params->{ $table }};
		print_subsect_title( "$title Traffic Summary" );
		$self->print_table_from_hashes( $table, $sort, 15, 10,
			[ 'recieved', $pf_cnt->get_node('incoming', $key) ],
			[ 'delivered', $pf_cnt->get_node('sent', $key) ],
			[ 'deffered', $pf_cnt->get_node('deferred', $key), ],
			[ 'bounced', $pf_cnt->get_node('bounced', $key), ],
			[ 'rejected', $pf_cnt->get_node('reject', $key) ],
		);
	}

	return;
}

sub print_totals {
	my ( $self, $cnt ) = @_;
	my $pf_cnt = $cnt->{'Postfix'};
	my $smtpdConnCnt = 0;

	# PostfixRejects
	my $msgsRjctd = $pf_cnt->get_value_or_zero('reject', 'total', 'reject');
	my $msgsDscrdd = $pf_cnt->get_value_or_zero('reject', 'total', 'discard');
	my $msgsWrnd = $pf_cnt->get_value_or_zero('reject', 'total', 'warning');
	my $msgsHld = $pf_cnt->get_value_or_zero('reject', 'total', 'hold');

	# PostfixRecieved
	my $msgsRcvd = $pf_cnt->get_value_or_zero('incoming', 'total');

	my $msgsDlvrd = $pf_cnt->get_value_or_zero('sent', 'total');
	my $msgsDfrd = $pf_cnt->get_value_or_zero('deferred', 'total');
	my $msgsFwdd = $pf_cnt->get_value_or_zero('forwarded');
	my $msgsBncd = $pf_cnt->get_value_or_zero('bounced', 'total');

	my $sizeRcvd = $pf_cnt->get_value_or_zero('recieved', 'size', 'total');
	my $sizeDlvrd = $pf_cnt->get_value_or_zero('sent', 'size', 'total');

	my $sendgUserCnt = $pf_cnt->get_key_count('recieved', 'by_sender');
	my $sendgDomCnt = $pf_cnt->get_key_count('recieved', 'by_domain'); 
	my $recipUserCnt =$pf_cnt->get_key_count('sent', 'by_rcpt');
	my $recipDomCnt = $pf_cnt->get_key_count('sent', 'by_domain');

	# Calculate percentage of messages rejected and discarded
	my $msgsRjctdPct = 0;
	my $msgsDscrddPct = 0;
	if(my $msgsTotal = $msgsDlvrd + $msgsRjctd + $msgsDscrdd) {
	    $msgsRjctdPct = int(($msgsRjctd/$msgsTotal) * 100);
	    $msgsDscrddPct = int(($msgsDscrdd/$msgsTotal) * 100);
	}

	print "Postfix log summaries generated on ".Time::Piece->new->ymd."\n";

	print_subsect_title("Grand Totals");
	print "messages\n\n";
	printf " %6d%s  received\n", adj_int_units($msgsRcvd);
	printf " %6d%s  delivered\n", adj_int_units($msgsDlvrd);
	printf " %6d%s  forwarded\n", adj_int_units($msgsFwdd);
	printf " %6d%s  deferred", adj_int_units($msgsDfrd);
	#printf "  (%d%s deferrals)", adj_int_units($msgsDfrdCnt) if($msgsDfrdCnt);
	print "\n";
	printf " %6d%s  bounced\n", adj_int_units($msgsBncd);
	printf " %6d%s  rejected (%d%%)\n", adj_int_units($msgsRjctd), $msgsRjctdPct;
	printf " %6d%s  reject warnings\n", adj_int_units($msgsWrnd);
	printf " %6d%s  held\n", adj_int_units($msgsHld);
	printf " %6d%s  discarded (%d%%)\n", adj_int_units($msgsDscrdd), $msgsDscrddPct;
	print "\n";
	printf " %6d%s  bytes received\n", adj_int_units($sizeRcvd);
	printf " %6d%s  bytes delivered\n", adj_int_units($sizeDlvrd);
	printf " %6d%s  senders\n", adj_int_units($sendgUserCnt);
	printf " %6d%s  sending hosts/domains\n", adj_int_units($sendgDomCnt);
	printf " %6d%s  recipients\n", adj_int_units($recipUserCnt);
	printf " %6d%s  recipient hosts/domains\n", adj_int_units($recipDomCnt);
	print "\n";

	return;
}

sub print_smtpd_stats {
	my ( $self, $cnt ) = @_;
	my $smtpdConnCnt = $cnt->get_value_or_zero('conn', 'total');
	print "\nsmtpd\n\n";
	printf "  %6d%s  connections\n",
	adj_int_units($smtpdConnCnt);
	printf "  %6d%s  hosts/domains\n",
	adj_int_units(int(keys %{$cnt->get_node('conn', 'per_domain')}));
	printf "  %6d   avg. connect time (seconds)\n",
		$smtpdConnCnt > 0 ?
		($cnt->get_value_or_zero('conn', 'busy', 'total')
			/ $smtpdConnCnt ) + .5
		: 0;
	{
		my ($sec, $min, $hr) = get_smh($cnt->get_value_or_zero('conn', 'busy', 'total'));
		printf " %2d:%02d:%02d  total connect time\n",
		$hr, $min, $sec;
	}
	return;
}

sub print_problems_reports {
	my ( $self, $cnt ) = @_;

	if($self->deferral_detail != 0) {
		$self->print_nested_hash( $cnt->get_node('deferred'),
			"message deferral detail",
			$self->deferral_detail );
	}
	if($self->bounce_detail != 0) {
		$self->print_nested_hash( $cnt->get_node('bounced'),
			"message bounce detail (by relay)",
			$self->bounce_detail );
	}
	if($self->reject_detail != 0) {
		foreach my $key ( 'reject', 'warning', 'hold', 'discard') {
			$self->print_nested_hash($cnt->get_node('reject', $key),
				"message $key detail",
				$self->reject_detail );
		}
	}

	if( my $smtp_cnt = $cnt->{'PostfixSmtp'} ) {
		my $messages = $smtp_cnt->get_node('messages');
		if( defined $messages ) {
			$self->print_nested_hash($messages, "smtp delivery failures",
				$self->smtp_detail );
		}
	}
	if( my $msg_cnt =  $cnt->{'PostfixMessages'} ) {
		if($self->smtpd_warn_detail != 0) {
			$self->print_nested_hash($msg_cnt->get_node('warning'),
				"Warnings",
				$self->smtpd_warn_detail );
		}
		$self->print_nested_hash($msg_cnt->get_node('fatal'),
			"Fatal Errors", 0 );
		$self->print_nested_hash($msg_cnt->get_node('panic'),
			"Panics", 0 );
		$self->print_hash_by_cnt_vals($msg_cnt->get_node('master'),
			"Master daemon messages", 0 );
	}
}

sub print_tls_stats {
	my ( $self, $cnt ) = @_;
	my $smtpdConnCnt;

	if( defined $cnt->get_node('conn') ) {
		$smtpdConnCnt = $cnt->get_value_or_zero('conn', 'total');
	}
	my $msgs_rcvd = $cnt->get_value_or_zero('incoming', 'total');
	my $msgs_sent = $cnt->get_value_or_zero('sent', 'total');

	print_subsect_title("TLS Statistics");

	my @total_stats = (
		[ 'incoming tls connections' => $smtpdConnCnt,
			'tls_conn', 'smtpd', 'total' ],
		[ 'incoming tls messages' => $msgs_rcvd,
			'tls_msg', 'smtpd', 'total' ],
		[ 'outgoing tls connections' => $smtpdConnCnt,
			'tls_conn', 'smtp', 'total' ],
		[ 'outgoing tls messages' => $msgs_sent,
			'tls_msg', 'smtp', 'total' ],
	);

	foreach my $stat ( @total_stats ) {
		my ( $name, $total, @node ) = @$stat;
		my $value = $cnt->get( @node );
		if( ! defined $value ) { next; }
		printf " %6d%s $name",
			adj_int_units($value);
		if( $total ) {
			print_in_percent($value, $total);
		} else { print "\n"; }
	}

	my @tls_statistics = (
		[ "Incoming TLS trust-level" =>
			$smtpdConnCnt, 'tls_conn', 'smtpd', 'level' ],
		[ "Outgoing TLS trust-level" =>
			0, 'tls_conn', 'smtp', 'level' ],
		[ "Incoming TLS Protocol Version" =>
			$smtpdConnCnt, 'tls_conn', 'smtpd', 'protocol' ],
		[ "Outgoing TLS Protocol Version" =>
			0, 'tls_conn', 'smtp', 'protocol' ],
		[ "Incoming TLS key length" =>
			$smtpdConnCnt, 'tls_conn', 'smtpd', 'keylen' ],
		[ "Outgoing TLS key length" =>
			0, 'tls_conn', 'smtp', 'keylen' ],
		[ "Incoming TLS Ciphers" =>
			$smtpdConnCnt, 'tls_conn', 'smtpd', 'cipher' ],
		[ "Outgoing TLS Ciphers" =>
			0, 'tls_conn', 'smtp', 'cipher' ],
	);

	foreach my $tls_stat ( @tls_statistics ) {
		my ( $title, $total, @node ) = @$tls_stat;
		my $values = $cnt->get_node(@node);
		if( ! defined $values ) { next; }
		$values = hash_key_add_percent( $values, $total );
		$self->print_hash_by_cnt_vals( $values, $title, 0, 1 );
	}
}

sub print_geo_stats {
	my ( $self, $cnt ) = @_;
	my $client = $cnt->get_node('client');
	if( defined $client ) {
    		$self->print_hash_by_cnt_vals( $client, 'Client Countries', 0, 1 );
	}
}

sub print_in_percent {
	my ( $value, $total ) = @_;
	my $percent = $value / $total * 100;
	printf(" (%3.2f%% of %d)\n", $percent, $total );
	return;
}

sub hash_key_add_percent {
	my ( $hash, $base ) = @_;
	if( ! defined $base || $base == 0 ) {
		return( $hash );
	}
	my $out = {
		map {
			my $percent = sprintf("%.2f%%", $hash->{$_} / $base * 100 );
			$_.' ('.$percent.')' => $hash->{$_};
		} keys %$hash
	};
	return( $out );
}

# print hash contents sorted by numeric values in descending
# order (i.e.: highest first)
sub print_hash_by_cnt_vals {
    my($self, $hashRef, $title, $cnt, $quiet) = @_;
    my $dottedLine;
    if( ! defined $hashRef) { return; }
    $title = sprintf "%s%s", $cnt? "top $cnt " : "", $title;
    unless(%$hashRef) {
	return if($quiet);
	$dottedLine = ": none";
    } else {
	$dottedLine = "\n" . "-" x length($title);
    }
    printf "\n$title$dottedLine\n";
    really_print_hash_by_cnt_vals($hashRef, $cnt, ' ');
}

# print hash contents sorted by key in ascending order
sub print_hash_by_key {
    my($hashRef, $title, $cnt, $quiet) = @_;
    my $dottedLine;
    $title = sprintf "%s%s", $cnt? "first $cnt " : "", $title;
    unless(%$hashRef) {
	return if($quiet);
	$dottedLine = ": none";
    } else {
	$dottedLine = "\n" . "-" x length($title);
    }
    printf "\n$title$dottedLine\n";
    foreach (sort keys(%$hashRef))
    {
	printf " %s  %s\n", $_, $hashRef->{$_};
	last if --$cnt == 0;
    }
}

# print "nested" hashes
sub print_nested_hash {
    my( $self, $hashRef, $title, $cnt ) = @_;
    my $quiet = $self->quiet;
    my $dottedLine;
    if( ! defined $hashRef ) { return; }
    unless(%$hashRef) {
	return if($quiet);
	$dottedLine = ": none";
    } else {
	$dottedLine = "\n" . "-" x length($title);
    }
    printf "\n$title$dottedLine\n";
    walk_nested_hash($hashRef, $cnt, 0);
}

# "walk" a "nested" hash
sub walk_nested_hash {
	my ($hashRef, $cnt, $level) = @_;
	$level += 2;
	my $indents = ' ' x $level;
	my ($keyName, $hashVal) = each(%$hashRef);

	if( ref($hashRef) ne 'HASH' ) { return; }

	if(ref($hashVal) ne 'HASH') {
		really_print_hash_by_cnt_vals($hashRef, $cnt, $indents);
		return;
	}
	foreach (sort keys %$hashRef) {
	    if( ref $hashRef->{$_} ne 'HASH' ) { next; }
	    print "$indents$_";
	    # If the next hash is finally the data, total the
	    # counts for the report and print
	    my $hashVal2 = (each(%{$hashRef->{$_}}))[1];
	    keys(%{$hashRef->{$_}});	# "reset" hash iterator
	    unless(ref($hashVal2) eq 'HASH') {
		print " (top $cnt)" if($cnt > 0);
		my $rptCnt = 0;
		$rptCnt += $_ foreach (values %{$hashRef->{$_}});
		print " (total: $rptCnt)";
	    }
	    print "\n";
	    walk_nested_hash($hashRef->{$_}, $cnt, $level);
	}
}

# print per-message info in excruciating detail :-)
sub print_detailed_msg_data {
    use vars '$hashRef';
    local($hashRef) = $_[0];
    my($title, $quiet) = @_[1,2];
    my $dottedLine;
    unless(%$hashRef) {
	return if($quiet);
	$dottedLine = ": none";
    } else {
	$dottedLine = "\n" . "-" x length($title);
    }
    printf "\n$title$dottedLine\n";
    foreach (sort by_domain_then_user keys(%$hashRef))
    {
	printf " %s  %s\n", $_, shift(@{$hashRef->{$_}});
	foreach (@{$hashRef->{$_}}) {
	    print "   $_\n";
	}
	print "\n";
    }
}

# *really* print hash contents sorted by numeric values in descending
# order (i.e.: highest first), then by IP/addr, in ascending order.
sub really_print_hash_by_cnt_vals {
    my($hashRef, $cnt, $indents) = @_;

    foreach (map { $_->[0] }
	     sort { $b->[1] <=> $a->[1] || $a->[2] cmp $b->[2] }
	     map { [ $_, $hashRef->{$_}, normalize_host($_) ] }
	     (keys(%$hashRef)))
    {
        printf "$indents%6d%s  %s\n", adj_int_units($hashRef->{$_}), $_;
        last if --$cnt == 0;
    }
}

# Print a sub-section title with properly-sized underline
sub print_subsect_title {
    my $title = $_[0];
    print "\n$title\n" . "-" x length($title) . "\n";
}

# Normalize IP addr or hostname
# (Note: Makes no effort to normalize IPv6 addrs.  Just returns them
# as they're passed-in.)
sub normalize_host {
    # For IP addrs and hostnames: lop off possible " (user@dom.ain)" bit
    my $norm1 = (split(/\s/, $_[0]))[0];

    if((my @octets = ($norm1 =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/)) == 4) {
	# Dotted-quad IP address
	return(pack('U4', @octets));
    } else {
	# Possibly hostname or user@dom.ain
	return(join( '', map { lc $_ } reverse split /[.@]/, $norm1 ));
    }
}

# subroutine to sort by domain, then user in domain, then by queue i.d.
# Note: mixing Internet-style domain names and UUCP-style bang-paths
# may confuse this thing.  An attempt is made to use the first host
# preceding the username in the bang-path as the "domain" if none is
# found otherwise.
sub by_domain_then_user {
    # first see if we can get "user@somedomain"
    my($userNameA, $domainA) = split(/\@/, ${$hashRef->{$a}}[0]);
    my($userNameB, $domainB) = split(/\@/, ${$hashRef->{$b}}[0]);

    # try "somedomain!user"?
    ($userNameA, $domainA) = (split(/!/, ${$hashRef->{$a}}[0]))[-1,-2]
	unless($domainA);
    ($userNameB, $domainB) = (split(/!/, ${$hashRef->{$b}}[0]))[-1,-2]
	unless($domainB);

    # now re-order "mach.host.dom"/"mach.host.do.co" to
    # "host.dom.mach"/"host.do.co.mach"
    $domainA =~ s/^(.*)\.([^\.]+)\.([^\.]{3}|[^\.]{2,3}\.[^\.]{2})$/$2.$3.$1/
	if($domainA);
    $domainB =~ s/^(.*)\.([^\.]+)\.([^\.]{3}|[^\.]{2,3}\.[^\.]{2})$/$2.$3.$1/
	if($domainB);

    # oddly enough, doing this here is marginally faster than doing
    # an "if-else", above.  go figure.
    $domainA = "" unless($domainA);
    $domainB = "" unless($domainB);

    if($domainA lt $domainB) {
	return -1;
    } elsif($domainA gt $domainB) {
	return 1;
    } else {
	# disregard leading bang-path
	$userNameA =~ s/^.*!//;
	$userNameB =~ s/^.*!//;
	if($userNameA lt $userNameB) {
	    return -1;
	} elsif($userNameA gt $userNameB) {
	    return 1;
	} else {
	    if($a lt $b) {
		return -1;
	    } elsif($a gt $b) {
		return 1;
	    }
	}
    }
    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::CountersOutput::Pflogsumm - plugin to output counters in pflogsumm style output

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
