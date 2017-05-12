package Mail::Convert::Mbox::ToEml;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.06';

sub new {
  my $class = shift;
  my $self  = {
    InFile => shift || undef,
    OutDir => shift || undef,
    isError => 0,
    Error   => undef
  };
  bless $self, $class;
  if (!$self->{InFile} || !$self->{OutDir}) { return; }
  if (!-e $self->{InFile}) { print "file does not exist!\n"; return; }
  if (!-d $self->{OutDir}) {
    print "output directory is not a directory!\n";
    return;
  }
  if (!-e $self->{OutDir}) {
    print "output directory does not exist!\n";
    return;
  }

  return $self;

}

sub CreateEML {
  my $self   = shift;
  my $infile = shift || $self->{InFile};
  my $outDir = shift || $self->{OutDir};
  if ($infile) {
    $self->{InFile} = $infile;
    if (!-e $self->{InFile}) { print "file does not exist!\n"; return; }
  }
  if ($outDir) {
    $self->{OutDir} = $outDir;
    if (!-d $self->{OutDir}) {
      print "output directory is not a directory!\n";
      return;
    }
    if (!-e $self->{OutDir}) {
      print "output directory does not exist!\n";
      return;
    }
  }

  $self->Parse();
  return 1;
}

sub GetMessageCount {
  my $self = shift;
  if   ($self->{MessageCount}) { return $self->{MessageCount}; }
  else                         { return; }
}

sub GetMessages {
  my $self        = shift;
  my $infile      = shift || $self->{InFile};
  my @subjectList = ();
  my $x0d         = chr(hex('0x0d'));
  if (open(FH, $infile)) {
    my $count = 0;
    while (<FH>) {
      if ($_ =~ /^subject:/i) {

        my $tmp = (split(/^subject:/i, $_))[1];
        chomp $tmp;
        $tmp =~ s/^\s+//;
        $tmp =~ s/$x0d$//i;
        push(@subjectList, $tmp);
        $count++;
      }

    }
    $self->{MessageCount} = $count;
    return @subjectList;
  } else {
    $self->{Error} = "No messages found!\n";
    return;
  }
}

sub SetFileAndDir {
  my $self = shift;
  $self->{InFile} = shift;
  $self->{OutDir} = shift;
  if (!-e $self->{InFile}) { print "file does not exist!\n"; return; }
  if (!-d $self->{OutDir}) {
    print "output directory is not a directory!\n";
    return;
  }
  if (!-e $self->{OutDir}) {
    print "output directory does not exist!\n";
    return;
  }
  return 1;
}

sub FindMessage {
  my $self   = shift;
  my $what   = shift;
  my $infile = shift || $self->{InFile};
  my $count  = 0;
  my $scount = 0;
  my %h;
  my @subjectlist = $self->GetMessages($infile);
  if (!@subjectlist) { return; }

  foreach (@subjectlist) {
    if (lc($_) =~ /$what/i) {
      $h{$scount} = { MSG => $_, MSGNUM => $count };

      #$h{MSGNUM}=;
      $scount++;
    }
    $count++;
  }
  if   (%h) { return %h; }
  else      { $self->{Error} = "Message(s) not found!\n"; return; }
}

sub Parse {
  my $self        = shift;
  my @currmail    = ();
  my $counter     = 0;
  my $mailcounter = 1;
  open(FH, $self->{InFile});
  binmode FH;
  while (<FH>) {
    if ($_ !~ /^From -/) {
      $currmail[$counter] = $_;
      $counter++;
    } else {

      if (@currmail) {
        $self->WriteToFile($mailcounter, \@currmail);
        $counter = 0;
        $mailcounter++;
        undef @currmail;
      }
    }
  }
  $self->WriteToFile($mailcounter, \@currmail) if @currmail;
  close FH;
  return 1;
}

# The subject will be used to generate the file name
sub WriteToFile {
  my $self      = shift;
  my $mailcount = shift;
  my $tmp       = shift;
  my @mail      = @{$tmp};
  my $subject;
  my $x0d = chr(hex('0x0d'));
  my @temp = grep(/subject:/i, @mail);
  if (@temp != 0) {
    $subject = (split(/subject:/i, $temp[0]))[1];

    chomp $subject;

    # remove characters which can not be used in a file name
    $subject =~ s/^\s+//;
    $subject =~ s/\"//g;
    $subject =~ s/\// /g;
    $subject =~ s/\/\//_/g;
    $subject =~ s/\\/_/g;
    $subject =~ s/:/_/g;
    $subject =~ s/'//g;
    $subject =~ s/\?//g;
    $subject =~ s/\<//g;
    $subject =~ s/\>//g;
    $subject =~ s/\|//g;
    $subject =~ s/\*//g;
    $subject =~ s/$x0d$//i;

  } else {
    $subject = "No Subject";
  }
  @mail = $self->checkLines(\@mail);
  my $file
    = $self->{OutDir} . "/" 
    . $subject . "_"
    . $mailcount . "_"
    . GetCurrentTime() . ".eml";
  print "writeing | $subject | to file\n";
  if (open(FHOUT, ">$file")) {
    binmode FHOUT;
    print FHOUT @mail;
    close FHOUT;
    return 1;
  } else {
    print "can not open $file for writeing! $!\n";
    return;
  }
}

