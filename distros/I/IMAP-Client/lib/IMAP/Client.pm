# IMAP::Client -low-level advanced IMAP manipulation w/ referral support
#
# Copyright (c) 2005 Brenden Conte <conteb@cpan.org>, All Rights Reserved
#

use strict;
use warnings;
#use diagnostics;


package IMAP::Client;

use IO::Socket::INET;
use IO::Socket::SSL;
use MIME::Base64;
use URI::imap;
use URI::Escape;

use Exporter;


$|=1;

our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

@ISA = qw( Exporter );
$VERSION = "0.13";
@EXPORT = qw ();
@EXPORT_OK = qw();
%EXPORT_TAGS = ();

# Create Class variables
my %Instances;
my @SERVER_RESPONSES = ('exists', 'recent'); # constant value
my $server_response_callback = undef;
my $ID;

=pod

=head1 NAME

    IMAP::Client - Advanced manipulation of IMAP services w/ referral support

=head1 SYNOPSIS

    use IMAP::Client
    
    my $imap = new IMAP::Client($server);
    unless (ref $imap) {
        die "Failed to create object: $imap\n";
    }
(or)
    my $imap = new IMAP::Client();
    $imap->connect(PeerAddr => $server,
		  ConnectMethod => 'SSL STARTTLS PLAIN',
		  )
    or die "Unable to connect to [$server]: ".$imap->error();

    $imap->onfail('ERROR');
    $imap->errorstyle('STACK');
    $imap->debuglevel(1);
    $imap->capability_checking(1);
    
	sub showstats ($) {
    	my $resp = shift;
	    foreach my $attr (keys %{$resp}) {
			print "$attr: $resp->{$attr}\n";
	    }
	}
	$imap->register_mailbox_update(\&showstats);

    $imap->authenticate($user,$pass)
        or die "Unable to authenticate as $user ".$imap->error()."\n";
(or)
    $imap->authenticate($user,$pass,$authas_user)
        or die "Unable to authenticate as $user on behalf of $authas_user: ".$imap->error()."\n";

    $imap->id() or die $imap->error();
    $imap->capability() or die $imap->error();
    $imap->noop() or die $imap->error();

 FIXME: more examples here

=head1 IMPORTANT! READ THIS FIRST IF YOU ARE UPGRADING FROM PRE-0.10 TO 0.10 OR ABOVE!

As of IMAP::Client 0.10, the "_active_server" mechanism has been removed, replaced instead by a class-wide monitoring of objects.  This means that if you have any code that utilizes the active_server functionality (using more than one connection in an instance of IMAP::Client), you will need to change your code to create seperate instances for each connection.

Unfortunately, backward compatibility could not be maintained with this change.  However since tracking is now behind-the-scenes, this style should be the final one.

=head1 DESCRIPTION

This module was created as a low-level inteface to any IMAP server.  It was built to be a 'clear box' solution to working with an IMAP environment.  The idea is that anything an IMAP client should be able to do, and any information available via the IMAP specs, should be available to a client interface and user.  This way, the full strength of the IMAP protocol and data can be utilized, ideally in the most network-efficient mannger possible, rather than being contrained only to a subset of commands or data-limited responses.  If the server says it, the client should be able to see it.

