package FASTX::ScriptHelper;
#ABSTRACT: Shared routines for binaries using FASTX::Reader and FASTX::PE.

use 5.012;
use warnings;
use File::Fetch;
use Carp qw(confess cluck);
use Data::Dumper;
use FASTX::Reader;
use File::Basename;
use File::Spec;
use Term::ANSIColor qw(color);
use JSON::PP;
use Capture::Tiny qw(capture);
use Time::HiRes qw( time );
use Scalar::Util qw( blessed refaddr reftype);
$FASTX::ScriptHelper::VERSION = '0.1.2';

our @ISA = qw(Exporter);
our @EXPORT = qw(rc fu_printfasta fu_printfastq verbose);
our @EXPORT_OK = qw($fu_linesize $fu_verbose);  # symbols to export on request


sub new {

    # Instantiate object
    my ($class, $args) = @_;

    my %accepted_parameters = (
      'verbose' => 1,
      'debug'   => 1,
      'logfile' => 1,
      'linesize'=> 1,
    );

    my $valid_attributes = join(', ', keys %accepted_parameters);

    for my $parameter (keys %{ $args} ) {
      confess("Attribute <$parameter> is not expected. Valid attributes are: $valid_attributes\n")
        if (! $accepted_parameters{$parameter} );
    }


    my $self = {
        logfile     => $args->{logfile}  // undef,
        debug       => $args->{debug}    // 0,
        verbose     => $args->{verbose}  // 0,
        linesize    => $args->{linesize} // 0,
    };
    my $object = bless $self, $class;

    # Regular log file
    if (defined $self->{logfile}) {
      verbose($self, "Ready to log in $object->{logfile}");
      open my $logfh, '>', "$object->{logfile}"  || confess("ERROR: Unable to write log file to $object->{logfile}\n");
      $object->{logfh} = $logfh;
      $object->{do_log} = 1;
    } else {
      # Set {logfh} to Stderr, but do not set {do_log}
      $object->{logfh} = *STDERR;
    }

    return $object;
}



sub fu_printfasta {

    my $self = undef;
    if ( ref($_[0]) eq 'FASTX::ScriptHelper' ) {
      $self = shift @_;
    }

    my ($name, $comment, $seq) = @_;
    confess("No sequence provided for $name") unless defined $seq;
    my $print_comment = '';
    if (defined $comment) {
        $print_comment = ' ' . $comment;
    }

    say '>', $name, $print_comment;
    if ($self) {
        print split_string($self,$seq);
    } else {
        print split_string($seq);
    }

}


sub fu_printfastq {
    my $self = undef;
    if ( ref($_[0]) eq 'FASTX::ScriptHelper' ) {
      $self = shift @_;
    }
    my ($name, $comment, $seq, $qual) = @_;
    my $print_comment = '';
    if (defined $comment) {
        $print_comment = ' ' . $comment;
    }
    $qual = 'I' x length($seq) unless (defined $qual);
    say '@', $name, $print_comment;
    if ($self) {
        print split_string($self,$seq) , "+\n", split_string($self,$qual);
    } else {
        print split_string($seq) , "+\n", split_string($qual);
    }

}


sub rc {
    my $self = undef;
    if ( ref($_[0]) eq 'FASTX::ScriptHelper' ) {
      $self = shift @_;
    }
    my   $sequence = reverse($_[0]);
    if (is_seq($sequence)) {
        $sequence =~tr/ACGTacgt/TGCAtgca/;
        return $sequence;
    }
}


sub is_seq {
    my $self = undef;
    if ( ref($_[0]) eq 'FASTX::ScriptHelper' ) {
      $self = shift @_;
    }
    my $string = shift @_;
    if ($string =~/[^ACGTRYSWKMBDHVN]/i) {
        return 0;
    } else {
        return 1;
    }
}


sub split_string {
  my $self = undef;
  if ( ref($_[0]) eq 'FASTX::ScriptHelper' ) {
    $self = shift @_;
  }
	my $input_string = shift @_;
  confess("No string provided") unless $input_string;
	my $formatted = '';
	my $line_width = $self->{linesize} // $main::opt_line_size // 0; # change here

  return $input_string. "\n" unless ($line_width);
	for (my $i = 0; $i < length($input_string); $i += $line_width) {
		my $frag = substr($input_string, $i, $line_width);
		$formatted .= $frag."\n";
	}
	return $formatted;
}


sub verbose {
  my $self = undef;
  if ( ref($_[0]) eq 'FASTX::ScriptHelper' ) {
    $self = shift @_;
  }
  my ($message, $reference, $reference_name, @remainder) = @_;
  if ($remainder[0]) {
    $message .= $reference . $reference_name . join('', @remainder);
    $reference = undef;
    $reference_name = undef;
  } elsif (defined $reference and reftype $reference eq undef) {
    # Mistakenly passed list instead of string
    $message .= $reference;
    if (defined $reference_name) {
      $message .= $reference_name;
      $reference_name = undef;
    }
    $reference = undef;

  }
  my $variable_name = $reference_name // 'data';
  my $timestamp = _getTimeStamp();
  if ( (defined $self and $self->{verbose} ) or (defined $main::opt_verbose and $main::opt_verbose) ) {
    # Print
    if (defined $self->{do_log}) {
      $self->writelog($message, $reference, $reference_name);
    }
    say STDERR color('cyan'),"[$timestamp]", color('reset'), " $message";
    say STDERR color('magenta'), Data::Dumper->Dump([$reference], [$variable_name])
        if (defined $reference);
  } else {
    # No --verbose, don't print
    return -1;
  }

}



