require 5.008008;
package Maildir::Lite;

use strict;
use Sys::Hostname 'hostname';
use File::Sync 'fsync';
use Carp;

our $VERSION ='0.02';


=head1 NAME

Maildir::Lite - A very simple implementation of Maildir

=head1 SYNOPSIS

Write to a file handle:

   my $mdir=Maildir::Lite->new(dir=>'/home/d/.maildir');
   ...
   # write messages
   my ($fh,$status)=$mdir->creat_message();
   die "creat_message failed" if $status;

   print $fh "Content-Type: text/plain\n"
             ."Date: $date\n"
             ."From: $from\n"
             ."To: $to\n"
             ."Subject: $subject\n\n"
             ."$message";

   die "delivery failed!\n" if $mdir->deliver_message($fh);

Write string and deliver message directly:

   my $status=$mdir->creat_message($email_content);
   die "creat_message failed" if $status;

Read new messages given a file handle:

   my ($fh,$status)=$mdir->get_next_message("new");
   unless($status) {
      while(<$fh>) { # read message
         ...
      }
   }
   $mdir->act($fh,'S'); # flag message as seen and move to cur

Read new messages into an array and flag message as seen while moving it to cur:

   my ($fh,$status)=$mdir->get_next_message("new",\@lines,'S');

=head1 DESCRIPTION

This is a simple and very light implementation of Maildir as specified 
by D. J. Bernstein at L<http://cr.yp.to/proto/maildir.html>

This module provide the user with a simple interface to reading and writing 
email messages to maildir folders. Some additional useful features are also 
supported (e.g. support for additional subdirecties and user defined actions 
for the maildir flags).

=cut



=head2 Methods

=cut

=head3 new

   my $maildir = Maildir::Lite->new();

   my $maildir = Maildir::Lite->new(create=>1,
      dir=>'.maildir/', mode=>0750, sort=>'asc');


=over 4

=item * C<create> - if set to 0, the directory and the subdirectories will 
not be created and are assumed to exist.

=item * C<dir> - the maildir directory; it defaults to F<~/.maildir> 
(if C<$ENV{HOME}> exits).

=item * C<mode> - the (default 0750) directory permissions of C<dir> and 
sub-directories.

=item * C<uniq> - set unique integer which will be otherwise randomly 
generated for filennames; it is important that uniq is actually unique.

=item * C<sort> - the read messege sorting method. See L</sort>.

=back

=cut


sub new {
   my($class,%args)=@_;

   my $create=exists $args{create} ? $args{create} : 1;
   my $dir=exists $args{dir} ? $args{dir} : 
               exists $ENV{HOME} ? "$ENV{HOME}/.maildir" : undef;
   my $mode=exists $args{mode} ? $args{mode} : 0750; 
   my $uniq=exists $args{uniq} ? $args{uniq} : int(rand(10000));
   my $sort=exists $args{sort} ? $args{sort} : 'non';

   my $self= {
      __create          =>      $create,
      __dir             =>      $dir,
      __uniq            =>      $uniq,
      __mode            =>      $mode,
      __message_fh      =>      {}, # keep track of fh/fname based on fileno
                                    # for open messages to be written
      __read_messages   =>      {},   # list of messages to be read
      __last_sort       =>      undef, #keep track of last sort method
      __sort            =>      $sort,  #current sort method
      __force_readdir      =>      0,  #force readdir
      __default_act     =>      'seen',
      __folder_actions  =>      {
         new =>  { 'default' => \&new_to_cur },
         tmp =>  { 'default' => 'close' },
         cur =>  { 'default' => 'close' }
      }
   };

   bless($self,$class);
   return $self;
}

# move file from new to current with changed filename
sub new_to_cur {
   my ($path, $filename,$action)=@_;
   if($action ne 'close') {
      my $flag=uc(substr($action,0,1));
      my $old="$path/new/$filename";
      my $new="$path/cur/$filename:2,$flag";

      if(rename($old,$new)) {
         return 0;
      } else {
         carp("new_to_cur: failed to rename \'$old\' to \'$new\': $!");
      }
   }
   return -1;
}

=head3 add_action($folder,$flag,$action)

Add a specific C<$action> (function or 'close') to C<$folder> for 
the C<$flag> flag.

For example, if you wish to move files from F<new> to F<trash> when given 
the flag 'T' (or 'trash'):

   $mdir->add_action('new','trash',\&new_to_trash);

Specifiying 'close' closes the file, without appending the info or moving 
the file.

The default action for folder F<new> is to move it to F<cur> and append the 
flag 'S' flag. Reading messages from F<cur> or F<tmp> by default only closes 
the file.

