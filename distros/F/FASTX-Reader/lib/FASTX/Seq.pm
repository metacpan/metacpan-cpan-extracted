package FASTX::Seq;
#ABSTRACT: A class for representing a sequence for FASTX::Reader

use 5.012;
use warnings;
use Carp qw(confess);
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use File::Basename;
$FASTX::Seq::VERSION = $FASTX::Reader::VERSION;

require Exporter;
our @ISA = qw(Exporter);



sub new {
 
    my ($class, $seq, $name, $comment, $qual) = @_;
 
    if ( defined $seq && defined $qual
      && (length($seq) != length($qual))) {
        confess "Sequence/quality length mismatch";
    }
 
    my $self = bless {}, $class;
    # Required
    $self->{seq}  = $seq  // '';

    $self->{name} = $name   // undef;
    $self->{comment} = $comment // undef;
    $self->{qual} = $qual // undef;
 
    return $self;
 
}




sub seq : lvalue {
    # Update sequence
    my ($self, $new_val) = @_;
    $self->{seq} = $new_val if (defined $new_val);
    return $self->{seq};
}



sub name : lvalue {
    # Update name
    my ($self, $new_val) = @_;
    $self->{seq} = $new_val if (defined $new_val);
    return $self->{name};
}



sub qual : lvalue {
    # Update quality
    my ($self, $new_val) = @_;
    $self->{qual} = $new_val if (defined $new_val);
    return $self->{qual};
}


sub comment : lvalue {
    # Update comment
    my ($self, $new_val) = @_;
    $self->{comment} = $new_val if (defined $new_val);
    return $self->{comment};
}



sub rev {
    # Update comment
    my ($self) = @_;
    $self->{seq} = reverse($self->{seq});
    $self->{qual} = reverse($self->{qual}) if (defined reverse($self->{qual}));
    return $self;
}


sub rc {
    # Update comment
    my ($self) = @_;
    $self->{seq} = reverse($self->{seq});    
    if ($self->{seq} =~ /U/i) {
        $self->{seq} =~ tr/ACGURYSWKMBDHVacguryswkmbdhv/UGCAYRSWMKVHDBugcayrswmkvhdb/;
    } else {                      
        $self->{seq} =~ tr/ACGTRYSWKMBDHVacgtryswkmbdhv/TGCAYRSWMKVHDBtgcayrswmkvhdb/;
    }
    $self->{qual} = reverse($self->{qual}) if (defined reverse($self->{qual}));
    return $self;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FASTX::Seq - A class for representing a sequence for FASTX::Reader

=head1 VERSION

version 1.3.0

=head1 SYNOPSIS

A sequence object supported from C<FASTX::Reader> structured as
a C<BioX::Seq> record, but keeping the attribute names as the
scalar natively provided by C<FASTX::Reader>.

  use FASTX::Seq;
  my $fastq = new($seq, $name, $comment, $qual);
  my $fasta = new($seq, $name, $comment);
  my $barseq = new("ATGC"); 

  # Change attribute
  $fastq->seq("ATGCTT");

=head2 new($seq, $name, $comment, $qual)

Create a new instance of C<FASTX::Seq>.
The sequence is the only required field.

=head2 seq()

Get or update the sequence field.

    my $seq = $fastq->seq();
    $fastq->seq("ATGCTT");

=head2 name()

Get or update the sequence field.

    my $seq = $fastq->name();
    $fastq->name("seq1");

=head2 qual()

Get or update the sequence field.

    my $seq = $fastq->qual();
    $fastq->qual("IIIII");

=head2 comment()

Get or update the sequence field.

    my $seq = $fastq->comment();
    $fastq->comment("len=" . length($fastq->seq()));

=head2 rev()

Reverse (no complement) the sequence.

    my $rev = $fastq->rev();

=head2 rc()

Reverse and complement the sequence.

    my $rc = $fastq->rc();

=head1 AUTHOR

Andrea Telatin <andrea@telatin.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