sub writelog  {
  my $self = undef;
  if ( ref($_[0]) eq 'FASTX::ScriptHelper' ) {
    $self = shift @_;
  }

  my ($message, $reference, $reference_name) = @_;
  my $variable_name = $reference_name // 'data';
  my $timestamp = _getTimeStamp();
  say {$self->{logfh}} "[$timestamp] $message";
  say {$self->{logfh}}  Data::Dumper->Dump([$reference], [$variable_name]) if (defined $reference);


}




sub download  {
  my $begin_time = time();
  my $self = undef;
  if ( ref($_[0]) eq 'FASTX::ScriptHelper' ) {
    $self = shift @_;
  }

  my ($url, $destination) = @_;
  if (defined $self->{do_log}) {
      $self->writelog( qq(Downloading "$url") );
  }


  my $downloader = File::Fetch->new(uri => $url);
  my $file_path = $downloader->fetch( to => $destination ) or confess($downloader->error);
  my $end_time = time();
  say Dumper $downloader;
  my $duration = sprintf("%.2fs", $end_time - $begin_time);
  return $file_path;
}

sub run  {
  my $begin_time = time();
  my $time_stamp = _getTimeStamp();
  my $self = undef;
  if ( ref($_[0]) eq 'FASTX::ScriptHelper' ) {
    $self = shift @_;
  }
  my %valid_attributes = (
    candie => 1,
    logall => 1,
  );


  my ($command, $options) = @_;
  _validate_attributes(\%valid_attributes, $options, 'run');
  if (defined $self) {
    $self->writelog("Shell> $command");
  }


  my $cmd = _runCmd($command);
  if ($cmd->{exit}) {
    $cmd->{failed} = 1;
    if (! $options->{candie}) {
      confess("Execution of an external command failed:\n$command");
    }
  }
  my $end_time = time();
  $cmd->{time} = $time_stamp;
  $cmd->{duration} = sprintf("%.2fs", $end_time - $begin_time);
  if (defined $self) {
    if ($options->{logall}) {
      $self->writelog("    +> Output: $cmd->{stdout}");
      $self->writelog("    +> Messages: $cmd->{stderr}");
    }
    $self->writelog("    +> Elapsed time: $cmd->{duration}; Exit status: $cmd->{exit};");

  }

  return ($cmd);


}


sub cpu_count {
  if ( $^O =~ m/linux/i ) {
    my($num) = qx(grep -c ^processor /proc/cpuinfo);
    return $1 if $num =~ m/^(\d+)/;
  }
  elsif ( $^O =~ m/darwin/i ) {
    my($num) = qx(system_profiler SPHardwareDataType | grep Cores);
    return $1 if $num =~ /.*Cores: (\d+)/;
  }
  return 1;
}

sub _getTimeStamp {

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
    my $timestamp = sprintf ( "%04d-%02d-%02d %02d:%02d:%02d",
                                   $year+1900,$mon+1,$mday,$hour,$min,$sec);
    return $timestamp;
}


sub _validate_attributes {
  my ($hash_ref, $options, $title) = @_;

  for my $attr (sort keys %{ $options } ) {
    confess "Invalid attribute '$attr' used calling routine '$title'\n" if (not defined ${ $hash_ref}{ $attr });
  }
  return;
}
sub _runCmd {
  if ( ref($_[0]) eq 'FASTX::ScriptHelper' ) {
     shift @_;
  }
  my @cmd = @_;
  my $output;
  $output->{cmd} = join(' ', @cmd);

  my ($stdout, $stderr, $exit) = capture {
    system( @cmd );
  };
  chomp($stderr);
  chomp($stdout);
  $output->{stdout} = $stdout;
  $output->{stderr} = $stderr;
  $output->{exit} = $exit;

  return $output;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FASTX::ScriptHelper - Shared routines for binaries using FASTX::Reader and FASTX::PE.

=head1 VERSION

version 1.11.0

=head2 new()

Initialize a new FASTX::ScriptHelper object. Notable parameters:

=over 4

=item I<verbose>

=item I<logfile>

=back

=head2 fu_printfasta

  arguments: sequenceName, sequenceComment, sequence

Prints a sequence in FASTA format.

=head2 fu_printfastq

  arguments: sequenceName, sequenceComment, sequence, Quality

Prints a sequence in FASTQ format.

=head2 rc

  arguments: sequence

Returns the reverse complementary of a sequence

=head2 is_seq

  arguments: sequence

Returns true if the sequence only contains DNA-IUPAC chars

=head2 split_string

  arguments: sequence

Returns a string with newlines at a width specified by 'linesize'

=head2 verbose

  arguments: message

Prints to STDERR (and log) a message, only if verbose is set

=head2 writelog

  arguments: message, []

Writes a message to the log file and STDERR, regardless of --verbose

=head2 download

  arguments: url, destination

Download a remote file

=head2 run

  arguments: command, [%options]

Execute a command. Options are:
  * candie BOOL, to tolerate non zero exit
  * logall BOOL, save to log STDOUT and STDERR

=head2 cpu_count

Returns the number of detected cores, default 1

=head1 AUTHOR

Andrea Telatin <andrea@telatin.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
