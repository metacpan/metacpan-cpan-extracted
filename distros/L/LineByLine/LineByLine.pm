#----------------------------------------------------------------
# Copyright (c) 2002 Benjamin Crowell
# This module is available under the same terms as Perl itself.
#----------------------------------------------------------------
# POD documentation is at the end of the file.
#----------------------------------------------------------------


use strict;

package Digest::LineByLine;

use Digest::SHA1;

$VERSION = '1.0';  # $Date: 2002/05/13 10:40:00 $

sub new {
    my $class = shift;
    my %args = (
		KEY=>"",
                DELIMITER=>" #",
                SALT=>sprintf("%06d",int(rand 1000000)),
                HASH_FUNCTION=>"SHA1",
                MIN_LINE_LENGTH=>80,
                INPUT=>"",
		@_
		);
    my $self = {};
    bless($self,$class);
    $self->{KEY} = $args{KEY};
    $self->{DELIMITER} = $args{DELIMITER};
    $self->{SALT} = $args{SALT};
    $self->{HASH_FUNCTION} = $args{HASH_FUNCTION};
    $self->{MIN_LINE_LENGTH} = $args{MIN_LINE_LENGTH};
    $self->{INPUT} = $args{INPUT};

    if ($self->{INPUT} eq "") {
      $self->{MODE} = "create";
    }
    else {
      $self->{MODE} = "read";
    }

    $self->get_named_hash_function();
    if (!defined $self->{HASH_FUNCTION_REF}) {return undef};

    $self->initialize();

    return $self;
}

# This is what we should do before reading or writing the file.
# If, e.g., you read the file twice, you should do this each time.
sub initialize {
    my $self = shift;
    $self->{RUNNING_HASH} = $self->do_hash("");
    $self->{LINE_COUNT} = 0;
    $self->{IS_OPEN} = 0;
}

sub get_named_hash_function {
    my $self = shift;
    $self->{HASH_FUNCTION_REF} = undef;
    if ($self->{HASH_FUNCTION} eq "SHA1") {
      $self->{HASH_FUNCTION_REF} =
          sub {
            my $data = shift;
            my $key = shift;
            return Digest::SHA1::sha1_base64($key,Digest::SHA1::sha1($key,$data));
          }
    }
}

sub head {
    my $self = shift;
    return $self->{DELIMITER}.",".identifier_string().",".$self->{SALT}.",".$self->{HASH_FUNCTION}."\n";
}

sub line {
    my $self = shift;
    my $line = shift;
    chomp $line;
    ($self->{LINE_COUNT})++;
    my $stuff = $self->{LINE_COUNT}." ".$line;
    $self->{RUNNING_HASH} = $self->do_hash($self->{RUNNING_HASH}.$stuff);
    my $hash = $self->do_hash($stuff);
    my $mac = $hash.",".length($hash).",".$self->{LINE_COUNT};
    my $padding = " ";
    my $len = length($line)+length($self->{DELIMITER})+length($padding)+length($mac);
    my $min = $self->{MIN_LINE_LENGTH};
    if ($min>0 && $len<$min) {$padding = $padding . (" "x($min-$len))}
    return $line.$self->{DELIMITER}.$padding.$mac."\n";
}

sub tail {
    my $self = shift;
    return $self->{DELIMITER}." end,count       =".$self->do_hash($self->{LINE_COUNT}).",end\n"
          .$self->{DELIMITER}." end,running hash=".$self->{RUNNING_HASH}.",end\n";
}

sub is_authentic {
    my $self = shift;
    return $self->authenticity() eq "";
}

sub authenticity {
    my $self = shift;
    if (!defined $self->{AUTHENTICITY}) {
      $self->{AUTHENTICITY} = $self->check_authenticity();
    }
    return $self->{AUTHENTICITY};
}

