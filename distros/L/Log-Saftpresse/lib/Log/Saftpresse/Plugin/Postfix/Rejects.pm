package Log::Saftpresse::Plugin::Postfix::Rejects;

use Moose::Role;

# ABSTRACT: plugin to gather postfix reject statistics
our $VERSION = '1.6'; # VERSION

use Log::Saftpresse::Plugin::Postfix::Utils qw(gimme_domain verp_mung string_trimmer );

requires 'message_detail';
requires 'reject_detail';
requires 'ignore_case';
requires 'rej_add_from';
requires 'verp_mung';

sub process_rejects {
	my ( $self, $stash ) = @_;
	my $service = $stash->{'service'};
	my $message = $stash->{'message'};

	if( $service eq 'cleanup' &&
			( my($rejSubTyp, $rejReas, $rejRmdr) = $message =~
			/.*?\b(reject|warning|hold|discard): (header|body) (.*)$/ ) ) {

		$stash->{'reject_type'} = $rejSubTyp;
		$stash->{'reject_reason'} = $rejReas;

		$rejRmdr =~ s/( from \S+?)?; from=<.*$//
			unless( $self->message_detail );
		$rejRmdr = string_trimmer($rejRmdr, 64, $self->message_detail);
		
		if( $self->{'reject_detail'} != 0 ) {
			$self->incr_host_one( $stash, 'reject', $rejSubTyp, $service, $rejReas, $rejRmdr);
		}
		$self->incr_host_one( $stash, $stash, 'reject', 'total', $rejSubTyp );
		if( $self->saftsumm_mode ) {
			$self->incr_per_time_one( $stash );
		}
	}

	if( my ($type, $reject_message) = $message
			=~ /^(reject|reject_warning|proxy-reject|hold|discard): (.*)$/ ) {
		$stash->{'reject_type'} = $type;
		$self->proc_smtpd_reject($stash, $type, $reject_message);
	}

	return;
}

sub incr_per_time_one {
	my ( $self, $stash ) = @_;
	my $time = $stash->{'time'};
	$self->incr_host_one( $stash, 'reject', 'per_hr', $time->hour );
	$self->incr_host_one( $stash, 'reject', 'per_mday', $time->mday );
	$self->incr_host_one( $stash, 'reject', 'per_wday', $time->wday );
	$self->incr_host_one( $stash, 'reject', 'per_day', $time->ymd );
	return;
}

