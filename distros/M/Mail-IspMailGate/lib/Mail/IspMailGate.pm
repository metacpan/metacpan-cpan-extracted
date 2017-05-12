# -*- perl -*-

require 5.005;
use strict;

use IO::File ();
use IO::Tee ();
use Mail::IspMailGate::Parser ();
use Net::SMTP ();
use Sys::Syslog ();
use File::Path ();


package Mail::IspMailGate;

$Mail::IspMailGate::VERSION = '1.102';


package Mail::IspMailGate::SMTP;

# Simple wrapper for Net::SMTP to make it usable for
# MIME::Entity->print()
#
# This relies on the assumption that the MIME-tools use only
# print() for output purposes!
#
@Mail::IspMailGate::SMTP::ISA = qw(Net::SMTP);

sub print {
    my($self) = shift;
    foreach (@_) {
	if (!$self->datasend($_)) {
	    return undef;
	}
    }
    return 1;
}


package Mail::IspMailGate;


############################################################################
#
#   Name:    Debug (Instance method)
#            Error (Instance method)
#            Fatal (Instance method)
#
#   Purpose: Create logfile entries with different severity levels.
#            The Debug method supresses output, unless the 'debug'
#            attribute is set. The Fatal method terminates the
#            current thread after logging the message.
#
#   Inputs:  $self - This instance
#            $fmt - printf-like format string
#            @args - arguments
#
#   Result:  Nothing
#
############################################################################

sub Debug ($$;@) {
    my($self, $fmt, @args) = @_;
    return unless $self->{'debug'};
    &Sys::Syslog::syslog('debug', $fmt, @args);
    printf STDERR ("$fmt\n", @args) if ($self->{'stderr'});
}

sub Error ($$;@) {
    my($self, $fmt, @args) = @_;
    &Sys::Syslog::syslog('err',  $fmt, @args);
    printf STDERR ("$fmt\n", @args);
}

sub Fatal ($$;@) {
    my($self, $fmt, @args) = @_;
    Error($self, $fmt, @args);
    exit 1;
}


############################################################################
#
#   Name:    GetUniqueId (Instance method)
#
#   Purpose: Returns a unique ID for this mail
#
#   Inputs:  $self - This instance
#
#   Returns: ID (decimal)
#
############################################################################

sub TmpDir {
    my $self = shift;
    return $self->{'tmpDir'} if exists $self->{'tmpDir'};
    $self->{'tmpDir'} = $Mail::IspMailGate::Config::config->{'tmp_dir'};
}

sub GetUniqueId ($) {
    # XXX: use attrs 'locked';
    my $self = shift;

    my $idFile = $self->TmpDir() . "/.id";

    # Generate a unique ID for this mail
    my $fh = Symbol::gensym();
    sysopen($fh, $idFile, Fcntl::O_RDWR()|Fcntl::O_CREAT())
	or  $self->Fatal("Cannot open lock file $idFile: $!");
    flock($fh, 2)  or  $self->Fatal("Cannot lock file $idFile: $!");
    my $id = <$fh>;
    if (!defined($id)) { $id = 0 }
    if (++$id < 0) {  $id = 1 }
    seek($fh, 0, 0)
	or $self->Fatal("Error while seeking to top of lock file $idFile: $!");
    truncate($fh, 0)
	or $self->Fatal("Error while truncating lock file $idFile: $!");
    printf $fh ("%d\n", $id)
	or  $self->Fatal("Error while writing lock file $idFile: $!");
    close($fh)  or  $self->Fatal("Error while closing lock file $idFile: $!");
    $id;
}


############################################################################
#
#   Name:    SendMimeMail (Instance method)
#
#   Purpose: Send a MIME entity
#
#   Inputs:  $self - This instance
#            $entity - MIME entity to send
#            $sender - Mail sender
#            $recipients - List of recipients
#            $host - Delivery host
#
#   Returns: Nothing
#
############################################################################

