package Mail::IMAPFolderSearch;
				
use strict;
use IO::Socket::SSL;
use IO::Socket;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(

);

$VERSION = '0.03';

=head1 NAME

Mail::IMAPFolderSearch - Search multiple mail folders via a IMAP4rev1 server

=head1 SYNOPSIS

     use Mail::IMAPFolderSearch;

     $imap = Mail::IMAPFolderSearch->new(SSL => 1,
                               Server => 'mail.example.com',
                               );

     $imap->login(User => 'imapuser',
                  Password => 'xxxx'
                  );

     $keywords = { Keyword1 => { Word => 'brian',
                                 What => 'FROM' },
                   Keyword2 => { Word => 'imap',
                                 What => 'NOT BODY' },
                   Keyword3 => { Word => '1-Dec-2001',
                                 What => 'SINCE' },
                   Keyword4 => { Word => '13-Jan-2002',
                                 What => 'BEFORE' },
                   Keyword5 => { Word => 'nobody',
                                 What => 'NOT TO' },
                   Keyword6 => { Word => 'test' }
                  };

     $imap->searchFolders(Keywords => $keywords);

     $imap->logout();

=head1 REQUIRES

IO::Socket, IO::Socket::SSL

=head1 DESCRIPTION

Many e-mail clients such as F<PINE> allow the user to search
for a string within a single folder.  Mail::IMAPFolderSearch allows
for scripting of multiple string searches, spanning multiple
mail folders.  Results are placed in a new folder allowing
the user to use their existing mail client to view  
matching messages.  The results folder is named IMAPSearch by 
default, but it is possible to specify a different name.  

=head1 CONSTRUCTOR

=over 4

=item C<new(%options)>

The constructor takes a list of attributes that provide 
information about the IMAP server.

OPTIONS are as follows:

F<Server>
    Server to connect to.  This is required.

F<SSL> 
    Use SSL or not.  Takes 0 or 1.  SSL is disabled 
    by default.

F<Port>
    Port to connect to.  If SSL is disabled, the 
    default is 143.  If it is enabled, the default
    is 993.

F<Prefix>
    If mail folders are located in the user's home 
    directory (e.g. under ~user/mail/), enable 
    searching in this location with 1.  
    Default is 0.

F<PrefixPath>
    If Prefix is enabled, specify the subdirectory 
    under ~user/ that contains mail folders.  
    Default is 'mail'.  

F<Debug>
    Turn on debugging with 1.  This will display
    output from the IMAP server.  Default is 0. 

F<Count>
    Specify the command number to start with when
    interacting with the IMAP server.  Default is 0.

=cut

sub new {
	my $class = shift;
	my $args = { @_ };
	my $self = { };
	$self->{SSL} = $args->{SSL} || 0;
	my $port;
	if ($self->{SSL} == 0) {
		$port = 143;
	} else {
		$port = 993;
	}
	$self->{Port} = $args->{Port} || $port;
	$self->{Server} = $args->{Server} || die "No Server specified";
	$self->{Count} = $args->{Count} || 0;
	$self->{Prefix} = $args->{Prefix} || 0;
	$self->{PrefixPath} = $args->{PrefixPath} || 'mail';
	$self->{Debug} = $args->{Debug} || 0;
	$self->{CmdLimit} = $args->{CmdLimit} || 4000;
	bless($self,$class);
	return $self;
}

=head1 METHODS

=over 4

=item login(%options)

Authenticate with the IMAP server. login() accepts 
F<User> and F<Password>.

=cut

sub login {
	my $imap = shift;
	my $args = { @_ };
	$imap->{User} = $args->{User} || die "User not specified";
	$imap->{Password} = $args->{Password} || die "Password is required";
	my $socket; 
	if ($imap->{SSL} == 0) {
		$socket = IO::Socket::INET->new("$imap->{Server}:$imap->{Port}") || die "Can't connect $!";
	} else {
		$socket = IO::Socket::SSL->new( SSL_verify_mode => 0x00,
							SSL_use_cert => 0,
							PeerAddr => $imap->{Server},
							PeerPort => $imap->{Port} 
							) || die "Can't connect $!";
	}
	$imap->{Socket} = $socket;
	my $ulen = length($imap->{User});
	my $plen = length($imap->{Password});
	$socket->print("$imap->{Count} LOGIN \{$ulen\}\r\n");	
	$socket->print("$imap->{User} \{$plen\}\r\n");	
	$socket->print("$imap->{Password}\r\n");	
	my $output = $imap->_readlinesIMAP();
	$imap->_checkOUT(Output => $output) || die 'Unable to login';
}
	
=item logout()

