use 5.006;
use strict;
package Mail::Audit;
{
  $Mail::Audit::VERSION = '2.228';
}
# ABSTRACT: library for creating easy mail filters

use Carp ();
use File::Basename ();
use File::HomeDir 0.61 ();
use File::Spec ();
use Mail::Audit::MailInternet ();
use Mail::Internet ();
use Symbol ();

use Sys::Hostname ();

use Fcntl ':flock';

use constant REJECTED  => 100;
use constant DEFERRED  => 75;
use constant DELIVERED => 0;


sub import {
  my ($pkg, @plugins) = @_;
  for (@plugins) {
    eval "use $pkg\::$_";
    die $@ if $@;
  }
}

sub _log { shift->log(@_) }

sub _get_opt {
  my ($self, $arg) = @_;

  my $opt;

  if (ref $arg->[0] eq 'HASH') {
    Carp::carp "prepending arguments is deprecated; append them instead"
      unless @$arg == 1;
    $opt = shift @$arg;
  } elsif (ref $arg->[-1] eq 'HASH') {
    $opt = pop @$arg;
  }

  return $opt || {};
}


my $default_mime_test = sub { $_[0]->get("MIME-Version") };

sub new {
  my $class = shift;
  my %opts  = @_;
  my $type  = ref($class) || $class;

  my $mime_test = (delete $opts{mime_test}) || $default_mime_test;

  my $self = Mail::Audit::MailInternet->new(
    (exists $opts{data} ? $opts{data} : \*STDIN),
    Modify => 0
  );

  # set up logging
  unless ($opts{no_log}) {
    my $log = {};
    $log->{level} = exists $opts{loglevel} ? $opts{loglevel} : 3;

    $log->{file} = exists $opts{log}
                 ? $opts{log}
                 : File::Spec->catfile(
                     File::HomeDir->my_home,
                     "mail-audit.log"
                   );

    my $output_fh;
    if ($log->{file} and open $output_fh, '>>', $log->{file}) {
      $log->{fh} = $output_fh;
    } else {
      warn "couldn't open $log->{file} to log: $!" if $log->{file};
      $log->{fh} = \*STDERR;
    }

    # This sucks, but the gut-construction order does, too.  We need to make it
    # saner in general. -- rjbs, 2006-06-04
    $self->{_log} = $log;
  }

  $self->_log(1, "------------------------------ new run at " . localtime);

  $self->_log(2, "   From: " . ($self->get("from")));
  $self->_log(2, "     To: " . ($self->get("to")));
  $self->_log(2, "Subject: " . ($self->get("subject")));

  # do we have a MIME-Version header?
  # if so,  we subclass MIME::Entity.
  # if not, we remain   Mail::Internet, and, presumably, diminish, and go
  # into the West.
  if ($opts{alwaysmime} or $mime_test->($self)) {
    unless ($opts{nomime}) {
      $self->_log(3,
        "message is MIME.  MIME-Version is " . ($self->get("MIME-Version"))
      );
      eval {
        require Mail::Audit::MimeEntity;
        Mail::Audit::MimeEntity->import;
      };
      die "$@" if $@;
      $self = Mail::Audit::MimeEntity->_autotype_new($self, $opts{mimeoptions});
    } else {
      $self->_log(3, "message is MIME, but 'nomime' option was set.");
    }
  }

  ($self->{_hostname} = Sys::Hostname::hostname) =~ s/\..*//;

  $self->{_audit_opts} = \%opts;
  $self->{_audit_opts}->{noexit}               ||= 0;
  $self->{_audit_opts}->{interpolate_strftime} ||= 0;
  $self->{_audit_opts}->{one_for_all}          ||= 0;

  return $self;
}

sub _emergency_mbox {
  my ($self) = @_;

  return $self->{_audit_opts}->{emergency}
    if exists $self->{_audit_opts}->{emergency};

  return $self->{_audit_opts}->{emergency} = $self->_default_mbox;
}

sub _default_mbox {
  my ($self) = @_;
  return $self->{_default_mbox} if exists $self->{_default_mbox};

  # XXX: How very unixocentric of us; how can we fix this? -- rjbs, 2006-06-04
  #      It's not really broken, but it's also not very awesome.
  my $default_mbox = $ENV{MAIL};

  return $default_mbox if $default_mbox;

  my $default_maildir = File::Spec->catdir(
    File::HomeDir->my_home,
    'Maildir'
  );

  $default_mbox =
       (-d File::Spec->catdir($default_maildir, 'new') ? $default_maildir : ())
    || ((grep { -d $_ } qw(/var/spool/mail/ /var/mail/))[0] . getpwuid($>));

  return $self->{_default_mbox} = $default_mbox;
}

# XXX: This is a test case until I have a better interface.  This will make
# testing simpler! -- rjbs, 2006-06-04
sub _exit {
  my ($self, $exit) = @_;

  return $self->{_audit_opts}->{_exit}->(@_)
    if exists $self->{_audit_opts}->{_exit};

  exit $exit;
}


