package FASTX::ScriptHelper;
#ABSTRACT: Shared routines for binaries using FASTX::Reader and FASTX::PE.

use 5.012;
use warnings;

use Carp qw(confess cluck);
use Data::Dumper;
use FASTX::Reader;
use File::Basename;
use File::Spec;
use Term::ANSIColor qw(color);
use JSON::PP;
use Capture::Tiny qw(capture);


$FASTX::ScriptHelper::VERSION = '0.1.0';

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

    if (defined $self->{logfile}) {
      verbose($self, "Ready to log in $object->{logfile}");
      open my $logfh, '>', "$object->{logfile}"  || confess("ERROR: Unable to write log file to $object->{logfile}\n");
      $object->{logfh} = $logfh;
      $object->{do_log} = 1;
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


sub rc ($) {
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
  my ($message, $reference, $reference_name) = @_;
  my $variable_name = $reference_name // 'data';
  my $timestamp = _getTimeStamp();
  if ( (defined $self and $self->{verbose} ) or (defined $main::opt_verbose and $main::opt_verbose) ) {
    if (defined $self->{do_log}) {
      say {$self->{logfh}} "[$timestamp] $message";
      say {$self->{logfh}}  Data::Dumper->Dump([$reference], [$variable_name])
        if (defined $reference);
    } 
    say STDERR color('cyan'),"[$timestamp]", color('reset'), " $message";
    say STDERR color('magenta'), Data::Dumper->Dump([$reference], [$variable_name])
        if (defined $reference);
  } else {
    return -1;
  }

}

sub run  {
  my $self = undef;
  if ( ref($_[0]) eq 'FASTX::ScriptHelper' ) {
    $self = shift @_;
  }
  my ($command, $options) = @_;

  

  my $cmd = _runCmd($command);
  if ($cmd->{exit}) {
    $cmd->{failed} = 1;
    if (! $options->{candie}) {
      confess("Execution of an external command failed:\n$command");
    }
  }
  return ($cmd);


}

sub writelog  {
  my $self = undef;
  if ( ref($_[0]) eq 'FASTX::ScriptHelper' ) {
    $self = shift @_;
  }
  my ($message, $reference) = @_;

  if (defined $self and $self->{do_log}) {
    say {$self->{logfh}} "[", _getTimeStamp() ,"] $message";
  }


}

sub _getTimeStamp {

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
    my $timestamp = sprintf ( "%04d-%02d-%02d %02d:%02d:%02d",
                                   $year+1900,$mon+1,$mday,$hour,$min,$sec);
    return $timestamp;
}

sub _runCmd(@) {
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

version 0.90

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

=head2 run

  arguments: command, [%options]

Execute a command. Options are:
  * candie BOOL, to tolerate non zero exit

=head2 writelog

  arguments: message, []

Writes a message to the log file and STDERR, regardless of --verbose

=head1 AUTHOR

Andrea Telatin <andrea@telatin.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
