#!/usr/bin/env perl
#
# Name:
#	create.table.pl.
#
# Purpose:
#	Create a db table called - by default - trees.

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Tree::DAG_Node::Persist::Create;

# --------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
 \%option,
 'dsn=s',
 'extra_columns=s',
 'help',
 'password=s',
 'table_name=s',
 'username=s',
) )
{
	pod2usage(1) if ($option{'help'});

	exit Tree::DAG_Node::Persist::Create -> new(%option) -> run;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

create.table.pl - Create a db table called - by default - trees

=head1 SYNOPSIS

create.table.pl [options]

	Options:
	-dsn DSN
	-extra_columns columnDefinitions
	-help
	-password aPassword
	-table_name aTableName
	-username aUsername

All switches can be reduced to a single letter.

Exit value: 0 for success.

=head1 OPTIONS

=over 4

=item -dsn DSN

Defaults to $DBI_DSN.

Sample: dbi:Pg:dbname=menus or dbi:SQLite:dbname=/tmp/menus.sqlite.

=item -extra_columns columnDefinitions

The names and details of one or more extra columns to add to the table at create time.

Separate the names with commas.

Examples:

=over 4

=item Add 1 extra column

	scripts/create.table.pl -e page_id:integer:default:0

=item Add 2 extra columns

	scripts/create.table.pl -d dbi:Pg:dbname=menus -e page_id:integer:default:0,node_id:integer:default:1
	scripts/create.table.pl -d dbi:Pg:dbname=menus -e "page_id:integer:default:0,node_id:varchar(255)"

With or without double quotes is ok sometimes, but are always strongly recommended.

When using characters - such as '(' - which can be interpreted by the shell, the quotes are mandatory.

When you use quotes you can then put spaces around the comma(s) and the colons.

=back

The default is to create the table with no extra columns, just those defined in the FAQ of Tree::DAG_Node::Persist.

Note: t/test.t uses this feature, if you wish to see sample code.

=item -help

Print help and exit.

=item -password aPassword

Defaults to $DBI_PASS.

=item -table_name aTableName

Use this to override the default table name 'trees'.

=item -username aUsername

Defaults to $DBI_USER.

=back

=cut
