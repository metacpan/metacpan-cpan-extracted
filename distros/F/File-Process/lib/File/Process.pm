package File::Process;

use strict;
use warnings;

use parent qw{ Exporter };

use vars qw{ @EXPORT_OK };

@EXPORT_OK = qw{ process_file };

use Carp;
use Carp::Always;
use English qw{-no_match_vars};
use IO::Scalar;
use ReadonlyX;
use Scalar::Util qw{ reftype openhandle };

Readonly my $SUCCESS => 1;
Readonly my $FAILURE => 0;
Readonly my $TRUE    => 1;
Readonly my $FALSE   => 0;
Readonly my $EMPTY   => q{};
Readonly my $NL      => "\n";

our $VERSION = '0.01';

our %DEFAULT_PROCESSORS = (
  pre => sub {
    my ( $file, $args ) = @_;

    my $fh;

    if ( openhandle $file ) {
      $fh = $file;

      $args->{file} = ref $fh;    # GLOB
    }
    else {
      open $fh, '<', $file
        or croak 'could not open ' . $file . $NL;

      $args->{'file'} = $file;
    } ## end else [ if ( openhandle($file))]

    $args->{'raw_count'}  = 0;
    $args->{'skipped'}    = 0;
    $args->{'start_time'} = time;

    my $lines = $args->{merge_lines} ? IO::Scalar->new : [];

    return ( $fh, $lines );
  },
  next_line => sub {
    my ( $fh, $all_lines, $args ) = @_;
    my $cur_line;

    if ( openhandle $fh ) {
      if ( !eof $fh ) {
        defined( $cur_line = readline $fh )
          or croak "readline failed: $OS_ERROR\n";
      }
    } ## end if ( !eof $fh )

    return $cur_line;
  },
  process => sub {
    my ( $fh, $all_lines, $args, $current_line ) = @_;

    return $current_line;
  },
  post => sub {
    my ( $fh, $all_lines, $args ) = @_;

    $args->{end_time} = time;

    my $retval;

    if ( $args->{merge_lines} ) {
      $retval = ${ $all_lines->sref };
    }
    else {
      $retval = $all_lines;
    }

    close $fh
      or croak 'could not close' . $args->{file} . $NL;

    return $retval, %$args;
  },
);

caller() or __PACKAGE__->main();

sub process_file {
  my ( $file, %args ) = @_;

  my $chomp = $args{'chomp'};

  $args{'file'} = $file || $EMPTY;

  my %processors = map { $_, $args{$_} } qw{ pre next_line process post };

  foreach (qw{ pre next_line process post}) {
    if ( !$processors{$_} ) {
      $processors{$_} = $DEFAULT_PROCESSORS{$_};
    }
  }

  $args{'default_processors'} = \%DEFAULT_PROCESSORS;

  my ( $fh, $all_lines ) = $processors{'pre'}->( $file, \%args );

  if ( !$fh || !ref $all_lines || !reftype($all_lines) eq 'ARRAY' ) {
    croak "invalid pre processor return: wanted file handle, array ref\n";
  }

  while (1) {
    my $cur_line = $processors{next_line}->( $fh, $all_lines, \%args );
    last if !defined $cur_line;

    $args{'raw_count'}++;

    if ( $args{'chomp'} ) {
      chomp $cur_line;
    }

    if ( $args{'trim'} && $args{'trim'} =~ /(front|both)/ ) {
      $cur_line =~ s/^\s+//;
    }

    if ( $args{'trim'} && $args{'trim'} =~ /(both|back)/ ) {
      $cur_line =~ s/\s+$//;
    }

    # skip?
    my $skip = $FALSE;

    if ( $args{'skip_blank_lines'} || $args{'skip_comments'} ) {

      if ( $args{'skip_blank_lines'} && "$cur_line" eq $EMPTY ) {
        $skip = $TRUE;
      }

      # if we're not chomping, then consider new line a blank line?
      if ( !$args{chomp} && "$cur_line" eq $NL ) {
        $skip = $TRUE;
      }

      if ( $args{'skip_comments'} && $cur_line =~ /^#/xsm ) {
        $skip = $TRUE;
      }
    } ## end if ( $args{'skip_blank_lines'...})

    $args{skipped} = $args{skipped} + $skip ? 1 : 0;
    next if $skip;

    $cur_line
      = $processors{'process'}->( $fh, $all_lines, \%args, $cur_line );

    # return undef to halt processing (or die)
    last if !defined $cur_line;

    if ( $args{merge_lines} ) {
      $all_lines->print($cur_line);
    }
    else {
      push @{$all_lines}, $cur_line;
    }
  } ## end while (1)

  return $processors{'post'}->( $fh, $all_lines, \%args );
} ## end sub process_file

