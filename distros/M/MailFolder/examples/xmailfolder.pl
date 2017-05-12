#!/usr/local/bin/perl -wI../blib/lib

# TODO
#   add {next|prev}_undeleted_message
#   font thingee doesn't work right on gutrfroth
#   add check for MAILDIR env to add default maildir folder to folderlist
#   add check for MAIL env to add default mbox folder to folderlist
#   add check for MAILPATH env to add list of mbox folders to folderlist
#      (use bash manpages for info on parsing it)
#   add error checking to make sure that 'Default*' options are valid
#      (eg: DefaultSignature)
#   create Option class like MIME-tools has
#   the options that .xmailfolderrc is setting should be in the Option array
#   have 'folder close' which updates current_message and 'folder abort'
#      which doesn't
#   make a subclass of Listbox to clean up 'bind' cruft
#   Fcc handling (including doing the 'right thing' for appending to folders)
#   tree representation of folder list
#   filters
#   x-face
#   pgp
#   uuencoded chunks
#   do MIME
#   improve folder summary output
#   include more info in folderlist summary
#   add:
#	write to a file
#       bounce message (make sure auto 'From:' generation does the right thing)
#       refile message
#       copy message
#       sort folder
#       message label stuff
#       select messages
#       search messages
#       create new folder
#       delete folder
#       rename folder
#   Options
#      automove on delete		boolean
#      folder locking style
#      signature list (with editor)
#    x Debug				boolean
#      DecodePrintedQuotableHeaders	boolean
#    x DefaultComposeTemplate
#    x DefaultSignature
#    x ShowAllHeaders			boolean
#      lots more...
#   composes should be in a draft folder
#   add toolbar
#   add pop3-downloader
#   make folderlist summary into it's own object class
#   add online help
#   optionally process delivery-status-notification field
#   virtual folders
#   maybe .xmailfolderc needs to be processed in it's own name space
#      with various methods to access values
#   variablize the embedded strings for internationalization
#   ispell interface
# PROBLEMS
#   figure out what caused this:
#      Tk::Error: (in cleanup) no lock on  at $MAILFOLDER/Mbox.pm line 689
#       Carp::croak at $PERLLIB/Carp.pm line 127
#       File::BasicFlock::unlock at $SITEPERL/File/BasicFlock.pm line 80
#       Mail::Folder::Mbox::unlock_folder at $MAILFOLDER/Mbox.pm line 689
#       Mail::Folder::Mbox::DESTROY at $MAILFOLDER/Mbox.pm line 650
#       (command bound to event) at $SITEPERL/auto/Tk/Error.al line 13.
#   need to investigate what happens to folder opening when the window is
#      slammed shut at inappropriate times
#   activation line is getting forgotten in folderlist summary after an Open
#   figure out how to have folderlist updated without having Folder->close
#      call main::CloseFolder
#   pack needs to adjust current_message accordingly
#   figure why a abnormal exit doesn't cleanup the open mailbox
#   key accelerators are conflicting with each other (Alt-f,c vs. c)
#   actually detect error returns from MailFolder calls
#   do more appropriate error handling in CoreCompose and friends
# SNIGGLES
#   add busy-cursor in appropriate places
#   figure how to get a Shift-(Next|Prior) to move the msg window in the
#      folder window
#   figure out how set width of scrollbars - normal way isn't working

require 5.00397;

my $VERSION = '0.01';
use vars qw($top
	    %fieldcolors
	    @ignore_headers
	    %signatures
	    %composetemplates
	    @folders
	    $username);

use strict;
use Tk qw(exit);
use Tk::widgets qw(Font Menubar Dialog DialogBox NoteBook
		   ROText WaitBox BrowseEntry);
use Mail::Folder::Mbox;
use Mail::Folder::Emaul;
use Mail::Folder::Maildir;
use Net::Domain;
use Mail::Internet;
use MIME::Head;
use IO::File;
use IO::Pipe;

$username = get_username();
my $homedir = $ENV{HOME};
my $sendmail = '/usr/lib/sendmail -t -oi -em';
my $indentstr = '>';

$top = new MainWindow;
$top->title('X-MailFolder');
$top->minsize(1, 1);

my $camel = $top->Photo(-file => Tk->findINC("Xcamel.gif"));
#my $fixedfont = $top->Font(family => 'courier', slant => 'r',
#			   point => 120, weight => 'medium');
my $fixedfont = $top->Font(family => 'courier', slant => 'r',
			   weight => 'medium');

my $foldersinfo;
my $foldersidx;
my $counter = 0;

