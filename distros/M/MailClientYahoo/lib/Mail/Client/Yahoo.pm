package Mail::Client::Yahoo;

use 5.006;
our $VERSION = 1.0;

#***** Interface *****#

sub login;
sub logout;

sub folder_list;
sub select_folder;

sub folder_size;
sub folder_count;

sub message_list;

sub message_size;
sub message_head;
sub message_body;
sub message;

sub move_message;
sub delete_message;

sub send_message;

sub empty_trash;

#***** Implementation *****#

use WWW::Mechanize;
use HTML::TableExtract;
use Mail::Header;
use Mail::Internet;

our %URLs = (
  login   => 'http://mail.yahoo.com/',
  slogin  => 'https://login.yahoo.com/config/login?.src=ym',
  logout  => 'Logout',
  folders => 'Folders',
  box     => 'ShowFolder?sort=date&order=up&box=%s',
  msghead => 'ShowLetter?bodyPart=HEADER&box=%s&MsgId=%s',
  msgbody => 'ShowLetter?bodyPart=TEXT&box=%s&MsgId=%s',
  message => 'ShowLetter?box=%s&MsgId=%s',
  movemsg => 'ShowLetter?MOV=1&.crumb=%s&box=%s&destBox=%s&MsgId=%s',
  delmsg  => 'ShowLetter?DEL=%A0Delete%A0&box=%s&MsgId=%s',
  sendmsg => 'Compose',
);

our %Patterns = (
  login_form    => 'login_form',
  user_field    => 'login',
  pass_field    => 'passwd',

  move_form     => 'showLetter',
  crumb_field   => '.crumb',

  delete_form   => 'showLetter',
  delete_field  => 'DEL',

  send_form     => 'Compose',
  to_field      => 'To',
  cc_field      => 'Cc',
  bcc_field     => 'Bcc',
  subject_field => 'Subj',
  body_field    => 'Body',
  html_field    => 'Format',
  html_value    => 'html',
  save_field    => 'SaveCopy',
  save_value    => 'yes',
  attach_field  => 'ATT',
  attach_value  => '1',
  send_button   => 'SEND',
  send_error    => qr/class="errmsg"/i,

  attach_form   => 'Attachments',
  first_field   => 'userFile0',
  second_field  => 'userFile1',
  third_field   => 'userFile2',
  attach_button => 'UPL',

  aconfirm_form => 'Compose',

  folder_link   => qr/\/ShowFolder\?.*\bbox=((?:%40B%40)?([^&]+))/,
  folder_size   => qr/(\d+[MKB])/i,
  folder_unread => qr/(\S+)/,

  message_link  => qr/\/ShowLetter\?.*\bMsgId=([^&]+)/,
  message_size  => qr/(\d+[MKB])/i,

  first_link    => qr/^First$/,
  next_link     => qr/^Next$/,

  empty_link    => qr/^Empty$/,

  bad_user      => qr/This Yahoo! ID does not exist/i,
  bad_pass      => qr/invalid password/i,

  folder_stats  => {
    'name'      => 'Name',
    'count'     => 'Messages',
    'unread'    => 'Unread',
    'size'      => 'Size',
  },
  message_stats => {
    'from'      => 'Sender',
    'link'      => 'Subject',
    'date'      => 'Date',
    'size'      => 'Size',
  },
);

sub DESTROY {
  my $self = shift;
  $self->logout();
}

sub error {
  my $self = shift;
  $self->{error}->(@_);
}