sub proc_smtpd_reject {
    my ( $self, $stash, $type, $message ) = @_;
    #my ($logLine, $rejects, $msgsRjctd, $rejPerHr, $msgsPerDay) = @_;
    my ($rejTyp, $rejFrom, $rejRmdr, $rejReas);
    my ($from, $to);
    my $rejAddFrom = 0;

    $self->incr_host_one( $stash,  'reject', 'total', $type );
    if( $self->saftsumm_mode ) {
      $self->incr_per_time_one( $stash );
    }

    # Hate the sub-calling overhead if we're not doing reject details
    # anyway, but this is the only place we can do this.
    return if( $self->reject_detail == 0);

    # This could get real ugly!

    # First: get everything following the "reject: ", etc. token
    # Was an IPv6 problem here
    ($rejTyp, $rejFrom, $rejRmdr) = $message =~ /^(\S+) from (\S+?): (.*)$/;
    if( ! defined $rejTyp )  { return; }

    # Next: get the reject "reason"
    $rejReas = $rejRmdr;
    unless( $self->message_detail ) {
	if($rejTyp eq "RCPT" || $rejTyp eq "DATA" || $rejTyp eq "CONNECT") {	# special treatment :-(
	    # If there are "<>"s immediately following the reject code, that's
	    # an email address or HELO string.  There can be *anything* in
	    # those--incl. stuff that'll screw up subsequent parsing.  So just
	    # get rid of it right off.
	    $rejReas =~ s/^(\d{3} <).*?(>:)/$1$2/;
	    $rejReas =~ s/^(?:.*?[:;] )(?:\[[^\]]+\] )?([^;,]+)[;,].*$/$1/;
	    $rejReas =~ s/^((?:Sender|Recipient) address rejected: [^:]+):.*$/$1/;
	    $rejReas =~ s/(Client host|Sender address) .+? blocked/blocked/;
	} elsif($rejTyp eq "MAIL") {	# *more* special treatment :-( grrrr...
	    $rejReas =~ s/^\d{3} (?:<.+>: )?([^;:]+)[;:]?.*$/$1/;
	} else {
	    $rejReas =~ s/^(?:.*[:;] )?([^,]+).*$/$1/;
	}
    }

    # Snag recipient address
    # Second expression is for unknown recipient--where there is no
    # "to=<mumble>" field, third for pathological case where recipient
    # field is unterminated, forth when all else fails.
    (($to) = $rejRmdr =~ /to=<([^>]+)>/) ||
	(($to) = $rejRmdr =~ /\d{3} <([^>]+)>: User unknown /) ||
	(($to) = $rejRmdr =~ /to=<(.*?)(?:[, ]|$)/) ||
	($to = "<>");
    $to = lc($to) if($self->{'ignore_case'});

    # Snag sender address
    (($from) = $rejRmdr =~ /from=<([^>]+)>/) || ($from = "<>");

    if(defined($from)) {
	$rejAddFrom = $self->rej_add_from;
        $from = verp_mung( $self->verp_mung, $from);
	$from = lc($from) if($self->ignore_case);
    }

    # stash in "triple-subscripted-array"
    if($rejReas =~ m/^Sender address rejected:/) {
	# Sender address rejected: Domain not found
	# Sender address rejected: need fully-qualified address
        $self->incr_host_one( $stash,  'reject', $type, $rejTyp, $rejReas, $from);
    } elsif($rejReas =~ m/^(Recipient address rejected:|User unknown( |$))/) {
	# Recipient address rejected: Domain not found
	# Recipient address rejected: need fully-qualified address
	# User unknown (in local/relay recipient table)
	#++$rejects->{$rejTyp}{$rejReas}{$to};
	my $rejData = $to;
	if($rejAddFrom) {
	    $rejData .= "  (" . ($from? $from : gimme_domain($rejFrom)) . ")";
	}
        $self->incr_host_one( $stash,  'reject', $type, $rejTyp, $rejReas, $rejData);
    } elsif($rejReas =~ s/^.*?\d{3} (Improper use of SMTP command pipelining);.*$/$1/) {
	# Was an IPv6 problem here
	my ($src) = $message =~ /^.+? from (\S+?):.*$/;
        $self->incr_host_one(  $stash, 'reject', $type, $rejTyp, $rejReas, $src);
    } elsif($rejReas =~ s/^.*?\d{3} (Message size exceeds fixed limit);.*$/$1/) {
	my $rejData = gimme_domain($rejFrom);
	$rejData .= "  ($from)" if($rejAddFrom);
        $self->incr_host_one( $stash,  'reject', $type, $rejTyp, $rejReas, $rejData);
    } elsif($rejReas =~ s/^.*?\d{3} (Server configuration (?:error|problem));.*$/(Local) $1/) {
	my $rejData = gimme_domain($rejFrom);
	$rejData .= "  ($from)" if($rejAddFrom);
        $self->incr_host_one( $stash,  'reject', $type, $rejTyp, $rejReas, $rejData);
    } else {
#	print STDERR "dbg: unknown reject reason $rejReas !\n\n";
	my $rejData = gimme_domain($rejFrom);
	$rejData .= "  ($from)" if($rejAddFrom);
        $self->incr_host_one( $stash,  'reject', $type, $rejTyp, $rejReas, $rejData);
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Plugin::Postfix::Rejects - plugin to gather postfix reject statistics

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