sub _shorthand_expand {
  # perform ~user and %Y%m%d strftime expansion
  my $self       = shift;
  my $local_opts = $self->_get_opt(\@_);
  my @out        = @_;

  my $opt = 'interpolate_strftime';
  if (
    ((exists $local_opts->{$opt} and $local_opts->{$opt})
      or $self->{_audit_opts}->{$opt})
    and grep { index($_, '%') >= 0 } @out
  ) {
    my @localtime  = localtime;
    require POSIX;
    import POSIX qw(strftime);
    @out = map { strftime($_, @localtime) } @out;
  }

  return @out = map { $self->_expand_homedir($_) } @out;
}

sub _expand_homedir {
  my ($self, $path) = @_;

  my ($user, $rest) = $path =~ m!^~(\w*)((?:[/\\]).+)?$!;

  return $path unless defined $user and defined $rest;
  my $base = (length $user) ? File::HomeDir->users_home($user)
                            : File::HomeDir->my_home;

  return "$base$rest";
}

sub accept {
  my $self = shift;

  my $local_opts = $self->_get_opt(\@_);

  return $self->{_audit_opts}->{accept}->(@_, $local_opts)
    if exists $self->{_audit_opts}->{accept};

  my @files = $self->_shorthand_expand(@_, $local_opts);

  @files = $self->_default_mbox unless @files;

  my @actually_saved_to_files = ();

  $self->_log(2, "accepting to @files");

  # from man procmailrc:
  #   If it is a directory, the mail will be delivered to a newly created,
  #   guaranteed to be unique file named $MSGPREFIX* in the specified
  #   directory.  If the mailbox name ends in "/.", then this directory  is
  #   presumed to be an MH folder; i.e., procmail will use the next
  #   number it finds available.  If the mailbox name ends in "/", then
  #   this directory is presumed to be a maildir folder; i.e., procmail will
  #   deliver the message to a file in a  subdirectory named  "tmp" and
  #   rename it to be inside a subdirectory named "new".  If the mailbox is
  #   specified to be an MH folder or maildir folder, procmail will create
  #   the necessary directories if they don't exist, rather than treat the
  #   mailbox as a non-existent filename.  When procmail is delivering to
  #   directories, you can specify multiple directories to deliver to
  #   (procmail will do so utilising hardlinks).
  #
  # for now we will support maildir and mbox delivery.
  # MH delivery remains TODO.
  my %accept_types = (
    mbox      => [],
    maildir   => [],
    mh        => [],
  );

  for my $file (@files) {
    my $mailbox_type = $self->_mailbox_type($file);
    push @{ $accept_types{$mailbox_type} }, $file;
    $self->_log(3, "$file is of type $mailbox_type");
  }

  foreach my $accept_type (sort keys %accept_types) {
    next if not @{ $accept_types{$accept_type} };
    my $accept_handler = "_accept_to_$accept_type";
    $self->_log(3,
      "calling accept handler $accept_handler(@{$accept_types{$accept_type}})"
    );
    push @actually_saved_to_files,
      $self->$accept_handler(@{ $accept_types{$accept_type} }, $local_opts);
  }

  if ((my $success_count = @actually_saved_to_files) > 0) {
    $self->_log(3,
      "delivered successfully to $success_count destinations at " . localtime
    );
    unless ((exists $local_opts->{noexit} and $local_opts->{noexit})
      or $self->{_audit_opts}->{noexit}
    ) {
      $self->_log(2, "Exiting with status DELIVERED = " . DELIVERED);
      $self->_exit(DELIVERED);
    }
  } else {
    # nothing got delivered, take emergency action.

    my $emergency = $self->_emergency_mbox;
    if (not defined $emergency) {
      $self->_log(0,
        "unable to write to @files and no emergency mailbox defined; "
        . "exiting DEFERRED"
      );
      warn "unable to write to @files";
      $self->_exit(DEFERRED);
    } else {
      if (grep { $emergency eq $_ } @files) {  # already tried that mailbox
        if (@files == 1) {
          $self->_log(0, "unable to write to @files; exiting DEFERRED");
        } else {
          $self->_log(0,
            "unable to write to any of (@files), which includes the emergency mailbox; exiting DEFERRED"
          );
        }
        warn "unable to write to @files";
        $self->_exit(DEFERRED);
      } else {
        my $accept_type    = $self->_mailbox_type($emergency);
        my $accept_handler = "_accept_to_$accept_type";
        @actually_saved_to_files = $self->$accept_handler($emergency);
        if (not @actually_saved_to_files) {
          $self->_log(0,
            "unable to write to @files or to emergency mailbox $emergency either; exiting DEFERRED"
          );
          warn "unable to write to @files" ;
          $self->_exit(DEFERRED);
        } else {
          $self->_log(0,
            "unable to write to @files; wrote to emergency mailbox $emergency."
          );
        }
      }
    }
  }
  return @actually_saved_to_files;
}

