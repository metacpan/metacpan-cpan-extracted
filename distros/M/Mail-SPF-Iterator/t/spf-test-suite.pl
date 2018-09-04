#!/usr/bin/perl
use strict;
use warnings;

$|=1;
my $DEBUG=1;
my $can_ip6;
BEGIN { $can_ip6 = eval 'use Socket6;1'; }

use Mail::SPF::Iterator;
use Net::DNS;
use Data::Dumper;

my $testcount = 0;
END { print "1..$testcount\n" }

sub run {
    my ($tfile,%testopt) = @_;
    my $tests;
    if (ref $tfile) {
	$tests = $tfile
    } else {
	for ( $tfile,"t/$tfile" ) {
	    -f or next;
	    $tests = do $_;
	    die $@ if $@;
	    last;
	}
    }

    if (my $skip = delete $testopt{skip}) {
	for my $test (@$tests) {
	    delete $test->{tests}{$_} for @$skip;
	}
    }

    return if ! @$tests;
    $testcount += 2*keys(%{ $_->{tests} }) for @$tests;

    Mail::SPF::Iterator->import( Debug => $DEBUG );

    for my $use_additionals ('with additionals','') {
	for my $test (@$tests) {
	    my $desc= $test->{description};
	    my $dns_setup = $test->{zonedata};
	    my $subtests = $test->{tests};

	    my $resolver = myResolver->new(
		records => $dns_setup,
		use_additionals => $use_additionals
	    );
	    for my $tname (sort keys %$subtests) {
		my $tdata = $subtests->{$tname};

		my %d = %$tdata;
		delete @d{qw/description/};
		my $whatever = (delete $d{comment} ||'') =~m{
		    matter\s+of\s+opinion        |
		    effectively\s+random
		}x;
		my $explanation = delete $d{explanation};

		my $result = delete $d{result};
		$result = [ $result ] if ! ref $result;
		$_=lc for(@$result);

		my $spec = delete $d{spec};
		$spec = [ $spec ] if ! ref($spec);
		my $comment = "$desc | $tname (@$spec) (@$result) $use_additionals";

		if ( ! $can_ip6 and ( $d{host} =~m{::} or $tname =~m{ip6} )) {
		    print "ok # skip Socket6.pm not installed\n";
		    next;
		}

		# capture debug output of failed cases
		my $debug = '';
		eval {
		    open( my $dbg, '>',\$debug );
		    local *STDERR = $dbg;

		    my $spf = eval {
			Mail::SPF::Iterator->new(
			    delete $d{host},
			    delete $d{mailfrom},
			    delete $d{helo},
			    undef,
			    \%testopt
			);
		    };
		    die "no spf: $@\n".Dumper($tdata) if ! $spf;
		    die "unhandled args :".Dumper(\%d) if %d;

		    $explanation = $spf->explain_default
			if $explanation and $explanation eq 'DEFAULT';

		    my ($status,@ans) = $spf->next;
		    my $dns_count = 0;
		    while ( ! $status ) {
			my @query = @ans;
			die "no queries" if ! @query;
			for my $q (@query) {
			    $dns_count++;
			    DEBUG( "next query ($dns_count) >>> ".($q->question)[0]->string );
			    my $answer = $resolver->send( $q );
			    ($status,@ans) = $spf->next(
				$answer || [ $q, $resolver->errorstring ]);
			    DEBUG( "status=$status" ) if $status;
			    last if $status or @ans;
			}
		    }
		    DEBUG("done after $dns_count queries");

		    my $mh = $spf->mailheader || '';
		    $mh =~m{^$status }i or die "bad mail header for status $status: $mh";
		    die bless [ lc($status),@ans ],'SPFResult';
		};

		if ( ref($@) ne 'SPFResult' ) {
		    print "not ok # $comment - error\n";
		    ( my $t = $@."\n".$debug ) =~s{^}{| }mg;
		    print Dumper($tdata),$t;
		    next;
		}

		my ($status,$info,$hash,$explain) = @{$@};
		if ( ! grep { $status eq $_ } @$result ) {
		    print "not ok # $comment - got $status\n";
		    $debug =~s{^}{| }mg;
		    print Dumper($tdata),$debug.Dumper(
			{ info => $info, hash => $hash, explain => $explain });
		    next;
		}

		if ( $explanation ) {
		    if ( $explain ne $explanation ) {
			print "not ok # $comment - ".
			    "exp should be '$explanation' was '$explain'\n";
			$debug =~s{^}{| }mg;
			print Dumper($tdata),$debug;
			next;
		    }
		}

		if ( $status ne $result->[0] ) {
		    if ($whatever) {
			print "ok # $comment - got $status\n";
		    } else {
			print "not ok # $comment - got $status\n";
			$debug =~s{^}{| }mg;
			print Dumper($tdata),$debug.Dumper(
			    { info => $info, hash => $hash, explain => $explain });
		    }
		    next;
		}


		print "ok # $comment\n";
	    }
	}
    }
}

############################################################################
# DEBUG
############################################################################

sub DEBUG {
    $DEBUG or return; # check against debug level
    my (undef,$file,$line) = caller;
    my $msg = shift;
    $file = '...'.substr( $file,-17 ) if length($file)>20;
    $msg = sprintf $msg,@_ if @_;
    print STDERR "DEBUG: $file:$line: $msg\n";
}

