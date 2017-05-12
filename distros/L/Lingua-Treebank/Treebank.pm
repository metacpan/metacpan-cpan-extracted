package Lingua::Treebank;

use 5.008;
use strict;
use warnings;

##################################################################
use Carp;

require Exporter;

our @ISA = qw ( Exporter ) ;
our @EXPORT_OK = qw();
our @EXPORT = qw();
our $VERSION = '0.16';

our $MAX_WARN_TEXT = 100;
our $VERBOSE = 1;
##################################################################
use Lingua::Treebank::Const;
our $CONST_CLASS = 'Lingua::Treebank::Const';
##################################################################
sub from_penn_file {
    my ($class, $file) = @_;

    open (my $fh, "<$file") or die "couldn't open $file: $!\n";
    my @results = $class->from_penn_fh($fh);
    close $fh or die "couldn't close $file: $!\n";

    return @results;
}
##################################################################
sub from_penn_fh {
    my ($class, $fh) = @_;

    my $rawTrees;

    if (not UNIVERSAL::isa($CONST_CLASS, 'Lingua::Treebank::Const')) {
	carp "CONST_CLASS value $CONST_CLASS",
	  " doesn't seem to be a subclass of Lingua::Treebank::Const\n";
    }

  LINE:
    while (<$fh>) {

        chomp;              # remove newlines

        if (   substr( $_, 0, 3 ) eq '*x*'
            or substr( $_, 0, 10 ) eq '=' x 10 )
        {
            # skip header copyright comments, bar of ====
            next LINE;
        }

	next if /^\s*$/; # skip entirely blank lines

	# slurp in the rest of the merge file all at once
	local $/;
	undef $/;
	$rawTrees = $_ . (<$fh>);
    }


    my (@utterances);
    while ($rawTrees) {
	$rawTrees =~ s/^\s+//;
	my $token = Lingua::Treebank::Const->find_brackets($rawTrees);

	if (defined $token) {
	    substr ($rawTrees, 0, length $token) = '';

	    $rawTrees =~ s/^\s+//;

	    my $utt = $CONST_CLASS->new->from_penn_string($token);
	    if (defined $utt) {
		push @utterances, $utt;
	    }
	    else {
		carp "couldn't parse '", cite_warning($token),
		  "' remaining data '", cite_warning($rawTrees),
		    "' in filehandle ignored";
		last;
	    }
	}
	else {
	    # no token extractable
	    carp "unrecognized data '", cite_warning($rawTrees),
	      "' remaining in filehandle ignored";
	    last;
	}
	$rawTrees =~ s/^\s*//;
    }

    return @utterances;
}


sub from_cnf_file {
    my ($class, $file) = @_;

    open (my $fh, "<$file") or die "couldn't open $file: $!\n";
    my @root_nodes = $class->from_cnf_fh($fh);
    close $fh or die "couldn't close $file: $!\n";

    return @root_nodes;
}

# BUGBUG Should share code with from_penn_fh
sub from_cnf_fh {
    my ($class, $fh) = @_;

    my @root_nodes;
  LINE:
    while (<$fh>) {
	chomp;
	s/#.*$//; # Remove comments
	next LINE if (/^\s*$/); # Skip empty lines.
	next LINE if (/^<s.*>$/); # Skip sentence annotation used by
                                  # the Structured Language Model.

      NODE:
	while (length $_) {
	    my $text = Lingua::Treebank::Const->find_brackets($_);

	    if (length $text) {

		# Remove the matched constituent from the remaining
		# text.
		substr ($_, 0, length $text) = '';
		s/^\s+//;

		# The bracketed text is a CNF treebank constituent.
		my Lingua::Treebank::Const $node =
		  Lingua::Treebank::Const->new->from_cnf_string($text);

		if (not defined $node) {
		    warn "couldn't parse '$text', remaining data '$_; in line $.filehandle ignored";
		    last NODE;
		}

		push @root_nodes, $node;
	    }
	    else {
		# No token extractable.
		warn "unrecognized data '$_', remaining in line $. ignored\n";
		last NODE;
	    }
	}
    }

    return @root_nodes;
}




