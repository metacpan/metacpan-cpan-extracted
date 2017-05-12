#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/RCS/TestSQL.pm,v 1.3 2007/06/26 08:17:04 claude Exp claude $
#
# copyright (c) 2006 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::TestSQL;
use Genezzo::TestSetup;
use Genezzo::GenDBI;
use Genezzo::Util;

use strict;
use warnings;
use File::Path;
use File::Spec;
use File::Copy;

sub TestSQL
{
#    my $self = shift;

    my %required = (
                    dbh => "no dbh",
                    log_dir => "no log dir",
                    sql_script => "no sql"
                    );

    my %args = (
                @_);

    return undef 
        unless (Validate(\%args, \%required));

    my $dbh = $args{dbh};
    my $log_dir = $args{log_dir};
    my $sql_script = $args{sql_script};

    my @foo = File::Spec->splitpath($sql_script);

    my $base_sql = $foo[-1]; # get filename
    
    my $log_name = $base_sql;
    $log_name =~ s/sql$/log/;

    my $out_log = File::Spec->catfile($log_dir, $log_name);
    
    my $old_log = $sql_script;
    $old_log =~ s/sql$/log/;

    unless (-e $log_dir)
    {
        mkpath($log_dir, 1, 0755);
    }

    my $spool_str = "spool " . $out_log;
    my $at_str    = '@' . $sql_script;

    $dbh->Parseall("startup");
    $dbh->Parseall($spool_str);
    $dbh->Parseall($at_str);
    $dbh->Parseall("spool off");
    $dbh->Parseall("shutdown");

    return TestDiff(old_log => $old_log,
                    new_log => $out_log);

}

sub TestDiff
{
#    my $self = shift;

    my %required = (
                    old_log => "no old log",
                    new_log => "no new log"
                    );

    my %args = (
                @_);

    return undef 
        unless (Validate(\%args, \%required));


    my $old_log = $args{old_log};
    my $new_log = $args{new_log};

    return "no such file: $old_log"
        unless (-e $old_log);
    return "no such file: $new_log"
        unless (-e $new_log);

    my ($old_line, $new_line) = ("no old line", "no new line");
    my $linecount = 0;

    # use a closure for the comparison function so can find out where
    # the diff happened and get the offending lines
    my $cmp_fn = sub
    {
        ($old_line, $new_line) = @_;
        $linecount++;

#        print "cmp_fn: $old_line\n$new_line\n";
        
        return ($old_line ne $new_line);
    };


    use File::Compare;

    my $stat = File::Compare::compare_text($old_log, $new_log, $cmp_fn);
#    my $stat = compare($old_log, $new_log);

    if ($stat == 0)
    {
        return "no differences found";
    }
    elsif ($stat == 1)
    {
#        print $old_line, "\n";
#        print $new_line, "\n";
#        print $linecount, "\n";

        return "differences found: $old_log, $new_log\nline $linecount:\nold:$old_line\nnew:$new_line";
    }

    return undef;
    

}

END { }       # module clean-up code here (global destructor)

## YOUR CODE GOES HERE

1;  # don't forget to return a true value from the file

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::TestSQL - Test SQL scripts

=head1 SYNOPSIS

use Genezzo::TestSQL;


=head1 DESCRIPTION

Run a SQL script and compare the output log with the old log.

=head1 ARGUMENTS

=head1 FUNCTIONS

=over 4

=item TestSQL

=item TestDiff

=back

=head2 EXPORT

=over 4


=back


=head1 LIMITATIONS


=head1 TODO

=over 4

=item stuff

=back

=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

L<perl(1)>.

Copyright (c) 2005 Jeffrey I Cohen.  All rights reserved.

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