Returns 0 upon success, -1 otherwise.

Example of action function:

   sub new_to_trash {
      my ($path, $filename,$action)=@_;
      my $flag=uc(substr($action,0,1));

      if($flag eq 'T') {
         if(-d "$path/trash/") { 
            my $old="$path/new/$filename";
            my $new="$path/trash/$filename:2,$flag";

            if(rename($old,$new)) {
               return 0;
            } else {
               die("failed to rename \'$old\' to \'$new\'");
            }
         } else {
            die("\'$path/trash\' directory does not exist");
         }
      }
      return -1;
   }

=cut


sub add_action {
   my ($self,$dir,$action,$func) = @_;

   
   if(!defined $dir) {
      carp("add_action: No folder specified");
      return -1;
   } elsif(!defined $action) {
      carp("add_action: No action specified");
      return -1;
   } elsif(!defined $func) {
      carp("add_action: No function specified");
      return -1;
   }

   my $path=$self->{__dir}."/$dir";
   my $flag=$action;

   if(!(-d $path)) {
      if(!mkdir($path)) {
         carp("add_action: mkdir failed to create folder \'$path\': $!");
         return -1;
      }
   }

   if($action ne 'default')  { $flag=uc(substr($action,0,1)); }
   $self->{__folder_actions}->{$dir}->{$flag}=$func;

   return 0;

}


=head3 dir

Set the maildir path:

   $maildir->dir('/tmp/.maildir/');

Get the maildir path:

   $maildir->dir();

=cut

sub dir {
   my ($self,$dir) = @_;

   if(defined $dir) { $self->{__dir}=$dir; } 

   return $self->{__dir};
}

=head3 mode

Set the mode for creating the directory and subdirectories F<tmp>, F<cur> 
and F<new>:

   $maildir->mode(0754);

Get the mode:

   $maildir->mode();

=cut

sub mode {
   my ($self,$mode) = @_;

   if(defined $mode) { $self->{__mode}=$mode; } 

   return $self->{__mode};
}

=head3 mkdir

Create the directory and subdirectories F<tmp>, F<cur> and F<new> if they 
do not already exist:

   $maildir->mkdir();

As above, but create the additional directories F<trash>, F<sent>:

   $maildir->mkdir("trash","sent");

This subroutine does B<not> need to be explicitly called before creating new 
messages (unless you want to create folders other than F<tmp>, F<new>, 
and F<cur>).

This subroutine returns 0 if the directories were created (or exist), otherwise 
it returns -1 and a warning with carp.

=cut

sub mkdir {
   my ($self,@additional_dir)=@_;
   my $mode=$self->{__mode};
   my @dirs=("","tmp","cur","new");
   push(@dirs,@additional_dir);

   if(!defined $self->{__dir}) {
      carp("mkdir: No directory name given");
      return -1;
   } 

   if($self->{__create}!=1) {
      carp("mkdir: The create flag is not 1");
      return -1;
   }

   foreach my $path (@dirs) {
      $path=$self->{__dir}."/$path";
      if(!(-e $path)) { 
         if(!mkdir($path)) {
            carp("mkdir: mkdir failed to create \'$path\': $!");
            return -1;
         }
      }

      if(-d $path) { 
         if(chmod($self->{__mode},$path)!=1) {
            carp("mkdir: chmod \'$path\' to ".$self->{__mode}." failed: $!");
         }
      } else {
         carp("mkdir: \'$path\' is not a directory\n");
         return -1;
      }

   }

   return 0;
}


# returns a unique filename
sub fname {
   my $self=shift;

   my $time=time();
   my $hostname=hostname();
#replace / with \057 and : with \072
   $hostname=~s/\//\\057/g; $hostname=~s/:/\\072/g; 

   return $time.'.'.($$."_".$self->{__uniq}++).'.'.$hostname;
}


=head3 creat_message

Get a file handle C<$fh> to a unique file in the F<tmp> subdirectory:

   my ($fh,$status) = $maildir->creat_message();

Write message to unique file in F<tmp> subdirectory which is then delivered 
to F<new>:

   my $status=$maildir->creat_message($message);

Return: C<$status> is 0 if success, -1 otherwise. 
C<$fh> is the filehandle (C<undef> if you pass C<create_message> an argument).

=cut