sub post {
  my ($fh, $all_lines, $args) = @_;
  return($_[2]->{default_processors}->{post}->(@_));
}

sub pre {
  my ($fh, $args) = @_;
  return ($args->{default_processors}->{pre}->(@_));
}

sub process {
  my ($fh, $all_lines, $args) = @_;
  return $_[2]->{default_processors}->{process}->(@_);
}

sub next_line {
  my ($fh, $all_lines, $args) = @_;
  return $_[2]->{default_processors}->{next_line}->(@_);
}

sub main {
  require IO::Scalar;
  require Data::Dumper;
  require JSON::PP;
  require Text::CSV_XS;
  
  JSON::PP->import('decode_json');
  
  Data::Dumper->import('Dumper');
  
  # +------------------+
  # | READ A TEXT FILE | 
  # +------------------+

  my $buffer =<<'END_OF_TEXT';
line 1
 line 2   
 
line 4

line 5
END_OF_TEXT

  my $fh = IO::Scalar->new(\$buffer);

  print Dumper(
    process_file(
      $fh,
      skip_blank_lines => $TRUE,
      chomp            => $TRUE,
      trim             => 'both'
    )
  );

  $fh = IO::Scalar->new(\$buffer);
  print Dumper(
    process_file(
      $fh,
      post  => sub {
        my @retval = post(@_);
        $retval[0] = join '', @{ $_[1] };
        return @retval;
      }
    )
  );


  # +------------------+
  # | READ A JSON FILE | 
  # +------------------+

  my $json_text =<<'END_OF_TEXT';
{
  "foo" : "bar",
  "baz" : "buz"
}

END_OF_TEXT

  $fh = IO::Scalar->new(\$json_text);
  
  print Dumper(
    process_file(
      $fh,
      chomp => 1,
      post  => sub {
        post(@_);
        return decode_json( join '', @{ $_[1] } );
      }
    )
  );

  $fh = IO::Scalar->new(\$json_text);
  
  print Dumper(
    decode_json(
      process_file( $fh, merge_lines => 1, chomp => 1)
    )
  );


  # +-----------------+
  # | READ A CSV FILE | 
  # +-----------------+

  my $csv_text = <<'END_OF_TEXT';
"id","first_name","last_name"
0,"Rob","Lauer"
END_OF_TEXT

  $fh = IO::Scalar->new( \$csv_text );

  my $csv = Text::CSV_XS->new;

  my ($csv_lines) = process_file(
    $fh,
    csv   => $csv,
    chomp => 1,
    has_headers => 1,
    pre   => sub {
      my ( $fh, $args ) = @_;

      if ( $args->{'has_headers'} ) {
        my @column_names = $args->{csv}->getline($fh);
        $args->{csv}->column_names(@column_names);
      }

      return (pre($fh, $args));
    },
    next_line => sub {
      my ( $fh, $all_lines, $args ) = @_;
      my $ref = $args->{csv}->getline_hr($fh);
      return $ref;
      }
  );

  print Dumper($csv_lines);
                               
  exit 0;
}

1;

=pod

=head1 NAME

C<File::Process>

=head1 SYNOPSIS

 my ($lines, $info) = $process_file($file, process => sub { 
     my ($fh, $lines, $args, $line) = @_;
     return uc($line);
    });

=head1 DESCRIPTION

Many scripts need to process on or more text files. The boiler-plate
usually looks something like:

 open my $fh, '<', $file
    or croak "blah blah blah...\n";

 while (<$fh> ) {
   # do something...
 }

 close $fh or
    croak "blah blah blah...\n";

The I<do something...> part often involves other common operations like
removing new lines, skipping blank lines, etc. It gets worse when you
have to write the same template for processing different files in a
script. 

This class that provides a simple harness for processing text files,
taking the drudgery out of writing a simple text processor. It is most
effect when used on relatively small files.

In it's most basic form the class will return all of the lines in a
text file. The class exports 1 method (C<process_file>) which uses
four subroutines that you can override or use in conjunction with your
processors.

=head1 METHODS AND SUBROUTINES

=head2 process_file(file, options)

You start the processing of the file by calling C<process_file> with
the name of the file or a handle to an open file and a B<list> of
options.  Note that the processors pass a B<reference> to this list of
options during the processing of the file.

The method returns a list containing a reference to an array that
contains each line of the file followed by the list of elements in the
hash that was originally passed to it (along with any other data your
custom method have inserted into it).

 my ($lines, %options) = process_file("foo.txt", chomp => 1);

=over 5

=item file

Path to the file to be processed or a handle to an open file.

=item options

A B<list> of options. You can send whatever options your custom
processor supports. As each line is read C<process_file> supports
these options:

=over 10

=item skip_blank_lines

Skip I<blank lines>. A blank line is considered a line with no data or
if I<chomp> mode is B<not> enabled, a line with only a new line character.

=item skip_comments

Set C<skip_lines> to a true value to skip lines that beging with '#'.

=item merge_lines

Merges lines together rather that creating an array of
lines. Typically used with the C<chomp> option. When C<merge_lines> is
set to a true value, C<IO::Scalar> is used to efficiently create a
single scalar from all of the lines in the file.

=item chomp

Set C<chomp> to a true value to remove a trailing new line.

=item trim

Set C<trim> to one of I<front>, I<back>, I<both> true value to remove
whitespace from the front, back or both front and back of a line. Note
that this operation is performed I<before> your custom processor is
called and may result in the line being skipped if the
C<skip_blank_lines> option is set to a true value.

=back

C<process_file> will execute a pre processing subroutine (I<pre>), a
processor (I<process>) which is passed the next line and returns the
processed line, and a post processing routine (I<post>).  The
default processors are described below.

=head2 pre(file, options)

=over 5

=item file

Path to a file that can be opened for reading or a handle
to an open file.

=item options

A reference to a hash that contains the options passed from
C<process_file>.  The hash will be passed to the C<process> method, so
can be used to store data as you are processing the each line.  The
default C<process> method will record counts of lines processed and other
potentially useful statistics.

=back

=head2 next_line(fh, lines, options)

The C<next_line> method is passed the file handle, the buffer of
accumulated lines, and a reference to a hash of options passed to
C<process_file>. It is expected to return the I<next line> of the
file. Your custom processor however can return anything it likes. That
object will be sent to the C<process> subroutine for possible further
processing.

Returning C<undef> will halt further processing.

=head2 process(fh, lines, options, current_line)

The C<process> method is passed the file handle, the buffer of
accumulated lines, a reference to a hash of options passed to
C<process_file> and the next line of the the text file.  The default
processor simply returns the C<current_line> value.  If the C<chomp>
option is set to true when you called C<process_file>, the line will
be chomped.  You can also set the C<skip_blank_lines> or
C<skip_comments> to skip blank lines or skip lines that begin with
'# '. 

=over 5

=item fh

Handle to an open file or an object that supports an C<IO::Handle>
like interface. If C<fh> is undefined the 

=item lines

A reference to an array that contains the lines read thus far.

=item options

A reference to a hash of options passed to C<process_file>.

=item current_line

The next line of data from the file.

=back

=head2 post(fh, lines, options)

The C<post> method is passed the same three arguments as passed to
C<process>.  The default C<post> method closes the file and records
the end time of process. The default C<post> method returns an array
reference to the buffer of lines and list of options.  Note that a
reference to the list is passed in but a B<list> is returned.  This is
also the return value of C<process_file>.  Your custon post can return
anything it wants.

=head1 DEFAULT PROCESSORS

Any of default processors (B<pre>, B<next_line>, B<process>, B<post>)
can be called before or after your custom processors.  Pass these
methods the same list you receive.

  process_file(
    "foo.txt",
    post  => sub {
      my @retval = post(@_);
      $retval[0] = join '', @{ $_[1] };
      return @retval;
    }
  );

=head1 STATISTICS

=over 5

=item start_time

=item end_time

=item raw_count

=item skipped

=back

=head1 EXAMPLES

=over 5

=item * Return the all of the lines in a text file

 my ($lines) = process_file('foo.txt');

=item * Read JSON file

  print Dumper(
    process_file(
      $fh,
      chomp => 1,
      post  => sub {
        post(@_);
        return decode_json( join '', @{ $_[1] } );
      }
    )
  );

...or

  print Dumper(
    decode_json(
      process_file(
        $fh,
        chomp       => 1,
        merge_lines => 1
      )
    )
  );

=item * Read CSV file

 my $csv = Text::CSV_XS->new;

 my ($csv_lines) = process_file(
   'foo.csv',
   csv   => $csv,
   chomp => 1,
   has_headers => 1,
   pre   => sub {
     my ( $fh, $args ) = @_;

     if ( $args->{'has_headers'} ) {
       my @column_names = $args->{csv}->getline($fh);
       $args->{csv}->column_names(@column_names);
     }

     return (pre($fh, $args));
   },
   next_line => sub {
     my ( $fh, $all_lines, $args ) = @_;
     my $ref = $args->{csv}->getline_hr($fh);
     return $ref;
     }
 );

=head1 LICENSE

This module is free software. It may be used, redistributed and/or
modified under the same terms as Perl itself.

=head1 AUTHOR

Rob Lauer - <rlauer6@comcast.net>

=cut