##################################################################
sub cite_warning {
    my $text = shift;
    my $warning;
    if (length $text > $MAX_WARN_TEXT) {
	$warning =
	  substr($text, 0, $MAX_WARN_TEXT / 2);
	$warning .= ' [ ... OMITTED ... ] ';
	$warning .=
	  substr($text, -($MAX_WARN_TEXT / 2) );
    }
    else {
	$warning = $text;
    }
    return $warning;
}
##################################################################
1;

__END__

=head1 NAME

Lingua::Treebank - Perl extension for manipulating the Penn Treebank format

=head1 SYNOPSIS

  use Lingua::Treebank;

  my @utterances = Lingua::Treebank->from_penn_file($filename);

  foreach (@utterances) {
    # $_ is a Lingua::Treebank::Const now

    foreach ($_->get_all_terminals) {
      # $_ is a Lingua::Treebank::Const that is a terminal (word)

      print $_->word(), ' ' $_->tag(), "\n";
    }

    print "\n\n";

  }

=head1 ABSTRACT

  Modules for abstracting out the "natural" objects in the Penn
  Treebank format.

=head1 DESCRIPTION

This class knows how to read two treebank formats, the Penn format and
the Chomsky Normal Form (CNF) format.  These formats differ in how
they handle terminal nodes.  The Penn format places pre-terminal part
of speech tags in the left-hand position of a parenthesis-delimited
pair, just like it does non-terminal nodes.  The CNF format attaches
pre-terminal tags to the word with an underscore.  For example, the
sentence "I spoke" would be rendered in each format as follows:

    (S
        (NP
            (N I))
        (VP
            (V spoke)))
            Penn

    (S
        (NP
            I_N)
        (VP
            spoke_V))
     Chomsky Normal Form

Almost all the interesting tree-functionality is in the
constituent-forming package (included in this distribution, see
L<Lingua::Treebank::Const>).

PLEASE NOTE: The format expected here is the C<.mrg> format, not the
C<.psd> format.  In other words, one POS-tag per word is required. (In
response to CPAN bug 15079.)

=head1 Variables

=over

=item CONST_CLASS

The value C<Lingua::Treebank::CONST_CLASS> indicates what class should
be used as the class for constituents.  The default is
C<Lingua::Treebank::Const>; it will generate an error to use a value
for $Lingua::Treebank::CONST_CLASS that is not a subclass of
C<Lingua::Treebank::Const>.

=head1 Methods

=head2 Class methods

=over

=item from_penn_file

given a Penn treebank file, open it, extract the constituents, and
return the roots.

=item from_penn_fh

given a Penn treebank filehandle, extract the constituents and return the roots.

=item from_cnf_file

given a Chomsky normal form file, open it, extract the constituents, and
return the roots.

=item from_cnf_fh

given a Chomsky normal form filehandle, extract the constituents and return the roots.

=back

=head2 EXPORT

None by default.

=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.22 with options

  -CAX
	Lingua::Treebank

=item 0.02

Improved documentation.

=item 0.03

added a VERBOSE variable that can be set.

=item 0.09

A variety of additional features

=item 0.10

more features still, also some bugfixes.

=item 0.11

Removed references to Text::Balanced, which is slow and not uniformly
available.

=item 0.12

Corrected bug in Makefile.PL pointed out by Vassilii Khachaturov.

Added some documentation distinguishing that .mrg (and not .psd files)
are supported.

=item 0.13

C<text()> method now suppresses anything with a C<-NONE-> tag.

C<$VERSION> for L<Lingua::Treebank> and L<Lingua::Treebank::Const> now
tied.

=item 0.14

Actually include patch intended for 0.13. *sheesh*.

=item 0.15

Include Lingua::Treebank::HeadFinder class in distro.  Modify
L::TB::Const to support head-child annotation.

also support 64-bit systems much better.

=item 0.16

Including data for Lingua::Treebank::HeadFinder.
Updating version numbers in Const.pm code
Revised test code so that it doesn't require Devel::Cycle (but uses it
if needed).

=back

=head1 SEE ALSO

TO DO: Where is Penn Treebank documented?

=head1 AUTHOR

Jeremy Gillmor Kahn, E<lt>kahn@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2008 by Jeremy Gillmor Kahn with additional support and
ideas from Bill McNeill

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