sub creat_message {
   my ($self,$message)=@_;
   my ($filename,$fh);

   $self->mkdir; #maybe some of the directories were deleted?

# make sure that the file does not exist
   $filename=$self->fname;
   while(-e $self->{__dir}."/tmp/$filename") {
      sleep(2);
      $filename=$self->fname;
   }

   unless(open($fh,">".$self->{__dir}."/tmp/$filename")) {
      carp("creat_message: failed to open file \'"
            .$self->{__dir}."/tmp/$filename\': $!");
      return (undef,-1);
   }

   if(defined $message) {
      print $fh $message;
      unless(fsync($fh)) {
         carp("creat_message: fsync failed: $!");
         return (undef,-1);
      }
      close($fh);

      return (undef,$self->deliver($filename));
   } elsif(defined $self->{__message_fh}->{fileno $fh}) {
      carp("creat_message: file handle \'"
            .(fileno $fh)."\' is already defined in table");
      return (undef,-1);
   } else {
      $self->{__message_fh}->{fileno $fh}->{'fh'}=$fh;
      $self->{__message_fh}->{fileno $fh}->{'filename'}=$filename;
      return ($fh,0);
   }
   
}

=head3 deliver_message

Given file handle C<$fh>, deliver message and close handle:

   $maildir->deliver_message($fh);

Returns 0 upon success, -1 otherwise.

=cut

sub deliver_message {
   my ($self,$fh)=@_;

   if(defined $self->{__message_fh}->{fileno $fh}) {
      my $rc=-1;
      my $fno=fileno $fh; #need to index the hash __message_fh
      unless(fsync($fh)) {
         carp("deliver_message: fsync failed: $!");
         return (undef,-1);
      }
      close($fh);

      $rc=$self->deliver($self->{__message_fh}->{$fno}->{'filename'});
      delete $self->{__message_fh}->{$fno};
      return $rc;
   }
 
   return -1;
}

=head3 deliver_all_messages

Deliver all messages and close all handles:

   $maildir->deliver_all_messages();

Returns 0 upon success, -1 otherwise.

=cut

sub deliver_all_messages {
   my $self=shift;

   foreach my $fno (keys %{$self->{__message_fh}}) {
      if($self->deliver_message($self->{__message_fh}->{$fno}->{'fh'})==-1) {
         return -1;
      }
   }
   return 0;
}



# copy filename from tmp to new and delte from tmp
sub deliver {
   my ($self,$filename)=@_;

   if(!(-e $self->{__dir}."/tmp/$filename")) {
      carp("deliver: "
            ."file \'$filename\' does not exist in subdirectory \'tmp\'");
      return -1;
   }

   if(-e $self->{__dir}."/new/$filename") {
      carp("deliver: "
            ."file \'$filename\' already exists in subdirectory \'new\'");
      return -1;
   }

   if(!link($self->{__dir}."/tmp/$filename", $self->{__dir}."/new/$filename")) {
      carp("deliver: "
         ."file \'$filename\' could not be linked from \'tmp\' to \'new\': $!");
      return -1;
   }

   if(unlink($self->{__dir}."/tmp/$filename")<1) {
      carp("deliver: "
            ."file \'$filename\' could not be unlinked from \'tmp\': $!");
      return -1;
   }

   return 0;
}

=head3 sort

Get the current method for sorting messages:

   my $sort=$maildir->sort();

Set the sorting function of method:

   $maildir->sort('non'); # no specific sorting

   $maildir->sort('asc'); # sort based on mtime in increasing order

   $maildir->sort('des'); # sort based on mtime in decreasing order

   $maildir->sort(\&func); # sort based on user defined function

Example of sorting function which sorts according to a line in the 
message beggining with "sort:" followed by possible spaces and then
a digit:

   sub func {
      my ($path,@messages)=@_;
      my %files; my @newmessages;

      foreach my $file (@messages) {
         my $f;
         open($f,"<$path/$file") or return @messages; #don't sort
         while(my $line=<$f>) {
            if($line=~m/sort:\s*(\d)+$/) { # string where sort info is
               $files{$file}=$1;
               close($f);
               last;
            }
         }
      }

      @newmessages= sort { $files{$a} <=> $files{$b}} keys %files;

      return @newmessages;
   }

=cut


sub sort {
   my ($self,$func)=@_;
   if(defined $func) {
      $self->{__last_sort}=$self->{__sort};
      $self->{__sort}=$func;
   }
   return $self->{__sort};
}