sub login {
  my $class = shift;
  my $self  = bless {}, $class;
  my %args  = @_;

  $self->{error} = sub {
    my $msg = $self->{mech}->res->message;
    $msg = shift()."\n" if $msg =~ /^OK/;
    ($args{error} || sub { die @_ })->(
      "$self->{phase} failed on $self->{step}: $msg"
    );
  };

  my $mech = $self->{mech} = Mail::Client::Yahoo::Mechanize->new(
    autocheck => 1,
    onerror   => $self->{error},
    onwarn    => $self->{error},
  );

  $self->{phase} = 'Login';

  $self->{step} = 'Front Page Retrieval';
  $mech->get($args{secure} ? $URLs{slogin} : $URLs{login});

  $self->{step} = 'Login Submission';
  $mech->submit_form(
    form_name => $Patterns{login_form},
    fields => {
      $Patterns{user_field} => $args{username},
      $Patterns{pass_field} => $args{password},
    },
  );

  $self->{step} = 'Redirection';
  while(my $redir = $mech->res->header('Location')) {
    $mech->get($redir);
  }
  if ( $mech->content =~ m#window.location.replace\("([^"]*?)"# ) {
    $mech->get($1);
  }

  $self->{step} = 'Login';
  if($mech->content =~ $Patterns{bad_user}) {
    $self->error("Invalid username");
  } elsif($mech->content =~ $Patterns{bad_pass}) {
    $self->error("Invalid password");
  }

  $self->{connected} = 1;

  return $self;
}

sub logout {
  my $self = shift;
  return unless $self->{connected};

  $self->{phase} = 'Logout';
  $self->{step}  = 'Logout Submission';
  $self->{mech}->get($URLs{logout});

  undef $self->{mech};
  %$self = ();

  return $self;
}


sub _fetch_folder_stats {
  my $self = shift;

  $self->{step} = 'Folder Stats Retrieval';
  
  $self->{mech}->get($URLs{folders});

  my @stats = keys %{$Patterns{folder_stats}};
  my @cols  = @{$Patterns{folder_stats}}{@stats};

  my $te = new HTML::TableExtract(headers => [@cols], keep_html => 1);
  $te->parse($self->{mech}->content);

  foreach my $row ($te->rows) {
    my %stats;
    @stats{@stats} = @$row;
    next unless $stats{name} =~ $Patterns{folder_link};
    $stats{box} = $1;
    $stats{name} = $2;
    $stats{size} = $1 if $stats{size} =~ $Patterns{folder_size};
    $stats{unread} = $1 if $stats{unread} =~ $Patterns{folder_unread};
    %{$self->{folder_list}{$stats{name}}} = %stats;
  }
}

sub folder_list {
  my $self = shift;
  $self->{phase} = 'Folder List';
  $self->_fetch_folder_stats() unless exists $self->{folder_list};
  return keys %{$self->{folder_list}};
}

sub select_folder {
  my $self = shift;
  my $name = shift;

  return if $name eq $self->{current_folder};

  $self->{phase} = 'Select Folder';

  $self->_fetch_folder_stats() unless exists $self->{folder_list};

  $self->{step} = 'Folder Existance';

  $self->error("Folder `$name' does not exist")
    unless exists $self->{folder_list}{$name};

  $self->{current_folder} = $name;

  delete $self->{message_list};
  delete $self->{message_stats};

  return $self->{folder_list}{$name}{size};
}

sub folder_size {
  my $self = shift;
  my $box  = shift() || $self->{current_folder};
  $self->{phase} = 'Folder Size';
  $self->_fetch_folder_stats() unless exists $self->{folder_list};
  return $self->{folder_list}{$box}{size};
}

sub folder_count {
  my $self = shift;
  my $box  = shift() || $self->{current_folder};
  $self->{phase} = 'Folder Count';
  $self->_fetch_folder_stats() unless exists $self->{folder_list};
  return $self->{folder_list}{$box}{count};
}


