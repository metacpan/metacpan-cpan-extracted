package FASTQ::Reader;
use 5.014;
use Term::ANSIColor qw(:constants);
use warnings;

# ABSTRACT: FASTQ reader using Moose
use Moose;
use Data::Dumper;
use Path::Class;
use Carp qw(confess);

has message => (is => 'ro', isa => 'Str');
has status =>  (is => 'ro', isa => 'Int');

has debug        => (
    is => 'rw',
    isa => 'Bool'
);

has verbose      => (
    is => 'rw',
    isa => 'Bool'
);


has filename => (is => 'ro', isa => 'Str', required => 1);
    has fh => (is => 'rw', isa => 'FileHandle', lazy => 1, builder => '_build_fh');
    #                                           ~~~~~~~~~

    sub _build_fh {
        my ($self) = @_;
        open my $fh, '<', $self->filename or die $!;
        return $fh
    }


sub getFastqRead {
  my $self   = shift;
  my $seq_object = undef;
  my $header = readline($self->fh);
  my $seq    = readline($self->fh);
  my $check  = readline($self->fh);
  my $qual   = readline($self->fh);

  # Check 4 lines were found (FASTQ)
  return undef unless (defined $qual);
  # Fast format control: header and separator
  if ( (substr($header, 0, 1) eq '@') and (substr($check, 0, 1) eq '+') ) {
    chomp($header);
    chomp($seq);
    chomp($qual);
    # Also control sequence integrity
    if ($seq=~/^[ACGTNacgtn]+$/ and length($seq) == length($qual) ) {
      my ($name, $comments) = split /\s+/, substr($header, 1);
      $seq_object->{name} = $name;
      $seq_object->{comments} = $comments;
      $seq_object->{seq} = $seq;
      $seq_object->{qual} = $qual;

    } else {
      # Return error (corrupted FASTQ)
      $self->{message} = "Unknown format: expecting FASTQ (corrupted?)";
      $self->{status} = 0;

    }
  } else {
    # Return error (not a FASTQ)
    $self->{message} = "Unknown format: expecting FASTQ (wrong header)";

    if (substr($seq, 0,1 ) eq '>' ) {
      # HINT: is FASTA?
      $self->{message} .= " (might be FASTA instead)";
    }
    $self->{status} = 0;
  }

  return $seq_object;
}

sub _debug_get {
    my $this = shift;
    my $line = '<undef>';

    $line = readline($this->fh);

    return $line;

}


1;
