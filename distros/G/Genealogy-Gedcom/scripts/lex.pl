#!/usr/bin/env perl

use strict;
use warnings;

use Genealogy::Gedcom::Reader::Lexer;

use Getopt::Long;

use Pod::Usage;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
 \%option,
 'help',
 'input_file=s',
 'maxlevel=s',
 'minlevel=s',
 'report_items=i',
 'strict=i',
) )
{
	pod2usage(1) if ($option{'help'});

	# Return 0 for success and 1 for failure.

	exit Genealogy::Gedcom::Reader::Lexer -> new(%option) -> run;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

lex.pl - Run Genealogy::Gedcom::Reader::Lexer.

=head1 SYNOPSIS

lex.pl [options]

	Options:
	-help
	-input_file aRawFileName
	-maxlevel logOption1
	-minlevel logOption2
	-report_items 0 or 1
	-strict 0 or 1

Exit value: 0 for success, 1 for failure. Die upon error.

=head1 OPTIONS

=over 4

=item -help

Print help and exit.

=item -input_file aRawFileName

Read the GEDCOM data from a file.

Default: ''.

=item -maxlevel logOption1

This option affects Log::Handler.

See the Log::handler docs.

Default: 'info'.

=item -minlevel logOption2

This option affects Log::Handler.

See the Log::handler docs.

Default: 'error'.

No lower levels are used.

=item -report_items 0 or 1

Report the items recognised by the state machine.

Default: 0.

=item -strict 0 or 1

Specify the degree of strictness in validation.

Default: 0.

=back

=cut
