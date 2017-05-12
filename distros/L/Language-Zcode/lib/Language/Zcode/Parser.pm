package Language::Zcode::Parser;

use strict;
use warnings;

use Language::Zcode::Parser::Routine;
use Language::Zcode::Parser::Opcode;

=head1 NAME

Language::Zcode::Parser - reads and parses a Z-code file into a big Perl hash

=head1 SYNOPSIS

    # Create a Pure Perl Parser
    my $pParser = new Language::Zcode::Parser "Perl";

    # If they didn't put ".z5" at the end, find it anyway
    $infile = $pParser->find_zfile($infile) || exit;

    # Read in the file, store it in memory
    $pParser->read_memory($infile);

    # Parse header of the Z-file
    $pParser->parse_header();

    # Get the subroutines in the file (LZ::Parser::Routine objects)
    my @subs = $pParser->find_subs($infile);

=head1 DESCRIPTION

For finding where the subroutines start and end, you can either depend on
an external call to txd, a 1992 C program available at ifarchive.org, or 
a pure Perl version.

Everything else is done in pure Perl.

=cut

=head2 new (class, how to find subs, args...)

This is a factory method. Called with 'Perl' or 'TXD' (or 'txd') as arguments,
it will create Parsers of LZ::Parser::Perl or LZ::Parser::TXD, which
are subclasses of LZ::Parser::Generic.

That class' 'new' method will be called with any other passed-in args.

=cut

sub new {
    my ($class, $sub_finder, @arg) = @_;
    # XXX I'll bet there's some fancy way of telling if a class exists.
    # E.g., test $class->can("new")
    die "Arg for how to find subs must be 'Perl' or 'txd', not '$sub_finder\n'"
        unless $sub_finder =~ /^(perl|txd)$/i;
    $sub_finder =~ s/perl/Perl/i;
    $sub_finder =~ s/txd/TXD/i;
    my $new_class = "Language::Zcode::Parser::${sub_finder}";
    eval "use $new_class"; die $@ if $@;
    return new $new_class @arg;
}

1;
