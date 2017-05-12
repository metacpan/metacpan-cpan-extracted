#!/usr/bin/perl -w

# $Id: data2mysql.pl,v 1.5 2008-04-25 16:55:47 mike Exp $
#
# Converts data from a simple, easy-to-edit format called d2m into SQL
# INSERT statements suitable for feeding to MySQL.  The d2m format is
# defined as follows:
#	Comments, from "#" to the end of the line, are discarded
#	Leading and trailing whitespace is discarded
#	Blank lines are ignored
#	Otherwise, lines are either Table or Row Directives:
#	Table Directives looks like this: *<name>=<col1>,<col2>,...
#		They indicate that following lines are row lines for
#		the table called <name>, and that they consist of
#		values for the specified values in the specified
#		order.
#	Row Directives look like this: <val1>,<val2>,...
#		The indicate that the specified values should be added
#		as a row to the table most recently indicated by a
#		Table Directive, with the values corresponding in
#		order to the columns nominated in that Directive.
# If the -o command-line option is given, then the output is suitable
# for feeding to Oracle rather than MySQL.

use strict;
use warnings;
use Getopt::Std;

my %opts;
if (!getopts('mo', \%opts)) {
    print STDERR "\
Usage: $0 [options] [<input-file> ...]
	-m	Generate SQL suitable for MySQL [default]
	-o	Generate SQL suitable for Oracle
";
    exit 1;
}

die "$0: -m and -o options conflict"
    if $opts{m} && $opts{o};
my $oracle = $opts{o};

if ($oracle) {
    # This is pretty dumb, but Oracle takes every ampersand (&) in a
    # fragment of SQL as an invitation to interactively prompt for the
    # value of the variable named after it.  And there is NO WAY to
    # quote the ampersand to make it literal.  According to the FAQ:
    #	http://www.orafaq.com/wiki/SQL*Plus_FAQ#How_does_one_disable_interactive_prompting_in_SQL.2APlus.3F
    # you can get around it this way:
    print "SET DEFINE OFF\n";
}

my $table = undef;
my @columns;

while (<>) {
    chomp();
    s/^#.*//;
    s/[^&0-9]#.*//;
    s/\s+$//;
    s/^\s+//;
    next if !$_;
    if (/^\*(.*)=(.*)/) {
	$table = $1;
	@columns = split /,/, $2;
	next;
    }

    die "$0: no Table Directive before first Row Directive"
	if !defined $table;

    my @data = split /,/, $_, -1;

    # Serial-specific hacks are neither necessary (as matching is
    # case-insensitive) nor desirable (since these are edited in the
    # Admin UI).
    if (0 && $table eq "serial") {
	foreach my $i (0 .. $#columns) {
	    if ($columns[$i] eq "name") {
		# Normalise case and whitespace in serial title
		my $title = lc($data[$i]);
		$title =~ s/^\s+//;
		$title =~ s/\s+$//;
		$title =~ s/\s+/ /g;
		$data[$i] = $title;
	    } elsif ($columns[$i] eq "issn") {
		# Normalise hyphens and whitespace in ISSN
		my $issn = $data[$i];
		$issn =~ s/\s+//g;
		$issn =~ s/-//g;
		$data[$i] = $issn;
	    }
	}
    }

    if ($oracle) {
	# Unlike MySQL, Oracle actually honours foreign key constraints.
	my @values;
	my @cc;
	foreach my $i (0..$#columns) {
	    my $col = $columns[$i];
	    my $val = $data[$i];
	    if ($col =~ /_id$/ &&
		(!defined $val || $val eq "" || $val == 0)) {
		# Undefined link-ID: omit from INSERT statement
	    } else {
		push @cc, $col;
		push @values, $val;
	    }
	}
	print(qq[INSERT INTO "$table" (], join(", ", map { qq["$_"] } @cc), ") ",
	      "VALUES (", join(", ", map { s/[']/''/g; "'$_'" } @values), ");\n");
    } else {
	print("INSERT INTO $table (", join(", ", @columns), ") ",
	      "VALUES (", join(", ", map { s/[']/''/g; "'$_'" } @data), ");\n");
    }
}

if ($oracle) {
    # *sigh* ... Oracle doesn't quit at the end of the input file.
    print "QUIT\n";
}