sub _mailbox_type {
  my $self = shift;
  my $file = shift;

  return 'maildir' if $file =~ m{/\z};
  return 'mh'      if $file =~ m{/\.\z};
  return 'maildir' if -d $file;

  return 'mbox';
}

sub _accept_to_mbox {
  my $self       = shift;
  my @saved_to   = ();
  my $local_opts = $self->_get_opt(\@_);

  foreach my $file (@_) {
    # auto-create the parent dir.
    if (my $mkdir_error = $self->_mkdir_p(File::Basename::dirname($file))) {
      $self->_log(0, $mkdir_error);
      next;
    }
    my $error = $self->_write_message($file,
      { need_lock => 1, need_from => 1, extra_newline => 1 });
    if (not $error) { push @saved_to, $file; }
    else { $self->_log(1, $error); }
  }
  return @saved_to;
}

sub _write_message {
  my $self       = shift;
  my $file       = shift;
  my $write_opts = shift || {};

  $write_opts->{need_from} = 1 if not defined $write_opts->{need_from};
  $write_opts->{need_lock} = 1 if not defined $write_opts->{need_lock};
  $write_opts->{extra_newline} = 0
    if not defined $write_opts->{extra_newline};

  $self->_log(3, "writing to $file; options @{[%$write_opts]}");

  my $fh = Symbol::gensym;
  unless (open($fh, ">>$file")) { return "Couldn't open $file: $!"; }

  if ($write_opts->{need_lock}) {
    my $lock_error = $self->_audit_get_lock($fh, $file);
    return $lock_error if $lock_error;
  }
  seek $fh, 0, 2;

  if (not $write_opts->{need_from} and $self->head->header->[0] =~ /^From\s/)
  {
    $self->_log(3, "mbox From line found, stripping because we're maildir");
    $self->delete_header("From ");
    $self->unescape_from();
  }

  if ($write_opts->{need_from} and $self->head->header->[0] !~ /^From\s/) {
    $self->_log(3, "No mbox From line, making one up.");
    if (exists $ENV{UFLINE}) {
      $self->_log(3,
        "Looks qmail, but preline not run, prepending UFLINE, RPLINE, DTLINE");
      print $fh $ENV{UFLINE};
      print $fh $ENV{RPLINE};
      print $fh $ENV{DTLINE};
    } else {
      my $from = (
          $self->get('Return-path')
          || $self->get('Sender')
          || $self->get('Reply-To')
          || 'root@localhost'
      );
      chomp $from;
      $from = $1 if $from =~ /<(.*?)>/; # comment <name@domain> -> name@domain
      $from      =~ s/\s*\(.*\)\s*//;   # name@domain (comment) -> name@domain
      $from =~ s/\s+//g;  # if any whitespace remains, get rid of it.

      # strip timezone.
      (my $fromtime = localtime) =~ s/(:\d\d) \S+ (\d{4})$/$1 $2/;

      print $fh "From $from  $fromtime\n";
    }
  }

  $self->_log(4, "printing self as mbox string.");
  if ($write_opts->{need_from}) {
    my $content = $self->as_string;
    $content =~ s/\nFrom /\n>From /g;
    print $fh $content;
  } else {
    print $fh $self->as_string;
  }

  # extra \n added because mutt seems to like a "\n\nFrom " in mbox files
  print $fh "\n" if $write_opts->{extra_newline};

  if ($write_opts->{need_lock}) {
    flock($fh, LOCK_UN) or return "Couldn't unlock $file";
  }

  close $fh or return "Couldn't close $file after writing: $!";
  $self->_log(4, "returning success.");
  return 0;  # success
}

sub _accept_to_mh {
  my $self       = shift;
  my @saved_to   = ();
  my $local_opts = $self->_get_opt(\@_);

  die "_accept_to_mh not implemented";
  return @saved_to;
}

# variables for accept_to_maildir

my $maildir_time    = 0;
my $maildir_counter = 0;