my %Options = (
	       ShowAllHeaders => 0,
	       DefaultSignature => 'short',
	       DefaultComposeTemplate => 'NONE',
	       Debug => 0,
	      );
%fieldcolors = ();

@ignore_headers = ();

@folders = ();
foreach my $dir (qw(/var/spool/mail /usr/spool/mail /usr/mail)) {
  if (-e "$dir/$username") {
    @folders = "$dir/$username";
    last;
  }
}

%signatures = (
	       NONE => '',
	       long => '~/.signature',
	      );

%composetemplates = (
		    NONE => ''
		    );
###############################################################################
do "$homedir/.xmailfolderrc"
  if (-e "$homedir/.xmailfolderrc");

{
  my $i = 0;
  foreach my $folder (@folders) {
    next if defined($foldersinfo->{$folder});
    $foldersinfo->{$folder}{Status} = 'closed';
    $foldersinfo->{$folder}{Idx} = $i;
    $foldersidx->{$i} = $folder;
    $i++;
  }
}
###############################################################################
my $menu = $top->Menubar;
my $file = $menu->Menubutton(-text => "~File");
#------------------------------------------------------------------------------
$file->command(-label => "~Quit", -command => \&CleanQuit);
$file->pack(-side => "left");
$top->protocol('WM_DELETE_WINDOW' => \&CleanQuit);
#------------------------------------------------------------------------------
my $options = $menu->Menubutton(-text => '~Options');
$options->checkbutton(-label => 'Show All Headers',
		      -variable => \$Options{ShowAllHeaders});
$options->separator;
$options->command(-label => 'Preferences...',
		  -command => sub { Preferences($options) });
$options->cascade(-label => 'UI Preferences');
$options->separator;
$options->command(-label => 'Save Options (stub)');
$options->command(-label => 'Restore Options (stub)');
$options->pack(-side => 'left');
my $uim = $options->cget('-menu')->Menu;
$uim->checkbutton(-label => 'Strict Motif',
		  -variable => 'Tk::strictMotif');
$options->menu->entryconfigure('UI Preferences', -menu => $uim);
#------------------------------------------------------------------------------
my $help = $menu->Menubutton(-text => "~Help");
$help->pack(-side => 'right');
$help->command(-label => 'On Context');
$help->command(-label => 'On Help');
$help->command(-label => 'On Window');
$help->command(-label => 'On Keys');
$help->command(-label => 'On Version', -command => [\&ShowVersion, $top]);
###############################################################################
sub Preferences {
  my $top = shift;
  my $db = $top->DialogBox(-title => 'Preferences',
			   -buttons => ['OK', 'Cancel']);
  my $n = $db->add('NoteBook', -ipadx => 6, -ipady => 6);
  my $fl = $n->add('folderlist', -label => 'FolderList');
  my $fv = $n->add('folderview', -label => 'FolderView');
  my $m = $n->add('messages', -label => 'Messages');

  $fv->Checkbutton(-text => 'Automove on Delete')->pack;
  $m->Checkbutton(-text => 'Show All Headers')->pack;

  $n->pack(-expand => 'yes',
	  -fill => 'both',
	  -padx => 5, -pady => 5,
	  -side => 'top');
  my $button = $db->Show;
  # do actual option update processing here...
}
###############################################################################
my $list = createMyListbox($top,
			     -scrollbars => 'sw',
			     -relief => 'sunken',
			     -width => 80, -height => 5,
			     -setgrid => 'yes',
			     -selectmode => 'browse',
			     -font => $fixedfont,
			    );
$list->pack(-side => 'left', -fill => 'both', -expand => 'yes');
PopulateFolderListSummary();
$list->bind('<Double-ButtonRelease-1>' => sub {
	      OpenFolder($foldersidx->{$list->index('active')});
	    });
$list->bind('<Return>' => sub {
	      OpenFolder($foldersidx->{$list->index('active')});
	    });