sub SendMimeMail ($$$$$) {
    my($self, $entity, $sender, $recipients, $host) = @_;
    my $cfg = $Mail::IspMailGate::Config::config;

    if ($self->{'noMails'}) {
	if (ref($self->{'noMails'}) eq 'SCALAR') {
	    ${$self->{'noMails'}} .= $entity->stringify();
        } else {
	    $entity->print(\*STDOUT);
	}
	return;
    }

    my $mailHost = $cfg->{'mail_host'};
    my $addIspMailGate = 1;
    if ($host) {
	$addIspMailGate = 0;
	$mailHost = $host;
    }

    my($smtp) = Mail::IspMailGate::SMTP->new($mailHost);
    if (!$smtp) {
	$self->Fatal("Failed to connect to mail server $mailHost: $!");
    }
    #$smtp->debug(1);
    my $msender = $sender;
    if ($msender !~ /\@/  &&  $cfg->{'unqualified_domain'}) {
	$msender .= $cfg->{'unqualified_domain'};
    }
    if (!$smtp->mail($sender)) {
	$self->Fatal("Failed to pass sender to mail server $mailHost: $!");
    }
    my($r);
    foreach $r (@$recipients) {
	if (!$smtp->to($addIspMailGate ? "$r.ispmailgate" : $r)) {
	    $self->Fatal("Failed to pass recipient $r to mail server"
			 . " $mailHost: $!");
	}
    }
    if (!$smtp->data()) {
	$self->Fatal("Failed to request data mode from mail server"
		     . " $mailHost: $!");
    }
    if (!$entity->print($smtp)) {
	$self->Fatal("Failed to write mail to mail server $mailHost");
    }
    if (!$smtp->dataend()) {
	$self->Fatal("Failed to terminate data connection: $!");
    }
}


############################################################################
#
#   Name:    SendBackupFile (Instance method)
#
#   Purpose: If something went wrong while parsing the mail, we do the
#            following: Move the mail to a folder where it will be
#            saved, send it to the recipients and tell the postmaster
#            about the problem.
#
#   Inputs:  $self - This instance
#            $id - Mail id
#            $ifh - Backup file's file handle
#            $fileName - Backup file's file name
#            $sender - Sender's email address
#            $recipients - Recipient list
#
#   Returns: Nothing, exits
#
############################################################################

sub SendBackupFile ($$$$$$) {
    my($self, $id, $ifh, $fileName, $sender, $recipients) = @_;

    my $cfg = $Mail::IspMailGate::Config::config;
    my $mailHost = $cfg->{'mail_host'};

    if (!$ifh->seek(0, 0)) {
	$self->Fatal("Failed to rewind backup file $fileName: $!");
    }

    if ($self->{'noMails'}) {
	my($line);
	while (defined($line = $ifh->getline())) {
	    if (ref($self->{'noMails'}) eq 'SCALAR') {
		${$self->{'noMails'}} .= $line;
	    } else {
	        print $line;
	    }
	}
	exit 0;
    }

    my($smtp) = Net::SMTP->new($mailHost);
    if (!$smtp) {
	$self->Fatal("Failed to connect to mail server $mailHost: $!");
    }
    if (!$smtp->mail($sender)) {
	$self->Fatal("Failed to pass sender to mail server $mailHost: $!");
    }
    my($r);
    foreach $r (@$recipients) {
	if (!$smtp->to($r . ".ispmailgate")) {
	    $self->Fatal("Failed to pass recipient $r to mail server"
			 . " $mailHost: $!");
	}
    }
    if (!$smtp->data()) {
	$self->Fatal("Failed to request data mode from mail server"
		     . " $mailHost: $!");
    }
    my($line);
    while (defined($line = $ifh->getline())) {
	if (!$smtp->datasend($line)) {
	    $self->Fatal("Failed to send data to mail server $mailHost: $!");
	}
    }
    if (!$smtp->dataend()  ||  !$smtp->quit()) {
	$self->Fatal("Failed to end data on $mailHost: $!");
    }
    if ($ifh->error()  ||  !$ifh->close()) {
	$self->Fatal("Failed to read from backup file $fileName: $!");
    }

    my($keepDir) = $self->TmpDir() . "/keep";
    my($keepFile) = $keepDir . "/mail$id";
    if (! -d $keepDir  &&  ! mkdir $keepDir, 0770) {
	$self->Fatal("Failed to create directory $keepDir: $!");
    }
    if (!rename $fileName, $keepFile) {
	$self->Fatal("Failed to rename backup file $fileName as",
		     " $keepFile: $!");
    }

    $smtp->mail($sender)  &&
    $smtp->to($cfg->{'postmaster'})  &&
    $smtp->data()  &&
    $smtp->datasend("Failed to parse mail, kept in $keepFile\n")  &&
    $smtp->dataend()  &&
    $smtp->quit();
    exit 0;
}