sub _fetch_message_list {
  my $self = shift;

  $self->{step} = 'Message List Retrieval';

  $self->error('No folder selected') unless defined $self->{current_folder};

  # Read the folder, and make sure we're on the first page
  $self->{mech}->get(sprintf $URLs{box}, $self->{current_folder});
  $self->{mech}->follow_link(text_regex => $Patterns{first_link});

  do {
    my @stats = keys %{$Patterns{message_stats}};
    my @cols  = @{$Patterns{message_stats}}{@stats};
    my $te = new HTML::TableExtract(headers => [@cols], keep_html => 1);
    $te->parse($self->{mech}->content);
    foreach my $row ($te->rows) {
      my %stats;
      @stats{@stats} = @$row;
      next unless $stats{link} =~ $Patterns{message_link};
      $stats{msgid} = $1;
      $stats{size} = $1 if $stats{size} =~ $Patterns{message_size};
      push @{$self->{message_list}}, $stats{msgid};
      %{$self->{message_stats}{$stats{msgid}}} = %stats;
    }
  } while($self->{mech}->follow_link(text_regex => $Patterns{next_link}));
}


sub _id_or_index {
  my $self = shift;
  my $i    = shift;

  $self->_fetch_message_list() unless exists $self->{message_list};

  return $i if exists $self->{message_stats}{$i};
  return $self->{message_list}[$i] if 0 <= $i && $i < @{$self->{message_list}};
  $self->error("Invalid message id: $i");
}


sub message_list {
  my $self = shift;
  $self->{phase} = 'Message List';
  $self->_fetch_message_list() unless exists $self->{message_list};
  return @{$self->{message_list}};
}


sub message_size {
  my $self = shift;

  $self->{phase} = 'Message Size';
  $self->{step}  = 'Message Size';

  my $msgid = $self->_id_or_index(shift);

  return $self->{message_stats}{$msgid}{size};
}

sub message_head {
  my $self = shift;

  $self->{phase} = 'Message Headers';
  $self->{step}  = 'Header Retrieval';

  my $msgid = $self->_id_or_index(shift);

  $self->{mech}->get(sprintf $URLs{msghead}, $self->{current_folder}, $msgid);

  return Mail::Header->new([split /(?<=\n)/, $self->{mech}->content]);
}

sub message_body {
  my $self = shift;

  $self->{phase} = 'Message Body';
  $self->{step}  = 'Body Retrieval';

  my $msgid = $self->_id_or_index(shift);

  $self->{mech}->get(sprintf $URLs{msgbody}, $self->{current_folder}, $msgid);

  return Mail::Internet->new(
    Body => [split /(?<=\n)/, $self->{mech}->content],
  );
}

sub message {
  my $self = shift;

  $self->{phase} = 'Message';
  $self->{step}  = 'Message Retrieval';

  my $msgid = $self->_id_or_index(shift);

  return Mail::Internet->new(
    Header => $self->message_head($msgid),
    Body   => $self->message_body($msgid)->body,
  );
}


sub move_message {
  my $self = shift;

  $self->{phase} = 'Move Message';
  $self->{step} = 'Input Validation';

  my $msgid = $self->_id_or_index(shift);
  my $dest = shift;

  $self->error("Invalid folder")
    unless exists $self->{folder_list}{$dest};

  $self->{step} = 'Message Selection';
  $self->{mech}->get(sprintf $URLs{message}, $self->{current_folder}, $msgid);

  # Would that I could just submit the 'Move to folder' form,
  # but alas, HTML::Form (and by extension WWW::Mechanize)
  # doesn't allow a SELECT to take on a value not in the OPTION
  # list. It doesn't even provide a way to override it.  Crappy. :(
  # So, instead, I must extract the crumb and fetch manually.
  $self->{step} = 'Move Submission';
  $self->{mech}->form_name($Patterns{move_form});
  my $crumb = $self->{mech}->current_form->value($Patterns{crumb_field});
  $self->{mech}->get(
    sprintf $URLs{movemsg}, $crumb, $self->{current_folder}, $dest, $msgid
  );
}

sub delete_message {
  my $self = shift;

  $self->{phase} = 'Delete Message';
  $self->{step} = 'Input Validation';

  my $msgid = $self->_id_or_index(shift);

  $self->{step} = 'Message Selection';
  $self->{mech}->get(sprintf $URLs{message}, $self->{current_folder}, $msgid);

  $self->{step} = 'Delete Submission';
  $self->{mech}->submit_form(
    form_name => $Patterns{delete_form},
    button    => $Patterns{delete_field},
  );
}