# Returns a null string if authentic. If inauthentic, it returns a string,
# which is meant for internal use. This routine doesn't try to recover from errors at all ---
# it's just meant to be an efficient check on authenticity. In most cases, that's all we
# need, since it isn't every day that we detect tampering. Cf. report_on_tampering().
sub check_authenticity {
    my $self = shift;
    open(FILE,"<".$self->{INPUT}) or return undef;
    my $head = <FILE>;
    if ($head eq "") {return "empty file"}
    chomp $head;
    if (!($head =~ m/^(.*),([^,]*),([^,]*),([^,]*)/)) {return "bad header"};
    ($self->{DELIMITER},$self->{SALT},$self->{HASH_FUNCTION}) = ($1,$3,$4);
    $self->get_named_hash_function();
    if (!defined $self->{HASH_FUNCTION_REF}) {return "bad hash function ".$self->{HASH_FUNCTION}};
    $self->initialize();
    my $part = 2; # what we expect next: 1=header, 2=body, 3=count, 4=running hash
    while (<FILE>) {
      my $line = $_;
      my $recognized_line_type = 0;

      #------- count line ----------
      if ($line =~ m/^(.*) end,count *=(.*),end$/) {
        $recognized_line_type = 1;
        if ($1 ne $self->{DELIMITER}) {return "bad delimiter on count line, $1"}
        if ($2 ne $self->do_hash($self->{LINE_COUNT})) {
          return "bad count, $2,".$self->do_hash($self->{LINE_COUNT})
        }
        if ($part!=2) {return "count line out of order"}
        $part = 4; # expect running hash line next
      }

      #------- running hash line ----------
      if (!$recognized_line_type && $line =~m/^(.*) end,running hash *=(.*),end$/) {
        $recognized_line_type = 1;
        if ($1 ne $self->{DELIMITER}) {return "bad delimiter on running hash line"}
        if ($2 ne $self->{RUNNING_HASH}) {return "bad running hash"}
        if ($part!=4) {return "running hash line out of order"}
      }

      #------- body line ----------
      if (!$recognized_line_type){

        if ($part!=2) {return "body line out of order"}

        my ($err,$stuff) = $self->slice_line($line);
        if ($err ne "") {return "syntax error at line ".$self->{LINE_COUNT}};

        ($self->{LINE_COUNT})++;
        my ($start,$hash,$line_number) = @$stuff;
        if ($line_number != $self->{LINE_COUNT}) {
          return "line number mismatch, $line_number,".$self->{LINE_COUNT}
        };

        my $what_to_hash = $self->{LINE_COUNT}." ".$start;
        $self->{RUNNING_HASH} = $self->do_hash($self->{RUNNING_HASH}.$what_to_hash);
        my $my_hash = $self->do_hash($what_to_hash);
        if ($hash ne $my_hash) {return "bogus hash at line ".$self->{LINE_COUNT}}

      }
    }
    close(FILE);
    return "";
}

