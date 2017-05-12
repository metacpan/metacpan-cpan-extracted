package GO::Utils::General;

=head1 NAME

GO::Utils::General - provides some general utilities for clients of other GO classes

=head1 SYNOPSIS

  use GO::Utils::General qw (CategorizeGenes);

  CategorizeGenes(annotation  => $annotation,
		  genes       => \@genes,
		  ambiguous   => \@ambiguous,
		  unambiguous => \@unambiguous,
		  notFound    => \@notFound);

=cut

use strict;
use warnings;
use diagnostics;

use vars qw (@ISA @EXPORT_OK $VERSION);
use Exporter;
@ISA = ('Exporter');
@EXPORT_OK = qw (CategorizeGenes);

$VERSION = 0.11;

my @kRequiredArgs = qw (annotation genes ambiguous unambiguous notFound);

##########################################################################
sub CategorizeGenes{
##########################################################################

=head2 CategorizeGenes

CategorizeGenes categorizes a set of genes into three categories, whether they
are ambiguous, whether they are not found, or whether they are unambiguous.  The 
category to which they belong is determined by using an annotation provider.

Usage:

  use GO::Utils::General qw (CategorizeGenes);

  CategorizeGenes(annotation  => $annotation,
		  genes       => \@genes,
		  ambiguous   => \@ambiguous,
		  unambiguous => \@unambiguous,
		  notFound    => \@notFound);

All the above named arguments are required:

annotation : A GO::AnnotationProvider concrete subclass instance
genes      : A reference to an array of gene names

The remaining arguments should be empty arrays, passed in by reference, that
will be populated by this function.

=cut

##########################################################################

    my (%args) = @_;

    foreach my $arg (@kRequiredArgs){

	if (!exists $args{$arg} || !defined $args{$arg}){

	    die "You must provide a $arg argument to CategorizeGenes";

	}

    }

    my $annotation     = $args{'annotation'};
    my $genesRef       = $args{'genes'};
    my $ambiguousRef   = $args{'ambiguous'};
    my $unambiguousRef = $args{'unambiguous'};
    my $notFoundRef    = $args{'notFound'};

    foreach my $gene (@{$genesRef}){

	if ($annotation->nameIsAmbiguous($gene)){

	    push(@{$ambiguousRef}, $gene);
	    next;

	}

	my $name = $annotation->standardNameByName($gene);

	if (defined $name){

	    push(@{$unambiguousRef}, $gene);

	}else{

	    push(@{$notFoundRef}, $gene);

	}

    }

}

1; # keep Perl happy
