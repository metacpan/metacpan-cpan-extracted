#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/RCS/BasicHelp.pm,v 1.12 2007/06/26 08:12:39 claude Exp claude $
#
# copyright (c) 2006, 2007 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::BasicHelp;
use Genezzo::Util;
use Pod::Text;

use strict;
use warnings;
use warnings::register;

use Carp;

our $VERSION;

BEGIN {
    $VERSION = do { my @r = (q$Revision: 1.12 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

}

sub getpod
{
    my $bigHelp;
    ($bigHelp = <<EOF_HELP) =~ s/^\#//gm;
#=head1 Basic_Commands
#
# The Genezzo database supports a variety of interactive commands.
#
#=head2 @ : execute a command file.  Syntax - @<filename> 
#
#=head2 !<number>, !! : re-execute command history
#
#=head2 addfile, af : add a file to a tablespace.  Type "addfile help" for more details.
#
#=head2 alter : SQL alter
#
#        ALTER TABLE tablename 
#              ADD [CONSTRAINT constraint_name] 
#                  PRIMARY KEY (colname [, colname ...]);
#        ALTER TABLE tablename 
#              ADD [CONSTRAINT constraint_name] 
#                  UNIQUE (colname [, colname ...]);
#        ALTER TABLE tablename 
#              ADD [CONSTRAINT constraint_name] 
#                  CHECK (conditional_expression);
#
#=head2 ci : create index.  Syntax - ci <index name> <table name> <column name>.
#
#=head2 commit : flush changes to disk
#
#=head2 create : SQL Create
#
#         CREATE TABLE 
#            tablename (column_name column_type [, column_name column_type]...)
#            [TABLESPACE tsname] [AS SELECT...]
#
#         CREATE TABLESPACE tsname
#
#         CREATE INDEX indexname 
#            ON tablename (column_name [, column_name]...)
#               [TABLESPACE tsname]
#
#=head2 ct : create table.  
#
#    Syntax - 
#    ct <tablename> <column name>=<column type> [<column name>=<column type>...]
#    Supported types are "c" for character data and "n" for numeric.
#
#=head3 SEE ALSO: Create Table
#
#=head2 d : delete from a table.  Syntax - d <table-name> <rid> [<rid>...]
#
#=head2 delete : SQL Delete
#
#         DELETE FROM tablename [WHERE ...]
#
#=head2 describe, desc :  describe a table
#
#=head2 drop :  SQL Drop
#
#        DROP TABLE tablename
#
#=head2 dt : drop table.  Syntax - dt <table-name>
#
#=head2 dump :  dump internal state.  Type "dump help" for more details.
#
#=head2 help, help <topic> : Get general help or help on a specific topic
#
#        help         - general help for all topics
#        help <topic> - find the matching topics and list them.  Some perl
#                       regex is supported.  
#        
#        The general help provides the full help for every topic.  If
#        "Help <topic>" is used, help lists all matching topics, followed 
#        by a short description for each one.  If only a single 
#        topic matches, it prints a full (long) description.  A more
#        complex help syntax is also supported:
#
#        help [area=<area>] [list=<topic>] [short=<topic>] [long=<topic>] [topic]
#       
#        Provide the specified level of detail on a topic or set of topics
#        in a particular area.  If unspecified, the default area
#        (which you are currently viewing) is Basic_Commands.  To list
#        all available areas enter
#          help area=
#
#        For example, the command
#          help area=sql_functions short=u
#        provides a short description of all topics beginning with 'u' in
#        the area of "sql_functions".  Note that "area=" supports a regex
#        match as well, but the regex must match a unique area.
#
#=head2 history, h : command history.  Use shell-style "!<command-number>" to repeat.
#
#    use "history -clear" to clear the history buffer.
#
#=head2 i : insert into a table. 
#
#    Syntax - i <tablename> <column-data> [<column-data>...]
#
#=head2 insert : SQL Insert
#
#         INSERT INTO tablename VALUES (expr [, expr ...]);
#         INSERT INTO tablename (colname [, colname ...]) 
#                               VALUES (expr [, expr ...]);
#         INSERT INTO tablename SELECT ... FROM ...
#
#=head2 password : password authentication [unused]
#
#=head2 quit : quit the line-mode app
#
#=head2 reload : Reload all genezzo modules
#
#=head2 rem : Remark [comment]
#
#=head2 rollback : discard uncommitted changes
#
#=head2 s : select from a table.  
#
#    Syntax - s <table-name> *
#             s <table-name> <column-name> [<column-name>...]
#    Legal "pseudo-columns" are "rid", "rownum".
#
#=head2 select : SQL Select
#
#         SELECT expr [[AS] column_alias] [, expr [[AS] column_alias]]
#         FROM tablename [[AS] table_alias] [, tablename ...]
#         [WHERE ...]
#
#   
#=head2 show :  License, warranty, and version information.  Type "show help" for more information.
#
#=head2 shutdown : shutdown an instance.  Provides read-only access to "pref1" table.
# 
#=head2 spool : write output to a file.  Syntax - spool <filename>
#
#=head2 startup : Loads dictionary, provides read/write access to tables.
#
#=head2 sync : flush changes to disk (*without* committing transaction like "commit")
#
#=head2 u : update a table.  
#
#    Syntax - u <table-name> <rid> <column-value> [<column-value>...]
#
#=head2 update : SQL Update
#
#         UPDATE tablename SET colname = expr [, colname = expr ...] [WHERE ...]
EOF_HELP

    my $msg = $bigHelp;

    return $msg;

}

sub getpod2text
{
    my $rawpod = getpod();
    my $podtxt = 1; # need to initialize this for some reason...

    my ($in_fh, $out_fh);

    open($in_fh, '<', \$rawpod);
    open($out_fh, '>', \$podtxt);

    # use loose setting to get spaces after headings...
    my $parser = Pod::Text->new(loose => 1);     

    $parser->parse_from_filehandle($in_fh,$out_fh);

    return $podtxt;
}

sub pod2gnzhelp
{
    my ($self, $pod) = @_;

    my @biga = split(/\n/, $pod);

    my $bigh = {};

    if (exists($self->{bigh})
        && defined($self->{bigh}))
    {
        $bigh = $self->{bigh};
    }

    my $topic_group;
    my $topic_group_name;
    my $topic_group_desc;

    my $topic;
    my $topic_name;

    my $long_desc;

    my $maxline = scalar(@biga);

    my $lineno = 0;

    while ($lineno < $maxline)
    {
        my $line = $biga[$lineno];

        if ($line =~ m/^=head/)
        {
            if ($line =~ m/^=head(1|2|3)/)
            {
                if (defined($long_desc) && defined($topic))
                {
                    $topic->{long_desc} = $long_desc;
                    $long_desc = undef;
                }

                if (defined($topic_group_desc) && 
                    defined($topic_group))
                {
                    $topic_group->{long_desc} = $topic_group_desc;
                    $topic_group_desc = undef;
                }
            }

            if ($line =~ m/^=head(1|2)/ && defined($topic))
            {
                $topic_group->{entries}->{$topic_name} = $topic
                    if (defined($topic_group));
                $topic = undef;
            }

            if ($line =~ m/^=head3/ && defined($topic))
            {
                $line =~ s/^=head3//;

                my @foo = split(/:/, $line, 2);

                unless (scalar(@foo) == 2)
                {
                    print "bad header3: ", $line, "\n";
                    goto L_endloop;
                }
            
                my $kk = shift @foo;
                $kk =~ s/^\s*//;
                $kk =~ s/\s*$//;
                my $vv = shift @foo;
                $vv =~ s/^\s*//;
                $vv =~ s/\s*$//;
                $topic->{$kk} = $vv;
            }

            if ($line =~ m/^=head2/ && defined($topic_group))
            {
                $line =~ s/^=head2//;

                my @foo = split(/:/, $line, 2);

                unless (scalar(@foo) == 2)
                {
                    print "bad header2: ", $line, "\n";
                    goto L_endloop;
                }
                my $kk = shift @foo;
                $kk =~ s/^\s*//;
                $kk =~ s/\s*$//;
                $topic_name = $kk;
                $topic = {};
                $topic_group->{entries}->{$topic_name} = $topic;
                my $vv = shift @foo;
                $vv =~ s/^\s*//;
                $vv =~ s/\s*$//;
                $topic->{short_desc} = $vv;
            }
            
            if ($line =~ m/^=head1/)
            {
                $topic_group = {};

                $topic_group->{entries} = {};

                $line =~ s/^=head1//;
                $line =~ s/^\s*//;
                $line =~ s/\s*$//;

                $bigh->{entries}->{$line} = $topic_group;
                $topic_group_name = $line;

            }
        }
        else
        {
            if (defined($long_desc) && defined($topic))
            {
                $long_desc .= "\n" . $line;
            }
            elsif (!defined($long_desc) && 
                   defined($topic) &&
                   # need to handle case of head3 after long_desc, and
                   # not create new long_desc if one already exists
                   !(exists($topic->{long_desc})))
            {
                
                $long_desc = "";
                $long_desc .= $line;

            }
            elsif (defined($topic_group_desc) && 
                   defined($topic_group))
            {
                $topic_group_desc .= "\n" . $line;
            }
            elsif (!defined($topic_group_desc) && 
                   defined($topic_group) &&
                   !(exists($topic_group->{long_desc})))
            {
                $topic_group_desc = "";
                $topic_group_desc .= $line;
            }
        }

      L_endloop:
        $lineno++;
    } # end while

    if (defined($long_desc) && defined($topic))
    {
        $topic->{long_desc} = $long_desc;
        $long_desc = undef;
    }

    if (defined($topic_group_desc) && 
        defined($topic_group))
    {
        $topic_group->{long_desc} = $topic_group_desc;
        $topic_group_desc = undef;
    }

    if (defined($topic))
    {
        $topic_group->{entries}->{$topic_name} = $topic
            if (defined($topic_group));
        $topic = undef;
    }

    return $bigh;
}

# build the initial help hash based upon the BasicHelp pod
sub _basic_help_hash
{
    my $self = shift;

    my $bigpod = getpod();

    return pod2gnzhelp($self, $bigpod);

}

sub _init
{
    my $self = shift;

    my %nargs = @_;

    $self->{bigh} = _basic_help_hash($self);
    
    return 1;
}

sub new 
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 
    my $self = { };
    
    my %args = (@_);

    if ((exists($args{GZERR}))
        && (defined($args{GZERR}))
        && (length($args{GZERR})))
    {
        $self->{GZERR} = $args{GZERR};
    }

    return undef
        unless (_init($self, %args));

    return bless $self, $class;

} # end new

sub search_topic
{
    my $self = shift;
    my %optional = (
#                    topic_pattern => '',
                    option => 'LIST',
                    topic_group => "Basic_Commands"
                    );

    my %required = (
#                    topic_group => "no topic group !"
                    );

    my %args = (%optional,
                @_);

#    return 0
#        unless (Validate(\%args, \%required));

    my $topic_group   = $args{topic_group};
    my $format_option = $args{option};
    my $topic_pattern;

    if (exists($args{topic_pattern}) && defined($args{topic_pattern}))
    {
        $topic_pattern = $args{topic_pattern};

        if ($topic_pattern =~ m/^\*/)
        {
            $topic_pattern =~ s/^\*/\.\*/;
        }

        my @baz;
        my $foo = "foo";
        my $test_pattern = "\@baz = (\$foo =~ m/$topic_pattern/);";

        # avoid blowing up
        eval $test_pattern;

        if ($@)
        {
            my $outi = "invalid pattern \"$topic_pattern\": $@\n";
            return $outi;
        }

    }

    {
        if ($topic_group =~ m/^\*/)
        {
            $topic_group =~ s/^\*/\.\*/;
        }

        my @baz;
        my $foo = "foo";
        my $test_pattern = "\@baz = (\$foo =~ m/$topic_group/);";

        # avoid blowing up
        eval $test_pattern;

        if ($@)
        {
            my $outi = "invalid group specification \"$topic_group\" : $@\n";
            return $outi;
        }

    }

    
    my $bigh = $self->{bigh};

    my $top_h = $bigh;

    my @all_topic_groups;

    # case-insensitive match for area/group name
    for my $tg (sort(keys(%{$top_h->{entries}})))
    {
        if ($tg =~ m/^$topic_group/i)
        {
            push @all_topic_groups, $tg;
        }
    }

    unless (scalar(@all_topic_groups))
    {
        my $outi = "no matches for $topic_group\n";
        return $outi;
    }

    if (scalar(@all_topic_groups) > 1)
    {
        my $outi = "multiple matches: \n " . 
            join("\n ", @all_topic_groups) . "\n";
        return $outi;
    }

    $topic_group = shift @all_topic_groups;

    return undef
        unless (exists($top_h->{entries}->{$topic_group}));

    my $tg_h = $bigh->{entries}->{$topic_group};

    my (@topics, @fullnames);

    my $maxlen = 4; # minimum name length of four

    for my $tp (sort(keys(%{$tg_h->{entries}})))
    {
        if (defined($topic_pattern))
        {
            unless ($tp =~ m/$topic_pattern/i)
            {
                # don't bother with extra check if not a 
                # comma-separated list of names...
                next if ($tp !~ m/\,/);

                my @foo = split(/\,/, $tp, 2);

                my $gotmatch = 0;
                for my $ff (@foo)
                {
                    $ff =~ s/^\s*//;
                    $ff =~ s/\s*$//;

                    # special check for keys like "command, alias" --
                    # try to match the alias
                   $gotmatch = 1
                       if ($ff =~ m/$topic_pattern/i);
                }
                next unless ($gotmatch);
            }

        }

        push @fullnames, $tp;

        if ($tp =~ m/\,/)
        {
            my @foo = split(/\,/, $tp, 2);
            $tp = shift @foo;
        }

        $maxlen = length($tp)
            if (length($tp) > $maxlen);

        push @topics, $tp;
    }


    return undef
        unless (scalar(@topics));

    use POSIX ;

    $maxlen += 2; # add two spaces for clarity

    my $numcols = POSIX::floor(60/$maxlen);

#    $numcols = 5;

    # guarantee at least one row
    my $numrows = POSIX::ceil(scalar(@topics)/$numcols);

    my @outi;
    
#    sort(@topics);

    for my $rc1 (1..$numrows)
    {
        last unless scalar(@topics);

        my $tp = shift @topics;

        $tp .= ' ' x ($maxlen - length($tp));
        push @outi, $tp;
    }

    while (scalar(@topics))
    {
        for my $rc1 (0..($numrows-1))
        {
            last unless scalar(@topics);

            my $tp = shift @topics;

            $tp .= ' ' x ($maxlen - length($tp));
            $outi[$rc1] .= $tp;
        }
    }
#    use Text::Wrap;

#    return wrap('','', @topics);

    my $msg = "help area=$topic_group\n\n";

    $msg .= join("\n", @outi);

    if (scalar(@fullnames) == 1)
    {
        $msg = "";
        $format_option = "long";
    }

    if (scalar(@outi) && ($format_option =~ m/short|long|full/i))
    {
        $msg .= "\n\n";

        for my $name (@fullnames)
        {
            my $entry = $tg_h->{entries}->{$name};

            $msg .= '  ' . $name . ' : ' . $entry->{short_desc} . "\n";

            if (($format_option =~ m/long|full/i)
                && exists($entry->{long_desc}))
            {
                $msg .= $entry->{long_desc} ;

                # make sure have trailing newline
                $msg .= "\n"
                    unless ($msg =~ m/\n$/);
            }
            $msg .= "\n";

        }

    }

    return $msg;

}

END { }       # module clean-up code here (global destructor)

1;
## YOUR CODE GOES HERE



if (0)
{
    use Data::Dumper;

    my $bh = Genezzo::BasicHelp->new();

    print Data::Dumper->Dump([$bh]);


    my $podtxt = $bh->getpod2text();

    print $podtxt, "\n";


    my $cmds = $bh->search_topic(topic_group=>'Basic_Commands');

    print $cmds, "\n\n";
    $cmds = $bh->search_topic(topic_group=>'Basic_Commands', 
                              topic_pattern=>'^d',
                              option=>'list');

    print $cmds, "\n\n";
    $cmds = $bh->search_topic(topic_group=>'Basic_Commands', 
                              topic_pattern=>'^.*d',
                              option=>'full');

    print $cmds, "\n\n";

    # help area=foo/bar
    # help tag=foo,bar,baz
    # help list=foo # names only
    # help verbose=foo # names and short and full desc
    # help foo # names and short desc
}

1;  # don't forget to return a true value from the file

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::BasicHelp - Genezzo Help Facility

=head1 SYNOPSIS

use Genezzo::BasicHelp;


=head1 DESCRIPTION

BasicHelp builds searchable data structures out of Pod documents which
are used for the Genezzo Help system.  The help system is composed of
a collection of topic groups or areas, with multiple topics in each
group.

BasicHelp Pod documents must follow a specific format -- please see the 
following example:

perl -Iblib/lib
     -e "use Genezzo::BasicHelp; print Genezzo::BasicHelp::getpod();"

The document must start with a "head1" command which designates the topic 
group or area, followed by a paragraph describing the area.  The primary
heading is followed by any number of "head2" commands which list the 
specific help topics.  The format for the topic headings is:

  "head2" topic name [, topic alias] : short description

      [long description...]

Topics are alphabetically sorted by name, but the alias is a valid
search pattern as well.  Note that topic name matching is
case-insensitive.

The "head3" command is reserved for future use -- examples are a 
"SEE ALSO" heading which hyperlinks to a related topic, or a "TAGS" field
which groups related help topics.


=head1 ARGUMENTS

none

=head1 FUNCTIONS

=over 4

=item getpod2text 

Return the BasicHelp pod document as a formatted text string.

=item search_topic

Find the topics which match the search pattern in a particular group,
and return the results as a formatted string.

The search_topic function takes the following optional named arguments:

=over 4

=item topic_group

A case-insensitve prefix match for a particular group or area.  
Default is "Basic_Commands".

=item topic_pattern

A case-insensitive regex to match a specific set of topics in the
group.  Defaults to all topics if not specified.

=item option

Output formatting option: LIST (default), SHORT, or LONG.

LIST simply lists the matching topics in a series of columns (similar
to "ls").  SHORT lists the matching topics and then outputs a brief
description for each one.  LONG lists the matching topics and then
outputs a full description for each one.  Note that if only a single
topic matches then the listing is suppressed and a full description is
always performed.


=back

If no arguments are supplied, search_topic simply lists the available topics 
for the default topic group "Basic_Commands".  


=item pod2gnzhelp

Take a raw pod help document (as a string) and parse it, updating the 
searchable BasicHelp data structure.

=back

=head2 EXPORT

=over 4


=back


=head1 LIMITATIONS


=head1 TODO

=over 4

=item convert hashes back to pod

=item hyperlink "SEE ALSO" headings

=item TAG search

=item hierarchical topic groups and searches

=back

=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

L<perl(1)>.

Copyright (c) 2006, 2007 Jeffrey I Cohen.  All rights reserved.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

Address bug reports and comments to: jcohen@genezzo.com

For more information, please visit the Genezzo homepage 
at L<http://www.genezzo.com>

=cut