############################################################################
# myResolver
# implements Net::DNS::Resolver for tests, ideas stolen from
# Net::DNS::Resolver::Programmable
############################################################################

package myResolver;
use base 'Net::DNS::Resolver';
use Data::Dumper;

sub DEBUG { goto &::DEBUG }

sub new {
    my ($class,%options) = @_;
    my $self = $class->SUPER::new(%options);
    $self->{records} = $options{records};
    $self->{use_additionals} = $options{use_additionals};
    return $self;
}

sub send {
    my ($self,$pkt) = @_;
    my $q = ($pkt->question)[0];
    my $qname = lc($q->qname);
    my $qtype = $q->qtype;
    my $qclass = $q->qclass;

    $self->_reset_errorstring;

    DEBUG( "got query=".$q->string );

    # create answer packet
    my $packet = Net::DNS::Packet->new($qname, $qtype, $qclass);
    $packet->header->qr(1);
    $packet->header->aa(1);
    $packet->header->id($pkt->header->id);

    my (%ans,$timeout,@answer,@cname);
    while (1) {
	( my $key = $qname ) =~ s{\.$}{};
	# newer Net::DNS versions encode space as \\032, older do not :(
	$key =~s{\\(?:(\d\d\d)|(.))}{$2||chr($1)}esg;
	my @match = grep { lc($key) eq lc($_) } keys %{ $self->{records}}
	    or last;

	my $rrdata = $self->{records}{$match[0]};

	for my $data (@$rrdata) {
	    if ( $data eq 'TIMEOUT' ) {
		# report as error
		$timeout = 1;
	    } elsif ( ref($data) eq 'HASH' ) { ### { SPF => ... }
		# create and collect RR
		my @typ = keys %$data;
		@typ == 1 or die Dumper( $data ); # expect only 1 key
		push @{ $ans{$typ[0]}}, $data->{$typ[0]};
	    }
	}


	$ans{TXT} ||= $ans{SPF};
	for (values %ans) {
	    $_ = undef if $_ and @$_ == 1 and $_->[0] eq 'NONE';
	}

	if ( my $ans = $ans{$qtype} ) {
	    push @answer, @$ans;
	} elsif ( !@answer and ( $ans = $ans{CNAME})) {
	    @$ans == 1 or die;
	    $qname = $ans->[0];
	    push @cname, [ $match[0],$qname ];
	    redo;
	}

	if ( $timeout and !@answer and !@cname) {
	    $self->errorstring('TIMEOUT');
	    return undef;
	}

	my @additional;
	for my $ans (@answer) {
	    my %rr = ( type => $qtype, name => $qname );
	    my $aname;
	    if ( $qtype eq 'MX' ) {
		$aname = $rr{exchange} = $ans->[1];
		$rr{preference} = $ans->[0];
	    } elsif ( $qtype eq 'A' || $qtype eq 'AAAA' ) {
		$rr{address} = $ans
	    } elsif ( $qtype eq 'SPF' || $qtype eq 'TXT' ) {
		$rr{char_str_list} = ref($ans) ? $ans : [ $ans ];
	    } elsif ( $qtype eq 'PTR' ) {
		$rr{ptrdname} = $ans;
	    } elsif ( $qtype eq 'CNAME' ) {
		$aname = $rr{cname} = $ans;
	    } else {
		die $qtype
	    }

	    #DEBUG( Dumper( \%rr ));
	    # work around a Bug in Net::DNS 0.64, where it will interpret
	    # cafe:babe::1 as cafe:babe:0:1:0:0:0:0 when given in hash
	    # to Net::DNS::RR->new
	    if ( $rr{type} eq 'AAAA' ) {
		# replace with long form
		my @a = split( ':',$rr{address});
		if ( my $fill = 8 - @a ) {
		    @a = map { $_ eq '' ? (0) x ($fill+1) : $_ } @a;
		    $rr{address} = join(':',@a);
		}
	    }
	    $ans = Net::DNS::RR->new( %rr ) or die;
	    DEBUG( "answer: ".$ans->string );

	    if ( $self->{use_additionals} and $qtype eq 'MX' ) {
		# add A/AAAA records as additional data
		$aname =~s{\.$}{};
		for (@{ $self->{records}{$aname} || [] }) {
		    next if ! ref;
		    my @k = keys %$_;
		    next if @k != 1 or ( $k[0] ne 'A' and $k[0] ne 'AAAA' );
		    push @additional, Net::DNS::RR->new(
			name => $aname,
			type => $k[0],
			address => $_->{$k[0]}
		    ) or die;
		    DEBUG( "additional: ".$additional[-1]->string );
		}
	    }
	}

	for(@cname) {
	    $packet->push(answer => Net::DNS::RR->new(
		type => 'CNAME', name => $_->[0], cname => $_->[1] ));
	}
	if ( @answer ) {
	    $packet->push(answer => @answer);
	    $packet->push(additional => @additional) if @additional;
	}
	DEBUG( $packet->string );
	$packet->header->rcode('NOERROR');
	return $packet;
    }

    # report that domain does not exist
    DEBUG( "send NXDOMAIN" );
    $packet->header->rcode('NXDOMAIN');
    return $packet;
}

1;