# Call this routine for more information if your file has been tampered with. This
# is not an efficient way to verify on a routine basis that your file has not been
# tampered with -- use is_authentic() for that.
sub report_tampering {
    my $self = shift;
    open(FILE,"<".$self->{INPUT}) or return undef;
    my $head = <FILE>;
    my $report = "file ".$self->{INPUT}."\n\n";
    if ($head eq "") {return $report . "The file is empty.\n"}
    chomp $head;
    if (!($head =~ m/^(.*),([^,]*),([^,]*),([^,]*)/)) {
      return $report . "The header has been deleted. You may be able to recover the six-digit salt by brute force.\n"
    };
    ($self->{DELIMITER},$self->{SALT},$self->{HASH_FUNCTION}) = ($1,$3,$4);
    $self->get_named_hash_function();
    if (!defined $self->{HASH_FUNCTION_REF}) {return $report . "The hash function ".$self->{HASH_FUNCTION}." is unknown.\n"};
    $self->initialize();
    $report = $report . "The header was read successfully:\n"
         ."  delimiter =".$self->{DELIMITER}."\n"
         ."  salt      =".$self->{SALT}."\n"
         ."  hash fn   =".$self->{HASH_FUNCTION}."\n\n";
    my $part = 2; # what we expect next: 1=header, 2=body, 3=count, 4=running hash
    while (<FILE>) {
      my $line = $_;
      my $recognized_line_type = 0;

      #------- count line ----------
      if ($line =~ m/^(.*) end,count *=(.*),end$/) {
        $recognized_line_type = 1;
        if ($1 ne $self->{DELIMITER}) {
          $report = $report . "Bad delimiter on count line, $1. It is not possible to check whether lines have been deleted\n"
                         ." from the end of the file.\n"
        }
        if ($2 ne $self->do_hash($self->{LINE_COUNT})) {
          $report = $report . "The number of lines in the file is incorrect. Attempting to reconstruct the\n"
                            . "number by brute force. If no other discrepancies are found, this means that\n"
                            . "the file was tampered with by deleting some lines from the end.\n\n";
          my $found = "";
          my ($min,$max) = (0,10*$self->{LINE_COUNT});
          if ($max<10000) {$max=10000}
          for (my $n = $min; $n<=$max; $n++) {
            if ($self->do_hash($n) eq $2) {
              $found = $n;
              last;
	    }
	  }
	  if ($found ne "") {
	    $report = $report . "The original file had $found lines in it. The modified file has ".$self->{LINE_COUNT}.".\n";
	  }
          else {
            $report = $report . "Brute-force reconstruction failed. The number of lines in the original file\n"
                              . "was not in the range from $min to $max.\n";
          }
        }
        if ($part!=2) {$report = $report . "Count line out of order.\n"}
        $part = 4; # expect running hash line next
      }

      #------- running hash line ----------
      if (!$recognized_line_type && $line =~m/^(.*) end,running hash *=(.*),end$/) {
        $recognized_line_type = 1;
        if ($1 ne $self->{DELIMITER}) {$report = $report . "Bad delimiter on running hash line.\n"}
        if ($2 ne $self->{RUNNING_HASH}) {
          $report = $report . "Bad running hash. This is expected to occur for any type of tampering. This\n"
                            . "should never be the only indication of tampering.\n";
        }
        if ($part!=4) {$report = $report . "Running hash line out of order.\n"}
      }

      #------- body line ----------
      if (!$recognized_line_type){

        if ($part!=2) {$report = $report . "Body line out of order at line ".$self->{LINE_COUNT}.":\n$line\n\n"}

        my ($err,$stuff) = $self->slice_line($line);
        if ($err ne "") {$report = $report . "Syntax error at line ".$self->{LINE_COUNT}.":\n$line\n\n"};

        ($self->{LINE_COUNT})++;
        my ($start,$hash,$line_number) = @$stuff;
        if ($line_number != $self->{LINE_COUNT}) {
          $report = $report . "Line number mismatch, original=$line_number, modified=".$self->{LINE_COUNT}.":\n$line\n";
          if ($line_number>$self->{LINE_COUNT}) {
            $report = $report .
               "This may indicate that ".($line_number-$self->{LINE_COUNT})." lines were deleted, or that some lines were permuted.\n";
	  }
          else {
            $report = $report .
                 "This may indicate that ".($self->{LINE_COUNT}-$line_number)." lines were inserted, or that some lines were permuted.\n";
          }
          $report = $report . "Further mismatches will not be reported unless they indicate further tampering.\n\n";
          $self->{LINE_COUNT} = $line_number;
        };

        my $what_to_hash = $self->{LINE_COUNT}." ".$start;
        $self->{RUNNING_HASH} = $self->do_hash($self->{RUNNING_HASH}.$what_to_hash);
        my $my_hash = $self->do_hash($what_to_hash);
        if ($hash ne $my_hash) {$report = $report . "Line ".$self->{LINE_COUNT}." has been tampered with:\n$line\n\n"}

      }
    }
    close(FILE);
    return $report;
}

sub do_hash {
    my $self = shift;
    my $data = shift;
    my $the_function = $self->{HASH_FUNCTION_REF};
    return &$the_function($self->{SALT}.$data,$self->{KEY});
}

