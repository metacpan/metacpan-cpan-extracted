package Email::Received;
use 5.006;
use strict;
use warnings;
use constant DEBUG => 0;

require Exporter;
use base 'Exporter';
our @EXPORT = qw( parse_received);
our $VERSION = '1.00';
use Email::Received::Constants;
my $IP_ADDRESS = IP_ADDRESS;
my $LOCALHOST = LOCALHOST;
use Regexp::Common qw/net/;

# So the plan - man, this is so evil - is to make parse_received on the
# fly from the rules below.
*parse_received = generate_parse_received( unparse_rules(parse_rules()));

sub tidy_up {
    my $r = shift;
    no warnings;
    #print "Tidy up called for $_\n";
    $r->{envfrom} =~ s/^\s*<*//gs; $r->{envfrom} =~ s/>*\s*$//gs;
    $r->{by} =~ s/\;$//;
    if ($r->{ip} =~ /($RE{net}{IPv4})/) { $r->{ip} = $1 } else { return }

    exists $r->{$_} and $r->{$_} =~ s/[\s\0\#\[\]\(\)\<\>\|]/!/gs for qw/ip rdns helo by ident envfrom /;
    delete $r->{rdns} if lc $r->{rdns} eq "unknown";
    return $r;
}

sub generate_parse_received {
    my $code = shift;
    $code = q|sub { 
    local $_ = shift;
    s/\s+/ /gs;
    #print "Got $_\n";
    my $r = {};
|.
$code. q/
#print "Dropped off the end\n";
return tidy_up($r);
    }
/;
    my $subref = eval $code;
    die "Couldn't create subroutine: $@" if $@;
    return $subref;
}

=head1 NAME

Email::Received - Parse an email Received: header

=head1 SYNOPSIS

  use Email::Received;

  for ($mail->header("Received")) {
    my $data = parse_received($_);
    return "SPAM" if rbl_lookup($data->{ip});
  }

=head1 DESCRIPTION

This module is a Perl Email Project rewrite of SpamAssassin's email
header parser. We did this so that the great work they did in analysing
pretty much every possible Received header format could be used in
applications other than SpamAssassin itself.

The module provides one function, C<parse_received>, which takes a
single Received line. It then produces either nothing, if the line is
unparsable, a hash reference like this:

    { reason => "gateway noise" }

if the line should be ignored for some good reason, and one like this:

   { ip => '64.12.136.4', id => '875522', by => 'xxx.com',
     helo => 'imo-m01.mx.aol.com' }

if it parsed the message. Possible keys are:

    ip rdns helo ident envfrom auth by id

=head1 RULE FORMAT

Where SpamAssassin used a big static subroutine full of regular expressions
to parse the data, we build up a big subroutine full of regular expressions
dynamically from a set of rules. The rules are stored at the bottom of
this module. The basic format for a rule looks like this:

    ((var=~)?/REGEXP/)? [ACTION; ]+

The C<ACTION> is either C<SET variable = $value>, C<IGNORE "reason"?>,
C<UNPARSABLE> or C<DONE>. 

One control structure is provided, which is basically an C<if> statement:

    GIVEN (NOT)? /REGEXP/ {
        ACTION+
    }

=head2 EXPORT

parse_received

=head1 SEE ALSO

L<Mail::SpamAssassin::Message::Metadata::Received>, from which the
rules and some of the IP address matching constants were blatantly
stolen. Thanks, guys, for doing such a comprehensive job!

=head1 AUTHOR

simon, E<lt>simon@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by simon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut

use Text::Balanced qw(extract_quotelike);
sub parse_rules {
    my $in_given = shift;
    my $tree = [];
    while (<DATA>) {
        chomp; s/^\s+//;
        s/^#.*//; next unless /\S/;
        if (/^}\s*$/) {
            return $tree if $in_given;
            die "Syntax error on line $.: superfluous close bracket\n";
        } 
        if (s/^GIVEN\s+//) { 
            my $inverse = s/^NOT\s+//;
            my $referent = s/^(\S+)=~//?$1:"";
            my $re;
            unless ($re= extract_quotelike($_)) {
                die "Syntax error on line $.: given has no expression\n";
            }
            die "Syntax error on line $.: improper given\n" unless /\s*{\s*$/;
            my $subtree = parse_rules(1); # Let the reader understand!
            push @$tree, {given => $re, 
                          ($referent ? (referent => $referent) : ()), 
                          subtree => $subtree, inverse => $inverse };
            next;
        }
        my $referent;
        $referent = $1 if s/^(\S+)=~//;
        my $current = {};
        if (DEBUG) { $current->{line} = "$.: $_"; }
        if (my $re= extract_quotelike($_)) {
            $current->{regexp} = $re;
            $current->{referent} = $referent if $referent;
        } elsif($referent) { die "Syntax error on line $.: Referent with no regexp!\n"; }
        # At this point we want a set of commands delimited with
        # semicolons
        my @actions;
        while ($_) {
            s/^\s+// and next;
            if (s/^SET (\w+)\s*((?:\|\|)?=)\s*(.*?);//) { 
                push @actions, { action => "SET", variable => $1, value => $3, operator => $2 };
                next;
            }elsif (s/^IGNORE\s*//) {
                my $reason = extract_quotelike($_);
                die "No semicolon after reason? on line $.\n" unless s/^\s*;//;
                push @actions, { action => "IGNORE", reason => $reason};
                next;
            } elsif (s/^(DONE|UNPARSABLE)\s*;//) {
                push @actions, { action => $1 };
                next;
            }
            die "Can't parse action '$_' at line $.\n";
        }
        if (@actions) { $current->{actions} = \@actions }
        push @$tree, $current;
    }
    return $tree;
}

sub unparse_rules {
    my $tree = shift;
    my $level = shift||0;
    my $output;
    for (@$tree) {
        $output .= " " x ($level * 5);
        if ($_->{given}) {
            #$output .= "print q{Trying given $_->{given} against |}.\$_.qq{|\n};\n";
            $output .= $_->{inverse} ? "unless " : "if ";
            $output .= "(";
            $output .= '$r->{'.$_->{referent}."}=~" if $_->{referent};
            $output .= $_->{given}.") {\n";
            #$output .= "print q{In given\n};\n";
            $output .= unparse_rules($_->{subtree}, $level+1);
            $output .= " " x ($level * 5);
            $output .= "}\n";
            #$output .= "print qq{Given over\n};\n";
            next;
        }
        if ($_->{regexp}) {
            #$output .= "print qq{Trying regexp }.q{$_->{regexp}}.qq{\n};";
            $output .= 'if (';
            $output .= '$r->{'.$_->{referent}."}=~" if $_->{referent};
            $output .= $_->{regexp}.") {\n";
        } else { $output .= "do { \n"; }
        $level++;
        if (DEBUG) { 
            $output .= " " x ($level * 5);
            $output .= 'push @{$r->{rules_fired}}, q{'.$_->{line}."};\n";
        }
        for (@{$_->{actions}||[]}) {
            $output .= " " x ($level * 5);
            if ($_->{action} eq "DONE") { $output .= "return tidy_up(\$r)" }
            elsif ($_->{action} eq "UNPARSABLE") { $output .= "return" }
            elsif ($_->{action} eq "IGNORE") { 
                $output .= 'return ';
                if ($_->{reason}) { $output .= "{reason => $_->{reason} }" };
            } elsif ($_->{action} eq "SET") {
                $output .= '$r->{'.$_->{variable}."} ".$_->{operator} . " ".$_->{value} } 
            else { die "Couldn't unparse action!\n" }
            $output .= ";\n";
        }
        $level--;
        $output .= " " x ($level * 5);
        $output .= "};\n";
    }
    return $output;       
}
__DATA__
/^\(/                                 IGNORE "gateway noise";
/\sid\s+<?([^\s<>;]{3,})/             SET id = $1;
/ by .*? with (ESMTPA|ESMTPSA|LMTPA|LMTPSA|ASMTP|HTTP)\;? /i SET auth = $1;

GIVEN /^from/ {

/ \(SquirrelMail authenticated user / IGNORE "SquirrelMail injection";
/^from .*?(?:\]\)|\)\])\s+\(AUTH: (LOGIN|PLAIN|DIGEST-MD5|CRAM-MD5) \S+(?:, .*?)?\)\s+by\s+/ SET auth = $1;
/^from .*?(?:\]\)|\)\]) .*?\(.*?authenticated.*?\).*? by/ SET auth ||= "Sendmail";
/\) by .+ \(\d{1,2}\.\d\.\d{3}(?:\.\d{1,3})?\) \(authenticated as .+\) id / SET auth ||= "CriticalPath";
/(?:return-path:? |envelope-(?:sender|from)[ =])(\S+)\b/i SET envfrom = $1;