sub _accept_to_maildir {
  my $self       = shift;
  my @saved_to   = ();
  my $local_opts = $self->_get_opt(\@_);

  $local_opts->{one_for_all} = exists $local_opts->{one_for_all}
    ? $local_opts->{one_for_all}
    : $self->{_audit_opts}->{one_for_all};

  $self->_log(3, "will write to @_");

  # since mutt won't add a lines tag to maildir messages, we'll add it here
  # XXX: Why the nuts is this here?  This should be another method, or a
  # plugin! -- rjbs, 2006-05-30
  unless (length $self->get("Lines")) {
    my @lines = $self->body;
    @lines = @{ $lines[0] } if @lines == 1 and ref $lines[0] eq 'ARRAY';
    my $num_lines = @lines;
    $self->head->add("Lines", $num_lines);
    $self->_log(4, "Adding Lines: $num_lines header");
  }

  if ($maildir_time != time) {
    $maildir_time = time;
    $maildir_counter = 0;
  } else {
    $maildir_counter++;
  }

  # write the tmp file.
  # hardlink to all the new files.
  # unlink the temp file.

  # write the tmp file in the first writable maildir directory.

  my $tmp_path;
  foreach my $file (my @maildirs = @_) {
    $file =~ s/\/$//;
    my $tmpdir = $local_opts->{one_for_all} ? $file : "$file/tmp";

    my $msg_file;
    do {
      $msg_file = join ".",
        ($maildir_time, $$ . "_$maildir_counter", $self->{_hostname});
      $maildir_counter++;
    } while (-e "$tmpdir/$msg_file");

    $tmp_path = "$tmpdir/$msg_file";
    $self->_log(3, "writing to $tmp_path");

    # auto-create the maildir.
    if (
      my $mkdir_error = $self->_mkdir_p(
        $local_opts->{one_for_all}
        ? ($file)
        : map { "$file/$_" } qw(tmp new cur)
      )
    ) {
      $self->_log(0, $mkdir_error);
      next;
    }

    my $error
      = $self->_write_message($tmp_path, { need_from => 0, need_lock => 0 });

    # only write to the first writeable maildir
    last unless $error;

    $self->_log(1, $error);
    unlink $tmp_path;
    $tmp_path = undef;
  }

  # unable to write to any of the specified maildirs.
  if (not $tmp_path) {
    return 0;
  }

  # it is now in tmp/.  hardlink to all the new/ destinations.
  foreach my $file (my @maildirs = @_) {
    $file =~ s/\/$//;

    my $msg_file;
    my $newdir = $local_opts->{one_for_all} ? $file : "$file/new";
    $maildir_counter = 0;

    do {
      $msg_file = join ".",
        ($maildir_time = time, $$ . "_$maildir_counter", $self->{_hostname});
      $maildir_counter++;
    } while (-e File::Spec->catdir($newdir, $msg_file));

    # auto-create the maildir.
    if (
      my $mkdir_error = $self->_mkdir_p(
        $local_opts->{one_for_all}
        ? ($file)
        : map { File::Spec->catdir($file, $_) } qw(tmp new cur)
      )
    ) {
      $self->_log(0, $mkdir_error);
      next;
    }

    my $new_path = File::Spec->catfile($newdir, $msg_file);
    $self->_log(3, "maildir: hardlinking to $new_path");

    if (link $tmp_path, $new_path) {
      push @saved_to, $new_path;
    } else {
      require Errno;
      if ($! == Errno::EXDEV()) {
        # Invalid cross-device link, see /usr/**/include/*/errno.h
        $self->_log(0, "Couldn't link $tmp_path to $new_path: $!");
        $self->_log(0, "attempting direct maildir delivery to $new_path...");
        push @saved_to, $self->_accept_to_maildir($file);
        next;
      } else {
        $self->_log(0, "Couldn't link $tmp_path to $new_path: $!");
      }
    }
  }

  # unlink the temp file
  unlink $tmp_path or $self->_log(1, "Couldn't unlink $tmp_path: $!");
  return @saved_to;
}


sub reject {
  my $self = shift;

  my $local_opt = $self->_get_opt(\@_);

  return $self->{_audit_opts}->{reject}->(@_, $local_opt)
    if exists $self->{_audit_opts}->{reject};

  $self->_log(1, "Rejecting with exitcode " . REJECTED . " and reason $_[0]");

  $self->_exit(REJECTED);
}


sub resend {
  my $self       = shift;
  my $local_opts = $self->_get_opt(\@_);
  my $rcpt       = shift;

  $self->smtpsend(
    To => $rcpt,
    (exists $local_opts->{host}  ? (Host  => $local_opts->{host})  : ()),
    (exists $local_opts->{port}  ? (Port  => $local_opts->{port})  : ()),
    (exists $local_opts->{debug} ? (Debug => $local_opts->{debug}) : ()),
  );

  unless (
    (exists $local_opts->{noexit} and $local_opts->{noexit})
    or $self->{_audit_opts}->{noexit}
  ) {
    $self->_log(2, "Exiting with status DELIVERED = " . DELIVERED);
    $self->_exit(DELIVERED);
  }
}