sub slice_line {
    my $self = shift;
    my $line = shift;
    if (!($line =~ m/^(.*),(\d+),(\d+)\n?$/)) {return ("bad_syntax",[$line])}
    my ($start,$hash_len,$line_number) = ($1,$2,$3);
    if (length($start)<$hash_len) {return ("bad_hash_len",[$line])}
    my $hash = substr($start,-$hash_len);
    $start = substr($start,0,length($start)-length($hash));
    $start =~ s/ *$//; # strip off trailing blanks
    if (length($start)<length($self->{DELIMITER})) {return ("bad_delim_len",[$line])}
    if (substr($start,-length($self->{DELIMITER})) ne $self->{DELIMITER}) {
      return ("bad_delim",[$line])
    }
    $start = substr($start,0,length($start)-length($self->{DELIMITER}));
    return ("",[$start,$hash,$line_number]);
}

sub filter {
    my $self = shift;
    my %args = (
      INFILE=>"-",
      OUTFILE=>"-",
      @_
    );
    local ($_);

    open(INFILE,"<".$args{INFILE}) or return $!;
    open(OUTFILE,">".$args{OUTFILE}) or return $!;

    print OUTFILE $self->head();
    while (my $line = <INFILE>) {
      print OUTFILE $self->line($line);
    }
    print OUTFILE $self->tail();

}

sub strip {
    my $self = shift;
    my %args = (
      INFILE=>"-",
      OUTFILE=>"-",
      @_
    );
    local ($_);

    open(INFILE,"<".$args{INFILE}) or return $!;
    open(OUTFILE,">".$args{OUTFILE}) or return $!;

    <INFILE>; # Header line goes in the bit bucket.
    while (my $line = <INFILE>) {
      $line = $self->strip_line($line);
      if ($line ne "") {print OUTFILE $line}
    }

    close(INFILE);
    close(OUTFILE);

}

# Returns a newline-terminated line, with the MAC removed. Returns null if the line isn't a body
# line.
sub strip_line {
  my $self = shift;
  my $line = shift;
  my $d = $self->{DELIMITER};
  my $id = identifier_string();
  if (   $line =~ m/^(.*)end,count(.*),end$/ 
      || $line =~ m/^(.*)end,running hash(.*),end$/
      || $line =~ m/^$d,$id,\d+,[A-Za-z0-9]+/) {
    return "";
  }
  else {
    my ($err,$stuff) = $self->slice_line($line);
    return $stuff->[0]."\n";
  }
}

sub identifier_string {
  return "LineByLine.pm";
}

#=============================================================================

=head1 NAME

Digest::SHA1::LineByLine - Line-by-line message authentication for a plain text file.

=head1 SYNOPSIS

  # Signing:
  my $mac = LineByLine->new(KEY=>"secret");
  print $mac->head();
  print $mac->line("This is the first line.");
  print $mac->line("This is the second line.");
  print $mac->tail();

  # Authentication:
  my $mac = LineByLine->new(KEY=>"secret",INPUT=>"myfile");
  if ($mac->is_authentic()) { # Besides checking authenticity, reads and uses the header line.
    open(FILE,"<myfile");
    while (<FILE>) {
      next LINE unless my $line = $mac->strip_line($_); # gets rid of MAC part

      ...
    }
    ...
  }
  else {
    print "The file has been tampered with.\n";
    print $mac->report_tampering(); # describes the tampering in human-readable form
  }

  # Strip authentication from a preexisting file:
  $mac->strip(INFILE=>"foo",OUTFILE=>"bar");

  # Add authentication to a preexisting file, using the key in $mac:
  $mac->filter(INFILE=>"foo",OUTFILE=>"bar");


=head1 DESCRIPTION

=head2 What It's For

This module allows you to add line-by-line authentication codes
to a plain-text file. The file can still be manipulated using all
the text-file tools you know and love, including a text editor.
However, if someone else tampers with the file, you can detect
the tampering.