############################################################################
#
#   Name:    MakeFilterList (Instance method)
#
#   Purpose: Given a recipient, find the list of filters to apply for
#            him.
#
#   Inputs:  $self - This instance
#            $sender
#            $recipient
#
#   Returns: List of filter instances
#
############################################################################

#
#   Sender and Recipient may be "Joe User <joe.user@my.domain>" or
#   "joe.user@my.domain (Joe User)"
#
sub _CanonicAddress($) {
    my($address) = @_;
    $address =~ s/^\s+//;
    $address =~ s/\s+$//;
    if ($address =~ /\<(.*)\>/) {
	$address = $1;
    } elsif ($address =~ /(.*?)\s*\(.*\)/) {
	$address = $1;
    }
    $address;
}

sub MakeFilterList ($$) {
    my($self, $sender, $recipient) = @_;
    my $cfg = $Mail::IspMailGate::Config::config;

    $sender = _CanonicAddress($sender);
    $recipient = _CanonicAddress($recipient);

    my $filters;

    my($r);
    foreach $r (@{$cfg->{'recipients'}}) {
	my($rec) = $r->{'recipient'};
	my($sen) = $r->{'sender'};
	if ((!$rec  ||  $recipient =~ /$rec/)  &&
	    (!$sen  ||  $sender =~ /$sen/)) {
	    $filters = $r->{'filters'};
	    last;
	}
    }
    $filters ||= $cfg->{'default_filter'};

    map {
	if (!ref($_)) {
	    my $proto = $_;
	    my $c = "$_.pm";
	    $c =~ s/\:\:/\//g;
	    require $c;
	    $proto->new({});
	} else {
	    $_
	}
    } @$filters;
}


############################################################################
#
#   Name:    Main (Instance method)
#
#   Purpose: Process a single mail.
#
#   Inputs:  $self - This instance
#            $sender - Mail sender
#            $recipients - Array ref to list of recipients
#            $host - The delivery host
#
#   Returns: Nothing; exits in case of error
#
############################################################################