sub pipe {
  my $self = shift;
  return $self->{_audit_opts}->{pipe}->(@_)
    if exists $self->{_audit_opts}->{pipe};

  my $local_opts = $self->_get_opt(\@_);
  my ($command) = @_;

  my ($file) = $self->_shorthand_expand($command, $local_opts);
  $self->_log(1, "Piping to $file");

  my $pipe = Symbol::gensym;
  unless (open($pipe, "|$file")) {
    $self->_log(0, "Couldn't open pipe $file: $!");
    $self->accept();
  }

  $self->print($pipe);
  close $pipe;
  my $status = $? >> 8;
  $self->_log(3, "Pipe closed with status $status");

  unless ((exists $local_opts->{noexit} and $local_opts->{noexit})
    or $self->{_audit_opts}->{noexit}
  ) {
    $self->_log(2, "Exiting with status DELIVERED = " . DELIVERED);
    $self->_exit(DELIVERED);
  }

  return $status;
}


sub ignore {
  my ($self, $reason) = @_;

  $self->_log(
    1,
    "Ignoring: " . (defined $reason ? $reason : '(no reason given)')
  );

  my $local_opts = $self->_get_opt(\@_);

  $self->_exit(DELIVERED)
    unless ((exists $local_opts->{noexit} and $local_opts->{noexit})
    or $self->{_audit_opts}->{noexit});
}


sub _reply_recipient {
  my $self = shift;

  # TODO: clean this up with Mail::Address.  right now if From: <> we barf.
  return ($self->get("Resent-From")
      || $self->get("Reply-To")
      || $self->get("From")
      || $self->get("Sender")
      || $self->get("Return-Path"));
}

sub reply {
  my $self       = shift;
  my %reply_opts = @_;
  foreach my $k (keys %reply_opts) {
    $reply_opts{ lc $k } = delete $reply_opts{$k};
  }  # lowercase option names

  # thanks to man procmailrc(1), this is ^FROM_DAEMON
  if ($self->from_daemon) {
    unless (defined $reply_opts{even_if_from_daemon}
      and $reply_opts{even_if_from_daemon}
    ) {
      $self->_log(2, "message is ^FROM_DAEMON, skipping reply");
      return "(^FROM_DAEMON, no reply)";
    }
  }

  if ( length $self->get("X-Loop")
    or length $self->get("X-Loop-Detect")
  ) {
    return "(X-Loop header found, not replying)";
  }

  require Mail::Mailer;

  my $rcpt = ($reply_opts{"to"} || $self->_reply_recipient);

  return if not $rcpt;

  my $subject = (
    $reply_opts{"subject"}
      || (
      defined $self->subject
      && length $self->subject
      ? (
        $self->subject !~ /\bRe:/i
        ? "Re: " . $self->subject
        : $self->subject
      )
      : "your mail"
      )
  );

  chomp($rcpt, $subject);

  my @references;
  @references = (
    defined $reply_opts{"references"}
    ? (
      ref($reply_opts{"references"})
      ? map { split ' ', $_ } @{ $reply_opts{"references"} }
      : split ' ', $reply_opts{"references"}
      )
    : grep { length $_ } (
      split(' ', $self->get("References")),
      split(' ', $self->get("Message-ID"))
    )
  );
  @references = grep { /^<.*>$/ } @references;

  my %headers = (
    To      => $rcpt,
    Subject => $subject,
  );
  $headers{From}       = $reply_opts{from} if defined $reply_opts{from};
  $headers{CC}         = $reply_opts{cc}   if defined $reply_opts{cc};
  $headers{BCC}        = $reply_opts{bcc}  if defined $reply_opts{bcc};
  $headers{References} = "@references"     if @references;
  $headers{"X-Loop"}   = $reply_opts{"x-loop"} || $self->get("X-Loop") || "1";
  $headers{"X-Loop-Detect"} = $self->get("X-Loop-Detect") || "1";

  my $reply = Mail::Mailer->new(qw(sendmail));

  $reply->open(\%headers);

  print $reply (
    defined $reply_opts{body}
    ? $reply_opts{body}
    : "Your message has been received.\n");
  $reply->close;  # complete the message and send it

  $self->_log(1, "reply sent to $rcpt");
  return $rcpt;
}


sub log {
  my ($self, $priority, $what) = @_;
  return unless $self->{_log};
  return if $self->{_log}{level} < $priority;
  chomp $what;
  chomp $what;
  my ($subroutine) = (caller(1))[3];
  $subroutine =~ s/(.*):://;
  my ($line) = (caller(0))[2];
  print { $self->{_log}{fh} } "$line($subroutine): $what\n"
    or die "couldn't write to log file: $!";
}


# ----------------------------------------------------------

sub header         { $_[0]->head->as_string() }
sub add_header     { $_[0]->head->add($_[1], $_[2]); }
sub put_header     { &add_header }
sub get_header     { &get }
sub replace_header { $_[0]->head->replace($_[1], $_[2]); }
sub delete_header  { $_[0]->head->delete($_[1]); }

sub get {
  my ($self, $header) = @_;

  if (wantarray) {
    my @strings = $self->head->get($header);
    chomp @strings;
    return @strings;
  } else {
    my $string = $self->head->get($header);
    chomp($string = (defined $string && length $string) ? $string : "");
    return $string;
  }
}