GIVEN / SMTPSVC/ {
    /^from (\S+) \(\[(${IP_ADDRESS})\][^\)]{0,40}\) by (\S+) with Microsoft SMTPSVC/ SET helo = $1; SET ip = $2; SET by = $3; DONE;
    /^from mail pickup service by (\S+) with Microsoft SMTPSVC;/ IGNORE;
}

GIVEN /^from (\S+) \((\[?${IP_ADDRESS}\]?)(?::\d+|)\) by (\S+)(?: \(\S+\)|) with \[XMail/ {
    SET helo = $1; SET ip = $2; SET by = $3; 
    / id <(\S+)> / SET id = $1; 
    / from <(\S+)>; / SET envfrom = $1; 
    DONE;
}

GIVEN /Exim/ {
    GIVEN /^from \[(${IP_ADDRESS})\] \((.*?)\) by (\S+) / {
        SET ip = $1; SET sub = $2; SET by = $3;
        sub=~s/helo=(\S+)// SET helo = $1;
        sub=~s/ident=(\S*)// SET ident = $1;
        DONE;
    }
    GIVEN /^from (\S+) \(\[(${IP_ADDRESS})\](.*?)\) by (\S+) / {
        SET rdns = $1; SET ip = $2; SET sub = $3; SET by = $4;
        sub=~s/helo=(\S+)// SET helo = $1;
        sub=~s/ident=(\S*)// SET ident = $1;
        DONE;
    }
    /^from (\S+) \[(${IP_ADDRESS})\](:\d+)? by (\S+) / SET rdns = $1; SET ip = $2; SET helo = $1; SET by = $4; DONE;
    /^from (\S+) /                    SET rdns = $1;
    / \((\S+)\) /                     SET helo = $1;
    GIVEN / \[(${IP_ADDRESS})(?:\.\d+)?\] / {
        SET ip = $1;
        /by (\S+) / SET by = $1; DONE;
    }
    /by (\S+) / SET by = $1;
}

/^from (\S+) \((\S+) \[(${IP_ADDRESS})\]\) by (\S+) with \S+ \(/ SET rdns = $2; SET ip = $3; SET helo = $1; SET by = $4; DONE;
/^from (\S+) \(\[(${IP_ADDRESS})\] helo=(\S+)\) by (\S+) with / SET rdns = $1; SET ip = $2; SET helo = $3; SET by = $3; DONE;
/^from (\S+) \(<unknown\S*>\[(${IP_ADDRESS})\]\) by (\S+) / SET helo = $1; SET ip = $2; SET by = $3; DONE;
/^from (\S+) \((\S+\.\S+)\[(${IP_ADDRESS})\]\) by (\S+) / SET helo = $1; SET rdns = $2; SET ip = $3; SET by = $4; DONE;

GIVEN / \(Postfix\) with/ {
    /^from (\S+) \((\S+) \[(${IP_ADDRESS})\]\) by (\S+) / SET helo = $1; SET rdns = $2; SET ip = $3; SET by = $4; DONE;
    /^from (\S+) \((\S+)\[(${IP_ADDRESS})\]\) by (\S+) / SET helo = $1; SET rdns = $2; SET ip = $3; SET by = $4; DONE;
}

GIVEN NOT /^from .* by \S+ \(qmail-\S+\) with / {
   GIVEN /^from (\S+) \((\S+) \[(${IP_ADDRESS})\].*\) by (\S+) \(/ {
       SET helo = $1; SET rdns = $2; SET ip = $3; SET by = $4;
       rdns=~s/^IDENT:([^\@]*)\@// SET ident = $1;
       rdns=~ s/^([^\@]*)\@// SET ident = $1;
       DONE;
   }
}

/^from (\S+) \((\S*)\@\[(${IP_ADDRESS})\].*\) by (\S+) \(/ SET helo = $1; SET ident = $2; SET ip = $3; SET by = $4; DONE;

GIVEN /by (\S+\.hotmail\.msn\.com) / {
   SET by = $1;
   /^from (\S+) / SET ip = $1;
   DONE;
}

/^from (\S+) \((?:HELO|EHLO) (\S*)\) \((${IP_ADDRESS})\) by (\S+) \(qpsmtpd\/(\S+)\) with (ESMTP|SMTP)/ SET rdns = $1; SET helo = $2; SET ip = $3; SET by = $4; DONE;

/^from (\S+) \(\[(${IP_ADDRESS})\]\) by (\S+) via smtpd \(for \S+\) with SMTP\(/ SET helo = $1; SET ip = $2; SET by = $3; DONE;

GIVEN /^from \S+( \((?:HELO|EHLO) \S*\))? \((\S+\@)?\[?${IP_ADDRESS}\]?\)( \(envelope-sender <\S+>\))? by \S+( \(.+\))* with (.* )?(SMTP|QMQP)/ {

    /^from (\S+) \((?:HELO|EHLO) ([^ \(\)]*)\) \((\S*)\@\[?(${IP_ADDRESS})\]?\)( \(envelope-sender <\S+>\))? by (\S+)/ SET rdns = $1; SET helo = $2; SET ident = $3; SET ip = $4; SET by = $6; DONE;

    /^from (\S+) \((?:HELO|EHLO) ([^ \(\)]*)\) \(\[?(${IP_ADDRESS})\]?\)( \(envelope-sender <\S+>\))? by (\S+)/ SET rdns = $1; SET helo = $2; SET ip = $3; SET by = $5; DONE;

    /^from (\S+) \((\S*)\@\[?(${IP_ADDRESS})\]?\)( \(envelope-sender <\S+>\))? by (\S+)/ SET helo = $1; SET rdns = $1; SET ident = $2; SET ip = $3; SET by = $5; DONE;
    
    /^from (\S+) \(\[?(${IP_ADDRESS})\]?\)( \(envelope-sender <\S+>\))? by (\S+)/ SET helo = $1; SET rdns = $1; SET ip = $2; SET by = $4; DONE;
}

/^from \[(${IP_ADDRESS})\] by (\S+) via HTTP\;/ SET ip = $1; SET by = $2; DONE;

/^from (\S+) \( \[(${IP_ADDRESS})\]\).*? by (\S+) / SET ip = $2; SET by = $3; DONE;

/^from \((\S+) \[(${IP_ADDRESS})\]\) by (\S+) / SET helo = $1; SET ip = $2; SET by = $3; DONE;

/^from \[(${IP_ADDRESS})\] by (\S+) / SET ip = $1; SET by = $2; DONE;

/^from (\S+) \[(${IP_ADDRESS})\] by (\S+) \[(\S+)\] with / SET helo = $1; SET ip = $2; SET by = $4; DONE;

/^from (\S+) \(\[(${IP_ADDRESS})\]\) by (\S+) \(/ SET helo = $1; SET ip = $2; SET by = $3; DONE;

# The following line does not pick up rdns; see SA's Received.pm:704
/^from (\S+) \((\S+) \[(${IP_ADDRESS})\]\).*? by (\S+) / SET helo = $1; SET ip = $3; SET by = $4; DONE;

/^from (\S+) \(\[(${IP_ADDRESS})\]\).*? by (\S+) / SET helo = $1; SET ip = $2; SET by = $3; DONE;

/^from (\S+) \((\S+) \[(${IP_ADDRESS})\]\)(?: \(authenticated bits=\d+\))? by (\S+) \(/ SET helo = $1; SET rdns = $2; SET ip = $3; SET by = $4; DONE;

/^from (\S+) \[(${IP_ADDRESS})\] by (\S+) with \S+ \(fetchmail/ IGNORE "fetchmail";

/^from (\S+) \((?:HELO|EHLO) ([^\)]*)\) \((\S*@)?\[?(${IP_ADDRESS})\]?\).* by (\S+) / SET rdns = $1; SET helo = $2; SET ident = $3; SET ip = $4; SET by = $5; DONE;

/^from (\S+) \((\S*@)?\[?(${IP_ADDRESS})\]?\).* by (\S+) / SET rdns = $1; SET helo = $1; SET ident = $2; SET ip = $3; SET by = $4; DONE;

/^from \[(${IP_ADDRESS})\] by (\S+) with http for / SET ip = $1; SET by = $2; DONE;

/^from (\S+) \[(${IP_ADDRESS})\] by (\S+) with POP3 / SET rdns = $1; SET ip = $2; SET by = $3; DONE;

/^from (\S+)\((${IP_ADDRESS})\) by (\S+) via smap / SET rdns = $1; SET ip = $2; SET by = $3; DONE;

/^from (\S+)\((${IP_ADDRESS}), (?:HELO|EHLO) (\S*)\) by (\S+) via smap / SET rdns = $1; SET ip = $2; SET helo = $3; SET by = $4; DONE;

/^from \[(${IP_ADDRESS})\] by (\S+) \(Post/     SET ip = $1; SET by = $2; DONE;
/^from \[(${IP_ADDRESS})\] by (\S+) \(ArGoSoft/ SET ip = $1; SET by = $2; DONE;
/^from (${IP_ADDRESS}) by (\S+) \(InterScan/    SET ip = $1; SET by = $2; DONE;

/^from (\S+) by (\S+) with BSMTP/ IGNORE "Not a TCP/IP handover";

/^from (\S+) \((\S+) \[(${IP_ADDRESS})\]\) by (\S+) with / SET helo = $1; SET rdns = $2; SET ip = $3; SET by = $4; DONE;

GIVEN /^from (\S+) \((?:HELO|EHLO) (\S*)\) \((\S+).*?\) by (\S+) with / {
    SET rdns = $1; SET helo = $2; SET ip = $3; SET by = $4;
    ip=~s/([^\@]*)\@//g SET ident = $1;
    DONE;
}

/^from (\S+) by (\S+) with local/ IGNORE;

/^from \[(${IP_ADDRESS})\] \(account \S+ (?:HELO|EHLO) (\S*)\) by (\S+) \(/ SET ip = $1; SET helo = $2; SET by = $3; DONE;

/^from \(\[(${IP_ADDRESS})\]\) by (\S+) with / SET ip = $1; SET by = $2;

/^from ([^\d]\S+) \((${IP_ADDRESS})\) by (\S+) / SET helo = $1; SET ip = $2; SET by = $3; DONE;

/^from (\S+) \((\S+)\) by (\S+) \(Content Technologies / IGNORE "Useless without IP";

/^from (\S+) \(\[(\S+)\] \[(\S+)\]\) by (\S+) with / SET helo = $1; SET ip = $2; SET by = $4; DONE;

/^from (${IP_ADDRESS}) by (\S+) with / SET ip = $1; SET by = $2; DONE;

/^from (\S+) \((\S+)\[(${IP_ADDRESS})\]\) by (\S+) / SET helo = $1; SET rdns = $2; SET ip = $3; SET by = $4; DONE;

/^from \[(${IP_ADDRESS})\]\S+ \((?:HELO|EHLO) (\S*)\) by (\S+) / SET ip = $1; SET helo = $2; SET by = $3; DONE;

/^from (${IP_ADDRESS}) \((?:HELO|EHLO) (\S*)\) by (\S+) / SET ip = $1; SET helo = $2; SET by = $3; DONE;

/^from (\S+) \[(${IP_ADDRESS})\] by (\S+) / SET helo = $1; SET ip = $2; SET by = $3; DONE;

/^from (\S+)\((${IP_ADDRESS})\) by (\S+) / SET rdns = $1; SET ip = $2; SET by = $3; DONE;

/^from \[(${IP_ADDRESS})\] by (\S+) \(MailGate / SET ip = $1; SET by = $2; DONE;

/^from (\S+) \(unverified \[(${IP_ADDRESS})\]\) by (\S+) / SET helo = $1; SET ip = $2; SET by = $3; DONE;

/^from (${IP_ADDRESS}) \([A-Za-z][^\)]+\) by (\S+) with / SET ip = $1; SET by = $2; DONE;

GIVEN /^from \[(${IP_ADDRESS})\] \(([^\)]+)\) by (\S+) / {
    SET ip = $1; SET sub = $2; SET by = $3;
    sub=~s/helo=(\S+)// SET helo = $1;
    sub=~s/ident=(\S+)// SET ident = $1;
    DONE;
}

/^from (\S+) \((?:\S+\@)?(${IP_ADDRESS})\) by (\S+) with / SET rdns = $1; SET ip = $2; SET by = $3; DONE;

/^from (\S+)\((${IP_ADDRESS})\)(?:, claiming to be "(\S+)")? via \S+ by (\S+),/ SET rdns = $1; SET ip = $2; SET helo = $3; SET by = $4; DONE;

}

/^FROM (\S+) \((\S+) \[(${IP_ADDRESS})\]\) BY (\S+) (?:ID (\S+) )?/ SET helo = $1; SET rdns = $2; SET ip = $3; SET by = $4; SET id = $5; DONE;

/^by / IGNORE "By line, not from line!";
/^from \S+ \(\S+\@${LOCALHOST}\) by \S+ \(/ IGNORE "local";
/^from \S+ \S+ by \S+ with local-e?smtp / IGNORE "local";
/^from 127\.0\.0\.1 \(AVG SMTP \S+ \[\S+\]\); / IGNORE "local";
#/^from \S+\@\S+ by \S+ by uid \S+ / IGNORE "local";
/^from \S+\@\S+ by \S+ / IGNORE;
/^from Unknown\/Local \(/ IGNORE "local";
/^from ${LOCALHOST} \((?:\S+\@)?${LOCALHOST}[\)\[]/ IGNORE "local";
/^from \S+ \((?:\S+\@)?${LOCALHOST}\) / IGNORE "local";
/^from (\S+) \(\S+\@\S+ \[${LOCALHOST}\]\) / IGNORE "local";
/^from \(AUTH: (\S+)\) by (\S+) with / IGNORE;
/^from localhost \(localhost \[\[UNIX: localhost\]\]\) by / IGNORE "local";
/^Message by / IGNORE "whatever";
/^FROM \S+ BY \S+ \; / IGNORE;
/^from \S+\.amazon\.com by \S+\.amazon\.com with ESMTP \(peer crosscheck: / IGNORE "internal amazon traffic";
/^from [^\.]+ by \S+ with Novell_GroupWise; / IGNORE;
/^from no\.name\.available by \S+ via smtpd \(for / IGNORE "internal mail across a Raptor firewall";
/^from \S+ by \S+ (?:with|via|for|\()/ UNPARSABLE;
/^from (\S+) by (\S+) *\;/ UNPARSABLE;

/\bhelo=([-A-Za-z0-9\.]+)[^-A-Za-z0-9\.]/ SET helo = $1;
/^from (\S+)[^-A-Za-z0-9\.]/ SET helo ||= $1;
/\[(${IP_ADDRESS})\]/ SET ip = $1;
/ by (\S+)[^-A-Za-z0-9\;\.]/ SET by = $1;
