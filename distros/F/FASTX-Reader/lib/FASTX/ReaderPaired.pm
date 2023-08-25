package FASTX::ReaderPaired;
#ABSTRACT: Warning, Experimental Paired-End FASTQ files reader, based on FASTX::Reader.

use 5.012;
use warnings;
use Carp qw(confess cluck);
use Data::Dumper;
use FASTX::Reader;
use File::Basename;
$FASTX::ReaderPaired::VERSION = $FASTX::Reader::VERSION;

my $for_suffix_re = '(/1|_R?1)';
my $rev_suffix_re = '(/2|_R?2)';


sub new {

    # Instantiate object
    my ($class, $args) = @_;

    my %accepted_parameters = (
      'filename' => 1,
      'tag1' => 1,
      'tag2' => 1,
      'rev' => 1,
      'interleaved' => 1,
      'nocheck' => 1,
      'revcompl' => 1,
      'verbose'  => 1,
    );

    my $valid_attributes = join(', ', keys %accepted_parameters);

    if ($args) {
      for my $parameter (keys %{ $args} ) {
        confess("Attribute <$parameter> is not expected. Valid attributes are: $valid_attributes\n")
          if (! $accepted_parameters{$parameter} );
      }
    } else {
      $args->{filename} = '{{STDIN}}';
    }

    my $self = {
        filename    => $args->{filename},
        rev         => $args->{rev},
        interleaved => $args->{interleaved} // 0,
        tag1        => $args->{tag1},
        tag2        => $args->{tag2},
        nocheck     => $args->{nocheck} // 0,
        revcompl    => $args->{revcompl} // 0,
        verbose     => $args->{verbose} // 0,
    };


    my $object = bless $self, $class;

    # Required to read STDIN?
    if ($self->{filename} eq '{{STDIN}}' or not $self->{filename}) {
      $self->{interleaved} = 1;
      $self->{stdin} = 1;
    }

    if ($self->{interleaved}) {
      # Decode interleaved
      if ($self->{stdin}) {
        $self->{R1} = FASTX::Reader->new({ filename => '{{STDIN}}' });
      } else {
        $self->{R1} = FASTX::Reader->new({ filename => "$self->{filename}"});
      }
    } else {
      # Decode PE
      if ( ! defined $self->{rev} ) {

        # Auto calculate reverse (R2) filename
        my $rev = basename($self->{filename});

        if (defined $self->{tag1} and defined $self->{tag2}) {
          $rev =~s/$self->{tag1}/$self->{tag2}/;
          $rev = dirname($self->{basename}) . $rev;
        } else {

          $rev =~s/_R1/_R2/;
          say STDERR "R2 not provided, autoguess (_R1/_R2): $rev" if ($self->{verbose});
          if ($rev eq basename($self->{filename}) ) {
              $rev =~s/_1\./_2./;
              say STDERR "R2 not provided for $self->{filename}, now autoguess (_1/_2): $rev" if ($self->{verbose});
          }

          $rev = dirname($self->{filename}) . '/' . $rev;
        }

        if (not -e $rev)  {
          # TO DEFINE: confess("ERROR: The rev file for '$self->{filename}' was not found in '$rev'\n");
          say STDERR "WARNING: Pair not specified and R2 \"$rev\" not found for R1 \"$self->{filename}\":\n trying parsing as interleaved.\n";
          $self->{interleaved} = 1;
          $self->{nocheck} = 0;
        } elsif ($self->{filename} eq $rev) {
          say STDERR "WARNING: Pair not specified for \"$self->{filename}\":\n trying parsing as interleaved.\n";
          $self->{interleaved} = 1;
          $self->{nocheck} = 0;
        } else {
          $self->{rev} = $rev;
        }

      }

      $self->{R1}  = FASTX::Reader->new({ filename => "$self->{filename}"});
      $self->{R2}  = FASTX::Reader->new({ filename => "$self->{rev}"})
        if (not $self->{interleaved});

    }


    return $object;
}



