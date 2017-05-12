#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/RCS/XEval.pm,v 7.5 2006/03/30 07:21:36 claude Exp claude $
#
# copyright (c) 2005 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::XEval;
use Genezzo::Util;

use Genezzo::XEval::Prepare;
use Genezzo::XEval::SQLAlter;

use strict;
use warnings;
use warnings::register;

use Carp;

our $VERSION;

BEGIN {
    $VERSION = do { my @r = (q$Revision: 7.5 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

}

our $GZERR = sub {
    my %args = (@_);

    return 
        unless (exists($args{msg}));

    if (exists($args{self}))
    {
        my $self = $args{self};
        if (defined($self) && exists($self->{GZERR}))
        {
            my $err_cb = $self->{GZERR};
            return &$err_cb(%args);
        }
    }

    my $warn = 1;
    if (exists($args{severity}))
    {
        my $sev = uc($args{severity});
        $sev = 'WARNING'
            if ($sev =~ m/warn/i);

        # don't print 'INFO' prefix
        if ($args{severity} =~ m/info/i)
        {
            printf ("%s: ", $sev);
            $warn = 0;
        }

    }
    carp $args{msg}
      if (warnings::enabled() && $warn);
    
};

sub _init
{
    my $self = shift;
    my %args = (@_);

    return 0
        unless (defined($args{plan}));

    $self->{plan} = $args{plan};
    $self->{prepare} = Genezzo::XEval::Prepare->new();
    
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
        # NOTE: don't supply our GZERR here - will get
        # recursive failure...
        $self->{GZERR} = $args{GZERR};
        my $err_cb     = $self->{GZERR};
        # capture all standard error messages
        $Genezzo::Util::UTIL_EPRINT = 
            sub {
                &$err_cb(self     => $self,
                         severity => 'error',
                         msg      => @_); };
        
        $Genezzo::Util::WHISPER_PRINT = 
            sub {
                &$err_cb(self     => $self,
#                         severity => 'error',
                         msg      => @_); };
    }

    return undef
        unless (_init($self, %args));

    return bless $self, $class;

} # end new

# get or set the dictionary object
sub Dict
{
    my $self = shift;

    if (scalar(@_))
    {
        $self->{dictobj} = shift;
    }
    return $self->{dictobj};    
}

sub Prepare
{
    whoami;

    my $self = shift;

    my %required = (
                    plan => "no plan!"
                    );

    my %args = ( # %optional,
                @_);

    my ($msg, %earg);

    return undef
        unless (Validate(\%args, \%required));

    my $alg = $args{plan};

    return ($self->{prepare}->Prepare(plan => $alg,
                                      dict => $self->Dict()));

}

sub SQLAlter
{
    whoami;

    my $self = shift;

    my %required = (
                    plan => "no plan!"
                    );

    my %args = ( # %optional,
                @_);

    my ($msg, %earg);

    return undef
        unless (Validate(\%args, \%required));

    my $alg = $args{plan};

    return 0
        unless (exists($alg->{sql_alter}));

    if (exists($alg->{sql_alter}->{add_table_cons}))
    {
        my $add_tab_cons = $alg->{sql_alter}->{add_table_cons};

        my $tablename = $alg->{sql_alter}->{tc_table_fullname};
        
        my $cons_name;

        if (scalar(@{$add_tab_cons->{name}}))
        {
           $cons_name = 
             $add_tab_cons->{name}->[0]->[0]->{bareword};
        }

        greet $tablename, $cons_name;

        my %nargs = (
                     tname   => $tablename,
                     dbh_ctx => $args{dbh_ctx}
                     );

        if (defined($cons_name))
        {
            $nargs{cons_name} = $cons_name;
        }
        
        if (exists($add_tab_cons->{constraint}) &&
            exists($add_tab_cons->{constraint}->{cons_type}) &&
            ($add_tab_cons->{constraint}->{cons_type} 
             =~ m/check|primary|unique/i))
        {
            $nargs{cons_type} = $add_tab_cons->{constraint}->{cons_type};
        }
        else
        {
            $msg = "unknown constraint\n";
            $msg .= Data::Dumper->Dump( [%nargs]);
            %earg = (self => $self, msg => $msg,
                     severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));
            
            return 0;
        }

        if ($add_tab_cons->{constraint}->{cons_type} 
            =~ m/primary|unique/i)
        {

            # XXX XXX XXX: need to move these checks to typecheck
            my %dupi;

            # check the column list for duplicates
            for my $col (@{$add_tab_cons->{constraint}->{tc_column_list}})
            {
                if (exists($dupi{$col}))
                {
                    $msg = 'Duplicate column (' . $col . ') ';
                    $msg .= 'in constraint declaration';
                    %earg = (self => $self, msg => $msg,
                             severity => 'warn');
                    
                    &$GZERR(%earg)
                        if (defined($GZERR));
            
                    return 0;

                }
                else
                {
                    $dupi{$col} = 1;
                }
            }


            $nargs{cols} = $add_tab_cons->{constraint}->{tc_column_list};
        }
        elsif ($add_tab_cons->{constraint}->{cons_type} 
               =~ m/check/i)
        {
            my $where_clause =
                $add_tab_cons->{constraint}->{operands}->{sc_txt};
            $nargs{where_clause} = $where_clause;

            # needs to be an array to match WHERE clause
            my $where_arr = [
                $add_tab_cons->{constraint}->{operands}
                             ];

            my $where_filter = 
                $self->{plan}->SQLWhere2(tablename => $tablename,
                                         where     => $where_arr
                                         );

            unless (defined($where_filter))
            {
                $msg = "invalid where clause";
                %earg = (self => $self, msg => $msg,
                            severity => 'warn');
                    
                &$GZERR(%earg)
                    if (defined($GZERR));
                return 0;
            }
            $nargs{where_filter} = $where_filter->{filter_text};
        }

        greet %nargs;

        my ($stat, $new_consname, $new_iname) = 
            $self->{dictobj}->DictTableAddConstraint(%nargs);
        
        my $severity;
        if ($stat)
        {
            $cons_name = $new_consname
                unless (defined($cons_name));
            $msg = "Added constraint $cons_name" .
                " to table $tablename\n";
            $severity = 'info';
        }
        else
        {
            $msg = "Failed to add constraint\n";
            $severity = 'warn';
        }
        %earg = (self => $self, msg => $msg,
                 severity => $severity);
        
        &$GZERR(%earg)
            if (defined($GZERR));
        
        return $stat;
        
    } # end alter table constraint
    
    $msg = "cannot execute ALTER command";
    %earg = (self => $self, msg => $msg,
             severity => 'warn');
                    
    &$GZERR(%earg)
        if (defined($GZERR));

    return 0;
} # end SQLAlter

