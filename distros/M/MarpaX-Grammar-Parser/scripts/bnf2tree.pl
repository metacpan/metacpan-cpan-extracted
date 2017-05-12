#!/usr/bin/env perl

use strict;
use warnings;

use MarpaX::Grammar::Parser;

use Getopt::Long;

use Pod::Usage;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
	\%option,
	'bind_attributes=i',
	'cooked_tree_file=s',
	'help',
	'logger=s',
	'marpa_bnf_file=s',
	'maxlevel=s',
	'minlevel=s',
	'output_hashref=i',
	'raw_tree_file=s',
	'user_bnf_file=s',
) )
{
	pod2usage(1) if ($option{'help'});

	# Return 0 for success and 1 for failure.

	my($parser) = MarpaX::Grammar::Parser -> new(%option);
	my($exit)   = $parser -> run;
	$exit       = $parser -> report_hashref if ($exit == 0);

	# Return 0 for success and 1 for failure.

	exit $exit;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

bnf2tree.pl - Convert a Marpa grammar into a tree using Tree::DAG_Node.

=head1 SYNOPSIS

bnf2tree.pl [options]

	Options:
	-bind_attributes Boolean
	-cooked_tree_file aTextFileName
	-help
	-logger aLog::HandlerObject
	-marpa_bnf_file aMarpaBNFFileName
	-maxlevel logOption1
	-minlevel logOption2
	-output_hashref Boolean
	-raw_tree_file aTextFileName
	-user_bnf_file aUserBNFFileName

Exit value: 0 for success, 1 for failure. Die upon error.

=head1 OPTIONS

=over 4

=item o -bind_attributes Boolean

Include (1) or exclude (0) attributes in the tree file(s) output.

Default: 0.

=item o -cooked_tree_file aTextFileName

The name of the text file to write containing the grammar as a cooked tree.

If '', the file is not written.

Default: ''.

=item o -help

Print help and exit.

=item o -logger aLog::HandlerObject

By default, an object is created which prints to STDOUT.

Set this to '' to stop logging.

Default: undef.

=item o -marpa_bnf_file aMarpaBNFFileName

Specify the name of Marpa's own BNF file.

This file ships with L<Marpa::R2>'s file as share/metag.bnf.

This option is mandatory.

Default: ''.

=item o -maxlevel logOption1

This option affects Log::Handler.

See the L<Log::Handler> docs.

Nothing is printed by default.

Default: 'notice'.

=item o -minlevel logOption2

This option affects Log::Handler.

See the L<Log::Handler> docs.

Default: 'error'.

No lower levels are used.

=item o -output_hashref Boolean

Log (1) or skip (0) the hashref version of the cooked tree.

Note: This needs -maxlevel elevated from its default value of 'notice' to 'info', to do anything.

Default: 0.

=item o -raw_tree_file aTextFileName

The name of the text file to write containing the grammar as a raw tree.

If '', the file is not written.

Default: ''.

=item o -user_bnf_file aUserBNFFileName

Specify the name of the file containing your Marpa::R2-style grammar.

See share/stringparser.bnf for a sample.

This option is mandatory.

Default: ''.

=back

=cut