This module also takes steps to be able to handle anticipated situations for the user rather than forcing a per-implementation behavior for such expected events, such as referrals.  IMAP::Client will fully support referrals, and will transparently handle them for whatever command is issued to them (so long as the referral s for anonymous or the same user with the same password - a new user or different password would require a new username/password to be obtained.  As of 0.01, this is not supported, however the framework is down.

This module also tries to follow the various RFCs for IMAPrev1 communications very closely, enforcing client-side responsabilities where appropriate.  The complete lists of RFCs referenced for this module include:
    
=over 4

=item * RFC 3501 - INTERNET MESSAGE ACCESS PROTOCOL - VERSION 4rev1 (partial)

=item * RFC 2086 - IMAP4 ACL extension (0.01)

=item * RFC 2087 - IMAP4 QUOTA extension (0.01)

=item * RFC 2088 - IMAP4 non-synchronizing literals (0.01)

=item * RFC 2177 - IMAP4 IDLE command (Not supported yet)

=item * RFC 2192 - IMAP4 URL Scheme (0.01)

=item * RFC 2193 - IMAP4 Mailbox Referrals (0.01 [Partial])

=item * RFC 2342 - IMAP4 Namespace (Not directly supported yet)

=item * RFC 2359 - IMAP4 UIDPLUS extension (Partial in 0.01 - UID EXPUNGE check ok, need COPYUID and APPENDUID support)

=item * RFC 2971 - IMAP4 ID extension (0.01)

=item * RFC 3348 - IMAP4 Child Mailbox Extention (Not directly supported yet)

=item * RFC 3502 - IMAP MULTIAPPEND extention (Not directly supported yet)

=item * RFC 3516 - Binary Content Extention (Not directly supported yet)

=item * RFC 3691 - Internet Message Access Protocol (IMAP) UNSELECT command (Not directly supported yet)

=back

In addition, the following drafts functionalities are also included.  While functionality is included for these drafts (because a server is using them), drafts expire after 6 months, and thus functionality from the server side may be spotty at best.

=over 4

=item * draft-ietf-imapext-annotate-15 - IMAP ANNOTATE Extension (Not directly supported yet)

=item * draft-daboo-imap-annotatemore-08 - IMAP ANNOTATEMORE Extension (Partial in 0.12 - GETANNOTATION works)

=back


=head1 DEFINITIONS

=over 4

=item * sequence set - A comma-seperated list of numbers and number ranges.  A number range is in the format number:number, such as "2:4", meaning messages 2 through 4.

=back

=head1 METHODS - SUBINTERFACE

These are the lowest-level functions for use by the program.  These offer the most raw access for interacting with an IMAP service, short of doing it manually.

=cut 

########## Internal, Undocumented Support functions ##########
# First things first...
sub dprint ($$$) {
	my ($self, $debugbit,$string) = @_;
	
	# Error checking - make sure the debugbit is only 1 bit
	unless ($debugbit && !($debugbit & ($debugbit - 1))) {
		warn "Debugbit passed into dprint is not a single bit! (String = [$string])\n";
	}
	
	if ($self->{DEBUG} & $debugbit) {
		print STDERR $string;
	}
};


# RFC3501 specifies a valid tag contains any char other than...
my $RESP_SPECIALS = '\]';
my $ATOM_SPECIALS = '\(\)\{ ';
my $LIST_WILDCARDS = '\%\*';
my $QUOTED_SPECIALS = '\"\\\\';
my $VALID_TAG = "[^".$RESP_SPECIALS.$ATOM_SPECIALS.$LIST_WILDCARDS.$QUOTED_SPECIALS.'+'."]";
sub ok_response(@) {
    return (($_[$#_] =~ /^$VALID_TAG+?\s*OK\s+/) ? 1 : 0);
}
sub continue_response(@) {
    return(($_[$#_] =~ /^\+ /) ? 1 : 0);
}
sub untagged_response(@) {
    return(($_[$#_] =~ /^\* (?!BAD)/) ? 1 : 0);
}
sub untagged_ok_response(@) {
    return (($_[$#_] =~ /^\*\s*OK\s+/) ? 1 : 0);
}
sub failure_response(@) {
    return (($_[$#_] =~ /^(?:$VALID_TAG|\*)+?\s*(BAD|NO)\s+/) ? 1 : 0);
}

sub is_sequence_set($) {
    return (($_[0] =~ /^(?:(?:\d+|\d+\:\d+)(?:\,\d+|\d+\:\d+)*|\d+:\*|\*)$/) ? 1 : 0);
}
sub sequencify (@){ # preserves ordering over compression
    my $string;
    my ($start,$end);
    foreach my $number (@_) {
		($start = $end = $number and next) unless ($start); # first entry;
		if ($start) {
		    if ($end+1 == $number) {
				$end = $number;
		    } else {
				$string .= ($start == $end) ? "$start," : "$start:$end,";
				$start = $end = $number;
		    }
		}
    }
    $string .= ($start == $end) ? "$start" : "$start:$end"; # last entry
    return($string);
}

sub throw_error($$) {
    my ($self,$error) = @_;
    $error =~ s/^(.*?)\s*\r?\n?$/$1/;
    my $newerror = $error || "Unknown/Generic error";

    if ($self->{onfail} eq 'error') {
		if (($self->{errorstyle} eq 'stack') && (!$self->{error_read})) {
		    $self->{error} .= "\n". $newerror;
		} else {
		    $self->{error} = $newerror;
		}
		$self->{error_read} = 0;
		return (undef);
    } elsif ($self->{onfail} eq 'abort') {
		print STDERR $newerror."\n";
		exit(-1);
    } else {
		print STDERR "INTERNAL ERROR: Unknown failure handler string [",$self->{onfail},"], aborting...\n";
		exit(-1);
    }
}
sub parse_select_examine(@) {
	return() unless $_[0];
    my %ret;
    my ($_t, $_v); # t is the TITLE (or label/tag), and v is the VALUE of t.
    foreach my $line (@_) {
		if (ok_response($line)) { # done
		    my ($perm) = $line =~ /\[([\w-]+)\]/;
		    $ret{OK} = $perm;
		} elsif (($_t,$_v) = $line =~ /(\w+)\s*\((.*)\)/) { # flags: TITLE (\F \T...)
		    $_v =~ s/\\//g;
		    $ret{$_t} = $_v;
		} elsif (($_t,$_v) = $line =~ /\[(\w+)\s*(\d+)\]/) { # title-num: [TITLE #]
		    $ret{$_t} = $_v;
		} elsif (($_v, $_t) = $line =~ /(\d+)\s*(\w+)/) { # num-title: # TITLE
		    $ret{$_t} = $_v;
		} elsif (($_t, $_v) = $line =~ /NO\s+\[(.*?)\]\s+(.*)$/) { # NO [TITLE] VALUE (usually for ALERTs)
			$ret{$_t} = $_v;
		} else {
		    warn "Unknown tagless response(): $line\n";
		}
    }
    return(%ret);
}
sub parse_list_lsub(@) {
    my @result = @_;
    my @list;
    foreach my $line (@result) {
		next if (ok_response($line));
		my ($flags,$reference,$mailbox) = $line =~ /^\*\s+LIST\s+\((.*?)\)\s+\"(.*?)\"\s+\"?(.*?)\"?\r\n$/;
		my %hash = (FLAGS => $flags, REFERENCE => $reference, MAILBOX => $mailbox);
		push @list, \%hash;
    }
	@list = () unless ($list[0]);
    return(@list);
}

# from http://www.perl.com/pub/a/2002/08/22/exegesis5.html?page=5
our $parens;
# $parens = qr/
#     \(             # Match a literal '('
#     (?:            # Start a non-capturing group
#      (?>           #     Never backtrack through...
#       [^()] +      #         Match a non-paren (repeatedly)
#       )            #     End of non-backtracking region
#      |             # Or
#      (??{$parens}) #    Recursively match entire pattern
#      )*            # Close group and match repeatedly
#     \)             # Match a literal ')'
#     /x;
$parens = qr/\((?:(?>[^()]+)|(??{$parens}))*\)/s; # nested paren matcher
my $nparens = qr/\((?:(?>[^()]+)|(??{$parens}))*\)|NIL/s;
my $string = '\"[^\"]+\"';
my $nstring = "(?:$string|NIL)";
my $number = '\d+';
sub quote_once ($) {
	my $string = shift;
	$string = "\"$string\"" unless ($string =~ /^\".*\"$/); # Quote if its not already quoted
	return($string);
}
sub dequote($) {
    return(undef) unless $_[0];
    if ($_[0] eq "NIL") { return undef; }
    my ($base) = $_[0] =~ /^\"(.*)\"/;
    return($base || $_[0]);
}
sub debracket($) {
    return(undef) unless $_[0];
    if ($_[0] eq "NIL") { return undef; }
    my ($base) = $_[0] =~ /^\<(.*)\>/;
    return($base || $_[0]);
}
sub address($) {
    my $rawlist = shift;
    my @addresses;
    if ($rawlist eq "NIL") { return undef; }
    $rawlist =~ s/^\((.*)\)$/$1/;
    foreach my $address (split (/\)\(/,$rawlist)) {
		my ($name,$relay,$mailbox,$host) = $address =~/^\(?($nstring) ($nstring) ($nstring) ($nstring)\)?$/;
		next unless ($name);
		push @addresses,((dequote($name)) ? dequote($name).' ' : '').'<'.
	    dequote($mailbox).(($relay ne 'NIL') ? '%'.dequote($relay) : '').
	    '@'.dequote($host).'>';
    }
    return(join(',',@addresses));
}
sub parse_parameters($);
sub parse_parameters($) { # Parse parameter sequences, including w/ nested parens
    my $parameters = shift @_;
    return $parameters unless $parameters; # returns both undefs and empty strings ('')
    return $parameters if (substr($parameters,0,1) ne '(');
    $parameters =~ s/^\((.*)\)$/$1/;
    my %hash;
    while ($parameters) {
		my ($key,$value,$more) = $parameters =~ /^\s?\"(.*?)\" ($nstring|$parens)(.*)$/g;
		$parameters = $more;
		$value = dequote($value) || '';
		$hash{uc($key)} = parse_parameters($value);
    }
    return(\%hash);
}
sub parse_envelope($) {
    my $value = shift;
    my %ret;
    my $_t;
    my ($date,$subject,$from,$sender,$replyto,$to,$cc,$bcc,$inreplyto,$messageid) = $value =~/^\(($string) ($nstring) ($nparens) ($nparens) ($nparens) ($nparens) ($nparens) ($nparens) ($nparens) ($nstring)\)$/;

    $ret{'DATE'} = $_t if ($_t = dequote($date));
    $ret{'SUBJECT'} = $_t if ($_t = dequote($subject));
    $ret{'FROM'} = $_t if ($_t = address($from));
    $ret{'SENDER'} = $_t if ($_t = address($sender));
    $ret{'REPLYTO'} = $_t if ($_t = address($replyto));
    $ret{'TO'} = $_t if ($_t = address($to));
    $ret{'CC'} = $_t if ($_t = address($cc));
    $ret{'BCC'} = $_t if ($_t = address($bcc));
    $ret{'INREPLYTO'} = $_t if ($_t = address($inreplyto));
    $ret{'MESSAGEID'} = $_t if ($_t = debracket(dequote($messageid)));
    return(\%ret);
}
# recursive function for building body hash

sub parse_body_structure ($$);
sub parse_body_structure ($$) {
    my $structure = shift;
    my $level = shift;
    return undef unless $structure;

    my $entry=1;
    my %ret;
    my $substruct;
    while ((($substruct,$structure) = $structure =~ /^($parens)(.*)$/)) {
	#	printf("DEBUG[$level]: Deciding fate of [%.80s...] ".(($structure)?"<more>":'')."\n",$substruct);# if ($self->{DEBUG});

		#body-type-mpart/body-type-message
		if (my @results = $substruct =~ /^\((?:($parens+) ($string)|\"MESSAGE\" \"RFC822\" ($nparens) ($nstring) ($nstring) ($string) ($number) ($parens) ($parens) ($number))(?: ($nparens)(?: ($nparens)(?: ($nparens|$string)(?: ($nstring)(?:( $string| $number| $parens)+)?)?)?)?)?\)$/) {
		    my ($body1, $subtype, $parameters, $id, $description, $encoding, $size, $envelope, $body2, $lines, $ext_parameters, $dsp, $lang, $loc, @extentions) = @results;
		    # body1 and body2 will never both contain something (its an XOR relationship), so we can just use (body1 || body2) for 'the active body'	    
	#	    print "DEBUG[$level]: Processing body-type-" . (($parameters) ? "message" : "mpart") . " [$entry]\n";# if ($self->{DEBUG});
	#	    print "DEBUG[$level]: subtype = $subtype\n";
		    if ($body1) { # ONLY create a new level if there is more than one entity on this (or next) level
		#		print "DEBUG[$level]: Diving one level deeper\n";# if ($self->{DEBUG});
				$ret{$entry}=\%{{(parse_body_structure($body1||$body2,$level+1))}};
		#		print "DEBUG[$level]: rose back - above saved in [$entry]\n";# if ($self->{DEBUG});
		    } else {
		#		print "DEBUG[$level]: applying at same-level\n";# if ($self->{DEBUG});
		#		print "DEBUG[$level]: Parsing envelope\n";# if ($self->{DEBUG} && $parameters);
				my %body_step = parse_body_structure($body1||$body2,$level+1);
		#		print "DEBUG[$level]: collapsing above into current [$entry]\n";# if ($self->{DEBUG});
				my $new_entry = $entry;
				foreach my $key (keys %body_step) {
				    if ($key =~ /^\d+$/) {
			#			print "DEBUG[$level]: Storing a level higher [$entry+($key-1)]=$body_step{$key} at this level\n";# if ($self->{DEBUG});
						$ret{$entry+($key-1)} = $body_step{$key}; #mv to local lvl
						$new_entry = $entry+($key-1);
				    } else {
			#			print "DEBUG[$level]: Storing mpart [$key]=[$body_step{$key}] in [$entry]\n";# if ($self->{DEBUG});
						$ret{$entry}->{$key} = $body_step{$key};
				    }		    
				}
				$entry = $new_entry;
		    }
		    my %envelope = parse_envelope($envelope) if ($envelope);
		    $ret{$entry}->{'ENVELOPE'} = \%envelope if (%envelope); #$fetch->...->{header}->{?}
		    # apply local-entry stuff here, after {$entry} has been 'ovewritten' above
		    $ret{$entry}->{'CONTENTTYPE'} = "MULTIPART/".dequote($subtype) if ($subtype); # the only topic that is applied one level above
		    $ret{$entry}->{'PARAMETERS'} = parse_parameters($parameters) if ($parameters && ($parameters ne 'NIL'));
		    $ret{$entry}->{'ID'} = $id if ($id && ($id ne 'NIL'));
		    $ret{$entry}->{'DESCRIPTION'} = $description if ($description && ($description ne 'NIL'));
		    $ret{$entry}->{'ENCODING'} = $encoding if ($encoding);
		    $ret{$entry}->{'SIZE'} = $size if ($size);
		    $ret{$entry}->{'LINES'} = $lines if ($lines);
		    $ret{$entry}->{'DISPOSITION'} = parse_perameters($dsp) if ($dsp && ($dsp ne 'NIL'));
		    $ret{$entry}->{'LANGUAGE'} = parse_parameters($lang) if ($lang && ($lang ne 'NIL'));
		    $ret{$entry}->{'LOCATION'} = $loc if ($loc && ($loc ne 'NIL'));
		    $ret{$entry}->{'EXT_PARAMETERS'} = parse_parameters($ext_parameters) if ($ext_parameters && ($ext_parameters ne 'NIL'));
		    # WARNING: custom extentions currently ignored
			
		}
		 
	
		#body-type-text/body-type-basic/body-type-msg (media)
		elsif (my ($type, $subtype, $parameters, $id, $description, $encoding, $size, $lines, $md5, $dsp, $lang, $loc, @extentions) = $substruct =~ /^\(($string) ($string) ($nparens) ($nstring) ($nstring) ($string) ($number)(?: ($number))?(?: ($nstring)(?: ($nparens)(?: ($nparens|$string)(?: ($nstring)(?:( $string| $number| $parens)+)?)?)?)?)?\)$/) {
		    # hash the parameters
	#	    print "DEBUG[$level]: Processing body-type-text/basic [$entry]\n";# if ($self->{DEBUG});
		    my %t_ret;
		    $t_ret{'CONTENTTYPE'} = dequote($type).'/'.dequote($subtype);
		    $t_ret{'PARAMETERS'} = parse_parameters($parameters);
		    $t_ret{'ID'} = $id if ($id ne 'NIL');
		    $t_ret{'DESC'} = $description if ($description && ($description ne 'NIL'));
		    $t_ret{'ENCODING'} = dequote($encoding);
		    $t_ret{'SIZE'} = $size;
		    $t_ret{'LINES'} = $lines if ($lines);
		    $t_ret{'MD5'} = $md5 if ($md5 && ($md5 ne 'NIL'));
		    $t_ret{'DISPOSITION'} = parse_parameters($dsp) if ($dsp && ($dsp ne 'NIL'));
		    $t_ret{'LANGUAGE'} = parse_parameters($lang) if ($lang && ($lang ne 'NIL'));
		    $t_ret{'LOCATION'} = $loc if ($loc && ($loc ne 'NIL'));
		    $ret{$entry} = \%t_ret;
		} 
		
		else {	#unknown (error)
		    die("Unknown structure in parse_body_structure: [$substruct]");
		}
		$entry++;
    }
    if ($level == 0) {
		#	print "DEBUG[$level]: Returning final result\n";# if ($self->{DEBUG});
		# FIXME: DIRTY, DIRTY HACK - return self only if no children to children- otherwise return level 1
		if ($ret{1}->{1}) {
		    return(%{$ret{1}});
		} else {
		    return(%ret);
		}
    } else {
	#	print "DEBUG[$level]: Returning\n";# if ($self->{DEBUG});
		return(%ret);
    }
}

sub parse_fetch($@) {
   my ($self, @resp) = @_;

	### Parse out fetch response into internal structure	
	# Load up hash with fetch results (one entry per * tag FETCH)
    my %fetchsets;
    my $msgid = -1;
    foreach my $line (@resp) {
		if ($line =~ /^\* (\d+) FETCH \(/gs) {
			$msgid = $1;
			$fetchsets{$msgid} .= $line;
		} elsif (ok_response($line)) {
			$msgid = -1; # We Found the OK - This should be the end of the command
		} else {
			$self->throw_error("INTERNAL ERROR: No msgid set, but still trying to build fetchsets\n") if ($msgid < 0);
			$fetchsets{$msgid} .= $line;
		}
    }

    $self->dprint(0x02, "-- parse_fetch: Fetch count: ".scalar(keys %fetchsets)."\n");
    my %results;

	#$self->dprint(0x02, "-- parse_fetch: evaluating [$fetchset]\n");

    # find FETCH lines and process results
	foreach my $msgid (keys %fetchsets) {
		$self->dprint(0x02, "-- parse_fetch: Parsing FETCH response [$fetchsets{$msgid}]\n");
		my %ret;
		my $len = length($msgid)+10; # get length of just-extracted line
		$fetchsets{$msgid} = substr($fetchsets{$msgid}, $len); # remove fetch line from the remainder of the FETCH response
		$self->dprint(0x02, "-- parse_fetch: FETCH response after FETCH line removed: [$fetchsets{$msgid}]\n");
		# Break into hash (unfortunately, we can't do it inline regexp, since thre is a 32765 char limit on {min,max}. grr)
		my %result_entries;
		while ($fetchsets{$msgid}) {
		    my ($key, $length) = ($fetchsets{$msgid} =~ /^(BODY|BODYSTRUCTURE|ENVELOPE|FLAGS|INTERNALDATE|UID|RFC822.SIZE|BODY\[.*?\](?:\<\d+\>)?|RFC822(?:\.TEXT|\.HEADER)?) (?:\{(\d+)\}\r?\n?)?/gis) or return($self->throw_error("INTERNAL ERROR: unable to find keys in [".substr($fetchsets{$msgid},0,20)."...]"));
		    $fetchsets{$msgid} = substr($fetchsets{$msgid},(length($key)+1)+(($length) ? length($length)+4 : 0)); # trim newly found entries
		    if ($length) {
				$result_entries{$key}{'length'} = $length;
				$result_entries{$key}{'value'} = substr($fetchsets{$msgid},0,$length); # Save length of value

				if (length($result_entries{$key}{'value'}) < $length) {
				    return($self->throw_error("INTERNAL ERROR: unable to get [$length] length of fetchset [".length($fetchsets{$msgid})." available]"));
				}
			$fetchsets{$msgid} = substr($fetchsets{$msgid},$length); # trim length of message
		    } else { # no length, just a value
				($result_entries{$key}{'value'}) = ($fetchsets{$msgid} =~ /^($parens|$nstring|$number)/gis) 
				    or return($self->throw_error("INTERNAL ERROR: No value in [".substr($fetchsets{$msgid},0,20)."]"));
				$fetchsets{$msgid} = substr($fetchsets{$msgid},length($result_entries{$key}{'value'}));
		    }
		    $fetchsets{$msgid} =~ s/^[\)\r\n\s]*// if ($fetchsets{$msgid}); # Remove all 'unessesary trailers' (varies depending on end-of-command, end-of-line, etc)
		}


		 # Ok, we have our entries for this msgid - store them
		foreach my $key (keys %result_entries) {
		    if ($key eq "FLAGS") { #list of flags
				$result_entries{$key}{'value'} =~ s/^\((.*)\)/$1/; # deparenthesize
				my @flags = split(/ /,$result_entries{$key}{'value'}); # split flags to list
				$ret{$key}=\@flags;
		    } elsif ($key =~ /^BODY\[(.*)\](?:\<(\d+)\>)?$/) {
				my ($section, $offset) = ($1, $2); # save selection id, offset
				unless ($ret{'BODY'}) { my %newhash; $ret{'BODY'} = \%newhash; } # if no accompanying BODY[STRCUTURE] 
				my $hashptr = $ret{'BODY'}; # set up hash pointer
				foreach my $next (split(/\./,$section)) { # split on . for each level
				    unless ($hashptr->{$next}) { # if a BODYSTRUCTURE or BODY does not acompany the BODY[]
						my %newhash;
						$hashptr->{$next} = \%newhash; # create structure depth
				    }
				    $hashptr = $hashptr->{$next}; # dive one level deeper
				}
				$hashptr->{'BODY'} = $result_entries{$key}{'value'};
				$hashptr->{'BODYSIZE'} = $result_entries{$key}{'length'} || 0;
				$hashptr->{'OFFSET'} = $offset if $offset;
		    } elsif ($key eq "RFC822") {
				my ($headers, $text) = split(/\r\n\r\n/,$result_entries{$key}{'value'});
				$ret{'RFC822'}->{'HEADERS'} = $headers;
				$ret{'RFC822'}->{'TEXT'} = $text;
		    } elsif (my ($token) = ($key =~ /^RFC822.(.+)$/)) {
				$ret{'RFC822'}->{$token} = $result_entries{$key}{'value'};
		    } elsif ($key eq "INTERNALDATE") {
				$result_entries{$key}{'value'} =~ s/\"([^\"]+)\"/$1/; # remove quotes
				$ret{$key} = $result_entries{$key}{'value'};
		    } elsif ($key eq "ENVELOPE") {
				$ret{$key} = parse_envelope($result_entries{$key}{'value'});
		    } elsif (($key eq "BODY") || ($key eq "BODYSTRUCTURE")) {
				my %body = parse_body_structure($result_entries{$key}{'value'},0);
				$ret{$key} = \%body;
		    } else {
				$ret{$key}=$result_entries{$key}{'value'};
		    }
		}
		die "*****************************WARNING: ret is empty!************************\n" unless (%ret);
		$results{$msgid} = \%ret;
    }
    die "*****************************WARNING: results are empty!************************\n" unless (%results);
    return(%results);
}
sub extract_body($$) {
    my ($text,$length) = @_;
    $length =~ s/^\{(\d+)\}$/$1/; # extract body length
    my ($body) = ($text =~ /^\r\n(.{$length})/s); # extract length of body
    return($body);
}
sub parse_search (@) {
    my (@resp) = @_;
    my @results = ();
    # find SEARCH line and process results
    foreach my $line (@resp) {
        next unless ($line =~ s/^\*\s+SEARCH\s+([\d+\s]+)\s*\r\n$/$1/);
		@results = split(/ /,$line);
		last; # theres only 1 line
    }
    return(wantarray ? @results : @results ? sequencify(@results) : undef );
}
use re 'eval';

sub fill_permissions($) {
    my $hash = shift;
    # map short answers to long
    $hash->{'lookup'} = 1 if ($hash->{'l'});
    $hash->{'list'} = 1 if ($hash->{'l'});
    $hash->{'read'} = 1 if ($hash->{'r'});
    $hash->{'seen'} = 1 if ($hash->{'s'});
    $hash->{'write'} = 1 if ($hash->{'w'});
    $hash->{'insert'} = 1 if ($hash->{'i'});
    $hash->{'post'} = 1 if ($hash->{'p'});
    $hash->{'create'} = 1 if ($hash->{'c'});
    $hash->{'delete'} = 1 if ($hash->{'d'});
    $hash->{'admin'} = 1 if ($hash->{'a'});
    $hash->{'administer'} = 1 if ($hash->{'a'});
    
    # And vice versa
    $hash->{'l'} = 1 if ($hash->{'lookup'} || $hash->{'list'});
    $hash->{'r'} = 1 if ($hash->{'read'});
    $hash->{'s'} = 1 if ($hash->{'seen'});
    $hash->{'w'} = 1 if ($hash->{'write'});
    $hash->{'i'} = 1 if ($hash->{'insert'});
    $hash->{'p'} = 1 if ($hash->{'post'});
    $hash->{'c'} = 1 if ($hash->{'create'});
    $hash->{'d'} = 1 if ($hash->{'delete'});
    $hash->{'a'} = 1 if ($hash->{'admin'} || $hash->{'administer'});
    
    return($hash);
}    
sub parse_quota($$) {
    my ($localroot,$resp) = @_;
    my @resp = @{$resp};
    my %quota;
    
    foreach my $line (@resp) {
		if (my @resources = ($line =~ /^\* QUOTA $localroot ($parens+)\r\n$/)) {
		    foreach my $resource (@resources) {
				my ($topic, $values) = ($resource =~ /^\((\w+) (\d+ \d+)\)$/);
				if (defined $topic) {
					my @numbers = split(/ /,$values);
					$quota{$topic} = \@numbers;
				}
		    }
		} elsif (my ($ref) = ($line =~ /^\* QUOTAROOT $localroot (.*)\r\n$/)) {
		    $quota{'ROOT'} = $ref;
		    $localroot = $ref;
		}
    }
    return(%quota);
}


########## Raw communications functions ##########

=pod
    
=over 4
    
=item B<imap_send($string)>

Sends the string argument provided to the server.  A tag is automatically prepended to the command.

=cut
    
sub imap_send ($$) {
    my ($self,$string) = @_;
#    return($self->throw_error("No servers defined for [$string]")) unless $self->{'server'};
    my $server = $self->{'server'};

    my $tag = sprintf("%04i",++$self->{tag});
    chomp($string);

    $self->dprint(0x01, ">> $tag $string\r\n");
    print $server "$tag $string\r\n";

    $self->{tag} = $tag;
}

=pod

=item B<imap_send_tagless($string)>

Send the string argument provided to the server B<without a tag>.  This is needed for some operations.

=cut

sub imap_send_tagless ($$) {
    my ($self,$string) = @_;
#    return($self->throw_error("No servers defined for [$string]")) unless $self->{'server'};
    my $server = $self->{'server'};

    $self->dprint(0x01, ">> $string\r\n");
    print $server "$string\r\n";
}

=pod

=item B<imap_receive()> 

Accept responses from the server until the previous tag is encountered, at which point return the entire response.  CAUTION: can cause your program to hang if a tagged response isn't given.  For example, if the command expects more input and issues a '+' response, and waits for input, this function will never return. 

=cut

# FIXME: A timeout option would be nice...
sub imap_receive($) {
    my ($self) = @_;
#    return($self->throw_error("No servers defined for receiving")) unless $self->{'server'};
    my (@r, $_t);
    do {
		$_t = $self->{'server'}->getline; 
		$self->dprint(0x01, "<< $_t");
		push (@r, $_t);
    } until ($_t =~ /^$self->{tag}/);
	if ($#r < 1) {
		return ($r[0]);
    } else {
		return(@r);
    }
}

=pod

=item B<imap_receive_tagless()>

Accept a line of response, regardless if a tag is provided.  Misuse of this function can cause the module to be confused, especially if it received a tagged response and imap_receive() is subsequently used before another imap_send().  Applicable use of this function would be to read an (expected) untagged '+ go ahead' response.  If a tagged response is (unexpectedly) received, such as in a NO or BAD response, an imap_send() must be used before the next imap_receive().  You have been warned.

=cut

sub imap_receive_tagless($) {
    my ($self) = @_;
    my $_t;
    $_t = $self->{'server'}->getline; 
    $self->dprint(0x01, "<< $_t") if ($_t);
    return ($_t);
}

########## Object functions ###########
=pod

=back

=head1 METHODS - INTERFACE

These are the methods for manipulating the object or retrieving information from the object.

=over 4

=cut 

##### Constructor
=pod

=item B<new()>

=item B<new($server)>

Creates a new IMAP object.  You can optionally specify the server to connect to, using default parameters (see connect() for details).  On success, an IMAP object reference is returned - on failure, a string is returned detailing the error.

=cut

sub new ($){
    my $proto = shift; #ignore first arg
    my $self = {};
    bless $self = {
		'ID' => $ID++,
    	'name' => '', # the DNS/IP address to match
    	'server' => '', # Actual socket
		'tag' => '*',
		'error' => '',
		'error_read' => 1,
		'DEBUG' => 0,
		'onfail' => 'error',
		'errorstyle' => 'stack',
		'capability' => '',
		'capabilities' => {},
		'capability_checking' => 1,
		'user' => '',
		'auth' => '',
	    }, $proto;
	
	$Instances{$self->{'ID'}} = \$self;
    # If a server was supplied, try to connect to it
    if (my $server = shift) {
		if ($self->connect(PeerAddr => $server)) {
		    return($self);
		} else {
		    my $err = $self->{error};
		    undef $self;
		    return($err);
		}
    } else {
		return($self);
    }
}
sub DESTROY { # Undocumented: Not to be directly called
	my $self = shift;
	if ($Instances{$self->{'ID'}}) {
		$self->disconnect(); # FIXME: Probably not nessesary
		delete $Instances{$self->{'ID'}};
		return;
	}
	
	# If we reach here, we didn't find ourself, which is a seirous problem
	warn "ERROR: Could not find self in Instances upon DESTROY - Something is seriously wrong!\n";
	foreach my $key (keys %Instances) {
		warn "PANIC DUMP: Instance name: ".(($Instances{$key}->{'name'}) ?  $Instances{$key}->{'name'} : "(none)")."\n";
	}
	die "DUMP COMPLETE: Aborting...\n\n";
}

##### Object manipulation functions
=pod

=item B<debuglevel($level)>

Set the debug level.  Debug levels are set on a bitmask, and all debug output is to STDERR.  Valid bits are as follows:

=over 4

=item B<0x01 - Communications dump>

=over 2

This will output all IMAP communications, with >> showing the sent data, and << showing the received data.

=back

=item B<0x02 - Fetch-parsing dump>

=over 2

This dumps a *lot* of data about the parsing of a fetch statement.  

=back

= item B<0x04 - Annotations dump>

=over 2

This will print debugging information about processing getannotations and setannotations\n";

=back

=back

=cut

sub debuglevel($$) {
    my ($self,$level) = @_;
    if ($level >= 0)  {
		$self->{DEBUG} = $level;
    } else {
		return($self->throw_error("Invalid value [$level] for debuglevel: valid values are 0 and above"));
    }
}

=pod

=item B<onfail($action)>

Tell the object what to do when a command fails, either in the object, or if a !OK response is received (i.e. NO or BAD).  Valid values are 'ERROR' (return undef, set error()) or 'ABORT' (abort, printing error to stderr).  Default is ERROR.  Values are case insensitive.

=cut

sub onfail($$) {
    my ($self,$action) = @_;
    $action = lc($action);
    if (($action eq 'error') || ($action eq 'abort')){
		$self->{onfail} = $action;
    } else {
		return($self->throw_error("Invalid value [$action] for onfail: valid values are 'ERROR' or 'ABORT'"));
    }
}

=pod

=item B<errorstyle($action)>

Controls how errors are handled when onfail is 'ERROR'.  Valid values are 'LAST', for only storing the last error, or 'STACK', where all errors are saved until the next call to error().  STACK is most useful for those programs that tend to call nested functions, and finding where a program is truly failed (so the last error doesn't erase the original error that caused the problem).  Default is 'STACK'

=cut

sub errorstyle($$) {
    my ($self,$action) = @_;
    $action = lc($action);
    if (($action eq 'last') || ($action eq 'stack')){
		$self->{errorstyle} = $action;
    } else {
		return($self->throw_error("Invalid value [$action] for errorstyle: valid values are 'LAST' or 'STACK'"));
    }
}

=pod

=item B<error()>

Prints the last error encountered by the imap object.  If you executed a command and received an undef in response, this is where the error description can be found.

=cut
    
sub error($) {
    my ($self) = @_;
    $self->{error_read} = 1;
    return ($self->{error});
}

=pod

=item B<capability_checking()>

Enable or disable capability checking for those commands that support it.  If enabled, a supported command will first check to see that the appropriate atom, as specified in the command's respective RFC, appears in the capability string.  If it does not, the command will not be sent to the server, but immediately fail.  If disabled, all commands will assume any required atom exists, and the command will be sent to the server.

Any valid 'true' value will enable the checking, while any 'false' value will disable it.

=cut
    
sub capability_checking($$) {
    my ($self, $value) = @_;
    $self->{capability_checking} = $value;
}

##### _imap_command
=pod

=item B<_imap_command($command, $arguments, <$continuation>, ...)>

Execute an IMAP command, wait for and return the response.  The function accepts the command as the first argument, arguments to that command as the second argument, followed by continuation responses for if/when the server issues a '+' response, such as '+ go ahead'.  If there are less continuations specified than the server requests, the command will fail in the normal manner.  If there are more continuations specified than the server requests, a warning is printed, however the response is parsed as usual - if it was OK then the command will be considered successful.

The function returns the server response on success, and undef on failure, setting error().

=cut

sub _imap_command ($$@) {
    my ($self,$command, @argset) = @_;
    my @fullresp;
    my $i=0;
    return($self->throw_error("No servers defined for [$command][".join('][',@argset)."]")) unless $self->{'server'};

    $self->imap_send(($argset[0]) ? "$command $argset[0]" : $command);
    
    my ($datasize,$datasizemax) = (0,0);
    while (1) {
		my $resp = $self->imap_receive_tagless();
		if ($resp) {
		    push(@fullresp,$resp);

			# First, check to see if we are in the middle of a size-based continuation response
			if ($datasizemax > 0) {
				$datasize += length($resp) + 1;
				# >= because we could get termination chars (like a ')n', for instance) in the last line.  
				if ($datasize >= $datasizemax) { 
					($datasize,$datasizemax) = (0,0);
				}
				next; # next line
			}

			# First, check if this is a multi-line response
		    if (untagged_response($resp)) { 
				if ($resp =~ /\{(\d+)\}\s*$/) {
					$datasizemax = $1; 
				}
				next;
		    } 
		    
		    if (ok_response($resp)) {
				if ($i != $#argset) {
				    print STDERR "WARNING: Only ", $i+1 ," arguments of ", $#argset+1 ," used before successful response in [$command] command\n";
				}
				# Check for 'server responses' as defined in RFC3501, Section 7.
				if ($server_response_callback) {
					my %actual_responses;
					foreach my $line (@fullresp) {
						if (my ($_v, $_t) = $line =~ /(\d+)\s*(\w+)/) { # num-title: # TITLE
							foreach my $attr (@SERVER_RESPONSES) { # We only match pre-approved values (FIXME: Is this what we want?)
								if (lc($_t) eq lc($attr)) {	
									$actual_responses{$attr} = $_v;
								}
							}
						}
					}
					$server_response_callback->(\%actual_responses); # Run the callback with the values
				}
			    # Return the results
				return(@fullresp);
		    } elsif (continue_response($resp)) {
				if ($i < $#argset) {
				    $self->imap_send_tagless($argset[++$i]);
				} else {
				    return($self->throw_error("$command failed: Server wanted more continuations than the ".$#argset." provided"));
				}
		    } elsif (failure_response($resp)) {
				return($self->throw_error("$command failed: @fullresp"));
		    } elsif (untagged_response($resp)) { 
				# This is just to avoid having untagged responses flagged as 'unrecognised'
		    } else {
				# unrecognized response - put in any times its ok for this to happen in the unless statement.
				unless ((lc($command) eq 'fetch') || (lc($command) eq 'uid fetch')) {
				    return($self->throw_error("INTERNAL ERROR: _IMAP_COMMAND - Unrecognized response from $command: @fullresp"));
				}
	    	}
		} else {
			# We got nothing back.... ?  we must have been disconnected
			$self->disconnect();
			return($self->throw_error("Disconnected\n"));
		}
    }
    
# finish reading command, since we're out of arguments
#    my @resp = $self->imap_receive();
    
#    (ok_response(@resp)) ?
#	return(@resp) :
#	return($self->throw_error("$command failed: @resp"));	
}


##### connect
=pod

=item B<connect(%args)>

Connect to the supplied IMAP server.  Inerits all the options of IO::Socket::SSL (and thusly, IO::Socket::INET), and adds the following custom options:

=over 4

=item ConnectMethod

=over 2

Sets the priority of the login methods via a space seperated priority-ordered list.  Valid methods are 'SSL', 'STARTTLS', and 'PLAIN'.  The default is to try loggin in via SSL, then connecting to the standard IMAP port and negotiating STARTTLS.  'PLAIN' is entirly unencrypted, and is not a default option - it must be specified if desired.

The 'STARTTLS' method uses the starttls() command to negotiate the insecure connection to a secure status - it is functionally equivlant to using the 'PLAIN' method and subsequently calling starttls() within the program.

=back

=item IMAPSPort

=over 2

Set the IMAPS port to use when connecting via the SSL method (default 993).

=back

=item IMAPPort

=over 2

Set the IMAP port to use when connecting via the STARTTLS or PLAIN methods (default 143).

=back

=back 

The error logs are cleared during a connection attempt, since (re)connecting essentially is a new session, and any previous errors cannot have any relation the current operation.  Also, the act of finding the proper method of connecting can generate internal errors that are of no concern (as long as it ultimately connects).  Should the connection fail, the error() log will contain the appropriate errors generated while attempting to connect.  Should the connection succeed, the error log will be clear.

Returns 1 on success, and undef on failure, setting error().

=cut

sub connect($%) {
    my ($self, %args) = @_;
    $self->throw_error("No arguments supplied to connect") unless (%args);
    my @methods = ($args{ConnectMethod}) ? split(' ',$args{ConnectMethod}) : qw(SSL STARTTLS);
    my $connected;
    my $errorstr;
    my $server;
    foreach my $method (@methods) {
		my @resp;
		if ($method eq "SSL") {
		    $args{PeerPort} = $args{IMAPSPort} || 993;
		    unless ($server = new IO::Socket::SSL(%args)) {
				$errorstr .= "SSL Attempt: ". IO::Socket::SSL::errstr() ."\n";
				next;
		    }
		} elsif ($method eq 'STARTTLS') {
		    $args{PeerPort} = $args{IMAPPort} || 143;
		    unless ($server = new IO::Socket::INET(%args)) {
				$errorstr .= "STARTTLS Attempt: Unable to connect: $@\n";
				next;
		    }
		} elsif ($method eq 'PLAIN') {
		    $args{PeerPort} = $args{IMAPPort} || 143;
		    unless ($server = new IO::Socket::INET(%args)) {
				$errorstr .= "PLAIN Attempt: Unable to connect: $@\n";
				next;
		    }
		}
		# Execute a command to verify we're connected - some servers will accept a connection
		# but immediately dump the connection if something isn't supported (i.e. Exchange and
		# connecting to Non-ssl when SSL is required by the server)
	
		$self->{'server'} = $server;
		@resp = $self->imap_receive_tagless(); # collect welcome
		if ($resp[0] && untagged_ok_response(@resp) && ok_response($self->noop())) {
		    # Post-processing
		    if ($method eq 'STARTTLS') {
				if ($self->starttls(%args)) {
				    $connected = 'ok';
				    last;
				} else {
				    $errorstr .= "STARTTLS Attempt: ".$self->error()."\n";
				    next;
				}
		    } else {
				$connected = 'ok';
		    }
		} else {
		    $errorstr .= "$method attempt: Connection dropped upon connect\n";
		}
    }
	    
    if (!$connected) {
		chop($errorstr); # clip the tailing newline: we print errors without them
		return ($self->throw_error($errorstr));
    } else {
		$self->{'server'} = $server;
		$self->error; # clear error logs
    }
    
    return(1);
}

=pod

=item B<disconnect()>

Disconnect from the server.  This command can safely be used on an already-disconnected server.

=cut

sub disconnect($) {
    my ($self) = @_;

	if ($self->{'server'}) { # If we're still connected to something...
	    $self->{'server'}->close(); # close connection
		undef $self->{'server'}; # remove server
	    undef $self->{'name'}; # clear name
	    undef $self->{'auth'}; # clear authentication info
	    $self->{'tag'} = '*'; # Reset tag to * (for welcome message)
	}
}

=pod 

=item B<register_mailbox_update(&subfunction)>

This function sets up a callback function for when the IMAP server sends back a Server Response in accordance with RFC3501 Section 7.3, which stiuplates that while select()ed or examine()ing a mailbox, updates as to the mailbox content can be sent back after any command as tagless responses.

The subfunction will be passed one hash argument.  The hash argument will contain keys that represent the data type (EXISTS, RECENT), and their respective values will be the values returned by the server.

If no function is registered via this method, or this method is called with an 'undef' argument, no special action will be taken should these server responses be encountered by the library.

=cut 

sub register_mailbox_update($$) {
	my ($self, $callback_func) = @_;

	# Test to make sure we have a sub reference (or undef to clear the callback)
	return($self->throw_error("Argument to register_mailbox_update is not a CODE reference\n"))
		unless ((ref($callback_func) eq 'CODE') || (!defined $callback_func)); 
	
	$server_response_callback = $callback_func;
}

=pod 

=back

=head1 METHODS - COMMANDS

These are the standard IMAP commands from the IMAP::Client object.  Methods return various structures, simple and complex, depending on the method.  All methods return undef on failure, setting error(), barring an override via the onfail() function.

=over 4

=cut 

###########################################################
########## rfc3501 (IMAP VERSION 4rev1) commands ##########
###########################################################
# any state

=pod

=item B<capability()>

Request a listing of capabilities that the server supports.  Note that the object caches the response of the capability() command for determining support of certain features.

=cut

sub capability() {
    my ($self) = @_;
    
    if ($self->{capability}) {
		return($self->{capability});
    }
    my @resp = $self->_imap_command("CAPABILITY", undef);

    # Cache the results if ok:
    if ($resp[0]) {
		$self->{capability} = @resp;
		my %abilities;
		foreach my $line (@resp) {  # find the untagged capability line
		    if (my ($capability) = $line =~ /^\*\s+CAPABILITY (.*)$/) {
				foreach my $caps (split(/ /,$capability)) {
				    $abilities{$caps} = 1;
				}
				last;
		    }
		}
		$self->{capabilities} = \%abilities;
    }
    return(@resp);
}

=pod

=item B<noop()>

Issue a "No Operation" command - i.e. do nothing.  Also used for idling and checking for state changes in the select()ed mailbox

=cut

sub noop() {
    my ($self) = @_;
    return($self->_imap_command("NOOP", undef));
}

=pod

=item B<logout()>

Log the current user out and return This function will not work for multi-stage commands, such as those that issue a '+ go ahead' to indicate the continuation to send data.the connection to the unauthorized state.

=cut

sub logout() {
    my ($self) = @_;
    $self->{user} = '';
    $self->{auth} = '';
    # FIXME: untagged response BYE required by rfc - check for it?
    return($self->_imap_command("LOGOUT", undef));
}

# not authenticated state

=pod

=item B<starttls(%args)>

Issue a STARTTLS negotiation to secure the data connection.  This function will call capability() twice - once before issuing the starttls() command to verify that the atom STARTTLS is listed as a capability(), and once after the sucessful negotiation, per RFC 3501 6.2.1.  See capability() for unique rules on how this module handles capability() requests.  Upon successful completion, the connection will be secured.  Note that STARTTLS is not available if the connection is already secure (preivous sucessful starttls(), or connect() via SSL, for example).

STARTTLS is checked in capability() regardless of the value of capability_checking().

Any call arguments in %args are passed onto the underlying IO::Socket::SSL->start_SSL() function.

This function returns 1 on success, since there is no output to return on success.  Failures are treated normally.

=cut

sub starttls ($%){
    my ($self, %args) = @_;

    unless ($self->check_capability('STARTTLS')) {
		return($self->throw_error("STARTTLS not found in CAPABILITY"));
    }
    my @recv = $self->_imap_command("STARTTLS",undef);
    $self->dprint(0x01, "<TLS negotiations>\n"); # compensation for lack of tapping into dump
    $args{SSL_version} ||= 'TLSv1';
    if (IO::Socket::SSL->start_SSL($self->{'server'}, %args)) {
		# per RFC 3501 - 6.2.1, we must re-establish the CAPABILITY of the server after STARTTLS
		$self->{capability} = '';
		@recv = $self->capability();
    } else {
		return($self->throw_error("STARTTLS Attempt: ".IO::Socket::SSL::errstr()))
    }
    return(@recv);
}

=pod

=item B<authenticate($login, $password)>

=item B<authenticate($login, $password, $authorize_as)>

=item B<authenticate2($login, $password)>

=item B<authenticate2($login, $password, $authorize_as)>

Login in using the AUTHENTICATE mechanism.  This mechanism supports authorization as someone other than the logged in user, if said user has permission to do so.
authenticate() uses a one-line login sequence, while authenticate2() uses a multi-line login sequence.  Both are provided for compatiblity reasons.

OBSOLETE WARNING: In the future, this split-line behavior will be controlled by an object function, and authenticate() will be the only function.

=cut

sub authenticate($$$) { # One-line version of authentication
    my ($self,$login,$passwd,$autheduser) = @_;
    $self->error; # clear error logs
    $self->{user} = $login;
    $self->{auth} = $autheduser || $login;
    $autheduser='' unless (defined $autheduser);
    my $encoded = encode_base64("$autheduser\000$login\000$passwd");
    return($self->_imap_command("AUTHENTICATE","PLAIN $encoded"));
}
sub authenticate2($$$) { # Multi-line version of authentication
    my ($self,$login,$passwd,$autheduser) = @_;
    $self->error; # clear error logs
    $self->{user} = $login;
    $self->{auth} = $autheduser || $login;
    $autheduser='' unless (defined $autheduser);
    my $encoded = encode_base64("$autheduser\000$login\000$passwd");    
    return($self->_imap_command("AUTHENTICATE","PLAIN","$encoded"));
}

=pod

=item B<login($username,$password)>

Login using the basic LOGIN mechanism.  Passwords are sent in the clear, and there is no third-party authorization support.

=cut

sub login ($$$) {
    my ($self,$username,$password) = @_;
    $self->{user} = $self->{auth} = $username;
    return($self->_imap_command("LOGIN","$username $password"));
}

# authenticated state
=pod

=item B<select($mailbox)>

Open a mailbox in read-write mode so that messages in the mailbox can be accessed.  This function returns a hash of the valid tagless responses.  According to RFC-3501, these responses include:

=over 4

=item * FLAGS (<flags>)

=item * <n> EXISTS

=item * <n> RECENT

=item * OK [UNSEEN <n>]

=item * OK [PERMANENTFLAGS <flaglist>]

=item * OK [UIDNEXT <n>]

=back

If the server supports an earlier version of the protocol than IMAPv4, the only flags required are FLAGS, EXISTS, and RECENT.

Finally, hash responses will have an 'OK' key that will contain the current permissional status, either 'READ-WRITE' or 'READ-ONLY', if returned by the server.  Returns an empty (undefined) hash on error.

IMPORTANT!  You should always check to see if an ALERT was issued.  ALERTs should be relayed to the user if they exist!

=cut

sub select($$) {
    my ($self,$mailbox) = @_;
    # Don't add quotes around mailbox if they already exist
    return(parse_select_examine($self->_imap_command("SELECT", quote_once($mailbox))));
}

=pod

=item B<examine($mailbox)>

Identical to select(), except the mailbox is opened READ-ONLY.  Returns an empty (unefined) hash on error.

=cut

sub examine($$) {
    my ($self,$mailbox) = @_;
    return(parse_select_examine($self->_imap_command("EXAMINE", quote_once($mailbox))));
}

=pod

=item B<create($mailbox,\%properties)>

Create a mailbox with the given name.  Also assigns the properties given immediately upon creation.  Valid properties are:

=over 4

=item * quota - A hash, with the keys being the type (aka STORAGE), and the values being the actual quota for that type, with size-based quotas given in kb

=item * permissions - initial permissions for the mailbox owner(s) (equivalent to setacl), for if the owner needs different permissions than the server's default

=back

For example:
    $imap->create("asdfasdf",{quota=>{'STORAGE',50000}, permissions => 'lrws'})

=cut

sub create($@) {
    my ($self,$mailbox,$properties,$server) = @_;

    # Create mailbox
    if ($server) {
    	return undef unless ($self->_imap_command("CREATE", quote_once($mailbox)." $server")); #err already thrown
    } else {
	    return undef unless ($self->_imap_command("CREATE", quote_once($mailbox))); #err already thrown
    }
    
    # set quota (if needed)
    if ($properties->{quota}) {
		foreach my $type (keys %{$properties->{quota}}) {
		    unless ($properties->{quota}->{$type} =~ /^\d+$/) {
				$self->throw_error("Quota second argument not numerical in create");
				goto fail;
		    }
		    
		    unless ($self->setquota($mailbox,$type,$properties->{quota}->{$type})) {
				goto fail;
		    }
		}
    }

    # set current owner(s) permissions (if needed)
    if ($properties->{permissions}) {
		my %owners = $self->getacl($mailbox);
		foreach my $owner (keys %owners) {
		    unless ($self->setacl($mailbox,$owner,$self->buildacl($properties->{permissions}))) {
			goto fail;
		    }
		}
    }

    return(1);

fail:
    $self->setacl($mailbox,$self->{auth},$self->buildacl('all')); # cover cases where need explicit delete permission (as admin, for example)
    unless ($self->delete($mailbox)) {
		return($self->throw_error("Failed applying properties, and couldn't delete mailbox in recovery ****CLEANUP REQUIRED***"));
    }
    return($self->throw_error("Mailbox [$mailbox] creation aborted"));
}

=pod

=item B<delete($mailbox)>

Delete an existing mailbox with the given name.  
B<NOTE>: RFC notes that sub-mailboxes are not automatically deleted via this command.

=cut

sub delete($$) {
    my ($self,$mailbox) = @_;
    return($self->_imap_command("DELETE", quote_once($mailbox)));
}

=pod

=item B<rename($oldmailbox,$newmailbox)>

Rename an existing mailbox from oldmailbox to newmailbox.

=cut

sub rename($$$) {
    my ($self,$oldmailbox,$newmailbox) = @_;
    return($self->_imap_command("RENAME", quote_once($oldmailbox).' '.quote_once($newmailbox)));
}

=pod

=item B<subscribe($mailbox)>

Subscribe the authorized user to the given mailbox

=cut

sub subscribe($$) {
    my ($self,$mailbox) = @_;
    return($self->_imap_command("SUBSCRIBE", quote_once($mailbox)));
}

=pod

=item B<unsubscribe($mailbox)>

Unsubscribe the authorized user from the given mailbox

=cut

sub unsubscribe($$) {
    my ($self,$mailbox) = @_;
    return($self->_imap_command("UNSUBSCRIBE", quote_once($mailbox)));
}

=pod

=item B<list($reference,$mailbox)>

List all the local mailboxes the authorized user can see for the given mailbox from the given reference.  Returns a listref of hashrefs, with each list entry being one result.  Keys in the hashes include FLAGS, REFERENCE, and MAILBOX, and their returned values, respectivly.

=cut

sub list($$$) {
	warn "DEPRECIATED: list-returning IMAP::Client::list(): Array return values are depreciated and will be removed in future revisions! Instead, accept scalar list-reference\n" if (wantarray);
    my ($self,$reference,$mailbox) = @_;
    my @result = $self->_imap_command("LIST", quote_once($reference).' '.quote_once($mailbox));
	return(undef) unless ($result[0]);
    my @parsed_result = parse_list_lsub(@result);
	return((wantarray) ? @parsed_result : \@parsed_result);
}

=pod

=item B<lsub($reference,$mailbox)>

List all the local subscriptions for the authorized user for the given mailbox from the given reference. Returns a listref of hashrefs, which each list entry being one result.  Keys in the hashes include FLAGS, REFERENCE, and MAILBOX, and their returned values, respectivly.

=cut

sub lsub($$$) {
	warn "DEPRECIATED: list-returning IMAP::Client::lsub(): Array return values are depreciated and will be removed in future revisions! Convert code to accept scalar list-reference\n" if (wantarray);
    my ($self,$reference,$mailbox) = @_;
    my @result = $self->_imap_command("LSUB", quote_once($reference).' '.quote_once($mailbox));
	return(undef) unless ($result[0]);
    my @parsed_result = parse_list_lsub(@result);
	return((wantarray) ? @parsed_result : \@parsed_result);
}

=pod

=item B<status($mailbox,@status)>

Get the provided status items on the currently select()ed or examine()d mailbox.  Each argument is a different status information item to query.
According to RFC, the following tags are valid for status() queries: B<MESSAGES>, B<RECENT>, B<UIDNEXT>, B<UIDVALIDITY>, B<UNSEEN>.  Since there may be future RFC declarations or custom tags for various servers, this module does not restrict to the above tags, but rather lets the server handle them appropriately (which may be a NO or BAD response).

Upon successful completion, the return value will be a hash of the queried items and their returned values.

=cut

sub status($$@) {
    my ($self,$mailbox,@statuslist) = @_;
    my %results;

    unless (@statuslist) {
		return($self->throw_error("No status options to check in STATUS command"));
    }
    my $statusitems = '(';
    foreach my $status (@statuslist) {
		$statusitems .= "$status ";
    }
    chop($statusitems); # we don't want that trailing space
    $statusitems .= ')';

    my @resp = $self->_imap_command("STATUS", quote_once($mailbox)." $statusitems");
    return(undef) unless ($resp[0]);
    
    # find STATUS line and process results
    foreach my $line (@resp) {
        next unless ($line =~ s/^\*\s+STATUS\s+\S+\s+\((.*?)\)\r\n$/$1/);
		%results = split(/ /,$line); # thanks to the "key value key value" string
    }
    
    return(%results);
}


=pod

=item B<append($mailbox, $message, $flaglist)>

Append the given message to the given mailbox with the given flaglist.  For information on the flaglist, see the buildflaglist() method.

The append() method will do some housekeeping on any message that comes in - namely, it will ensure that all lines end in 'CRLF'.  The reasoning is that the RFC strictly states that lines must end in 'CRLF', and most *nix files end with just 'LF' - therefore rather than force every program to muck with message inputs to ensure compatiblity, the append() method will ensure it for them.

This 'CRLF' assurance is done for all commands - however its noted here because it also does it to the message itself in this method, potentially modifying data.

Unless overridden, append will check for the LITERAL+ capability() atom, and use non-synchronizing literals if supported - otherwise, it will use the standard IMAP dialog.

Upon successful execution, the return of this function depends on the type of variable receiving the data.

=cut

sub append ($$$) {
    my ($self,$mailbox,$message,$flaglist) = @_;
    my $flagstring = "";

    #use IO::File;
    #my $testfile = new IO::File "/tmp/test.txt", ">" or warn "Unable to open /tmp/test.txt\n";
    #print $testfile $message;

    # ensure newlines end in CRLF
    $message =~ s/((?<!\r))\n/$1\r\n/gs; # ensure newlines end in CRLF (replace all lone LF with CRLF)

    #print $testfile $message;
    #$testfile->close();

    my $messagelen = length($message); # use the length of the *clean* message

    $flaglist = "()" unless $flaglist;

	my @result = ($self->check_capability('LITERAL+')) ? #non-synchronizing literals support
					$self->_imap_command("APPEND",quote_once($mailbox)." $flaglist {$messagelen+}\r\n$message") :
					$self->_imap_command("APPEND",quote_once($mailbox)." $flaglist {$messagelen}",$message);
					
	if ($self->check_capability('UIDPLUS')) {
		
	}
}

# selected state

=pod

=item B<check()>

Request a checkpoint of the currently select()ed mailbox.  The specific actions and responses by the server are on an implementation-dependant basis.  

=cut

sub check() {
    my ($self) = @_;
    return($self->_imap_command("CHECK", undef));
}

=pod

=item B<close()>

Close the currently select()ed mailbox, expunge()ing any messages marked as \Deleted first.  Unlike expunge(), this command does not return any untagged responses, and closes the mailbox upon completion.

=cut

sub close() {
    my ($self) = @_;
    return($self->_imap_command("CLOSE", undef));
}

=pod

=item B<expunge()>

Expunge() any messages marked as \Deleted from the currently select()ed mailbox.  Will return untagged responses indicating which messages have been expunge()d.

=cut

sub expunge() {
    my ($self) = @_;
    return($self->_imap_command("EXPUNGE", undef));
}

=pod

=item B<search($searchstring,<$charset>)>

Search for messages in the currently select()ed or examine()d mailbox matching the searchstring critera, where searchstring is a valid IMAP search query.See the end of this document for valid search terminology.  The charset argument is optional - undef defaults to ASCII.

This function returns a listref of sequence IDs that match the query when in list context, and a space-seperated list of sequence IDs if in scalar context.  The scalar context allows nested calling within functions that require sequences, such as `fetch(search('RECENT'),undef,'FLAGS')`

=cut

sub search($$) {
    my ($self,$searchstring,$charset) = @_;
    return(parse_search($self->_imap_command("SEARCH", (($charset) ? "CHARSET $charset $searchstring" : $searchstring))));
}


=pod
    
=item B<fetch($sequence, [\%body, \%body, ...], @other)>
    
Fetch message data. The first argument is a sequence set to retrieve.

The second argument, the body hash ref, is designed to easily create the body section of the query, and takes the following arguments:

=over 4

=item * body

Specify the section of the body to fetch().  undef is allowed, meaning no arguments to the BODY option, which will request the full message (unless a header is specified - see below).

=item * offset

Specify where in the body to start retrieving data, in octets.  Default is from the beginning (0).  If the offset is beyond the end of the data, an empty string will be returned.  Must be specified with the length option.

=item * length

Specify how much data to retrieve starting from the offset, in octets.  If the acutal data is less than the length specified, the acutal data will be returned.  There is no default value, and thus must be specified if offset is used.

=item * header 

Takes either 'ALL', 'MATCH', or 'NOT'.  'ALL' will return all the headers, regardless of the contents of headerfields.  'MATCH' will only return those headers that match one of the terms in headerfields, while 'NOT' will return only those headers that *do not* match any of the terms in the headerfields.

=item * headerfields 

Used when header is 'MATCH' or 'NOT', it specifies the headers to use for comparison.  This argument is a string of space-seperated terms.

=item * peek

When set to 1, uses the BODY.PEEK command instead of BODY, which preserves the \Seen state of the message

=back

A single hash reference may be supplied for a single body command.  If multiple body commands are required, they must be passed inside an array reference (i.e. [\%hash, \%hash]).

If an empty hashref is supplied as a \%body argument, it is interpreted as a BODY[] request.

The third argument, other, is a string of space-seperated stand-alone data items.  Valid items via RFC3501 include:

=over 4

=item * BODY

The non-extensible form of BODYSTRUCTURE (not to be confused with the first argument - this command fetches structure, not content)

=item * BODYSTRUCTURE

The MIME-IMB body structure of the message.

=item * ENVELOPE

The RFC-2822 envelope structure of the message.

=item * FLAGS

The flags set for the message

=item * INTERNALDATE

The internal date of the message

=item * RFC822, RFC822.HEADER, RFC822.SIZE, RFC822.TEXT

RFC822, RFC822.HEADER, and RFC822.TEXT are equivilant to the similarly-named BODY options from the first argument, except for the format they return the results in (in this case, RFC-822).  Except RFC822.HEADER, which is the RFC822 equivilant of BODY.PEEK[HEADER], there is no '.PEEK' alternative available, so the \Seen state may be altered.  SIZE returns the RFC-822 size of the message and does not change the \Seen state.

=item * UID

The unique identifier for the message.

=item * ALL

equivalent to FLAGS, INTERNALDATE, RFC822(SIZE), ENVELOPE

=item * FAST

equivalent to FLAGS, INTERNALDATE RFC822(SIZE)

=item * FULL

equivalent to FLAGS, INTERNALDATE, RFC822(SIZE), ENVELOPE, BODY()

=back

The final argument, other, provides some basic option-sanity checking and assures that the options supplied are in the proper format.

The return value is a hash of nested hashes.  The first level of hashes represents the message id.  The second and subsequent levels represents a level of multiparts, equivilant to the depth computed by the server and used for the body[] section retrievals.  Particularly subject to nested hashing are the BODY and BODYSTRUCTURE commands.  Commands used in the other argument typically are found on the base level of the hash: for example, UID and FLAGS would be found on the first level.  Structure and BODY parts are found nested in their appropriate sections.

This is a complex method for a data-rich command.  Here are some examples to aid in your understanding:

This command is equivilant to `xxx FETCH 1 (BODY[1] BODY.PEEK[HEADER.FIELDS (FROM SUBJECT TO DATE X-STATUS) RFC822.SIZE FLAGS]`:
$imap->fetch(1,[{header=>'MATCH', headerfields=>'FROM SUBJECT TO DATE X-STATUS ', peek=>1},
                {body=>1, offset=>1024, length=>4000}],
               qw(RFC822.SIZE FLAGS));


Please see the "Fetch Response Tutorial" at the bottom of this document.
    
=cut

sub fetch ($$@) {
    my ($self,$sequence,$bodies,@other) = @_;

    return($self->throw_error("Invalid sequence string: $sequence")) unless (is_sequence_set($sequence));

    my $fetchstring = $self->buildfetch($bodies,join(' ',@other));
    return($self->throw_error("Invalid fetch string: <empty>")) unless ($fetchstring);
    
    return($self->parse_fetch($self->_imap_command("FETCH","$sequence $fetchstring")));
}


=pod

=item B<store($sequence, $operation, $flaglist)>

Set flags on a sequence set. For information on the flaglist, see the buildflaglist() method.  See DEFINITIONS above for "sequence set".

Operation is one of the following actions to take on the flags:

=over 4

=item * FLAGS - Replace the currently set flags of the message(s) with the flaglist.

=item * +FLAGS - Add the flaglist flags to the currently set flags of the message(s).

=item * -FLAGS - Remove the flaglist flags from the currently set flags of the message(s).

=back

Under normal circumstances, the command returns the new value of the flags as if a fetch() of those flags was done.  You can append a .SILENT operation to any of the above commands to negate this behavior, and not have it return the new flag values.

=over 4

=item * FLAGS.SILENT - Equivalent to FLAGS, but without returning a new value

=item * +FLAGS.SILENT - Equivalent to +FLAGS, but without returning a new value

=item * -FLAGS.SILENT - Equivalent to -FLAGS, but without returning a new value

NOTE ON SILENT OPTION: The server SHOULD send an untagged fetch() response if a change to a message's flags from an external source is observed.  The intent is that the status of the flags is determinate without a race condition.  In other words, .SILENT may still return important (unexpected) flag change information!

=back 

=cut

sub store ($$$$){
    my ($self,$sequence,$operation,$flaglist) = @_;    
    return($self->throw_error("Invalid sequence string: $sequence")) unless (is_sequence_set($sequence));
    return($self->_imap_command("STORE", "$sequence $operation $flaglist"));
}

=pod

=item B<copy($sequence, $mailbox)>

Copy a sequence set of messages to a mailbox.  See DEFINITIONS above for "sequence set"

=cut

sub copy($$$) {
    my ($self,$sequence,$mailbox) = @_;
    return($self->throw_error("Invalid sequence string: $sequence")) unless (is_sequence_set($sequence));
    return($self->_imap_command("COPY", "$sequence $mailbox"));
}

# valid UID commands (RFC-3501): COPY FETCH STORE SEARCH
# valid UID commands (RFC-2359): EXPUNGE

=pod

=item B<uidcopy($sequence,$mailbox)>

Identical to the copy() command, except set is a UID set rather than a sequence set.

=cut

sub uidcopy($$$) {
    my ($self,$sequence,$mailbox) = @_;
    return($self->throw_error("Invalid sequence string: $sequence")) unless (is_sequence_set($sequence));
    return($self->_imap_command("UID COPY","$sequence $mailbox"));
}

=pod

=item B<uidfetch($sequence,$fetchstring)>

Identical to the fetch() command, except set is a UID set rather than a sequence set.

=cut

sub uidfetch ($$@) {
    my ($self,$sequence,$bodies,@other) = @_;
    return($self->throw_error("Invalid sequence string: $sequence")) unless (is_sequence_set($sequence));

    my $fetchstring = $self->buildfetch($bodies,join(' ',@other));
    return($self->throw_error("Invalid fetch string: <empty>")) unless ($fetchstring);

    push(@other,'UID');
    return($self->parse_fetch($self->_imap_command("UID FETCH","$sequence $fetchstring")));
}

=pod

=item B<uidstore($sequence,$operation, $flaglist)>

Identical to the store() command, except set is a UID set rather than a sequence set.

=cut

#FIXME: does this need to be fixed (like store())?
sub uidstore($$$$) {
    my ($self,$sequence,$operation,$flaglist) = @_;
    return($self->throw_error("Invalid sequence string: $sequence")) unless (is_sequence_set($sequence));
    return($self->_imap_command("UID STORE","$sequence $operation $flaglist"));
}

=pod

=item B<uidexpunge($sequence)>

Identical to the expunge() command, except you can specify a set of messages to be expunged, rather than the entire mailbox, via a UID set.  This function ensures the existance of the UIDPLUS atom in the capability() command.

Note: At this time, the function does not implement the reccomendation in RFC2359, which suggestests that clients use alternate methods in selectivly expunging messages on servers that do not support UIDPLUS.

=cut

#FIXME This needs to implement the UIDEXPUNGE suggested alternate methods.
sub uidexpunge($$) { 
    my ($self,$sequence) = @_;
    return($self->throw_error("Invalid sequence string: $sequence")) unless (is_sequence_set($sequence));
    return($self->throw_error("UIDPLUS not supported for UID EXPUNGE command")) unless ($self->check_capability('UIDPLUS'));
    return($self->_imap_command("UID EXPUNGE","$sequence"));
}

=pod

=item B<uidsearch($searchstring)>

Identical to the search() command, except the results are returned with UIDs instead of sequence IDs.  See the end of this document for valid search terminology.

=cut

sub uidsearch($$) {
    my ($self,$searchstring) = @_;    
    return(parse_search($self->_imap_command("UID SEARCH","$searchstring")));
}

# experimental/expansion commands
#sub X{}

########## rfc2086 (IMAP4 ACL extention) commands ##########

=pod

=item B<setacl($mailbox,$user,@permissions)>

Modify the access control lists to set the provided permissions for the user on the mailbox, overwriting any previous access controls for the user.   See the end of this document for a complete list of possible permissions for use in the permissions list.

=cut

sub setacl ($$$@) {
    my ($self,$mailbox,$user,@permissions) = @_;
    my $aclstring = $self->buildacl(@permissions);
    return($self->_imap_command("SETACL", quote_once($mailbox)." $user $aclstring"));
};

=pod

=item B<deleteacl($mailbox,$user)>

Remove all permissions for user on the mailbox's access control list.

=cut

sub deleteacl ($$$) {
    my ($self, $mailbox, $user) = @_;
    return($self->_imap_command("DELETEACL",quote_once($mailbox)." $user"));
}

=pod

=item B<getacl($mailbox)>

Get the access control list for the supplied mailbox. Returns a two-level hash, with the first level consisting of userIDs, and the second level consisting of a hash of the permissions for the parent userID, in both short and long form.

=cut

sub getacl ($$) {
    my ($self, $mailbox) = @_;
    my @resp = $self->_imap_command("GETACL", quote_once($mailbox));
    return(()) unless ($resp[0]);

    my %permissions;
    foreach my $line (@resp) {
		if (my ($set) = ($line =~ /^\* ACL \"?$mailbox\"? (.*)\r\n$/i)) { #"
		    my %_hash = split(/ /,$set); # split out user/perms set
		    foreach my $user (keys %_hash) {
				my %_perms = map {$_ => 1} split(//,$_hash{$user});
				#fill_permissions(\%_perms);
				$permissions{$user} = \%_perms;
		    }
		}
    }
    
    return(%permissions);
}


=pod

=item B<grant($mailbox,$user,@permissions)> (not an official RFC2086 command)

Modify the access control lists to add the specified permissions for the user on the mailbox.   See the end of this document for a complete list of possible permissions for use in the permissions list.

=cut

sub grant ($$$@) {
    my ($self,$mailbox,$user,@permissions) = @_;
    my %acls = $self->getacl($mailbox,$user);

    return($self->setacl(quote_once($mailbox),$user,(@permissions, keys %{$acls{$user}})));
}

=pod

=item B<revoke($mailbox,$user,@permissions)> (not an official RFC2086 command)

Modify the access control lists to remove the specified permissions for the user on the mailbox.  If the end result is no permissions for the user, the user will be deleted from the acl list.  See the end of this document for a complete list of possible permissions for use in the permissions list.

=cut

sub revoke ($$$@) {
    my ($self,$mailbox,$user,@permissions) = @_;
    my %acls = $self->getacl(quote_once($mailbox));

    # REMOVE @permissions from %acls
    my %remove = map {$_ => 1} split(//,$self->buildacl(@permissions));
    #fill_permissions(\%remove);
    foreach my $perm (keys %remove) {
		delete $acls{$user}->{$perm};
    }

	if (scalar(keys %{$acls{$user}}) == 0) {
		return($self->deleteacl($mailbox,$user));
	}
	
    return($self->setacl($mailbox,$user,(keys %{$acls{$user}})));
}

=pod

=item B<listrights($mailbox,$user)>

Get the list of access controls that may be granted to the supplied user for the supplied mailbox. Returns a hash populated with both short and long rights definitions for testing for the existance of a permision, like $hash{'list'}.

=cut

sub listrights($$$) {
    my ($self, $mailbox, $user) = @_;
    my @resp = $self->_imap_command("LISTRIGHTS", quote_once($mailbox)." $user");
    return(()) unless ($resp[0]);    
    
    my %permissions;
    foreach my $line (@resp) {
		if (my ($permissionstring) = ($line =~ /^\* LISTRIGHTS $mailbox $user (.*)\r\n$/i)) {
		    %permissions = map{ $_ => 1 } split(/ /,$permissionstring);
		}
    }
    #fill_permissions(\%permissions);

    return(%permissions);
}

=pod

=item B<myrights($mailbox)>

Get the access control list information for the currently authorized user's access to the supplied mailbox.  Returns a hash of the permissions available, in both short and long form.

=cut

sub myrights($$) {
    my ($self, $mailbox) = @_;
    my @resp = $self->_imap_command("MYRIGHTS", quote_once($mailbox));
    return(()) unless ($resp[0]);

    my %permissions;
    foreach my $line (@resp) {
		if (my ($permissionstring) = ($line =~ /^\* MYRIGHTS \"?$mailbox\"? (.*)\r\n$/i)) { #"
		    %permissions = map {$_ => 1} split(//,$permissionstring);
		}
    }
    fill_permissions(\%permissions);

    return(%permissions);
}


########## rfc2087 (IMAP4 QUOTA extention) commands ##########

=pod

=item B<setquota($mailbox,$type,$quota)>

Set the quota on the mailbox.  Type is the type of quota to specify, for example STORAGE.  Sized-based quota is supplied in KB.

=cut

sub setquota($$$$) {
    my ($self,$mailbox,$type,$quota) = @_;
    return($self->_imap_command("SETQUOTA", quote_once($mailbox)." ($type $quota)"));
}

=pod

=item B<getquota($mailbox)>

Get the quota for the supplied mailbox.  The provided mailbox must be a quota root, and the authorized user might need to be an administrator, otherwise a "NO" reponse will be returned.  getquotaroot() is likely the more applicable command for finding the current quota information on a mailbox.  Quota is returned in a hash of lists: The hash elements correspond to the quota type (for example, STORAGE).  The list consists of all numbers that corresponded to the quote type.

For example, the RFC specifies that the STORAGE type returns the quota used in the first element, and the maximum quota in the second.  Quota units corresponding to sizes are in KB.

=cut

sub getquota($$) {
    my ($self,$mailbox) = @_;

    return($self->throw_error("QUOTA not supported for GETQUOTA command")) unless ($self->check_capability('QUOTA'));

    my @resp = $self->_imap_command("GETQUOTA", quote_once($mailbox));
    return(()) unless ($resp[0]);

    my %quota = parse_quota($mailbox,\@resp);
}

=pod

=item B<getquotaroot($mailbox)>

Fetch the list of quotaroots and the quota for the provided mailbox.  This command is idential to the getquota() command, except the query doesn't have to be at the quota root, since this command will find the quota root for the specified mailbox, then return the results based on the results of the find.  Thus, there will be an extra hash item, 'ROOT', that specified what was used as the quota root.  Quota units corresponding to sizes are in KB.

=cut

sub getquotaroot($$) {
    my ($self,$mailbox) = @_;

    return($self->throw_error("QUOTA not supported for GETQUOTAROOT command")) unless ($self->check_capability('QUOTA'));

    my @resp = $self->_imap_command("GETQUOTAROOT", quote_once($mailbox));
    return(undef) unless ($resp[0]);

    my %quota = parse_quota($mailbox,\@resp);
}



########## rfc2193 (IMAP4 Mailbox Referrals) commands ##########

=pod

=item B<rlist($reference,$mailbox)>

List all the mailboxes the authorized user can see for the given mailbox from the given reference.  This command lists both local and remote mailboxes, and can also be an indicator to the server that the client (you) supports referrals.  Not reccomended if referrals are not supported by the overlying program.

Returns a listref of hasherefs, one per element, where each hashes keys include FLAGS, REFERENCE, and MAILBOX.

IMPORTANT: Referrals come in a "NO" response, so this command will fail even if responded to with a referral.  The referral MUST be pulled out of the error(), and can then be parsed by the parse_referral() command if desired, to extract the important pieces for the clients used.

Unless overridden, rlist will check for the MAILBOX-REFERRALS capability() atom before executing the command.  If the capability is not advertised, the function will fail without sending the request to the server.

=cut

sub rlist($$$) {
	warn "DEPRECIATED: list-returning IMAP::Client::rlist(): Array return values are depreciated and will be removed in future revisions! Convert code to accept scalar list-reference\n" if (wantarray);
    my ($self,$reference,$mailbox) = @_;
    return($self->throw_error("MAILBOX-REFERRALS not supported for RLIST command")) unless ($self->check_capability('MAILBOX-REFERRALS'));
    my @result = $self->_imap_command("RLIST", quote_once($reference).' '.quote_once($mailbox));
	return(undef) unless ($result[0]);
    my @parsed_result = parse_list_lsub(@result);
	return((wantarray) ? @parsed_result : \@parsed_result);
}

=pod

=item B<rsub($reference,$mailbox)>

List all the subscriptions for the authorized user for the given mailbox from the given reference.  This command lists both local and remote subscriptions, and can also be an indicator to the server that the client (you) supports referrals.  Not reccomended if referrals are not supported by the overlying program.

Returns a listref of hasherefs, one result per element, where each hashes keys include FLAGS, REFERENCE, and MAILBOX.

IMPORTANT: Referrals come in a "NO" response, so this command will fail even if responded to with a referral.  The referral MUST be pulled out of the error(), and can then be parsed by the parse_referral() command if desired, to extract the important pieces for the clients used.

Unless overridden, rlsub will check for the MAILBOX-REFERRALS capability() atom before executing the command.  If the capability is not advertised, the function will fail without sending the request to the server.

=cut

sub rlsub($$$) {
	warn "DEPRECIATED: list-returning IMAP::Client::rlsub(): Array return values are depreciated and will be removed in future revisions! Convert code to accept scalar list-reference\n" if (wantarray);
    my ($self,$reference,$mailbox) = @_;
    return($self->throw_error("MAILBOX-REFERRALS not supported for RLSUB command")) unless ($self->check_capability('MAILBOX-REFERRALS'));
    my @result = $self->_imap_command("RLSUB", quote_once($reference).' '.quote_once($mailbox));
	return(undef) unless ($result[0]);
    my @parsed_result = parse_list_lsub(@result);
	return((wantarray) ? @parsed_result : \@parsed_result);
}


########## rfc2177 (IMAP4 IDLE) command ##########

=pod

=item B<idle(FIXME)>

Issue IDLE command, currently unimplemented.

=cut

sub idle {
    # This function is a little different, since instead of accumulating the response and returning it,
    # we acutally want to return the untagged responses in realtime without returning.  Impossilbe?  Nah...
    # FIXME: what to do, what to do....
    my ($self) = @_;
    return($self->throw_error("IDLE unimplemented"));
}

########## rfc2971 (IMAP4 ID extention) command ##########

=pod

=item B<id(%perams)>

Provide identifying information to the server, and have the server do the same to you.  The client can request the server's information without sharing its own by supplying an undef perams argument.  The information by both parties is useful for statistical or debugging purposes, but otherwise serves no other functional purpose.

The perams arguemnt is a hash, since information is in a key-value format.  Keys can be anything, but must be less than 30 characters in length, and values must be less than 1024 characters in length.  There are a set keys defined by the RFC that are reccomended:  These include:

=over 4

=item * name - Name of the program

=item * version - Version number of the program

=item * os - Name of the operating system

=item * os-version - Version of the operating system

=item * vendor - Vendor of the client/server

=item * support-url - URL to contact for support

=item * address - Postal address of contact/vendor

=item * date - Date program was released, specified as a date-time in IMAP4rev1

=item * command - Command used to start the program

=item * arguments - Arguments supplied on the command line, if any

=item * environment - Description of environment, i.e., UNIX environment List all the subscriptions for the authorized user for the given mailbox from the given reference.variables or Windows registry settings

=back

None of the keys are required - if the client wishes not to supply information for a key, the key is simply omitted.  Not all clients support this extention:  Support can be identified by using the capability() command, and verifying the atom "ID" is included in the server-supplied list.

=cut

sub id($%) {
    my ($self,%perams) = @_;
    my $peramlist;

    return($self->throw_error("ID not supported for ID command")) unless ($self->check_capability('ID'));

    if (%perams) {
		$peramlist = '(';
		foreach my $key (keys %perams) {
		    if (length($key) > 30) { # defined in RFC section 3.3
				return ($self->throw_error("Client key [$key] too long: ".length($key)." bytes, max 30 bytes"));
		    }
		    if (length($perams{$key}) > 1024) {# defined in RFC section 3.3
				return($self->throw_error("Client value [$perams{$key}] too long: ".length($perams{$key}).", max 1024 bytes"));
		    }
		    $peramlist .= quote_once($key).' '.quote_once($perams{$key}).' ';
		}
		chop $peramlist; # rid ourselves of the last space
		$peramlist .= ')'; #overwrite last space with )
    } else {
		$peramlist = 'NIL';
    }
    
    return($self->_imap_command("ID",$peramlist));
}

########## draft-ietf-imapext-annotate-15 ##########

=pod

=item B<getannotation($mailbox, $entry_specifier, $attribute_specifier)>

Retrieve annotations on a mailbox from the server.  If the mailbox argument is empty, it will retrieve global server annotations instead.

The entry specifier indicates which type of annotation you will retrieve.  the "*" wildcard is valid for retrieving all annotations, while the "%" wildcard will match all text except the hierarchy delimiter '/'.

As of draft-ietf-imapext-annotate-15, valid global entries are:

=over 4

=item * /comment

Defines a comment or note associated with the server

=item * /motd

Defines a "message of the day" for the server (Read-Only)

=item * /admin

Indicates a method for contacting the server administrator (Read-Only)

=item * /vendor/<vendor-token>

Defines the top-level of entries associated with the server as created by a particular product of some vendor.  Vendor tokens are registered with IANA, using the ACAP [RFC2244] vendor subtree registry.

=back

... and the mailbox entries are ...

=over 4 

=item * /comment

Defines a per-mailbox comment, connected with the specified mailbox

=item * /sort 

Defines the default sort criteria [I-D.ietf-imapext-sort] to use when first displaying the mailbox contents to the user, or NIL if sorting is not required.

=item * /thread

Defines the default thread criteria [I-D.ietf-imapext-sort] to use when first displaying the mailbox contents to the user, or NIL if threading is not required.  This takes precidence over the /sort annotation.

=item * /check

A true/false value that indicates whether this mailbox should be checked at regular intervals by the client.

=item * /checkperiod

if /check is true, this numberic value indicates a period of minutes that the client should check the mailbox.

=item * /vendor/<vendor-token>

Identical to the global version, except they apply only to the specified mailbox.

=back

The attribute specifier indicates which part of the annotation you wish to receive.  As of draft-ietf-imapext-annotate-15, valid global attributes are

=over 4

=item * /value

String or binary data representing the value of the annotation.  NIL can be stored to delete an annotation.  Text value sshould use the utf-8 character set.  Binary data uses the "literal8" syntax element [I-D.melnikov-imap-ext-abnf] to store and retreive such data.

=item * /size

the size, in octets, of the value. (Read-only)

=item * /content-language

Language used for the value.  This SHOULD be set if the value stored is textual.

=back

In addition, all attributes have a '.priv' and a '.shared' suffix, meaning private and shared, respecitvly.  If neither attribute suffix is specified, both will be retrieved (if allowed).

Returns a nested hash reference with the mailbox name as the first layer, the entry as the second layer, the attribute name in the third layer.

Structure example:

=over 2

$r{<mailbox>}->{<tag>}->{<attribute>} = value

=back

=cut

sub parse_annotation ($$$) {
	my ($resp,$mailbox,$self) = @_; # self last so its not seen by the user as a 'call'

	# Parse the results
	my %results = ($mailbox => undef);
	foreach my $line (@{$resp}) {
		$line =~ s/[\r\n]//gs; # Remove newlines
		my ($more) = $line =~ /\s*\*\s+ANNOTATION\s+\"?$mailbox\"?\s+(.*)$/; #"
		while ($more) {
			$self->dprint(0x04, "getannotation processing with [$more]\n");
			my ($entry, $attrset, $less) = $more =~ /\"?([^\"\s]+)\"?\s+($parens)(.*)/; #"
			$self->dprint(0x04, "getannotation found entry [$entry], attrset [$attrset], and less [$less]\n");
			my $attrs_href = parse_parameters($attrset);

			$results{$mailbox}->{$entry} = $attrs_href;
			$more = $less;
		}
	}
	return(%results);
}
sub getannotation($$$$) {
	my ($self, $mailbox, $entry, $attribute) = @_;
	unless ($self->check_capability('ANNOTATEMORE') || $self->check_capability('ANNOTATEMORE2')) {
		$self->throw_error("ANNOTATEMORE or ANNOTATEMORE2 not supported for GETANNOTATE command");
	}
	
	# Execute
	my @resp = $self->_imap_command("GETANNOTATION", quote_once($mailbox).' '.quote_once($entry).' '.quote_once($attribute));
	return(()) unless ($resp[0]);
	
	my %parse_annotation = parse_annotation(\@resp,$mailbox,$self);
	
	return (%parse_annotation)
}

=pod

=item B<setannotation($mailbox, $mailbox, \%annoation_hash)>

Set annotations on a mailbox from the server.  If the mailbox argument is empty, it will attempt to set global server annotations instead.

For details on annotations and its arguments, see the getannotation() command.

The setannotation() command only accepts annotations for one mailbox at a time - as a result, the setannotation() command accepts a mailbox argument and an attribute tree, rather than the entire annotation hash that getannotation returns.  

As a result, setannotation takes the same type of hash that getannotation returns, except starting at the mailbox level.  For example, the hash must be in the form of

=over 2

$r{<tag>}->{<attribute>} = value

=back

The the first level is for which tags to set, and the second level is what attributes those tags will have, while the value is the actual value to assign.

One key difference between the getannotation() and setannotation() hashes is that the setannotation() mailbox can contain a wildcard - for example, setting 'INBOX.%' as the mailbox will add an annotation for all mailboxes at the top-level of the INBOX hierarchy.

=cut

sub setannotation($$$) {
	my ($self, $mailbox, $tagset) = @_;
		unless ($self->check_capability('ANNOTATEMORE') || $self->check_capability('ANNOTATEMORE2')) {
		$self->throw_error("ANNOTATEMORE or ANNOTATEMORE2 not supported for GETANNOTATE command");
	}
	
	my $tagset_str;
	
	foreach my $tag (keys %{$tagset}) {
		$tagset_str .= quote_once($tag) . ' (';
		foreach my $attribute (keys %{$tagset->{$tag}}) {
			$tagset_str .= quote_once($attribute).' '.quote_once($tagset->{$tag}->{$attribute}).' ';
		}
		chop($tagset_str);
		$tagset_str .= ') ';
	}
	chop($tagset_str);
	
	
	return($self->_imap_command("SETANNOTATION", quote_once($mailbox).' '.$tagset_str));
}

=pod

=back

=head1 METHODS - SUPPORT

    These are the support methods created to support the coder in creating some of the more complex and open-ended arguments for the above command methods.

=over 4

=cut

########## SUPPORT FUNCTIONS ############

=pod

=item B<buildacl(@acls)>

This function is provided for the ease of creating an appropriate aclstring.  The set of arguments is the set of permissions to include in the aclstring.  The following are the supported rights:

=over 4

=item * lookup, list, l - mailbox is visible to list()/lsub()/rlist()/rlsub() commands

=item * read, r - select() the mailbox, perform check(), fetch(), PARTIAL?, search(), copy() from mailbox

=item * seen, s - keep seen/unseen information across sessions (store() SEEN flag)

=item * write, w - store() flags other than SEEN and DELETE

=item * insert, i - perform append(), copy() into mailbox

=item * post, p - send mail to submission address for mailbox

=item * create, c - create() new sub-mailboxes

=item * delete, d - store() DELETED flag, perform expunge()s

=item * administer, admin, a - perform setacl() commands 

=item * all - all the above rights.  Overrides all other commands

=item * none - none of the above rights.  This is the same as providing no arguments.  Is overriden by any other supplied commands

=item * 0-9 - implementation or site defined rights (nonstandard)

=back

=cut

sub buildacl ($@) {
    my $aclstr='';
    my ($self, @acls) = @_;
    my %acllist;
    foreach my $aclset (@acls) {
		$aclset = lc($aclset);
		foreach my $acl (split(/ /,$aclset)) {
		    if ($acl eq 'all') { # start with valid words
				push(@acls, qw(l r s w i p c d a 0 1 2 3 4 5 6 7 8 9));
		    } elsif ($acl eq 'none') { 
				# we silently accept 'none', which is the same as no options
		    } elsif ($acl =~ /^[lrswipcda0123456789]{2,}$/){ # if it looks like a valid permissions string (2 or more),split and use
				push(@acls,split(//,$acl));     
		    } elsif (($acl eq 'l') || ($acl eq 'lookup') || ($acl eq 'list')) { # move on to individual permissions
				$acllist{'l'} = 1;
		    } elsif (($acl eq 'r') || ($acl eq 'read')) {
				$acllist{'r'} = 1;
		    } elsif (($acl eq 's') || ($acl eq 'seen')) {
				$acllist{'s'} = 1;
		    } elsif (($acl eq 'w') || ($acl eq 'write')) {
				$acllist{'w'} = 1;
		    } elsif (($acl eq 'i') || ($acl eq 'insert')) {
				$acllist{'i'} = 1;
		    } elsif (($acl eq 'p') || ($acl eq 'post')) {
				$acllist{'p'} = 1;
		    } elsif (($acl eq 'c') || ($acl eq 'create')) {
				$acllist{'c'} = 1;
		    } elsif (($acl eq 'd') || ($acl eq 'delete')) {
				$acllist{'d'} = 1;
		    } elsif (($acl eq 'a') || ($acl eq 'admin') || ($acl eq 'administer')) {
				$acllist{'a'} = 1;
	    	} elsif ($acl =~ /^\d$/) {
				$acllist{"$acl"} = 1;
		    } else {
				return($self->throw_error("Invalid setacl option [$acl]"));
		    }
		}
    }
    
    # compile into final string and return
    foreach my $key (keys %acllist) {
		$aclstr .= $key;
    }
    return($aclstr);
}

=pod

=item B<buildfetch([\%body,\%body,...],$other)>

Builds a fetch query to get only the data you want.  The first argument, the body hash ref, is designed to easily create the body section of the query, and takes the following arguments:

=over 4

=item * body

Specify in a section of the body to fetch().  undef is allowed, meaning no arguments to the BODY option, which will request the full message (unless a header is specified - see below).

=item * offset

Specify where in the body to start retrieving data, in octets.  Default is from the beginning (0).  If the offset is beyond the end of the data, an empty string will be returned.  Must be specified with the length option.

=item * length

Specify how much data to retrieve starting from the offset, in octets.  If the acutal data is less than the length specified, the acutal data will be returned.  There is no default value, and thus must be specified if offset is used.

=item * header 

Takes either 'ALL', 'MATCH', or 'NOT'.  'ALL' will return all the headers, regardless of the contents of headerfields.  'MATCH' will only return those headers that match one of the terms in headerfields, while 'NOT' will return only those headers that *do not* match any of the terms in the headerfields.

=item * headerfields 

Used when header is 'MATCH' or 'NOT', it specifies the headers to use for comparison.  This argument is a string of space-seperated terms.

=item * peek

When set to 1, uses the BODY.PEEK command instead of BODY, which preserves the \Seen state of the message

=back

A single hash reference may be supplied for a single body command.  If multiple body commands are required, they must be passed inside an array reference (i.e. [\%hash, \%hash]).

If an empty hashref is supplied as a \%body argument, it is interpreted as a BODY[] request.

The final argument, other, is a string of space-seperated stand-alone data items.  Valid items via RFC3501 include:

=over 4

=item * BODY

The non-extensible form of BODYSTRUCTURE (not to be confused with the first argument - this command fetches structure, not content)

=item * BODYSTRUCTURE

The MIME-IMB body structure of the message.

=item * ENVELOPE

The RFC-2822 envelope structure of the message.

=item * FLAGS

The flags set for the message

=item * INTERNALDATE

The internal date of the message

=item * RFC822, RFC822.HEADER, RFC822.SIZE, RFC822.TEXT

RFC822, RFC822.HEADER, and RFC822.TEXT are equivilant to the similarly-named BODY options from the first argument, except for the format they return the results in (in this case, RFC-822).  There is no '.PEEK' available, so the \Seen state may be altered.  SIZE returns the RFC-822 size of the message and does not change the \Seen state.

=item * UID

The unique identifier for the message.

=item * ALL

equivalent to FLAGS, INTERNALDATE, RFC822.SIZE, ENVELOPE

=item * FAST

equivalent to FLAGS, INTERNALDATE RFC822.SIZE

=item * FULL

equivalent to FLAGS, INTERNALDATE, RFC822.SIZE, ENVELOPE, BODY

=back

The final argument, other, provides some basic option-sanity checking and assures that the options supplied are in the proper format.  For example, if a program has a list of options to use, a simple buildfetch(undef,join(' ',@args)) would manipulate the terms into a format suitable for a fetch() command.  It is highly recommended to pass options through this function rather than appending a pre-formatted string to the functions output to ensure proper formatting.

=cut

sub buildfetch($$$) {
    my ($self,$bodies,$other) = @_;

    my $fetchstr = '(';

    if (ref($bodies) eq "HASH") { # convert a single hash ref arg to an array ref of 1
		$bodies = [$bodies];
    }

    foreach my $body (@{$bodies}) {

		if ((exists $body->{'offset'}) && !(exists $body->{'length'})) {
		    return($self->throw_error("Length must be specified with offset"));
		}
	
		my $bodystr='';
		if ($body->{'header'}) {
		    if (uc($body->{'header'}) eq 'ALL') {
				$bodystr .= 'HEADER ';
		    } elsif (uc($body->{'header'}) eq 'MATCH') {
				return($self->throw_error("headerfields not defined for MATCH in buildfetch")) unless ($body->{headerfields});
				$bodystr .= 'HEADER.FIELDS ('.$body->{headerfields}.') ';
		    } elsif (uc($body->{'header'}) eq 'NOT') {
				return($self->throw_error("headerfields not defined for NOT in buildfetch")) unless ($body->{headerfields});
				$bodystr .= 'HEADER.FIELDS.NOT ('.$body->{headerfields}.') ';
		    }
		}
	
		$bodystr .= "$body->{body} " if ($body->{'body'});
		chop($bodystr) if $bodystr;
	
		$fetchstr .= "BODY" . (($body->{'peek'}) ? ".PEEK" : '') . "[$bodystr] ";
		
		if ($body->{'offset'} || $body->{'length'}) {
		    chop($fetchstr);
		    $fetchstr .= "<". ($body->{'offset'} || '0') . "." . $body->{'length'} . "> ";
		}
    }

    if ($other) {
		$other =~ s/^\(?(.*?)\)?$/$1/; # remove any surrounding parenthasies
		foreach my $item (split(/ /,$other)) {
		    $item = uc($item);
		    if ($item =~ /^(BODY|BODYSTRUCTURE|ENVELOPE|FLAGS|INTERNALDATE|UID|RFC822|RFC822\.HEADER|RFC822\.SIZE|RFC822\.TEXT|ALL|FAST|FULL)$/) {
				$fetchstr .= "$item ";
		    } else {
				return($self->throw_error("Invalid buildfetch command: $item"));
		    }
		}
    }

    chop($fetchstr);
    $fetchstr .= ')';
    return($fetchstr);
}


=pod

=item B<buildflaglist(@flags)>

This function is provided for the ease of creating an appropriate status flags string.  Simply provide it with a list of flags, and it will create a legal flags string for use in any append() command, store() command, or any other command that may require status flags.  

Since the RFCs don't explicity define valid flags, implementation dependant and custom flags may exist on any given service - therefore this function will blindly interpret any status flag you give it.  The server may reject the subsequent command due to an invalid flag.

=cut

sub buildflaglist($@) {
    my ($self,@flags) = @_;
    my $flagstring;
    my %flaghash;
    if (@flags) {
		$flagstring = '(';

		# first normalize to one occurance of each argument
		foreach my $flag (@flags) {
		    $flaghash{ucfirst(lc($flag))} = 1;
		}

		# add prefix '\' if nessesary
		foreach my $flag (keys(%flaghash)) {
		    $flag =~ s/^(\w)/\\$1/;
		    $flagstring .= "$flag ";
		}
		chop($flagstring);
		$flagstring .= ')';
    }

    return($flagstring);
}

=pod

=item B<check_capability($tag)>

This function returns a simple true/false answer to whether the supplied tag is found in the capability() list, indicating support for a certain feature.  Note: capability() results are cached by the object, however if capability() has not been executed at least once, this will cause it to do so.

=cut

sub check_capability($$) {
    my ($self,$tag) = @_;
    return (1) unless ($self->{capability_checking}); # dont restrict if we're not checking capabilities
    $self->capability() unless ($self->{capability}); # get new capability string if we have yet to run it
    return(($self->{capabilities}->{$tag}) ? 1 : 0);
}

=pod

=item B<parse_referral($referral_line)>

Given a referral line (the pre-cursory tag and 'NO' response are optional), this function will return a hash of the important information needed to connect to the referred server.  Hash keys for connecting to a referred server include SCHEME, USER, AUTH, HOST, PORT.  Other keys for use after successfull connection to the referred server include PATH, QUERY, UID, UIDVALIDITY, TYPE, SECTION.  Others are possible if returned within the path as '/;key=value' format.

=cut

sub parse_referral() { #FIXME: needs wider testing
    my ($self) = @_;
    my %hash;
    
    my ($url) = ($self->error =~ /^NO \[REFERRAL (.*?)\][^\[]$/);
    return($self->throw_error("Invalid referral: ".$self->error)) unless $url;

    my $uri = URI->new ($url);    
    return($self->throw_error("Wrong scheme: ".$uri->scheme)) unless ($uri->scheme eq "imap");
    
    %hash = ('SCHEME' => $uri->scheme,
	     'HOST' => $uri->host($uri->host),
	     'PORT' => $uri->port,
	     'QUERY' => uri_unescape($uri->query),
	     );
    ($hash{'USER'},$hash{'AUTH'}) = 
	split(/;AUTH=/,uri_unescape($uri->userinfo)); 
    my $fullpath = '';
    foreach my $dir (split('/',uri_unescape($uri->path))) {
		if (my ($option) = ($dir =~ /^\;(.*)$/)) {
		    my ($key,$value) = split(/=/,$1);
		    $hash{uc($key)} = $value;
		} else {
		    $fullpath .= $dir;
		}
    }
    $hash{'PATH'} = $fullpath;

    return(%hash);
}

=pod

=back

=head1 SEARCH KEYS

=over 4

=item * <sequence set> - Messages with message sequence numbers corresponding to the specified message sequence number set.

=item * ALL - All messages in the mailbox; the default initial key for ANDing.

=item * ANSWERED - Messages with the \Answered flag set.

=item * BCC <string> - Messages that contain the specified string in the envelope structure's BCC field.

=item * BEFORE <date> - Messages whose internal date (disregarding time and timezone) is earlier than the specified date.

=item * BODY <string> - Messages that contain the specified string in the body of the message.

=item * CC <string> - Messages that contain the specified string in the envelope structure's CC field.

=item * DELETED - Messages with the \Deleted flag set.

=item * DRAFT - Messages with the \Draft flag set.

=item * FLAGGED - Messages with the \Flagged flag set.

=item * FROM <string> - Messages that contain the specified string in the envelope structure's FROM field.

=item * HEADER <field-name> <string> - Messages that have a header with the specified field-name (as defined in [RFC-2822]) and that contains the specified string in the text of the header (what comes after the colon).  If the string to search is zero-length, this matches all messages that have a header line with the specified field-name regardless of the contents.

=item * KEYWORD <flag> - Messages with the specified keyword flag set.

=item * LARGER <n> - Messages with an [RFC-2822] size larger than the specified number of octets.

=item * NEW - Messages that have the \Recent flag set but not the \Seen flag.  This is functionally equivalent to "(RECENT UNSEEN)".

=item * NOT <search-key> - Messages that do not match the specified search key.

=item * OLD - Messages that do not have the \Recent flag set.  This is functionally equivalent to "NOT RECENT" (as opposed to "NOT NEW").

=item * ON <date> - Messages whose internal date (disregarding time and timezone) is within the specified date.

=item * OR <search-key1> <search-key2> - Messages that match either search key.

=item * RECENT - Messages that have the \Recent flag set.

=item * SEEN - Messages that have the \Seen flag set.

=item * SENTBEFORE <date> - Messages whose [RFC-2822] Date: header (disregarding time and timezone) is earlier than the specified date.

=item * SENTON <date> - Messages whose [RFC-2822] Date: header (disregarding time and timezone) is within the specified date.

=item * SENTSINCE <date> - Messages whose [RFC-2822] Date: header (disregarding time and timezone) is within or later than the specified date.

=item * SINCE <date> - Messages whose internal date (disregarding time and timezone) is within or later than the specified date.

=item * SMALLER <n> - Messages with an [RFC-2822] size smaller than the specified number of octets.

=item * SUBJECT <string> - Messages that contain the specified string in the envelope structure's SUBJECT field.

=item * TEXT <string> - Messages that contain the specified string in the header or body of the message.

=item * TO <string> - Messages that contain the specified string in the envelope structure's TO field.

=item * UID <sequence set> - Messages with unique identifiers corresponding to the specified unique identifier set.  Sequence set ranges are permitted.

=item * UNANSWERED - Messages that do not have the \Answered flag set.

=item * UNDELETED - Messages that do not have the \Deleted flag set.

=item * UNDRAFT - Messages that do not have the \Draft flag set.

=item * UNFLAGGED - Messages that do not have the \Flagged flag set.

=item * UNKEYWORD <flag> - Messages that do not have the specified keyword flag set.

=item * UNSEEN - Messages that do not have the \Seen flag set.

=back

=head1 FETCH RESPONSE TUTORIAL

The response to the fetch command is a tree of hash references pointing to other hash references in a tree-like structure.  Going into this module and using fetch without an understanding about how the results come back is at least frustrationg and at worst futile.  This section is meant to clear some of the potential confusion up, and for you to understand exactly where the data you want is stored.

The fetch response is stored in a tree structure of hash references.  This means that it will not be uncommon for you to have ugly-looking statements like such strewn throughout your code:

=over 2

$fetch{$msgid}->{BODY}->{2}->{HEADER}->{BODY}

=back

By the end of this tutorial, you will hopefully understand exactly what that top statement means.

To understand where this structure comes from, you need to understand the structure that RFC3506 defines parts of a message.  An example from the RFC looks like this:

=over 4

       HEADER     ([RFC-2822] header of the message)
       TEXT       ([RFC-2822] text body of the message) MULTIPART/MIXED
       1          TEXT/PLAIN
       2          APPLICATION/OCTET-STREAM
       3          MESSAGE/RFC822
       3.HEADER   ([RFC-2822] header of the message)
       3.TEXT     ([RFC-2822] text body of the message) MULTIPART/MIXED
       3.1        TEXT/PLAIN
       3.2        APPLICATION/OCTET-STREAM
       4          MULTIPART/MIXED
       4.1        IMAGE/GIF
       4.1.MIME   ([MIME-IMB] header for the IMAGE/GIF)
       4.2        MESSAGE/RFC822
       4.2.HEADER ([RFC-2822] header of the message)
       4.2.TEXT   ([RFC-2822] text body of the message) MULTIPART/MIXED
       4.2.1      TEXT/PLAIN
       4.2.2      MULTIPART/ALTERNATIVE
       4.2.2.1    TEXT/PLAIN
       4.2.2.2    TEXT/RICHTEXT

=back

This example is rather complicated, but it gets the point across that this is no small feat.  From the top, you can see that the HEADER and the TEXT are seperate pieces for the main message that was delivered, and thus can be retrieved as such.  1, 2, and 3 specify different sections of the email message - part 1 is a plain text email (the acutal text that was written to you), while part 2 is an OCTET-STREAM, perhaps a binary attachment to the email.  The 3rd message is defined as an RFC822 - a bounce message.  The bounce message (3), naturally has its own HEADER, and TEXT parts, along with an email with an attachment (the RFC822 bounce message included the original email, and all its attachments!).  This goes on, and as you can see with part 4, the nesting can be quite deep, depending on if the email is multi-part (i.e. both plain-text and HTML), and/or if attachments have attachments, etc.

Now, lets look at a concrete example.  Lets say that we received a plain-text email with a forwarded email as an attachment.  This would mean that the message contains 2 parts, and, for the sake of argument, we know this ahead of time.  The command to retrieve the header of the forwarded message would be 

=over 4

my %fetch = $imap->fetch($sequence, {'body' => '2.header'});

=back

For this example, however, we're going to retrieve the entire message, but still seek out the forwarded message's header

=over 4

my %fetch = $imap->fetch($sequence, {});

=back 

where $imap is a connected IMAP::Client instance, and $sequence has the message ID we are looking for.

Now, we need to retrieve the data that the IMAP server do dutifully sent to us, and this is where we get grease on our hands and learn exactly how to traverse a fetch response.

The first level of a fetch response is always the message ID of the message, and is the only level that is *not* a reference.  This allows the fetch command to retrieve multiple message within a single command (i.e. using the sequence of '1:*' will retrieve all messages in the mailbox), and still present the data in a managable fasion.

Lets say that $sequence was the message '1234'.  In order to reach the base of the message we are looking to retrieve the data from, we now need to access $fetch{1234}.  Everything below here is information about our message.

Next, we will need to navigate to the area of the tree that will contain the data.  The data we are looking for will *always* be in the same place, no matter if we retrieved the entire message, half the message, or just that one single peice of data, like the first example - if it was retreived, it will be in its specified place.  This the key design feature of the fetch return structure.  

At this level ($fetch{1234}), we can access anything about the main message.  We are looking at the message from the outside, what you would normally see in your email client when you first opened a message.  We can look at things like the date of the message, the flags set on this message by the imap server, the UID of the message, the envelope of the message, etc.

In this case, we're not interested in the main message, however.  We want to retrieve the header of the forwarded message, so we need to go into the BODY of the message.  To get there, we're now at $fetch{1234}->{BODY}.  IMAP::Client uses the {BODY} reference to seperate it from the other aspects of the main message, incidcating its a result from a BODY fetch query.   The BODY section also contains various peices of information, depending on what the CONTENTTYPE of the message is - for things like MULTIPART/ALTERNATIVE (which means the message comes in multiple forms, like plain text and HTML), there simply isn't much information to relay, since that content type is basically just a container for the two message formats.  If the section is part of the actual message (rather than just a container) - for example a PLAIN/TEXT part, things like SIZE for the size of the message, LINES for number of lines in the message, and even the ENCODING and extra PARAMETERS are available.  

Now that we're in the body, we can look at things like the content type of this particular piece of the email.  Again, we're not interested in whats here.  What we want is the second part of this body, the attachment part.  The main body of the email that was sent is located in $fetch{1234}->{BODY}->{1}, and the attachment is located at $fetch{1234}->{BODY}->{2}.  (See how the fetch structure reflects the IMAP structure of the message).  Had there been more attachments or parts, there would have been more parts we could traverse, like $fetch{1234}->{BODY}->{3}.

Now at $fetch{1234}->{BODY}->{2}, we're in the section of the message we are interested in.  Here we can find out information about the part we're in.  This part is essentially identical to the first {BODY} part, only representing a subset of the mesage that {BODY} represented.

Now that we're here, we want the header for this part, which gives us $fetch{1234}->{BODY}->{2}->{HEADER}.  We're not done yet, however, as there is still information about the HEADER available, like the SIZE.  If we want the acutal HEADER body of the header, rather than a piece of information about it, we need to go one level deeper, to $fetch{1234}->{BODY}->{2}->{HEADER}->{BODY}.  This is the value that will allow you to retreive the header of the forward that was sent in an attachment.  



In the last example, we assumed that we already knew the struture of the email.  In real life, this is almost never the case.  If you need to know what the structure of a message looks like so you can extract a small piece of it, you can use the BODYSTRCUTRE command, which is structured simiilarly to the BODY command.  If we use the example above, then we can traverse the BODYSTRUCTURE information by going to $fetch{1234}->{BODYSTRUCTURE}.  From here, you can explore and poke around to see exactly what the structure is that the message has.  The acutal data within a BODYSTRUCTURE is basically all the flags you would see when youre in a part - like the content  type, size, lines, etc - but without any of the acutal message.  As its name implies, its mainly for determining the structure and *type* of the message and its subparts.  Part numbers are always sequential.

=head1 AUTHOR/COPYRIGHT

    Copyright 2005-2006, Brenden Conte <conteb at cpan dot org>  All rights reserved.

    This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl, IO::Socket, IO::Socket::SSL, MIME::Base64, URI, URI::imap, URI::Escape

=cut


1;
__END__