Why not just store a single MAC at the end of the
file? Well, LineByLine's authentication method is designed so that you
can detect the modification of certain lines, the deletion or
addition of lines, and permutations of lines. For example, I use
it with the data files for some software I wrote to help teachers
keep track of their students' grades --- if my gradebook file has been
tampered with, it's interesting to know not just that the tampering
occurred but also that the changes consisted of increases in all of
John Smith's exam grades. Note that I may also intentionally edit
the file myself with a text editor, and forget to redo the MAC. In this
situation, a single MAC for the whole file would force me to choose
between trashing the whole file and accepting it without knowing what
was going on.

The issue addressed by this module is not secrecy or encryption: it's
authentication. For example, you probably don't care if anyone sees
what's in your cron scripts, but you do care if they have modified
them.

=head2 The Algorithm

The authentication scheme is as follows. If the original file
consists of lines [L1,...Ln], then the file with authentication
has [r,L1,A1,...Ln,An,F(n),Bn], where r is a random
salt,
Aj=F(j," ",Lj),
F(x)=H(r,x),
H(x)=SHA1(K,SHA1(K,x)) is a MAC function, K is the key,
and Bn is the final member of the sequence defined by
sequence B0=F(""), Bj=F(Bj-1,j," ",Lj).

In the following example, a two-line text file has had line-by-line
authentication added to it, with password "secret":

  #,LineByLine.pm,207906,SHA1
 Joe owes me $37.50 from Poker. #                aM9YjvDz/MeurH73Fx/L7dJTXMc,27,1
 He said he'd pay me by Wed. #                   FpkNiGB1viuHuG2hQ6GjVa5LhiY,27,2
  # end,count       =FD2Y/0me4img5h9u5XoQzyoDS2o,end
  # end,running hash=t0lWGG+Lq3KS46j9Hv2IScE6xFo,end

=head1 METHODS


=over 4

=item new(KEY=>$key,...)

Creates a new LineByLine object. 
When inputting a file, tack on INPUT=>$filename.
The other options are documented below.

=item initialize()

This is what we should do before reading or writing the file.
If, e.g., you read the file twice, you should do this each time.

=item head()

Returns the header line for the file.

=item line($line)

Adds a MAC to the line, and returns the result.

=item tail()

Returns the lines that go at the end of the file.

=item is_authentic()

Tells whether the file is authentic. If necessary, reads the
whole file. When called repeatedly, does not read the file
again.

=item report_tampering()

Similar to is_authentic(), but returns a detailed report
on the tampering. Call this routine for more information if your file has been tampered with. This
is not an efficient way to verify on a routine basis that your file has not been
tampered with -- use is_authentic() for that.

=item filter(INPUT=>$infile_name,OUTPUT=>$outfile_name)

Adds authentication codes. The files default to stdin
and stdout.

=item strip(INPUT=>$infile_name,OUTPUT=>$outfile_name)

Removes authentication codes. The files default to stdin
and stdout.

=back

=head2 Options When Creating a New LineByLine Object

KEY sets the authentication key.

DELIMITER is some text to add between the text the MAC on
each line. This defaults to " #", which is handy, since # marks
comments in many scripting languages and Unix configuration files.

SALT defaults to a value supplied randomly by the constructor, and you
shouldn't normally override that default. The randomness protects against
attacks in which the attacker collects pieces of known plaintext along
with their MACs.

HASH_FUNCTION defaults to "SHA1", and there are not currently any other
legal values. I don't intend to add any other options for the hashing
function unless SHA1 is cracked someday.
Whatever the hash function is, I'm assuming it returns base64.

MIN_LINE_LENGTH defaults to 80. For readability, short lines get
blank padding after the delimiter so that the MAC is shoved to the
right, out of the way.


=head1 SEE ALSO

L<Digest::HMAC>, L<Digest::SHA1>

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

 (c) 2002 Ben Crowell

=head1 AUTHOR

Ben Crowell <b_crowell67@hotmail.com>

=cut


1;