$list->bind('<KeyPress-m>' => sub { Compose(); });
$list->bind('<KeyPress-q>' => sub { CleanQuit(); });
$list->bind('<KeyPress-g>' => sub { PopulateFolderListSummary(); });
$list->bind('<Control-l>' => sub { PopulateFolderListSummary(); });
$list->Subwidget('listbox')->focus;
$list->Subwidget('yscrollbar')->configure(-takefocus => 0);
$list->Subwidget('xscrollbar')->configure(-takefocus => 0);
###############################################################################
Tk::MainLoop;
###############################################################################
sub PopulateFolderListSummary {

  $list->delete(0 => 'end');
  foreach my $idx (sort { $a <=> $b } keys %{$foldersidx}) {
    $list->insert(end => GenerateFolderListLine($foldersidx->{$idx}));
  }
}
###############################################################################
sub GenerateFolderListLine {
  my $foldername = shift;
  my $expanded_filename = expand_filename($foldername);
  my $type;

  $type = Mail::Folder::detect_folder_type($expanded_filename);

  return sprintf("%s %-7s %s",
		 ($foldersinfo->{$foldername}{Status} eq 'open' ?
		  'OPEN  ' : 'closed'),
		 $type, $foldername);
}
###############################################################################
sub OpenFolder {
  my $foldername = shift;
  my $folder;

  if ($foldersinfo->{$foldername}{Status} eq 'closed') {
    if ($folder = new Folder($top, $foldername)) {
      $foldersinfo->{$foldername}{Status} = 'open';
      PopulateFolderListSummary();
      $foldersinfo->{$foldername}{Folder} = $folder;
    } else {
      croak("can't open folder $foldername");
    }
  }
}

sub CloseFolder {
  my $foldername = shift;
  $foldersinfo->{$foldername}{Status} = 'closed';
  PopulateFolderListSummary();
}
###############################################################################
sub Compose {
  my $fh;
  my $mref;
  my $use_tmp = 0;
  my $tmpfile = gen_tmp_filename();

  croak("unknown template type: $Options{'DefaultComposeTemplate'}")
    if (!defined($composetemplates{$Options{'DefaultComposeTemplate'}}));
  my $templatefile = $composetemplates{$Options{'DefaultComposeTemplate'}};
  $templatefile = expand_filename($templatefile);
  unless ($templatefile && -f $templatefile) {
    $use_tmp++;
    $fh = new IO::File ">$tmpfile" or croak("can't create $tmpfile: $!\n");
    for my $tag ('To: ', 'Cc: ', 'From: ', 'Subject: ', '') {
      $fh->print("$tag\n");
    }
    $fh->close;
    $templatefile = $tmpfile;
  }
  $fh = new IO::File $templatefile or croak("can't open $templatefile: $!\n");
  $mref = new Mail::Internet $fh;
  $mref->tidy_body;
  $fh->close;
  unlink $templatefile if ($use_tmp);

  my $compose = new Compose($mref);
}
###############################################################################
sub bump_counter { return $counter++; }

sub gen_tmp_filename {
  return get_tmpdir() . "/xmf." . bump_counter() . ".$$";
}

sub expand_filename {
  my $filename = shift;
  $filename =~ s/^~\//$ENV{HOME}\//;
  return $filename;
}
###############################################################################
sub ShowVersion {
  my ($top) = @_;
  my $d = $top->Dialog(-title => 'Versions',
		       -popover => $top,
		       -image => $camel,
		       -text => "X-MailFolder: $VERSION\nAuthor: Kevin Johnson <kjj\@pobox.com>\nTk: $Tk::patchLevel\nLibrary: $Tk::library\nperl/Tk: $Tk::VERSION\nperl: $]",
		       -justify => 'center',
		       -font => '-*-Times-Medium-R--Normal-*-120-*-*-*-*-*-*',
		      );
  $d->Show
}
###############################################################################
sub CleanQuit {
  foreach my $folder (keys %{$foldersinfo}) {
    if ($foldersinfo->{$folder}{Status} eq 'open') {
      $foldersinfo->{$folder}{Status} = 'closed';
      $foldersinfo->{$folder}{Folder}->close;
    }
  }
  exit 0;
}
###############################################################################
sub get_tmpdir { return $ENV{TMPDIR} || '/tmp'; }

sub get_username {
  my $username;
  
  $username = $ENV{USER} || $ENV{LOGNAME} || (getpwuid($>))[6];
  unless (defined($username)) {
    croak("can't determine user name!");
    exit 1;
  }
  return $username;
}

sub get_option {
  my $key = shift;
  return undef if (!defined($Options{$key}));
  return $Options{$key};
}