sub send_message {
  my $self = shift;
  my %args = @_;
  my $mech = $self->{mech};

  $self->{phase} = 'Send Message';

  $self->{step} = 'Input Validation';
  $self->error('No recipient specified') unless exists $args{to};
  $self->error('No subject specified')   unless exists $args{subject};
  $self->error('No body specified')      unless exists $args{body};

  $self->{step} = 'Form Retrieval';
  $mech->get($URLs{sendmsg});

  if($args{attach}) {
    $self->{step} = 'Attach Files';
    $mech->submit_form(
      form_name => $Patterns{send_form},
      fields => {
        $Patterns{attach_field}  => $Patterns{attach_value},
      },
    );
    $mech->submit_form(
      form_name => $Patterns{attach_form},
      fields => {
        @$args{attach} >= 0 ? ($Patterns{first_field}  => $args{attach}[0]) :()
,
        @$args{attach} >= 1 ? ($Patterns{second_field} => $args{attach}[1]) :()
,
        @$args{attach} >= 2 ? ($Patterns{third_field}  => $args{attach}[2]) :()
,
      },
      button => $Patterns{attach_button},
    );
    $mech->submit_form(
      form_name => $Patterns{aconfirm_form},
    )
  }

  # HTML::Form doesn't allow you to set the value of certain inputs to
  # something other than the values supplied by the webpage.  Nor does
  # it provide a way to add new values to that list.  However, some
  # websites use JavaScript to set the inputs to new values, and we
  # need to emulate that.  Thus, we have to manually add the value to
  # the list of possible values, and then select it.
  $mech->form_name($Patterns{send_form});
  if($args{html}) {
    my $cb = $mech->current_form()->find_input($Patterns{html_field}, undef, 0)
;
    push @{$cb->{menu}}, $Patterns{html_value};
    $cb->value($Patterns{html_value});
  }

  $mech->submit_form(
    form_name => $Patterns{send_form},
    fields => {
      (exists $args{to}      ? ($Patterns{to_field}      => $args{to})     :())
,
      (exists $args{cc}      ? ($Patterns{cc_field}      => $args{cc})     :())
,
      (exists $args{bcc}     ? ($Patterns{bcc_field}     => $args{bcc})    :())
,
      (exists $args{subject} ? ($Patterns{subject_field} => $args{subject}):())
,
      (exists $args{body}    ? ($Patterns{body_field}    => $args{body})   :())
,
      (
        exists $args{save}   ? (
          $Patterns{save_field} => $args{save} ? $Patterns{save_value} : undef,
        ) : ()
      ),
    },
    button => $Patterns{send_button},
  );

  if($mech->response->as_string() =~ $Patterns{send_error}) {
    $self->error('Error sending message');
  }
}


sub empty_trash {
  my $self = shift;

  $self->{phase} = 'Empty Trash';
  $self->{step}  = 'Folder List Retrieval';
  $self->{mech}->get($URLs{folders});

  $self->{step}  = 'Empty Submission';
  $self->{mech}->follow_link(text_regex => $Patterns{empty_link});
}


#***** WWW::Mechanize Subclass *****#

package Mail::Client::Yahoo::Mechanize;

use base 'WWW::Mechanize';

# We subclass WWW::Mechanize to try to catch error messages from Yahoo
sub get {
  my $self = shift;
  my $resp = $self->SUPER::get(@_);

  # This might be a little fragile.  Not too much, though.
  if(
      $self->content =~ /<!--\s*start error\s*-->/
        &&
      $self->content =~ /<!--\s*end error\s*-->/
        &&
      $self->content =~ /<!--\s*error code:\s+((?:\w+\s?)+)\s+-->/
  ) {
    $self->die("Yahoo error: $1");
  }

  return $resp;
}

=head1 NAME

Mail::Client::Yahoo - Programmatically access Yahoo's web-based email