sub SQLInsert
{
    whoami;

    my $self = shift;

    my %required = (
                    plan => "no plan!",
                    dict => "no dictionary!",
                    magic_dbh => "no dbh!"
                    );

    my %args = ( # %optional,
                @_);

    my ($msg, %earg);

    return undef
        unless (Validate(\%args, \%required));

    my $alg     = $args{plan};
    my $dictobj = $args{dict};
    my $dbh     = $args{magic_dbh};

    unless (exists($alg->{sql_insert}) &&
            exists($alg->{sql_insert}->[1]->{insert_values}))
    {
        $msg = "cannot execute INSERT command";
        %earg = (self => $self, msg => $msg,
                 severity => 'warn');
        
        &$GZERR(%earg)
            if (defined($GZERR));
        
        return undef;
    }
    
    if (exists($alg->{sql_insert}->[0]->{insert_tabinfo}->{tc_column_list}))
    {
        my $tabinfo = $alg->{sql_insert}->[0]->{insert_tabinfo};


        # XXX XXX XXX: need to move these checks to typecheck
        my %dupi;

        # check the column list for duplicates
        for my $col (@{$tabinfo->{tc_column_list}})
        {
            if (exists($dupi{$col}))
            {
                $msg = 'Duplicate column (' . $col . ') ';
                $msg .= 'in INSERT';
                %earg = (self => $self, msg => $msg,
                         severity => 'warn');
                
                &$GZERR(%earg)
                    if (defined($GZERR));
            
                return undef;

            }
            else
            {
                unless (exists($tabinfo->{tc_table_colhsh}->{$col}))
                {
                    $msg =  'No such column ('. $col . ') ';
                    $msg .= 'in table ' . $tabinfo->{tc_table_fullname};
                    $msg .= ' for INSERT';
                    %earg = (self => $self, msg => $msg,
                             severity => 'warn');
                    
                    &$GZERR(%earg)
                        if (defined($GZERR));
            
                    return undef;

                }

                $dupi{$col} = 1;
            }
        }
    }

    # standard INSERT into ... VALUES ...
    if (ref($alg->{sql_insert}->[1]->{insert_values}) eq 'ARRAY')
    {
        my $tabinfo = $alg->{sql_insert}->[0]->{insert_tabinfo};

        use Genezzo::Row::RSExpr;
        use Genezzo::Row::RSDual;

        my @sel_list;
        
        for my $val (@{$alg->{sql_insert}->[1]->{insert_values}})
        {
            push @sel_list, { value_expression => $val};
        }
        greet @sel_list;
        
        my %tempo;
        my $rsd_tv = tie %tempo, 'Genezzo::Row::RSDual';
        
        my %nargs = (
                     GZERR       => $self->{GZERR},
                     dict        => $dictobj,
                     magic_dbh   => $dbh,
                     rs          => $rsd_tv,
                     select_list => \@sel_list,
                     # NOTE: alias is now a required argument for
                     # RSExpr, even though the DUAL rowsource cannot
                     # have name column expressions.
                     alias       => $tabinfo->{tc_table_fullname}
                     );
        my %rsx_h;
        my $rsx_tv = tie %rsx_h, 'Genezzo::Row::RSExpr', %nargs;
        
        my $sth = $rsx_tv->SQLPrepare();
        
        return ("vanilla", $sth);

    }
    elsif (ref($alg->{sql_insert}->[1]->{insert_values}) eq 'HASH')
    {
        my %q1 = (
                  orderby_clause => [],
                  sql_query      =>  $alg->{sql_insert}->[1]->{insert_values}
                  );
        return ("insert select", \%q1);
    }

    $msg = "cannot execute INSERT command";
    %earg = (self => $self, msg => $msg,
             severity => 'warn');
    
    &$GZERR(%earg)
        if (defined($GZERR));
    
    return undef;
} # end SQLInsert

END { }       # module clean-up code here (global destructor)

## YOUR CODE GOES HERE

1;  # don't forget to return a true value from the file

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::XEval - Execution and Expression Evaluation

=head1 SYNOPSIS

use Genezzo::XEval;


=head1 DESCRIPTION

Perform expression evaluation and command execution.

=head1 ARGUMENTS

=head1 FUNCTIONS

=over 4

=item Dict

get or set the dictionary object

=item SQLAlter

entry point for SQL Alter commands, e.g. ALTER TABLE 

=item SQLInsert

Execute SQL INSERT

=back

=head2 EXPORT

=over 4


=back


=head1 LIMITATIONS


=head1 TODO

=over 4

=item Should become more of a dispatch routine, with major guts for
each function stashed in separate modules under XEval.

=item SQLAlter, SQLInsert: move type checking to TypeCheck module.

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