Disconnect from the IMAP server.

=cut

sub logout {
	my $imap = shift;
	my $socket = $imap->{Socket};
	$socket->print("$imap->{Count} LOGOUT\r\n");
	my $output = $imap->_readlinesIMAP();
	$imap->_checkOUT(Output => $output) || die 'Unable to logout!?';
}

=item searchFolders(%options)

Do a search for provided keywords and place the results
in a separate mail folder.  

OPTIONS are as follows:

F<Keywords> is required and must point to a hashref
of keywords.  

F<Folders> can be a reference to an array of folders or 
'ALL' with 'ALL' being the default. 

F<OutFolder> can take a folder name as the location to 
place search results.  The default is 'IMAPSearch'.

F<Expunge> can be set to 1 or 0 with 0 being the default.  If
F<Expunge> is true, all messages in F<OutFolder> will be
deleted and expunged.  When F<Expunge> is set, be careful 
not to set F<OutFolder> to an existing folder that you care
about, such as INBOX!

F<Boolean> can be either 'AND' or 'OR'.

=cut

sub searchFolders {
	my $imap = shift;
	my $args = { @_ };
	my $socket = $imap->{Socket};
	$imap->{OutFolder} = $args->{OutFolder} || 'IMAPSearch';
	$imap->{Expunge} = $args->{Expunge} || 0;
	$imap->_cleanOutFolder();
	my $boolean = uc $args->{Boolean} || 'AND';
	my $searchterms = $args->{Keywords};
	my $searchcount;
	my $folders;
	# when ALL is specified or Folders is not and array ref we get all folders
	unless (defined($args->{Folders})) {
		$args->{Folders} = 'ALL';
	}
	if (($args->{Folders} =~ /^ALL$/i) or (ref($args->{Folders}) ne 'ARRAY')) {
		$folders = $imap->getFolders();
	} elsif (ref($args->{Folders}) eq 'ARRAY') {
		$folders = $args->{Folders};
	} 
	foreach my $folder (@$folders) {
		$searchcount = 0;
		# set up $outfolder, checking for a PrefixPath
		my $outfolder = $imap->_getOutFolder();
		if ($folder eq $outfolder) {
			next;
		}
		$imap->_selectFolder(Folder => $folder);
		my $searchstring;
		# Naming of search terms is arbitrary.  Any name will work.
		# it is important to remember that these are sorted which
		# may affect the results
		foreach my $key (sort keys %{$searchterms}) {
			unless (defined($searchterms->{$key}->{What})) {
				$searchterms->{$key}->{What} = 'TEXT';
				 $imap->{Debug} && print "\nundefined $searchterms->{$key}->{What}\n";
			} elsif ((defined($searchterms->{$key}->{What})) && ($searchterms->{$key}->{What} =~ /[a-z]/)) { 
				 $searchterms->{$key}->{What} = uc $searchterms->{$key}->{What};
			} 
			$searchstring .= "$searchterms->{$key}->{What} \"$searchterms->{$key}->{Word}\" ";
			++$searchcount;
		}
		# IMAP doesn't like an extra space at the end
		chop($searchstring);
		# Perform the search
		if (($searchcount == 1) || ($boolean eq 'AND')) {
			$socket->print("$imap->{Count} SEARCH $searchstring\r\n");
		} elsif (($searchcount > 1) && ($boolean eq 'OR')) {
			$socket->print("$imap->{Count} SEARCH OR $searchstring\r\n");
		} else {
			return 0;
		}
		my $output = $imap->_readlinesIMAP();
		$imap->_checkOUT(Output => $output) || die "Unable to SEARCH $folder";
		my $messages;
		foreach my $line (@$output) {
			if ($line =~ /^\* SEARCH(.*)/i) {
				$messages = [ split(/\s+/,$line) ];
				# Get rid of '* SEARCH'
				$messages = [ splice(@$messages, 2) ];
			} else {
				next;
			}
		}
		$imap->_messageCopy($messages);
	}
	return 1;
}

=item getFolders()

Returns a reference to an array containing
all mail folders.

=cut

sub getFolders {
	my $imap = shift;
	my $socket = $imap->{Socket};
	if ($imap->{Prefix} == 0) {
		$socket->print("$imap->{Count} LIST \"\" \*\r\n");
	} elsif ($imap->{Prefix} == 1) {
		$socket->print("$imap->{Count} LIST \"$imap->{PrefixPath}\" \*\r\n");
	}
	my $folderlines = $imap->_readlinesIMAP();
	$imap->_checkOUT(Output => $folderlines) || die 'Unable to LIST any folders';
	my ($folders, $folderlist);
	foreach my $folder (@$folderlines) {
		chomp $folder;
		if ($folder =~ /^\* LIST(.*)NoSelect(.*)/i) {
			next;
		} elsif ($folder =~ /^\* LIST.*\"\s\"(.*)\"/i) {
			push(@$folders,$1);
		} else {
			@$folderlist = split(/\s+/,$folder);
			push(@$folders,pop(@$folderlist));
		}
	}
	if ($imap->{Prefix} == 1) {
		push(@$folders,'INBOX');
	}
	return $folders;
}