# get all the filenames in directory $dir sorted accorting to $self->{__sort}
sub get_messages {
   my ($self,$dir)=@_;
   my $path;
   my @messages;

   if(defined $self->{__read_messages}->{$dir} 
         and ($self->{__last_sort} eq $self->{__sort}) 
         and !$self->{__force_readdir}) {
      return @{$self->{__read_messages}->{$dir}};
   } else {
      $self->{__force_readdir}=0;
      $self->{__last_sort}=$self->{__sort};
# and sort:
   }

   if(!defined $dir) {
      carp("get_messages: get_messages expects a directory to open");
      return -1;
   }

   $path=$self->{__dir}."/$dir";

   unless(opendir(DIR, $path)) {
      carp("get_messages: failed to open directory \'$path\': $!");
      return -1;
   }

   @messages=map{ /^(\d[\w.:,_]+)$/ && -f "$path/$1"?$1:() } readdir(DIR);

   closedir(DIR);

   @{$self->{__read_messages}->{$dir}}=$self->sort_messages($dir,@messages);
   return @{$self->{__read_messages}->{$dir}};
}

# sort default sorting methods (ascending|descending) wased on mtime
sub sort_messages {
   my ($self,$dir,@messages)=@_;
   my %files;
   my @newmessages;

   if($self->{__sort}=~m/asc|des/i) {
      foreach my $m (@messages) {
         $files{$m}=(stat($self->{__dir}."/$dir/$m"))[9];

         if(!(defined $files{$m})) {
            carp("sort_messages: ".
                  "stat failed for file \'".$self->{__dir}."/$dir/$m\': $!");
            return @messages;
         }
      }

      if($self->{__sort}=~m/asc/i) {
         @newmessages= sort { $files{$a} <=> $files{$b}} keys %files;
      } else {
         @newmessages= sort { $files{$b} <=> $files{$a}} keys %files;
      }
   } elsif($self->{__sort}=~/non/i) {
      @newmessages=@messages;
   } else {
      @newmessages=&{$self->{__sort}}($self->{__dir}."/$dir/",@messages);
   }

   return @newmessages;
}

=head3 get_next_message

Get the next message (as file handle) from directory F<new>:

   my ($fh,$status)=$maildir->get_next_message("new");

B<NOTE:> It is important to I<properly> close file handle once finished with 
L</close_message> or L</act>.

Read lines of next message in array @lines then, close message and 
execute the action specified for flag 'P' (default for F<new>: move 
to F<cur> and append ':2,P'):

   my $status=$maildir->get_next_message("new",\@lines,'passed');

Return: C<$status> is 0 if success, -1 otherwise. 
C<$fh> is the filehandle (C<undef> if you pass C<get_next_message> a 
second argument).

=cut

sub get_next_message {
   my ($self,$dir,$lines,$action)=@_;
   my $fh;
   $self->get_messages($dir);
   my $message=shift(@{$self->{__read_messages}->{$dir}});
   if(!defined $action) {
      $action=$self->{__default_act};
   }

   if(!$message) { return (undef,-1); }

   unless(open($fh,"<".$self->{__dir}."/$dir/$message")) {
      carp("get_next_message: "
            ."failed to open file \'".$self->{__dir}."/$dir/$message\': $!");
      return (undef,-1);
   }

   if(defined $self->{__message_fh}->{fileno $fh}) {
      carp("get_next_message: file handle \'$fh\' is already defined in table");
      return (undef,-1);
   } else {
      $self->{__message_fh}->{fileno $fh}->{'fh'}=$fh;
      $self->{__message_fh}->{fileno $fh}->{'filename'}=$message;
      $self->{__message_fh}->{fileno $fh}->{'dir'}=$dir;
      if(defined $lines) {
         @$lines=<$fh>;
         return (undef,$self->act($fh,$action));
      } else {
         return ($fh,0);
      }
   }
}

=head3 force_readdir

Force a readdir during the next L</get_next_message>. This is
useful if you are reading messages from F<new> and then from F<cur> as some
of the messages will be moved there.

   $mdir->force_readdir();

=cut

sub force_readdir {
   my $self=shift;
   $self->{__force_readdir}=1;
}

=head3 close_message

Given file handle C<$fh>, close handle:

   $maildir->close_message($fh);

Returns 0 upon success, -1 otherwise.

=cut

sub close_message {
   my ($self,$fh)=@_;

   if(defined $self->{__message_fh}->{fileno $fh}) {
      my $fno=fileno $fh; #need to index the hash __message_fh
      unless(fsync($fh)) {
         carp("close_message: fsync failed: $!");
         return (undef,-1);
      }
      close($fh);

      delete $self->{__message_fh}->{$fno};
      return 0;
   }
 
   return -1;
}

=head3 act

Given file handle C<$fh>, and flag ('P','R','S','T','D','F') close message, append
the info and execute the specified action for the flag:

   $maildir->act($fh,'T');