sub getReads {
  my $self   = shift;
  #my ($fh, $aux) = @_;
  #@<instrument>:<run number>:<flowcell ID>:<lane>:<tile>:<x-pos>:<y-pos>:<UMI> <read>:<is filtered>:<control number>:<index>
  my $pe;
  my $r1;
  my $r2;

  if ($self->{interleaved}) {
    $r1 = $self->{R1}->getRead();
    $r2 = $self->{R1}->getRead();
  } else {
    $r1 = $self->{R1}->getRead();
    $r2 = $self->{R2}->getRead();
  }

  if (! defined $r1->{name} and !defined $r2->{name}) {
    return;
  } elsif (! defined $r1->{name} or !defined $r2->{name}) {
    my $r = $r1->{name} // $r2->{name};
    $self->{error} = "Premature termination, missing read mate for \"$r\"";
    return;
  }

  my $name_1;
  my $name_2;

  if ($self->{nocheck} != 1) {
    $name_1 = $r1->{name};
    $name_2 = $r2->{name};
    $name_1 =~s/${for_suffix_re}$//;
    $name_2 =~s/${rev_suffix_re}$//;
    if ($name_1 ne $name_2) {
      confess("Read name different in PE:\n[$r1->{name}] !=\n[$r2->{name}]\n");
    }

    if (not $r1->{qual} or  not $r2->{qual}) {
      confess("Missing quality for one of the two reads ($name_1, $name_2)");
    }
  }


  $pe->{name} = $name_1 // $r1->{name};
  $pe->{seq1} = $r1->{seq};
  $pe->{qual1} = $r1->{qual};

  if ($self->{revcompl}) {
    $pe->{seq2} = _rc( $r2->{seq} );
    $pe->{qual2} = reverse( $r2->{qual} );
  } else {
    $pe->{seq2} = $r2->{seq};
    $pe->{qual2} = $r2->{qual};
  }

  $pe->{comment1} = $r1->{comment};
  $pe->{comment2} = $r2->{comment};

  return $pe;

}





sub _rc {
  my $sequence = shift @_;
  $sequence = reverse($sequence);
  $sequence =~tr/ACGTacgt/TGCAtgca/;
  return $sequence;
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FASTX::ReaderPaired - Warning, Experimental Paired-End FASTQ files reader, based on FASTX::Reader.

=head1 VERSION

version 1.11.0

=head1 SYNOPSIS

  use FASTX::ReaderPaired;
  my $filepath = '/path/to/assembly_R1.fastq';
  # Will automatically open "assembly_R2.fastq"
  my $fq_reader = FASTX::Reader->new({
    filename => "$filepath",
  });

  while (my $seq = $fasta_reader->getRead() ) {
    print $seq->{name}, "\t", $seq->{seq1}, "\t", $seq->{qual1}, "\n";
    print $seq->{name}, "\t", $seq->{seq2}, "\t", $seq->{qual2}, "\n";
  }

=head1 METHODS

=head2 new()

Initialize a new FASTX::Reader object passing 'B<filename>' argument for the first pairend,
and optionally 'B<rev>' for the second (otherwise can be guessed substituting 'R1' with 'R2' and
'_1.' with '_2.')

  my $pairend = FASTX::Reader->new({
      filename => "$file_R1",
      rev      => "$file_R2"
  });

To read from STDIN either pass C<{{STDIN}}> as filename, or don't pass a filename at all.
In this case the module will expect an interleaved pairedend file.

  my $seq_from_stdin = FASTX::Reader->new();

If a '_R2' file is not found, the module will try parsing as B<interleaved>. This can be forced with:

  my $seq_from_file = FASTX::Reader->new({
    filename    => "$file",
    interleaved => 1,
  });

=head2 getReads()

Will return the next sequences in the FASTA / FASTQ file.
The returned object has these attributes:

=over 4

=item I<name>

header of the sequence (identifier)

=item I<comment1> and I<comment2>

any string after the first whitespace in the header, for the first and second paired read respectively.

=item I<seq1> and I<seq2>

DNA sequence for the first and the second pair, respectively

=item I<qual1> and I<qual2>

quality for the first and the second pair, respectively

=back

=head1 SEE ALSO

=over 4

=item L<FASTX::Reader>

The FASTA/FASTQ parser this module is based on.

=back

=head1 AUTHOR

Andrea Telatin <andrea@telatin.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