sub createMyListbox {
  my $top = shift;
  my $retval;
  my $lb;
  
  $retval = $top->ScrlListbox(@_);
  $lb = $retval->Subwidget('listbox');
  $lb->bindtags([$lb, 'Tk::ListBox', $top, 'all']);
  $lb->bind('<Down>' => sub {
	      $lb->activate($lb->index('active')+1);
	      $lb->see('active');
	    });
  $lb->bind('<Up>' => sub {
	      $lb->activate($lb->index('active')-1);
	      $lb->see('active');
	    });
  $lb->bind('<Control-Home>' => sub {
	      $lb->activate(0);
	      $lb->see(0);
	    });
  $lb->bind('<Control-End>' => sub {
	      $lb->activate('end');
	      $lb->see('end');
	    });
  $lb->bind('<ButtonRelease-1>' => sub {
	      my $Ev = $lb->XEvent;
	      $lb->CancelRepeat;
	      $lb->activate($Ev->xy);
	    });
  $lb->bind('<Next>' => ['yview', 'scroll', 1, 'pages']);
  $lb->bind('<Prior>' => ['yview', 'scroll', -1, 'pages']);
  
  $lb->bind('<Left>' => ['xview', 'scroll', -1, 'units']);
  $lb->bind('<Control-Left>' => ['xview', 'scroll', -1, 'pages']);
  $lb->bind('<Control-Prior>' => ['xview', 'scroll', -1, 'pages']);
  $lb->bind('<Right>' => ['xview', 'scroll', 1, 'units']);
  $lb->bind('<Control-Right>' => ['xview', 'scroll', 1, 'pages']);
  $lb->bind('<Control-Next>' => ['xview', 'scroll', 1, 'pages']);
  $lb->bind('<Home>' => ['xview', 'moveto', 0]);
  $lb->bind('<End>' => ['xview', 'moveto', 1]);
  
  return $retval;
}
###############################################################################
package Folder;

BEGIN { import Compose; }

use strict;