=item messageCount($folder)

Returns the number of messages in $folder.

=cut

sub messageCount {
	my $imap = shift;
	my $socket = $imap->{Socket};
	my $folder = shift;
	$socket->print("$imap->{Count} STATUS $folder \(MESSAGES\)\r\n");
	my $output = $imap->_readlinesIMAP();
	my $msgline;
	my $msgcount;
	foreach my $line (@$output) {
		if ($line =~ /^\* STATUS(.*)/i) {
			@$msgline = split(/\s+/,$line);
			$msgcount = pop(@$msgline);
			chop $msgcount;
		}
	}
	$imap->_checkOUT(Output => $output) || die "Unable to get STATUS for $folder";
	return $msgcount;
}

#########
# Private _methods 
#########


# Copy any matching messages the results folder

sub _messageCopy {
	my $imap = shift;
	my $socket = $imap->{Socket};
	my $messages = shift;
	my $msglist;
	my $msgcommands;
	if (@$messages > 1) {
		# if multiple messages match, copy them all at once with ,'s
		$msglist = join(',',@$messages);
		if (length($msglist) > 4000) {
			$msgcommands = $imap->_splitMessages($messages);
		} else {
			push(@$msgcommands, $msglist);
		}
	} elsif (@$messages == 1) {
		# if only one message matches, set this to be the messagelist
		push(@$msgcommands, $messages->[0]);
	} else {
		return 0;
	}
	my $outfolder = $imap->_getOutFolder();
	foreach my $mcopy (@$msgcommands) {
		$socket->print("$imap->{Count} COPY $mcopy $outfolder\r\n");
		my $output = $imap->_readlinesIMAP();
		$imap->_checkOUT(Output => $output) || die "Unable to COPY to $imap->{OutFolder}, command line to long?";
	}
}

sub _splitMessages {
	my $imap = shift;
	my $messages = shift;
	my $msglist;
	my $length = 0;
	my $msgsplit;
	my $count = 0;
	my $msglength;
	foreach my $msg (@$messages) {
		$msglength = length($msg);
		if (($length + $msglength) < $imap->{CmdLimit}) {
			if ($count == 0) {
				$msglist .= $msg;
			} elsif ($count > 0) {
				$msglist .= ",$msg";
			}
			$count++;
		} elsif ($length + $msglength >= $imap->{CmdLimit}) {
			push(@$msgsplit,$msglist);
			$msglist = "";
			$count = 1;
			$length = 0;
			$msglist = $msg;
		} else {
			last;
		}
		$msglength++;
		$length += $msglength;
	}
	if ($msglist =~ /,/) {
		$msglist .= ',' . pop(@$messages);
	}
	push(@$msgsplit,$msglist);
	return $msgsplit;
}
	


# Setup the results folder

sub _cleanOutFolder {
	my $imap = shift;
	my $socket = $imap->{Socket};
	my $outfolder = $imap->_getOutFolder();
	$socket->print("$imap->{Count} LIST \"\" $outfolder\r\n");
	my $output = $imap->_readlinesIMAP();
	$imap->_checkOUT(Output => $output) || die "Unable to LIST $outfolder";
	my $exists = 0;
	my $msgcount;
	foreach my $line (@$output) {
			if ($line =~ /^\* LIST(.*)$outfolder/i) {
				$exists = 1;
				$msgcount = $imap->messageCount($outfolder);
				# Expunge all messages if asked
				if (($msgcount > 0) && ($imap->{Expunge})) {
					$imap->_deleteAll($msgcount);
				}
				last;
			} else {
				next;
			}
	}
	unless ($exists) {
		$imap->_createOutFolder();
	}
}


# Mark all messages as deleted in the results folder

sub _deleteAll {
	my $imap = shift;
	my $socket = $imap->{Socket};
	my $msgcount = shift;
	my $outfolder = $imap->_getOutFolder();
	$imap->_selectFolder(Folder => $outfolder);
	$socket->print("$imap->{Count} STORE 1\:$msgcount \+FLAGS \(\\DELETED\)\r\n");
	my $output = $imap->_readlinesIMAP();
	$imap->_checkOUT(Output => $output) || die "Unable to STORE FLAGS in $outfolder";
	$imap->_expunge();
}


