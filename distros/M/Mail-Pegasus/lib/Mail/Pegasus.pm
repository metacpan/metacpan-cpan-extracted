#!/usr/bin/perl -w
#

package Mail::Pegasus;

require 5.005;

use strict;

use vars qw($VERSION);

#use IO::Scalar;
use Mail::Internet;

$VERSION=sprintf("%d.%02d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/);

my $debug = 0;
my $directory = undef;
my $heirarch = "HIERARCH.PM";

sub new
{
  my $self =  shift;
  my $this = {};
  my %arg = @_;

  $debug = (exists $arg{Debug} ? $arg{Debug} : 0 );
  $this->{heirarch} = (exists $arg{Heirarch} ? $arg{Heirarch} : "HIERARCH.PM" );
  $this->{directory} = (exists $arg{Directory} ? $arg{Directory} : undef );

  bless $this;

  &init($this);
  return $this;
}

sub init
{
  my $self = shift;

  my %folders=();
  my %parents=();
  my $parentrootid=1;
  my @parentroots=();
  my %ifolders=();

  $self->{'folders'} = \%ifolders;

  warn("Directory: $self->{directory}\n");
  if ((!defined($self->{directory})) || (! -d $self->{directory}))
  {
    warn("You must specify a valid directory!\n");
    return;
  }

  my $h = $self->{directory} . "/" . $self->{heirarch};
  if ((! -f $h) || (! -r $h))
  {
    warn("cannot read hierachy file!\n");
    return;
  }

  open(HFD,"<$h");
  while(!eof(HFD))
  {
    my @fields;
    my ($line, $n1, $n2, $folderid, $parent, $name);

    chomp($line=<HFD>);
    $line =~ s/\r$//;
    printf("<<$line\n") if ($debug);
    @fields = split(/,/,$line);
    if (scalar @fields != 5)
    {
      warn("Can't parse line [$line]\n");
    }
    map($_ =~ s/^"//,@fields);
    map($_ =~ s/"$//,@fields);
    $n1 = $fields[0];
    $n2 = $fields[1];
    $folderid = $fields[2];
    $parent = $fields[3];
    $name = $fields[4];
    if ($folderid eq "")
    {
      warn("Found BLANK folder ID in line [$line]. Skipping\n");
      next;
    }
    if ($parent eq "")
    {
      if ($folderid =~ /:My mailbox$/)
      {
        $parent = "TOP00";
      } else {
        $parent = sprintf("TOP%.2d",$parentrootid++);
      }
      push(@parentroots,$parent);
    }
    printf(">>%s,%s,%s,%s,%s\n",$n1,$n2,$folderid,$parent,$name) if ($debug);

    if (exists($folders{$folderid}))
    {
      warn("Found duplicate folder ID $folderid\n");
    } else {
      $folders{$folderid} = {
                              'n1'      => $n1,
                              'n2'      => $n2,
                              'parent'  => $parent,
                              'name'    => $name,
                              'used'    => 0,
                            };
      printf("++%s->%s\n",$folderid, $parent) if ($debug);
      push(@{$parents{$parent}},$folderid);
    }
  }
  foreach my $parentroot (sort @parentroots)
  {
    &recursefolders(\%ifolders, \%parents, \%folders, $parentroot,$parentroot);
  }
  foreach my $ifolder (sort {length($a) <=> length($b)} keys %ifolders) {
    my $file = sprintf("%s/%s.PMM",$self->{directory},$ifolders{$ifolder});
    if (-f $file)
    {
      $ifolders{$ifolder} = $file;
    } else {
      $ifolders{$ifolder} = "";
    }
    printf("%s -> %s\n",$ifolder,$ifolders{$ifolder}) if ($debug);
  }
  close(FD);

  # INBOX is a special case and partly a hack.
  $ifolders{'INBOX'} = "INBOX";
  $self->{Folders} = \%ifolders;
}

sub recursefolders
{
  my $ifolders = shift;
  my $parents = shift;
  my $folders = shift;
  my($parent,$path) = @_;
  my($fpath,$folder);
  foreach my $folderid (@{$parents->{$parent}}) {
    $fpath = sprintf("%s|%s",$path,$folders->{$folderid}->{name});
    # printf(">>>%s\n",$fpath);
    if (exists($parents->{$folderid})) {
      &recursefolders($ifolders,$parents,$folders,$folderid,$fpath);
    } else {
      printf(">>>%s\n",$fpath) if ($debug);
      $fpath =~ s/^TOP\d{2}\|//;
      $fpath =~ s/^My mailbox\|//;
      $fpath =~ s/\|/\//g;
      $folderid =~ s/^[0-9A-F]+://;
      $folderid =~ s/^[0-9A-F]{4}://;
      $ifolders->{$fpath} = $folderid;
    }
  }
}

sub select_by_id
{
  my $self = shift;
  my $f = shift;
  my $result = undef;

  $self->{'Selected'} = undef;

  if ($f !~ /^\d+$/)
  {
    warn("You must specify a number!\n");
  } else {
    if (defined($self->{Folders}))
    {
      my $x = $self->{Folders};
      my $count = 1;
      my $fname;
      foreach my $fi (sort keys %$x)
      {
        $fname = $fi;
        last if ($count eq $f);
        $count++;
      }
      $f = $fname;
      warn("select(): selected->$f\n") if ($debug);
      &select($self, $f);
      $result = $self;
    }
  }
  return $result;
}

sub select
{
  my $self = shift;
  my $f = shift;
  my $result = undef;

  $self->{'Selected'} = undef;

  if ($f eq "")
  {
    warn("You must specify a folder name or number!\n");
  } else {
    if (defined($self->{Folders}))
    {
      my $x = $self->{Folders};

      if (defined($x->{$f}) && $x->{$f} ne "")
      {
        $self->{Selected} = $x->{$f};
        if ($f eq "INBOX")
        {
          build_inbox_hash($self);
        } else {
          build_folder_hash($self);
        }
        $result = $self;
      } else {
        warn("$f does not appear to exist!\n");
      }
    }
  }
  return $result;
}

sub list_folders
{
  my $self = shift;
  my $folder_array = [ ];

  foreach my $folder (sort keys %{$self->{Folders}})
  {
    push(@$folder_array, $folder);
  }
  warn("\@folder_array contains: \"" . join("\", \"", @$folder_array) . "\"\n") if ($debug);
  return $folder_array;
}

sub print_folders
{
  my $self = shift;
  my $count = 1;

  foreach my $folder (sort keys %{$self->{Folders}})
  {
    printf("%d. %s\n", $count, $folder);
    $count++;
  }
}

sub find_first_message
{
  my $self = shift;
  my $file;
  my $data;
  my $count = 0;
  my $ffile;

  if (!defined($self->{Selected}))
  {
    warn("No folder selected!\n");
    return undef;
  }
  $file = $self->{Selected};
  warn("find_first_message(): selected->$file\n") if ($debug);

  if (!-r $file)
  {
    die("Cannot Open File: $@");
  }

  $file =~ /^[\S+\/]*\/(\S+)\.PMM$/ && ($ffile = $1);

  open FOLDER, "$file";
  until ($data =~ /$ffile/ || eof FOLDER)
  {
    seek FOLDER, $count++, 0; # 0 = SEEK_SET
    read FOLDER, $data, length($ffile); # read until we find the folder name
  }
  warn("find_first_message(): Found filename [$ffile] at $count byte\n") if ($debug);
  $count += length($ffile);
  $count++;

  # this is a really bad hack, but it seems to work..
  until ($data =~ /R/ || eof FOLDER)
  {
    read FOLDER, $data, 1, $count++;
  }
  # $count now has the starting byte in the file of the first message
  close FOLDER;
  return $count;
}

sub get_message
{
  my $self = shift;
  my $id = shift;

  my $data = "";
  my $file = "";

  my $selected = $self->{Selected};
  if ($selected eq "INBOX")
  {
    $file = $self->{$selected}->{$id}->{File};
  } else {
    $file = $selected;
  }
  my $msg_start = $self->{$selected}->{$id}->{Start};
  my $msg_length = $self->{$selected}->{$id}->{Length};

  open FOLDER, "<$file";
  seek FOLDER, $msg_start, 0; # 0 = SEEK_SET
  read FOLDER, $data, $msg_length;
  close FOLDER;

  return $data;
}

sub message
{
  my $self = shift;
  my $id = shift;
  my $result = undef;

  my $message = get_message($self, $id);
  $result = new Mail::Internet [ $message =~ /(.*?\n)/g ];
  return $result;
}

sub head
{
  my $self = shift;
  my $id = shift;
  my $result = undef;

  $result = {message($self, $id)}->head();
  return $result;
}

sub body
{
  my $self = shift;
  my $id = shift;
  my $result = undef;

  $result = {message($self, $id)}->body();
  return $result;
}

sub get_message_status
{
  my $self = shift;
  my $id = shift;
  my $result = undef;

  my $message = get_message($self, $id);
  my $mail = new Mail::Internet [ $message =~ /(.*?\n)/g ];
  my $mail_headers = $mail->head();
  my $headers_ref = $mail_headers->header_hashref();
  # print Dumper($headersRef);
  if (defined($headers_ref->{'X-Pmflags'}))
  {
    $result = 1;
  }
  if (defined($headers_ref->{'X-PM-Placeholder'}))
  {
    $result = 0;
  }
  return $result;
}

sub find_message
{
  my $fh = shift;
  my $start = shift;

  my $msg = "";
  my $char = "";
  my $count = 1;
  my $eof = sprintf("%c", 26);

  seek $fh, $start, 0; # 0 = SEEK_SET
  until(eof $fh)
  {
    read $fh, $char, 4096; # average message size is less than 4k
    my $pos = index $char, $eof;
    # warn ("$count -> $pos\n") if ($debug);
    if ($pos > 0)
    {
      $count += $pos;
      last;
    } else {
      $count += 4096;
    }
  }

  # reset and read message
  seek $fh, $start, 0; # 0 = SEEK_SET
  read $fh, $msg, $count;

  return ($msg,$count);
}

sub build_inbox_hash
{
  my $self = shift;
  my $current_folder = "INBOX";
  my $id = 0;
  my $directory = $self->{directory};

  warn("Building hash for $current_folder ($directory)\n") if ($debug);

  opendir DIR, "$directory" or return undef;

  foreach my $file (readdir(DIR))
  {
    if ($file =~ /\.CNM/ && -f "$directory/$file")
    {
      my $folder_info_ref = {};
      my $size = -s "$directory/$file";
      warn("build_inbox_hash: Adding: $directory/$file ($size bytes)\n") if ($debug);
      $self->{$current_folder}->{$id} = $folder_info_ref;
      $self->{$current_folder}->{$id}->{'Start'} = 0;
      $self->{$current_folder}->{$id}->{'Length'} = $size;
      $self->{$current_folder}->{$id}->{'File'} = "$directory/$file";
      $id++;
    }
  }
  closedir DIR;
}

sub build_folder_hash
{
  my $self = shift;
  my $current_folder = $self->{'Selected'};
  my $id = 0;

  warn("Building hash for folder: $self->{'Selected'}\n") if ($debug);
  $self->{FirstMsg} = find_first_message($self);
  $self->{MessageStart} = $self->{FirstMsg};
  warn("First Message Header found at: $self->{FirstMsg}\n") if ($debug);
  open FOLDER, "<$current_folder";
  seek FOLDER, $self->{FirstMsg}, 0; # 0 = SEEK_SET
  until(eof FOLDER)
  {
    my $folder_info_ref = {};
    my ($message, $record_length) = find_message(\*FOLDER, $self->{MessageStart});

    $self->{$current_folder}->{$id} = $folder_info_ref;
    $self->{$current_folder}->{$id}->{'Start'} = $self->{MessageStart};
    $self->{$current_folder}->{$id}->{'Length'} = ($record_length-1);

    $self->{MessageStart} += $record_length;
    $id++;
  }
  close FOLDER;
}

sub messages
{
  my $self = shift;
  my $id = 0;

  if (!defined($self->{Selected}))
  {
    warn("No folder selected!\n");
  } else {
    my $file = $self->{Selected};
    foreach my $f (sort keys %{$self->{Folders}})
    {
      if ($file eq $self->{Folders}->{$f})
      {
        print "Folder: $f\n" if ($debug);
        last;
      }
    }

    until(!defined($self->{$self->{'Selected'}}->{$id}))
    {
      $id++;
    }
  }
  return $id;
}

sub list_messages
{
  my $self = shift;
  my $result = undef;
  my $id = 0;
  my $ret = 0;

  my $data;
  my $date;
  my $subject;

  if (!defined($self->{Selected}))
  {
    warn("No folder selected!\n");
  } else {
    $ret = 1;
    my $file = $self->{Selected};
    foreach my $f (sort keys %{$self->{Folders}})
    {
      #print "Folder: $self->{Folders}->{$f}\n";
      if ($file eq $self->{Folders}->{$f})
      {
        print "Folder: $f\n";
        last;
      }
    }

    until(!defined($self->{$self->{'Selected'}}->{$id}))
    {
      my $message = get_message($self, $id);
      # print("Message:\n" . $message . "\n");
      my $mail = new Mail::Internet [ $message =~ /(.*?\n)/g ];
      my $mail_headers = $mail->head();
      my $headers_ref = $mail_headers->header_hashref();
      if (defined($headers_ref->{'Date'}))
      {
        $date = join(", ", @{$headers_ref->{'Date'}});
        chomp($date);
        $date =~ s/\(\S+\)//g;
      } else {
        $date = "No Date Header!";
      }
      if (defined($headers_ref->{'Subject'}))
      {
        $subject = join("", @{$headers_ref->{'Subject'}});
        $subject =~ s/\n//g;
        chomp($subject);
      } else {
        $subject = "[No Subject]";
      }
      printf("ID: $id \tDate: $date \tSubject: $subject\n");
      $id++;
    }
  }
  return $ret;
}

1;

__END__

=head1 NAME

Mail::Pegasus - read Pegasus Mail folders and messages.

=head1 SYNOPSIS

This is a Perl Module to provide read only access to messsages in
a C<Pegasus> Mailbox folder.

=head1 CONSTRUCTOR

The following method contructs a new C<Mail::Pegasus> object:

=over 4

=item new ( Directory => $directory, [ OPTIONS ] )

C<Directory> is a required argument in the form of a key-value
pair, jusr like a hash table.  It will identify the mailbox
heirarchy for the Pegasus mail folder.

C<OPTIONS> is a list of options given in the form of key-value
pairs, just like a hash table.  Valid options are

=over 8

=item B<Debug>

The value of this option should be a C<1> or a C<0>.  When set to
1 extensive debug information is sent to I<STDERR>

=item B<Heirarch>

The value of this option should be the name of the HEIRARCHY.PM
file in the target Pegasus mail folder.  The default for this option
is 'HEIRARCHY.PM' (all upper case).

=back

A HEIRARCHY.PM file is expected and required in the directory
supplied to the constructor.

=back

=head1 METHODS

=over 4

=item init ( )

Will read the heirarchy file reinitialising the folder list.

=item print_folders ( )

Will provide a text list of folder names prefixed with a numeric
folder identifier.  The identifier may then be used to select a
folder using the C<select_by_id> method.

=item select_by_id ( FOLDER-ID )

Will mark a folder as selected and will initialise the message list
for that folder.  The argument must be a number that identifies a
valid folder.  B<WARNING>: Everytime C<init()> is called the folder
identifiers may be changed.

=item select ( FOLDER-NAME )

Will mark a folder as selected and will initialise the message list
for that folder.  The argument must be the folder name as found in
the C<print_folders()>

=item list_folders ( )

Will return a reference to an array which will contain a list of
all Pegasus Mail folders found.

=item get_message ( MSG-ID )

Will return the entire message indexed by the I<MSG-ID> in the
currently selected folder.

=item get_message_status ( MSG-ID )

Will return a flag indicating whether the message has been read or
not.  A return of C<1> indicates the message has been read, C<0> that
the message has not been read, and I<undef> if the status headers are
not found.

=item messages ( )

Will return the number of messages in the currently selected folder.

=item list_messages ( )

Will return a visual list of messsages in the currently selected
folder.  The format of the returned list is:

ID: # Date: I<message date> Subject: <message subject>

The ID number can be used with C<get_message()> and C<get_message_status()>
to retrieve the message from the folder.

=item message ( MSG-ID )

Will return a C<Mail::Internet> object for the message specified by
I<MSG-ID> in the currently selected folder.

=item head ( MSG-ID )

Will return a C<Mail::Header> object for the message specified by
I<MSG-ID> in the currently selected folder.

=item body ( MSG-ID )

Will return a body of the message. This is a reference to an array.
Each entry in the array represents a single line in the message.

=back

=head1 EXAMPLE

This example will show the Data and Subject of every folder of a user,
then it will show the first message of the INBOX for the same user and
finally it will return the status of the first message in the INBOX.

    my $mailbox = Mail::Pegasus->new(Directory => "$ENV{USER}/pmail");

    foreach my $mailFolder (@{$mailbox->list_folders()})
    {
        $mailbox->select($mailFolder);
        print "Selected $mailFolder [" . $mailbox->messages() . " messages]\n";
        $mailbox->list_messages();
    }

    $mailbox->select("INBOX");
    print $mailbox->get_message("1");
    my $status = $mailbox->get_message_status("1");

    if (defined($status))
    {
        print "Message has " . ($status ? "" : "not ") . "been read!\n";
    } else {
        print "Unable to determine the message status!\n";
    }

    exit;

=head1 BUGS

Known issues are:

    Drives and Paths in the heirarchy file will cause the folder
    not to be read.

    If present a seperate folder called INBOX will not be accessable.

    Duplicate folder names render the first read folders with the
    same name inaccessable.

=head1 SEE ALSO

L<Mail::Internet>
L<Mail::Header>

=head1 AUTHOR

Matthew Sullivan <sorbs@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004 Matthew Sullivan & Rodney McDuff. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