sub Main($$$$) {
    my($self, $infh, $sender, $recipients, $host) = @_;
    my $id = $self->GetUniqueId();
    my $td = $self->TmpDir();
    my $tmpDir = $self->{'tmpDir'} = "$td/$id";
    my($backupFile) = $self->{'backupFile'}  = "$td/mail$id";
    my $cfg = $Mail::IspMailGate::Config::config;

    if (! -d $tmpDir  &&  !mkdir $tmpDir, 0770) {
	$self->Fatal("Error while creating directory $tmpDir");
    }
    $self->Debug("Using tmpdir $tmpDir");

    # Create a new parser and let it read a mail from STDIN.
    my($ofh) = IO::File->new($backupFile, "w+");
    if (!$ofh) {
	$self->Fatal("Error while creating backup file $backupFile: $!");
    }

    my($ifh) = IO::Tee->new($infh, $ofh);
    if (!$ifh) {
	$self->Fatal("Error while creating input file handle: $!");
    }
    $self->Debug("Using backup file $backupFile");

    if (!$sender) {
	if (defined(my $line = $ifh->getline())) {
	    if ($line =~ /^\s*from\s+(\S+)\s+/i) {
		$sender = $1;
	    } else {
		$self->Fatal("Cannot parse From line: $line\n");
	    }
	} else {
	    $self->Fatal("Failed to read From line from mail: $!");
	}
    }
    $self->Debug("Received mail from $sender");

    $@ = '';
    my($parser, $entity);
    eval {
	$parser = Mail::IspMailGate::Parser->new('output_dir' => $tmpDir);
	$entity = $parser->read($ifh);
    };
    if ($@ || !$entity) {
	$self->SendBackupFile($id, $ofh, $backupFile, $sender, $recipients);
    }

    #
    #   For any recipient: Build his filter list
    #
    my @rFilters;
    foreach my $r (@$recipients) {
	$self->Debug("Making filter list for recipient $r");
	my(@filters) = $self->MakeFilterList($sender, $r);
	push(@rFilters, [$r, $entity, @filters]);
	$self->Debug("Filter list is: @filters");
    }

    #
    #   As long as there are filters in the filter lists: Find the
    #   first recipient with a filter. Pipe his entity into the filter.
    #   Replace his entity and that of all recipients with the same
    #   entity and filter with the result.
    #
    #   This is somewhat complicated, but this way we are guaranteed,
    #   that we call any filter only once, regardless of the number
    #   of recipients.
    #
    my $done;
    do {
	$done = 1;
	my($eOrig, $fOrig, $eNew, @rList);
	undef $eOrig;
	foreach my $r (@rFilters) {
	    if (@$r > 2) {
		if (!$eOrig) {
		    $eOrig = $r->[1];
		    $fOrig = $r->[2];
		    $self->Debug("Filtering entity %s for recipient %s via"
				 . " Filter %s", $eOrig, $r->[0], $fOrig);
		    $eNew = $eOrig->dup();
		    my $msg = eval { $fOrig->doFilter({'entity' => $eNew,
						       'parser' => $parser,
						       'main' => $self });
				  };
		    $self->Fatal($@) if $@;
		    if (length($msg)) {
			# The filter returned an error. Let the postmaster
			# know about it.
			$eNew = MIME::Entity->build
			    ('Type' => 'multipart/mixed',
			     'From' => $cfg->{'my-mail'},
			     'To' => $cfg->{'postmaster'},
			     'Reply-To' => join(",", $sender, @rList),
			     'Subject' => 'IspMailGate error report'
			    );
			$eNew->attach
			    ('Data' =>
			     [ "An error occurred while processing the",
			       " attached mail. The error\n",
			       "message is:\n",
			       "\n",
			       $msg,
			       "\n",
			       "This report was created by IspMailGate,",
			       " version $cfg->{'VERSION'}.\n"
			     ]);
			$eOrig->mime_type("message/rfc822") unless
			    $eOrig->mime_type();
			$eNew->add_part($eOrig);
			$sender = $cfg->{'my-mail'};
			@rList = $cfg->{'postmaster'};
			last;
		    }
		    $done = 0;
		}
		if ($r->[1] eq $eOrig  &&  $fOrig->IsEq($r->[2])) {
		    $r->[1] = $eNew;
		    splice(@$r, 2, 1);
		    $self->Debug("Replacing entity %s, recipient %s with %s",
				 $eOrig, $r->[0], $eNew);
		    if (@$r == 2) {
			# No more filters, send this mail
			$self->Debug("Delivering entity %s for recipient %s",
				     $eNew, $r->[0]);
			push(@rList, $r->[0]);
		    }
		}
	    }
	}
	if (@rList) {
	    $self->Debug("Array of parts while delivering: " . ($eNew->parts()));
	    $self->SendMimeMail($eNew, $sender, \@rList, $host);
	}
    } until ($done);
}


############################################################################
#
#   Name:   new
#
#   Purpose: IspMailGate constructor; not yet clear for what this
#            will be used, but it can be used (for example) to create
#            a new thread.
#
#   Inputs:  $class - This class
#            $attr - Constructor attributes
#
#   Returns: IspMailGate object or undef
#
############################################################################

sub new ($$) {
    my($class, $attr) = @_;
    my($self) = $attr ? { %$attr } : {};
    bless($self, (ref($class) || $class));
    $self;
}

sub DESTROY ($) {
    my($self) = @_;
    if ($self->{'tmpDir'}) {
	$self->Debug("Removing directory %s", $self->{'tmpDir'});
	&File::Path::rmtree($self->{'tmpDir'});
    }
#      if ( $self->{'backupFile'}   ) {
#  	$self->Debug("Removing backup file %s",  $self->{'backupFile'}  );
#  	unlink  $self->{'backupFile'}  ;
#      }
}

1;