# Expunge from the results folder

sub _expunge {
	my $imap = shift;
	my $socket = $imap->{Socket};
	$socket->print("$imap->{Count} EXPUNGE\r\n");
	my $output = $imap->_readlinesIMAP();
	$imap->_checkOUT(Output => $output) || die "Unable to EXPUNGE";
}


# Set a folder as being selected (necessary for some commands)

sub _selectFolder {
	my $imap = shift;
	my $socket = $imap->{Socket};
	my $args = { @_ };
	my $folder;
	if ($args->{Folder} =~ /\s+/) {
		$folder = '"' . $args->{Folder} . '"';
	} else {
		$folder = $args->{Folder};
	}
	$socket->print("$imap->{Count} SELECT $folder\r\n");
	my $output = $imap->_readlinesIMAP();
	$imap->_checkOUT(Output => $output) || die "Unable to SELECT $args->{Folder}";
}


# Delete specified folder if it is not in use
	
sub _deleteFolder {
	my $imap = shift;
	my $socket = $imap->{Socket};
	my $folder = shift;
	$socket->print("$imap->{Count} DELETE $folder\r\n");
	my $output = $imap->_readlinesIMAP();
	$imap->_checkOUT(Output => $output) || die "Unable to DELETE $folder - Folder in use?";
}


# Create a new results folder

sub _createOutFolder {
	my $imap = shift;
	my $socket = $imap->{Socket};
	my $outfolder = $imap->_getOutFolder();
	$socket->print("$imap->{Count} CREATE $outfolder\r\n");
	my $output = $imap->_readlinesIMAP();
	$imap->_checkOUT(Output => $output) || die 'Unable to CREATE $outfolder';
}


# Verify the server responded with OK

sub _checkOUT {
	my $imap = shift;
	my $args = { @_ };
	my $countchk = $imap->{Count} - 1;
	my $output = $args->{Output};
	my $lastline = pop(@$output);
	if ($lastline !~ /^$countchk OK(.*)/) {
		return 0;
	} else {
		return 1;
	}
}


# Use getline() or readline() to grab output from the IMAP server

sub _readlinesIMAP {
	my $imap = shift;
	my $socket = $imap->{Socket};
	my ($output,$line);
	if ($imap->{SSL} == 0) {
		while ($line = $socket->getline() ) {
			$imap->{Debug} && print $line;
			if ($line !~ /^$imap->{Count}\s/) { 
				push(@$output,$line);
			} else {
				push(@$output,$line);
				last;
			}
		}
	} else {
		while ($line = $socket->readline() ) {
			$imap->{Debug} && print $line;
			if ($line !~ /^$imap->{Count}\s/) { 
				push(@$output,$line);
			} else {
				push(@$output,$line);
				last;
			}
		}
	}
	++$imap->{Count};
	return $output;
}


# Return the results folder name including it's PrefixPath

sub _getOutFolder {
	my $imap = shift;
	my $socket = $imap->{Socket};
	my $outfolder;
	if ($imap->{Prefix} == 1) {
		$outfolder = "$imap->{PrefixPath}/$imap->{OutFolder}";	
	} else {
		$outfolder = "$imap->{OutFolder}";	
	}
	return $outfolder;
}

1;
__END__

=back

=head1 KEYWORDS

Keyword searching follows RFC 2060's specification
for SEARCH.  For a full list of options, check there.

As for the main points, note that:

=item *

When specifying 'OR', either of the first two keywords given 
will match.  When specifying more than 2 search terms,
elements 3 and above will be matched with 'AND'.

=item *

When setting up your keywords hashref, please consider
that keyword keys (i.e. F<Keyword1>, F<Keyword2>, etc.) will
be processed in a sorted order.  F<Word> is the option
used to match a string and is required.  F<What> specifies
the portion of the message that should be searched.  Commonly
used criteria are TEXT (full message including headers),
FROM (from: header), TO (to: header), SUBJECT (subject:
header), SINCE (messages sent since date), BEFORE 
(messages sent before date), BODY (limit search to message body)

If F<What> is not specified, it will default to TEXT.

=item *

You may negate 'AND' elements with 'NOT $what' where
$what is an acceptable IMAP SEARCH parameter.   

=item *

Regular expressions do not work, as per RFC 2060.

=head1 AUTHOR

Brian Hodges <bhodgescpan ^at^ pelemele ^dot^ com>

=head1 SEE ALSO

perl(1), L<IO::Socket>, L<IO::Socket::SSL>