# inheriting from MIME::Entity breaks this.  mengwong 20020112
sub tidy {
  $_[0]->tidy_body();
}

sub noexit {
  $_[0]->{_audit_opts}->{noexit} = $_[1] ? 1 : 0;
}


# ----------------------------------------------------------
sub from     { $_[0]->get("From") }
sub to       { $_[0]->get("To") }
sub subject  { $_[0]->get("Subject") }
sub bcc      { $_[0]->get("BCC") }
sub cc       { $_[0]->get("CC") }
sub received { $_[0]->get("Received") }

# from_mailer and from_daemon inspired by procmailrc
sub from_daemon {
  my $message = shift;
  my $head    = $message->head->dup;
  $head->unfold;
  if (
    $head->as_string =~ /(^(Mailing-List:
      |List-ID:
      |Precedence:.*(junk|bulk|list)
      |To:.*Multiple recipients of 
      |(((Resent-)?(From|Sender)|X-Envelope-From):|>?From )
      .*?\b
      (Post(ma?(st(e?r)?|n)|office)
       |(?-i)Mailer?(?i)
       |sendmail
       |daemon
       |m(mdf|ajordomo)
       |n?uucp
       |LIST(SERV|proc)
       |NETSERV
       |o(wner|ps)
       |(?-i)r(e(quest|sponse)|oot)(?i)
       |b(ounce|bs\.smtp)
       |mirror
       |s(erv(ices?|er)|mtp(error)?|ystem)
       |A(dmin(istrator)?|MMGR|utoanswer)
      )\@
      ))/imx
  ) {
    return $1;
  }
  return;
}

sub from_mailer {
  my $message = shift;
  my $head    = $message->head->dup;
  $head->unfold;
  __from_mailer($head->as_string);
}

sub __from_mailer {
  my $header = shift;

  if (
    $header =~ /
    (^(((Resent-)?(From|Sender)
     |X-Envelope-From):|>?From )
     .*?\b
     (Post(ma(st(er)?|n)|office)
     |(?-i)Mailer?(?i)
     |sendmail
     |daemon
     |mmdf
     |n?uucp
     |ops
     |(?-i)r(esponse|oot)(?i)
     |(bbs\.)?smtp(error)?
     |s(erv(ices?|er)|ystem)|A(dmin(istrator)?|MMGR)
     )\@
    )/imx
  ) {
    return $1;
  }

  return;
}

# ----------------------------------------------------------
# utility functions
# ----------------------------------------------------------

sub _audit_get_lock {
  my $self = shift;
  my $fh   = shift;
  my $file = shift;
  $self->_log(4, "  attempting to lock file $file");
  for (1 .. 10) {
    if (flock($fh, LOCK_EX)) {
      $self->_log(4, "  successfully locked file $file");
      return;
    } else {
      sleep $_ and next;
    }
  }
  $self->_log(1, my $errstr = "Couldn't get exclusive lock on $file");
  return $errstr;
}

sub _mkdir_p {  # mkdir -p (also create parents if necessary)
  my $self = shift;
  return if not @_;
  return if not length $_[0];
  foreach (@_) {
    next if -d $_;
    chop while m{/$};
    $self->_log(4, "$_ doesn't exist, creating.");
    if (my $error = $self->_mkdir_p(File::Basename::dirname($_))) {
      return $error
    }
    mkdir($_, 0755) or return "unable to mkdir $_: $!";
  }
  return;
}



1;

__END__

=pod

=head1 NAME

Mail::Audit - library for creating easy mail filters

=head1 VERSION

version 2.228

=head1 SYNOPSIS

  use Mail::Audit; # or use Mail::Audit qw(...plugins...);
 
  my $mail = Mail::Audit->new( emergency => "~/emergency_mbox");
 
  $mail->pipe("listgate p5p")            if $mail->from =~ /perl5-porters/;
  $mail->accept("perl")                  if $mail->from =~ /perl/;
  $mail->reject("We do not accept spam") if $mail->rblcheck();
  $mail->ignore                          if $mail->subject =~ /boring/i;
 
  $mail->noexit(1);
  $mail->accept("~/Mail/Archive/%Y%m%d");
  $mail->noexit(0);
 
  $mail->accept()

=head1 DESCRIPTION

F<procmail> is nasty. It has a tortuous and complicated recipe format, and I
don't like it. I wanted something flexible whereby I could filter my mail using
Perl tests.

Mail::Audit was inspired by Tom Christiansen's F<audit_mail> and F<deliverlib>
programs. It allows a piece of email to be logged, examined, accepted into a
mailbox, filtered, resent elsewhere, rejected, replied to, and so on. It's
designed to allow you to easily create filter programs to stick in a
F<.forward> file or similar.

Mail::Audit groks MIME; when appropriate, it subclasses MIME::Entity.  Read the
MIME::Tools man page for details.