# function to check if there are EOF characters and if the from: is correct
# EOF characters are removed.
sub checkLines {
  my $self       = shift;
  my $tmp        = shift;
  my @newmail    = ();
  my $count      = 0;
  my @mail       = @{$tmp};
  my $attachment = 0;
  my $attach     = "Content-Type: application";
  my $attach1    = "Content-Disposition: attachment";
  my $EOF        = chr(hex('0x1A'));
  my $ToVal;
  my @TVal = grep /^To:/i, @mail;

  if ($TVal[0]) {
    $ToVal = (split(/:/, $TVal[0]))[1];
    $ToVal =~ s/^\s+//;
  }

  foreach (@mail) {
    if ($_ =~ /^from:/i) {
      $tmp = (split(/from:/i, $_))[1]
        ;  # correct the From: line, insert the mail address in To:
      if (length($tmp) <= 2) {
        $_ = "From: " . $ToVal if $ToVal;
      }
      if ($_ =~ /^>from/i || $_ =~ /^>from:/i)  # correct the From: line
      {
        $_ = substr($_, 1, length($_) - 1);
      }
    }
    if ($_ =~ /^$attach/ || $_ =~ /^$attach1/) { $attachment = 1; }
    $_ =~ s/$EOF//g if $attachment == 1;        # removes EOF's in the line
    push(@newmail, $_);
    $count++;
  }
  return @newmail;
}

sub GetCurrentTime {

  #my $self=shift;
  return time;
}

1;
__END__
=head1 NAME

Mail::Convert::Mbox::ToEml - convert mbox files to Outlook Express .eml files

=head1 SYNOPSIS

  use Mail::Convert::Mbox::ToEml;

  my $EML = Mail::Convert::Mbox::ToEml->new($file, $outdir);

  die "failed to make EML file" unless" $EML->CreateEML();

=head1 DESCRIPTION

Mail::Convert::Mbox::ToEml is a module to convert Mbox mail folder which used
by many unix-born software to single Outlook Express .eml files.

=head1 FUNCTIONS

=head2 new

The constructor. 

  $EML = Mail::Convert::Mbox::ToEml->new($file, $outdir);

C<$file> is the MBox file to convert.

C<$outdir> is the directory where the single eml files are stored.

On error the method returns undef.

=head2 CreateEML

This function do the convertion and writes the .eml file.

The two optional arguments are:

C<$file> is the MBox file to convert.

C<$outdir> is the directory where the single eml files have to be stored.

The return value is undef if the file or the ouput directory does not exist and
1 on success.  If there was an error to create the eml file it will be printed
out and creation will continue with the next message.

=head2 GetMessages

This method returns the subject line of all messages in the file.

Paramter: the file to process (optional)

Return: an Array of subjects or undef.

=head2 FindMessage

This method return the found messages which match the keyword in the subject
line given as parameter.

Parameters: a keyword and optional a file to process

Return: a hash of hashes whith the subject line and the message number or
undef.

example: 

  my %h = $MBX->FindMessage("RE: Help", ["d:/mail/Inbox"]);
  foreach (keys %h)
  {
    print "The key: $_="; 
      foreach my $xx (keys %{$h{$_}})  
      {
        print "$xx=" . %{$h{$_}}->{$xx} . " ";
      }
    print " \n";
  }


=head2 GetMessageCount

This method returns the number of messages in the given file or undef.

There are no parameters.

=head2 SetFileAndDir

With this Method the input file and the output directory can be set.
Parameters: filename, output directory
Return 1 on success or undef if the file or the output directory does not exist.

=back

=head1 CREDITS

Many thank's to Ivan from Broobles.com (http://www.broobles.com/imapsize/) the
author of the usefull IMAPSize program for his help and tips to develop this
module.

=head1 AUTHOR

Reinhard Pagitsch, E<lt>rpirpag@gmx.atE<gt>

=head1 PERL EMAIL PROJECT

This module is maintained by the Perl Email Project.  It has no real
maintainer.  Volunteers should write to the PEP mailing list.

L<http://emailproject.perl.org/wiki/Mail::Convert::Mbox::ToEml>

=head1 SEE ALSO

L<perl>.

=cut