=head1 SYNOPSIS

  use Mail::Client::Yahoo;

  $y = Mail::Client::Yahoo->login(
    username => 'bob',
    password => 'secret',
    secure   => 1,            # for the paranoid and patient
  );

  $y->select_folder('Inbox');

  $m = $y->message(0);        # is equivalent to...
  @ids = $y->message_list();
  $y->message($id[0]);

  $y->delete_message(0);

  $y->logout();

=head1 DESCRIPTION

This module allows you to access your web-based Yahoo Mail account
programatically.  Similar in function to L<Mail::Webmail::Yahoo>, this
module is more geared towards manipulation of individual messages,
rather than simple bulk download.  This module is also probably more
reliable than L<Mail::Webmail::Yahoo>, as well.

=head1 METHODS

=head2 login( %options )

Creates a new Mail::Client::Yahoo object, and logs in to the Yahoo
Mail server.  You must include the C<username> and C<password>
options.  (The username and password is sent over a secure HTTPS
connection.)

You may also include an C<error> option, which should be a reference
to a subroutine to be called if there is an error.  The default
handler simply dies.

You may also include a C<secure> option, which should be either 0 or
1.  If C<secure> is 1, the session uses a secure HTTPS connection,
instead of a standard HTTP connection (the default).  Note that the
secure connection will be slower, and the username and password are
always sent over HTTPS, regardless of the value of C<secure>.

=head2 logout( )

Log out, and disconnect from the server.

=head2 folder_list( )

Returns a list of the names of all available folders.

=head2 select_folder( $name )

Selects the current working folder.  This must be done before any of
the message methods may be used.

=head2 folder_size( $name )

Returns the size of a folder, as give by Yahoo.  This size will
usually be a string ending in `K', which gives the number of kilobytes
in the message.  This is not an exact size.

=head2 folder_count( $name )

Returns the number of messages in a folder.

=head2 message_list( )

Returns an array containing the message-id's of all the messages in
the current folder.

=head2 message_size( $msgid_or_index )

Returns the size of the message, as given in the folder listing.  As
with the folder size, it is not exact, and will most likely be a
number followed by a `K' or `M', indicating kilobytes and megabytes,
respectively.

Note: The parameter passed may either be a message-id, such as
returned from the L<message_list( )> function, or the index of a
message in that list.

=head2 message_head( $msgid_or_index )

Returns a L<Mail::Header> object containing the headers of the message.

=head2 message_body( $msgid_or_index )

Returns a L<Mail::Internet> object containing the body of the message.
Note that the returned object contains B<only> the body of the
message; the headers are left empty.

This is the complete (possibly MIME-encoded) message body, including
any attachments.

=head2 message( $msgid_or_index )

Returns a L<Mail::Internet> object containing both the headers and
body of the message.

This is the complete message, including any attachments.

=head2 move_message( $msgid_or_index, $folder_name )

Moves a message from the current folder to another folder.

=head2 delete_message( $msgid_or_index )

Moves a message from the current folder to the special Trash folder.
Note that the Trash folder is not emptied automatically (though it may
be purged by Yahoo at random times).

=head2 send_message( %options )

Sends a message via the Yahoo website.  You must specify a primary
recipient via C<to>, a C<subject>, and a C<body>.  You may also
specify additional recipients via C<cc> and C<bcc>, a boolean
indicating whether to save the message in your Sent folder via
C<save>, and a boolean indicating whether the body contains HTML
formatting via C<html>.

Additionally, you can specify an array reference via C<attach>
containing a list of up to three file names to upload as attachments.

=head2 empty_trash( )

Removes all messages from the Trash folder.  These messages are
permanently lost.

=head1 SEE ALSO

L<Mail::Header>, L<Mail::Internet>, L<WWW::Mechanize>, L<HTML::TableExtract>

=head1 AUTHOR

Copyright (C) 2004, Cory Johns.

This module is free software; you can redistribute and/or
modify it under the same terms as Perl itself.

Address bug reports and comments to: 
Cory Johns E<lt>L<johnsca@cpan.org>E<gt>

=cut