=head1 CONSTRUCTOR

=over 4

=item new

  my $mail = Mail::Audit->new(%option)

The constructor reads a mail message from C<STDIN> (or, if the C<data> option
is set, from an array reference or \*GLOBref) and creates a C<Mail::Audit>
object from it.

Other options include the C<accept>, C<reject> or C<pipe> keys, which specify
subroutine references to override the methods with those names.

You are encouraged to specify an C<emergency> argument and check for the
appearance of messages in that mailbox on a regular basis.  If for any reason
an C<accept()> is unsuccessful, the message will be saved to the C<emergency>
mailbox instead.  If no C<emergency> mailbox is defined, messages will be
deferred back to the MTA, where they will show up in your mailq.

You may also specify C<< log => $logfile >> to write a debugging log.  If you
don't specify a log file, logs will be written to F<~/mail-audit.log>.   You
can set the verbosity of the log with the C<loglevel> key.  A higher loglevel
will result in more lines being logged.  The default level is 3.  To get all
internally generated logs, log at level 5.  To get none, log at -1.  

Usually, the delivery methods C<accept>, C<pipe>, and C<resend> are final;
Mail::Audit will terminate when they are done.  If you specify C<< noexit => 1
>>, C<Mail::Audit> will not exit after completing the above actions, but
continue running your script.

The C<reject> delivery method is always final; C<noexit> has no effect.

If you just want to print the message to STDOUT, $mail->print().

Percent (%) signs seen in arguments to C<accept> and C<pipe> do not undergo
C<strftime> interpolation by default.  If you want this, use the
C<interpolate_strftime> option.  You can override the "global"
interpolate_strftime option by passing an overriding option to C<accept> and
C<pipe>.

By default, MIME messages are automatically recognized and parsed.  This is
potentially expensive; if you don't want MIME parsing, use the C<nomime>
option.

You can pass further MIME options in the C<mimeoptions> variable: for example,
if you want to output_to_core (man MIME::Parser) set C<< mimeoptions =>
{output_to_core=>1} >>.

=back

=head1 DELIVERY METHODS

=over 4

=item accept

  $mail->accept(\%option, @locations);

You can choose to accept the mail into a mailbox by calling the C<accept>
method; with no argument, this accepts to F</var/spool/mail/you>. The mailbox
is opened append-write, then locked C<LOCK_EX>, the mail written and then the
mailbox unlocked and closed.  If Mail::Audit sees that you have a maildir style
system, where F</var/spool/mail/you> is a directory, it'll deliver in maildir
style.  If the path you specify does not exist, Mail::Audit will assume mbox,
unless it ends in /, which means maildir.

If multiple maildirs are given, Mail::Audit will use hardlinks to deliver to
them, so that multiple hardlinks point to the same underlying file.  (If the
maildirs turn out to be on multiple filesystems, you get multiple files.)

If you don't want the "new/cur/tmp" structure of a classical maildir, set the
one_for_all option, and you'll still get the unique filenames.

  accept( dir1, dir2, ..., { one_for_all => 1 });

If you want "%" signs to be expanded according to C<strftime(3)>, you can pass
C<accept> the option C<interpolate_strftime>:

  accept( file1, file2, ..., { interpolate_strftime => 1 });

"interpolate_strftime" is not enabled by default for two reasons: backward
compatibility (though nobody I know has a % in any mail folder name) and
username interpolation: many people like to save messages by their
correspondent's username, and that username may contain a % sign.  If you are
one of these people, you should

  $username =~ s/%/%%/g;

If your arguments contain "/", C<accept> will create arbitarily deep
subdirectories accordingly.  Untaint your input by saying

  $username =~ s,/,-,g;

By default, C<accept> is final; Mail::Audit will terminate after successfully
accepting the message.  If you want to keep going, set C<noexit>.  C<accept>
will return the filename(s) that it saved to.

  my  @pathnames = accept(file1, file2, ..., { noexit => 1 });
  my ($pathname) = accept(file1);

If for any reason C<accept> is unable to write the message (eg. you're over
quota), Mail::Audit will attempt delivery to the C<emergency> mailbox.  If
C<accept> was called with multiple destinations, the C<emergency> action will
only be taken if the message couldn't be delivered to any of the desired
destinations.  By default the C<emergency> mailbox is set to the system
mailbox.  If we were unable to save to the emergency mailbox, the message will
be deferred back into the MTA's queue.  This happens whether or not C<noexit>
is set, so if you observe that some of your C<accept>s somehow aren't getting
run, check your mailq.

If this isn't how you want local delivery to happen, you'll need to override
this method.

=item reject

  $mail->reject($reason);

This rejects the email; it will be bounced back to the sender as undeliverable.
If a reason is given, this will be included in the bounce.

This is a final delivery method.  The C<noexit> option has no effect here.

=item resend

  $mail->resend($address, \%option)