Returns 0 upon success, -1 otherwise.

=cut


sub act {
   my ($self,$fh,$action)=@_;

   if(!defined $fh) {
      carp("act: No file handle specified!\n");
      return -1;
   }
   if(!defined $action) {
      carp("act: No action specified!\n");
      return -1;
   }

   my $filename=$self->{__message_fh}->{fileno $fh}->{'filename'};
   my $dir=$self->{__message_fh}->{fileno $fh}->{'dir'};
   my $flag=uc(substr($action,0,1));

   my $close_rc=$self->close_message($fh);

   return $close_rc if $action eq 'close';

   if(exists $self->{__folder_actions}->{$dir}) {
      if(exists $self->{__folder_actions}->{$dir}->{$flag}) {
         if($self->{__folder_actions}->{$dir}->{$flag} ne 'close') {
            &{$self->{__folder_actions}->{$dir}->{$flag}}($self->{__dir},
                  $filename, $action);
         }
      } elsif(exists $self->{__folder_actions}->{$dir}->{'default'}) {
         if($self->{__folder_actions}->{$dir}->{'default'} ne 'close') {
            &{$self->{__folder_actions}->{$dir}->{'default'}}($self->{__dir},
                  $filename, $action);
         }
      } else {
         carp("act: unknown action \'$action\' for directory \'$dir\',"
               ."closed file");
      }
   } else {
      carp("act: unknown action \'$action\', closed file");
   }

   return $close_rc;
}

=head1 EXAMPLES

=head2 Writing messages

The example shows the use of this module with L<MIME::Entity> to write messages.

   #!/usr/bin/perl
   use strict;
   use warnings;
   use MIME::Entity;
   use Maildir::Lite;

   my $mdir=Maildir::Lite->new(dir=>'/tmp/.your_mdir');

   # print message to file handle
   sub print_message {
      my ($from,$to,$subj,$message,$fh)=@_;
      my $date=localtime;
      my $msg = MIME::Entity->build(
            Type        => 'text/plain',
            Date        => $date,
            From        => $from,
            To          => $to,
            Subject     => $subj,
            Data        => $message);

      $msg->print($fh);
   }

   # write messages to maildir folder
   sub  write_message {
      my ($from,$to,$subj,$message)=@_;
      my ($fh,$stat0)=$mdir->creat_message();

      die "creat_message failed" if $stat0;

      print_message($from,$to,$subj,$message,$fh);

      die "delivery failed!\n" if $mdir->deliver_message($fh);
   }

   write_message('me@foo.org', 'you@bar.com','Hi!','One line message');
   write_message('me@foo.org', 'bar@foo.com','Bye!','Who are you?');
   write_message('me2@food.org', 'bar@beer.org','Hello!','You again?');


=head2 Reading messages

The example shows the use of this module with L<MIME::Parser> to read messages.

   #!/usr/bin/perl
   use strict;
   use warnings;
   use MIME::Parser;
   use Maildir::Lite;


   my $mdir=Maildir::Lite->new(dir=>'/tmp/.your_mdir');
   # move file from new to trash with changed filename


   sub read_from {
      my $folder=shift;
      my $i=0;

      $mdir->force_readdir();

      print "$folder:\n|".("-"x20)."\n";

      while(1) {
         my $parser = new MIME::Parser;
         $parser->output_under("/tmp");

         my ($fh,$status)=$mdir->get_next_message($folder);
         last if $status;

         my $entity=$parser->parse($fh);

         print "Message $i:\n".$entity->stringify."\n";
         $i++;

         if($mdir->act($fh,'S')) { warn("act failed!\n"); }
      }

      print "|".("-"x20)."\n\n";
   }

   read_from("cur");
   read_from("new");

   read_from("cur"); # to see the force_readdir in action
   read_from("new");

=head1 SEE ALSO

There is already an implementation of Maildir, L<Mail::Box::Maildir>, which is
great, but more bulky and complicated.

Maildir specifications at L<http://cr.yp.to/proto/maildir.html>

=head1 VERSION

Version 0.01

=head1 AUTHOR

Deian Stefan, C<< <stefan at cooper.edu> >>

L<http://www.deian.net>

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-maildir-lite at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Maildir-Lite>.  
I will be notified, and then you'll automatically be notified of progress 
on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Maildir::Lite


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Maildir-Lite>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Maildir-Lite>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Maildir-Lite>

=item * Search CPAN

L<http://search.cpan.org/dist/Maildir-Lite>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2008 Deian Stefan, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Maildir::Lite