sub new {
  my $self = shift;
  my $type = ref($self) || $self;
  my $top = shift;
  my $foldername = undef;
  
  $foldername = shift if ($#_ != -1);
  
  my $me = bless {}, $type;
  
  $me->{'Msgs'} = ();
  $me->{'Indices'} = ();
  
  $me->{'foldername'} = undef;
  $me->{'top'} = $top;
  
  return undef if (defined($foldername) && !$me->open($foldername));
  
  return $me;
}

sub open {
  my $self = shift;
  my $foldername = shift;
  
  $self->{'foldername'} = $foldername;
  $self->{'topwindow'} = $self->{'top'}->Toplevel(-width => 200,
						  -height => 250);
  $self->{'topwindow'}->title($foldername);
  
  my $menuwin = $self->{'topwindow'}->Menubar;
  my $foldermenuwin = $menuwin->Menubutton(-text => '~Folder');
  $foldermenuwin->pack(-side => 'left');
  my $messagemenuwin = $menuwin->Menubutton(-text => '~Message');
  $messagemenuwin->pack(-side => 'left');
  my $fixedfont = $self->{'top'}->Font(family => 'courier', slant => 'r',
				       point => 120, weight => 'medium');
  my $listwin = main::createMyListbox($self->{'topwindow'},
				      -scrollbars => 'sw',
				      -relief => 'sunken',
				      -width => 80, -height => 15,
				      -setgrid => 'yes',
				      -selectmode => 'browse',
				      -font => $fixedfont,
				     );
  $listwin->packAdjust(-side => 'top', -fill => 'both', -delay => 1); 
  
  my $msgwin = $self->{'topwindow'}->Scrolled('ROText');
  $msgwin->pack(-side => 'bottom', -fill => 'both', -expand => 1);
  
  $foldermenuwin->command(-label => '~Expunge',
			  -command => sub { $self->expunge($listwin) });
  $foldermenuwin->command(-label => '~Pack',
			  -command => sub { $self->pack($listwin) });
  $foldermenuwin->separator;
  $foldermenuwin->command(-label => '~Close',
			  -command => sub { $self->close });
  
  $messagemenuwin->command(-label => 'Toggle ~Delete',
			   -command => sub {
			     $self->toggledelete($listwin, $msgwin) });
  $messagemenuwin->separator;
  $messagemenuwin->command(-label => '~Reply',
			   -command => sub { $self->reply($listwin, 0) });
  $messagemenuwin->command(-label => 'Reply~All',
			   -command => sub { $self->reply($listwin, 1) });
  $messagemenuwin->command(-label => '~Forward',
			   -command => sub { $self->forward($listwin) });
  
  my $waitboxwin = $self->{'top'}->WaitBox(-txt1 => "Opening $foldername",
					   -title => 'Wait...');
  $waitboxwin->transient;
  $waitboxwin->Show;
  
  $self->{'topwindow'}->protocol('WM_DELETE_WINDOW' => sub { $self->close });
  my $expanded_foldername = main::expand_filename($foldername);
  $self->{'folder'} = Mail::Folder->new('AUTODETECT', $expanded_foldername);
  
  $waitboxwin->configure(-txt1 => 'Building Summary');
  $waitboxwin->update;
  # need to add error handling here for folder open failures
  $self->populate_folder_summary($listwin);
  my $lb = $listwin->Subwidget('listbox');
  $lb->bind('<Down>' => sub {
	      my $fref = $self->{'folder'};
	      if (my $nextmsg = $fref->next_message) {
		$fref->current_message($nextmsg);
	      }
	      $lb->activate($lb->index('active')+1);
	      $lb->see('active');
	      $self->view_current_msg($msgwin);
	    });
  $lb->bind('<Up>' => sub {
	      my $fref = $self->{'folder'};
	      my $prevmsg = $fref->prev_message;
	      $fref->current_message($prevmsg) if ($prevmsg);
	      $lb->activate($lb->index('active')-1);
	      $lb->see('active');
	      $self->view_current_msg($msgwin);
	    });
  $lb->bind('<Control-Home>' => sub {
	      $self->{'folder'}->current_message($self->{'folder'}->first_message);
	      $lb->activate(0);
	      $lb->see(0);
	      $self->view_current_msg($msgwin);
	    });
  $lb->bind('<Control-End>' => sub {
	      $self->{'folder'}->current_message($self->{'folder'}->last_message);
	      $lb->activate('end');
	      $lb->see('end');
	      $self->view_current_msg($msgwin);
	    });
  $lb->bind('<ButtonRelease-1>' => sub {
	      my $Ev = $lb->XEvent;
	      $lb->CancelRepeat;
	      $lb->activate($Ev->xy);
	      my $active = $lb->index('active');
	      $self->{'folder'}->current_message($self->{'Indices'}{$active});
	      $self->view_current_msg($msgwin);
	    });
  $lb->bind('<Return>' => sub {
	      $lb->see('active');
	      $self->view_current_msg($msgwin);
	    });
  $lb->bind('<KeyPress-r>' => sub { $self->reply($listwin, 0) });
  $lb->bind('<KeyPress-R>' => sub { $self->reply($listwin, 1) });
  $lb->bind('<KeyPress-f>' => sub { $self->forward($listwin) });
  $lb->bind('<KeyPress-d>' => sub { $self->toggledelete($listwin, $msgwin) });
  $lb->bind('<KeyPress-u>' => sub { $self->set_delete($listwin, $msgwin, 0) });
  $lb->bind('<KeyPress-p>' => sub { $self->pack($listwin);
				    $self->view_current_msg($msgwin);
				  });
  $lb->bind('<KeyPress-x>' => sub { $self->expunge($listwin);
				    $self->view_current_msg($msgwin);
				  });
  $lb->bind('<KeyPress-q>' => sub { $self->close });
  $lb->focus;
  $listwin->Subwidget('yscrollbar')->configure(-takefocus => 0);
  $listwin->Subwidget('xscrollbar')->configure(-takefocus => 0);
  $msgwin->Subwidget('yscrollbar')->configure(-takefocus => 0);
  $msgwin->Subwidget('xscrollbar')->configure(-takefocus => 0);

  $self->view_current_msg($msgwin);

  $self->set_window_title;
  
  $waitboxwin->unShow;
  return(1);
}

sub set_window_title {
  my $self = shift;
  $self->{'topwindow'}->title("$self->{'foldername'}: " .
			      $self->{'folder'}->qty .
			      " messages");
}
  
sub close {
  my $self = shift;
  
  if ($self->is_open) {
    main::CloseFolder($self->{'foldername'});
    $self->{'folder'}->close;
    $self->{'foldername'} = undef;
    $self->{'topwindow'}->destroy;
  }
}

sub populate_folder_summary {
  my $self = shift;
  my $list = shift;
  my $mref;
  my $idx;
  my $from = '';
  my $subj = '';
  my $lb = $list->Subwidget('listbox');
  my $currmsg = $self->{'folder'}->current_message;
  my $curridx = 0;		# remember which item is the current message

  my $fref = $self->{'folder'};
  unless ($fref->message_exists($currmsg)) {
    $currmsg = $fref->next_message;
    $currmsg = $fref->prev_message unless ($fref->message_exists($currmsg));
    if ($fref->message_exists($currmsg)) {
      $fref->current_message($currmsg);
    } else {			# no messages - undo our little $msgnum jig
      $currmsg = $fref->current_message;
    }
  }

  $self->{Msgs} = ();
  $self->{Indices} = ();
  $lb->delete(0, 'end');
  foreach my $msg (sort { $a <=> $b } $self->{'folder'}->message_list) {
    $idx = $lb->index('end');
    $self->{Msgs}{$msg} = $idx;
    $self->{Indices}{$idx} = $msg;
    $curridx = $idx if ($msg == $currmsg);
    $lb->insert(end => $self->build_folder_summary_line($msg));
  }
  $lb->activate($curridx);
  $lb->see($curridx);
}

sub build_folder_summary_line {
  my $self = shift;
  my $msgnum = shift;
  my $retstr;
  my $subj = '';
  my $from = '';
  
  my $mref = $self->{'folder'}->get_mime_header($msgnum)
    or croak("can't get header for message $msgnum");
  my $dup_mref = $mref->dup;
  $dup_mref->decode;
  my $mime_type = $dup_mref->mime_type;
  # this is here temporarily...
  if ($Options{Debug}) {
    unless (($mime_type eq 'text') || ($mime_type eq 'text/plain') ||
	    ($mime_type eq 'multipart/mixed') ||
	    ($mime_type eq 'multipart/signed') ||
	    ($mime_type eq 'application/x-pgp-message')
	   ) {
      print("mime debug: $mime_type\n");
    }
  }
  
  $subj = beautify_subj($dup_mref->get('Subject'))
    if ($dup_mref->count('Subject'));
  $from =
    $dup_mref->get('Resent-From') ||
      $dup_mref->get('From') ||
	$dup_mref->get('Return-Path') || 'NOFROM';
  $from = beautify_from($from);
  $from = substr($from, 0, 30) if (length($from) > 30);
  
  my $is_deleted = $self->{'folder'}->label_exists($msgnum, 'deleted');
  $retstr = sprintf("%4d %s%s %-30s %s", $msgnum,
		    ($is_deleted ? 'D' : ' '),
		    (($mime_type !~ /^text/) ? 'M' : ' '),
		    $from, $subj);
  
  return $retstr;
}

sub view_current_msg {
  my $self = shift;
  my $msgwin = shift;
  my $msgnum = $self->{'folder'}->current_message;
  my $tmpmsgnum;
  
  my $junk;
  my $mref;
  my $dup_header;
  
  if (!$self->{'folder'}->message_exists($msgnum)) {
    $tmpmsgnum = $self->{'folder'}->prev_message($msgnum);
    if ($tmpmsgnum == 0) {
      return 0 unless ($tmpmsgnum = $self->{'folder'}->next_message($msgnum));
    }
    $msgnum = $tmpmsgnum;
    $self->{'folder'}->current_message($msgnum);
  }

  $mref = $self->{'folder'}->get_message($msgnum);
  $dup_header = new MIME::Head;
  $dup_header->header($mref->header);
  $dup_header->decode;
  unless ($Options{ShowAllHeaders}) {
    for my $tag (@main::ignore_headers) {
      $dup_header->delete($tag);
    }
  }
  $dup_header->fold(80);
  $msgwin->delete('1.0' => 'end');
  $msgwin->markSet('insert' => '1.0');
  for my $line (@{$dup_header->header}) {
    my $startpos = $msgwin->index('insert');
    $msgwin->insert('end', $line);
    $msgwin->markSet('insert' => 'end');
    foreach my $field (keys %main::fieldcolors) {
      if ($line =~ /^$field:/i) {
	$msgwin->tag('add', $field, $startpos, $msgwin->index('insert'));
	$msgwin->tag('configure', $field,
		     -foreground => $main::fieldcolors{$field},
		     -relief => 'raised');
      }
    }
  }
  $msgwin->insert('insert', "\n");
  $msgwin->markSet('insert' => 'end');
  for my $line (@{$mref->body}) {
    $msgwin->insert('insert', $line);
    $msgwin->markSet('insert' => 'end');
  }
  $msgwin->markSet('insert' => '0.0');
}

sub is_open {
  my $self = shift;
  
  return(defined($self->{'foldername'}));
}

sub expunge {
  my $self = shift;
  my $list = shift;
  
  $self->{'folder'}->sync;
  
  my $msgnum = $self->{'folder'}->current_message;
  if (!$self->{'folder'}->message_exists($msgnum)) {
    my $tmpmsgnum = $self->{'folder'}->prev_message($msgnum);
    if ($tmpmsgnum == 0) {
      $tmpmsgnum = $self->{'folder'}->next_message($msgnum);
      if ($tmpmsgnum == 0) {
	$tmpmsgnum = $msgnum;	# couldn't find a message - leave things alone
      }
    }
    $msgnum = $tmpmsgnum;
    $self->{'folder'}->current_message($msgnum);
  }
  
  $self->populate_folder_summary($list);
  $self->set_window_title;
}

sub pack {
  my $self = shift;
  my $list = shift;
  
  $self->{'folder'}->pack;
  $self->populate_folder_summary($list);
}

sub set_delete {
  my $self = shift;
  my $listwin = shift;
  my $msgwin = shift;
  my $arg = shift;

  my $cur = $listwin->index('active');
  my $msgnum = $self->{'folder'}->current_message;
  my $lb = $listwin->Subwidget('listbox');

  if ($arg) {
    $self->{'folder'}->delete_message($msgnum)
      or croak("internal error deleting $msgnum");
  } else {
    $self->{'folder'}->undelete_message($msgnum)
      or croak("internal error undeleting $msgnum");
  }
  $lb->delete($cur);
  $lb->insert($cur, $self->build_folder_summary_line($msgnum));
  $lb->activate($cur);
  $lb->see('active');
}

sub toggledelete {
  my $self = shift;
  my $listwin = shift;
  my $msgwin = shift;
  
  my $cur = $listwin->index('active');
  my $msgnum = $self->{'folder'}->current_message;
  my $lb = $listwin->Subwidget('listbox');

  $self->set_delete($listwin, $msgwin,
		    ($self->{'folder'}->label_exists($msgnum, 'deleted') ?
		     0 : 1));
  
  # step to the next message
  my $nextmsg = $self->{'folder'}->next_message;
  $self->{'folder'}->current_message($nextmsg) if ($nextmsg);
  $lb->activate($lb->index('active')+1);
  $lb->see('active');
  $self->view_current_msg($msgwin);
}

sub forward {
  my $self = shift;
  my $listwin = shift;
  
  my $msgnum = $self->{'folder'}->current_message;
  my $forw_mref;
  my $subj = '';
  my $body;
  my $mref = $self->{'folder'}->get_message($msgnum);
  my $dup_mref = $mref->dup;
  $dup_mref->head->cleanup;
  $dup_mref->tidy_body;
  $dup_mref->remove_sig();
  
  $forw_mref = Mail::Internet->new;
  $subj = $dup_mref->get('Subject') if ($dup_mref->head->count('Subject'));
  $forw_mref->replace('To', '');
  $forw_mref->replace('Cc', '');
  $forw_mref->replace('Subject', "Fw: $subj");
  
  push(@{$body}, "\n");
  push(@{$body}, "---------- Begin Forwarded Message ----------\n");
  push(@{$body}, @{$dup_mref->header});
  push(@{$body}, "\n");
  push(@{$body}, @{$dup_mref->body});
  push(@{$body}, "----------- End Forwarded Message -----------\n");
  
  $forw_mref->body($body);
  
  my $compose = new Compose($forw_mref);
}

sub reply {
  my $self = shift;
  my $listwin = shift;
  my $replyall = shift;
  
  my $msgnum = $self->{'folder'}->current_message;
  my $mref = $self->{'folder'}->get_message($msgnum);
  my $dup_mref = $mref->dup;
  $dup_mref->head->cleanup;
  $dup_mref->tidy_body;
  $dup_mref->remove_sig();
  my $reply_mref = ($replyall ?
		    $mref->reply(Indent => $indentstr, ReplyAll => 1) :
		    $mref->reply(Indent => $indentstr));
  
  my $compose = new Compose($reply_mref);
}
#------------------------------------------------------------------------------
sub beautify_subj {
  my $subj = shift;
  
  chomp($subj);
  $subj =~ s/^\s+//;		# geez...
  
  return $subj;
}

sub beautify_from {
  my $addr = shift;
  my @addrs;
  
  chomp($addr);
  
  @addrs = Mail::Address->parse($addr);
  
  if ($addr = $addrs[0]->phrase) {
    $addr =~ s/^\"//; $addr =~ s/\"$//;
  } elsif ($addr = $addrs[0]->comment) {
    $addr =~ s/^\(//; $addr =~ s/\)$//;
  } else {
    $addr = $addrs[0]->address;
  }
  return $addr;
}
###############################################################################
package Compose;

use strict;
use Carp;
use Mail::Util qw(mailaddress);

sub new {
  my $self = shift;
  my $type = ref($self) || $self;
  my $mref = shift;

  croak("internal error in Compose->new - missing mref") unless defined($mref);
  
  my $me = bless {}, $type;

  my $dup_mref = $mref->dup;
  $dup_mref->head->replace('From', mailaddress())
    unless ($dup_mref->head->count('From') && $dup_mref->head->get('From'));

  $me->{Signature} = main::get_option('DefaultSignature');

  $me->create_window($dup_mref);

  return $me;
}

sub create_window {
  my $self = shift;
  my $mref = shift;

  my $composewin = ${main::top}->Toplevel(-height => 250);
  $composewin->title('Compose');
  my $menu = $composewin->Menubar;
  my $filemenu = $menu->Menubutton(-text => "~File");
  my $editwin = $composewin->Scrolled('Text', -width => 80, -setgrid => 'yes');
  $filemenu->command(-label => "~Send", -command => sub {
		       $self->sendmail($editwin);
		       $composewin->destroy;
		     });
  $filemenu->command(-label => "~Cancel", -command => sub {
		       $composewin->destroy;
		     });
  $filemenu->pack(-side => 'left');
  $editwin->pack(-fill => 'both', -expand => 1);
  my $framewin = $composewin->Frame(-relief => 'ridge',
				    -borderwidth => 3);
  $framewin->pack(-side => 'bottom', -anchor => 'w');
  my $labelwin = $framewin->Label(-text => 'Signature:');
  $labelwin->pack(-side => 'left', -fill => 'none', -anchor => 'w');
  my $signaturewin =
    $framewin->Optionmenu(-options => [sort keys %main::signatures],
			  -relief => 'groove',
			  -command => sub {
			    $self->{Signature} = shift;
			  }
			 );
  $signaturewin->setOption($self->{Signature});
  $signaturewin->pack(-side => 'left', -anchor => 'w', -fill => 'none');
  
  for my $line (@{$mref->header}) {
    $editwin->insert('insert', $line);
  }
  $editwin->insert('insert', "\n");
  for my $line (@{$mref->body}) {
    $editwin->insert('insert', $line);
  }
  $editwin->Subwidget('text')->markSet('insert' => '0.0');
  
  $editwin->Subwidget('text')->focus;
  
  return 1;
}

sub sendmail {
  my $self = shift;
  my $editwin = shift;
  my $counter = main::bump_counter;
  my $tmpfile = main::gen_tmp_filename;
  my @timeary;
  
  my $fh = new IO::File ">$tmpfile" or croak("can't create $tmpfile: $!\n");
  $fh->print($editwin->get('1.0' => 'end'));
  $fh->close;
  
  $fh = new IO::File $tmpfile or croak("can't open $tmpfile: $!\n");
  my $mref = Mail::Internet->new($fh);
  $fh->close;
  unlink $tmpfile;
  
  $mref->replace('X-Mailer', "X-MailFolder v$VERSION");
  @timeary = gmtime(time);
  $mref->replace('Message-Id',
		 sprintf("<xmf.19%02d%02d%02d%02d%02d%02d.%d.%d@%s>",
			 $timeary[5], $timeary[4], $timeary[3],
			 $timeary[2], $timeary[1], $timeary[0],
			 $$, $counter, Net::Domain::domainname()));
  croak("missing 'To'\n") unless ($mref->get('To'));
  
  $mref->head->cleanup;
  $mref->tidy_body;

  my $signtype = $self->{Signature};
  my $signature = $main::signatures{$signtype};
  if ($signature) {
    if ($signature !~ /^-- /) {
      my $expanded_filename = main::expand_filename($signature);
      if (-f $expanded_filename) {
	if (-x $expanded_filename) {
	  $mref->sign(Signature => get_prog_output($expanded_filename));
	} else {
	  $mref->sign(File => $expanded_filename);
	}
      } else {
	$mref->sign(Signature => ("-- \n" . $signature));
      }
    } else {
      $signature =~ s/^-- \n//;
      $mref->sign(Signature => $signature);
    }
  }
  $mref->tidy_body;

  my $pipe = new IO::Pipe or croak "can't create pipe: $!";
  $pipe->writer($sendmail) or croak "can't pipe to $sendmail: $!";
  $mref->print($pipe) or croak "can't write to $sendmail: $!";
  $pipe->close or croak "error closing pipe to $sendmail: $!";
}

sub get_prog_output {
  my $prog = shift;
  my $str;

  my $pipe = new IO::Pipe or croak "can't create pipe: $!";
  $pipe->reader($prog) or croak "can't pipe from $prog: $!";
  while (<$pipe>) {
    $str .= $_;
  }
  $pipe->close or croak "error closing pipe from $prog: $!";
  return $str;
}