Reinjects the email in its entirety to another address, using SMTP.

This is a final delivery method.  Set C<noexit> if you want to keep going.

Other options are all optional, and include host, port, and debug; see
L<Mail::Internet/smtpsend>

At this time this method is not overrideable by an argument to C<new>.

=item pipe

  $mail->pipe($program)

This opens a pipe to an external program and feeds the mail to it.

This is a final delivery method.  Set C<noexit> if you want to keep going.  If
C<noexit> is set, the exit status of the pipe is returned.

=item ignore

  $mail->ignore;

This merely ignores the email, dropping it into the bit bucket for eternity.

This is a final delivery method.  Set C<noexit> if you want to keep going.
(Calling ignore with C<noexit> set is pretty pointless.)

=item reply

  $mail->reply(%option);

Sends an autoreply to the sender of the message.  Return value: the recipient
address of the reply.

Recognized content-related options are: from, subject, cc, bcc, body.  The "To"
field defaults to the incoming message's "Reply-To" and "From" fields.  C<body>
should be a single multiline string.

Set the option C<EVEN_IF_FROM_DAEMON> to send a reply even if the original
message was from some sort of automated agent.  What that set, only X-Loop will
stop loops.

If you use this method, use KillDups to keep track of who you've autoreplied
to, so you don't autoreply more than once.

 use Mail::Audit qw(KillDups);
 $mail->reply(body=>"I am on vacation") if not $self->killdups($mail->from);

C<reply> is not considered a final delivery method, so execution will continue
after completion.

=back

=head1 HEADER MANAGEMENT METHODS

=over

=item get_header

=item get

  my $header = $mail->get($header);

Retrieves the named header from the mail message.

=item add_header

=item put_header

  $mail->add_header($header => $value);

Inserts a new header into the mail message with the given value.  C<put_header>
is an alias for this method.

=item replace_header

  $mail->replace_header($header => $value);

Removes the old header, adds a new one.

=item delete_header

  $mail->delete_header($header);

Guess.

=back

=head1 MISCELLANEOUS METHODS

=over

=item log

  $mail->log($priority => $message);

This method logs the given message if C<$priority> is greater than the
F<loglevel> given during construction.

=item tidy

  $mail->tidy;

Tidies up the email as per L<Mail::Internet>.  If the message is a MIME
message, nothing happens.

=item noexit

  $mail->noexit($bool);

This method sets the value of C<noexit>.   If C<noexit> is true, final delivery
methods will not be considered final.

=back

=head1 ATTRIBUTE METHODS

The following attributes correspond to fields in the mail:

=over 4

=item * from

=item * to

=item * subject

=item * cc

=item * bcc

=item * received

=item * body

Returns a reference to an array of lines in the body of the email.

=item * header

Returns the header as a single string.

=item * is_mime

Am I a MIME message?  If so, MIME::Entity methods apply.  Otherwise,
Mail::Internet methods apply.

=item * from_mailer

Am I from a mailer-daemon?  See L<procmailrc>.  This method returns the part of
the header that matched.  This method's implementation of the pattern is not
identical to F<procmail>'s.

=item * from_daemon

Am I from any sort of daemon?  See L<procmailrc>.  This method returns the part
of the header that matched.  This method's implementation of the pattern is not
identical to F<procmail>'s.

=back

=head1 BUGS

Numerous and sometimes nasty.

=head1 CAVEATS

If your mailbox file in F</var/spool/mail/> doesn't already exist, you may need
to use your standard system MDA to create it.  After it's been created,
Mail::Audit should be able to append to it.  Mail::Audit may not be able to
create F</var/spool/mail> because programs run from F<.forward> don't inherit
the special permissions needed to create files in that directory.

=head1 HISTORY

Simon Cozens <simon@cpan.org> wrote versions 1 and 2.

Meng Weng Wong <mengwong@pobox.com> turned a petite demure v2.0 into a raging
bloated v2.1, adding MIME support, emergency recovery, filename interpolation,
and autoreply features.

Ricardo SIGNES <rjbs@cpan.org> took over after Meng and tried to tame the
beast, refactoring, documenting, and testing.  Thanks to Listbox.com for
sponsoring maintenance of this module!

=head1 SEE ALSO

=over 4

=item *

L<http://www.perl.com/pub/a/2001/07/17/mailfiltering.html>

=item *

L<Mail::Internet>

=item *

L<Mail::SMTP>

=item *

L<Mail::Audit::List>

=item *

L<Mail::Audit::PGP>

=item *

L<Mail::Audit::MAPS>

=item *

L<Mail::Audit::KillDups>

=item *

L<Mail::Audit::Razor>

=item *

L<Mail::Audit::Vacation>

=back

=head1 AUTHORS

=over 4

=item *

Simon Cozens

=item *

Meng Weng Wong

=item *

Ricardo SIGNES

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2000 by Simon Cozens.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
