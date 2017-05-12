#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/RCS/Plan.pm,v 7.6 2006/10/19 08:49:03 claude Exp claude $
#
# copyright (c) 2005 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::Plan;
use Genezzo::Util;

use Genezzo::Plan::TypeCheck;
use Genezzo::Plan::MakeAlgebra;
use Genezzo::Plan::QueryRewrite;
use Genezzo::Parse::SQL;
use Parse::RecDescent;

use strict;
use warnings;
use warnings::register;

use Carp;

our $VERSION;

BEGIN {
    $VERSION = do { my @r = (q$Revision: 7.6 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

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

    carp $args{msg}
        if warnings::enabled();
    
};

our $GZERR_MAGIC; # refer back to gzerr in a magic way...

sub _build_gzerr_wrapper 
{
    my $gzerr_cb = shift;

    # build a closure to control printing of statement position information
    my $gzerr_closure = sub {

        my %nargs = @_;

        my $statement = undef;

        if (0
            && exists($nargs{statement})
            && exists($nargs{stat_pos}))
        {
            my $stat = $nargs{statement};
            my $pos  = $nargs{stat_pos};

            if (scalar(@{$pos}) && length($stat))
            {
                #position vector points to start and finish of token
                my $p1 = $pos->[0];
                my $caret = (" " x ($p1+1) ) . "^";

                # remove newlines, tabs
                $stat =~ s/\n/ /g;
                $stat =~ s/\t/ /g;
                # high-end chars
                $stat =~ s/([\200-\377])/ /g; 
                # low-end chars (including newline (^J = octal 12))
                $stat =~ s/([\0-\37\177])/ /g;

                if (length($caret) > 40)
                {
                    my $off2 = 40;
                    $off2 *= -1;
                    $caret = substr($caret, $off2);
                    $stat  = substr($stat,  $off2);
                }

                print $stat, "\n", $caret, "\n";
            }

        }

#        if (exists($nargs{self}))
#        {
#            my $self = $nargs{self};
#            $statement = $self->GetStatement()
#                if ($self->can("GetStatement"));
#            $nargs{statement} = $statement
#                if (defined($statement));
#        }

        return &$gzerr_cb(%nargs);

    };

    return $gzerr_closure;
}


sub _init
{
    my $self = shift;

    $self->{dictobj}    = undef; # nothing
    $self->{parser}     = Genezzo::Parse::SQL->new();
    $self->{getAlgebra} = Genezzo::Plan::MakeAlgebra->new();

    my %nargs = @_;
    $nargs{plan_ctx}    = $self; # add self to args list;

    $self->{typeCheck}  = Genezzo::Plan::TypeCheck->new(%nargs);

    # Be stunned and amazed at the power of Perl!
    # Supply a hook to the parser to reroute its error reporting thru GZERR
    # Is there a simpler way to do this?  I hope so.

    # create a closure referring to caller's self and gzerr
    $GZERR_MAGIC =
        sub {
            my $msg1 = shift;
            my %earg = (self => $self, 
                        msg =>  $msg1, 
                        severity => 'error');

            &$GZERR(%earg)
                if (defined($GZERR));
        };

    # we don't need to redefine this function if it already exists
    # (and we'd like to avoid a compiler warning)
    unless (defined(&Parse::RecDescent::Genezzo::Parse::SQL::gnz_err_hook))
    {
        my $func;
        ($func = <<'EOF_func') =~ s/^\#//gm;
#
#        # SQLGrammar supports a hook in the start rule to override the
#        # default error reporting mechanism
#        
#        # create the gnz_err_hook in the correct namespace
#        sub Parse::RecDescent::Genezzo::Parse::SQL::gnz_err_hook
#        {
#            my $msg = shift; 
#            &$Genezzo::Plan::GZERR_MAGIC($msg);
#        }
#
EOF_func

    # hope this works!
    eval " $func ";

        if ($@)
        {
            my %earg = (self => $self,
                        msg => "$@\nbad function : $func");
            
            &$GZERR(%earg)
                if (defined($GZERR));
            
            return 0;
        }
    }

    $self->{queryRewrite} = Genezzo::Plan::QueryRewrite->new(%nargs);
    
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
        $self->{GZERR} = _build_gzerr_wrapper($args{GZERR});
#        $self->{GZERR} = $args{GZERR};
        my $err_cb     = $self->{GZERR};
        # pass the wrapped GZERR down to the other Plan subclasses...
        $args{GZERR}   = $self->{GZERR};

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


sub Parse
{
    my $self = shift;

    my %required = (
                    statement => "no statement!"
                    );

    my %args = ( # %optional,
                @_);

    return undef
        unless (Validate(\%args, \%required));

    return ($self->{parser}->sql_000($args{statement}));

}

sub Algebra
{
    my $self = shift;

    my %args = ( # %optional,
                @_);

    my $parse_tree;

    if (exists($args{statement}))
    {
        $parse_tree = $self->Parse(statement => $args{statement});
    }

    unless (defined($parse_tree))
    {
        unless (exists($args{parse_tree}))
        {
            my $msg = "no parse tree or statement";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));

            return 0;
        }

        $parse_tree = $args{parse_tree};
    }

    return $self->{getAlgebra}->Convert(parse_tree => $parse_tree);

}

sub TypeCheck
{
    my $self = shift;

    my %required = (
                    algebra   => "no algebra !",
                    statement => "no sql statement !"
                    );

    my %args = ( # %optional,
                @_);

    return undef
        unless (Validate(\%args, \%required));

    my @foo = $self->{typeCheck}->TypeCheck(algebra   => $args{algebra},
                                            statement => $args{statement},
                                            dict      => $self->Dict());


    return @foo;
}

sub QueryRewrite
{
    my $self = shift;

    my %required = (
                    algebra   => "no algebra !",
                    statement => "no sql statement !"
                    );

    my %args = ( # %optional,
                @_);

    return undef
        unless (Validate(\%args, \%required));

    # QUERY REWRITE

    whoami;
    my $alg = $args{algebra};

    my @baz =
        $self->{queryRewrite}->QueryRewrite(algebra   => $alg,
                                            statement => $args{statement},
                                            dict      => $self->Dict());

    return @baz;
}

sub Plan
{
    my $self = shift;

    my %required = (
                    statement => "no statement!"
                    );

    my %args = ( # %optional,
                @_);

    return undef
        unless (Validate(\%args, \%required));

    my $plan_status = {};
    my ($sqltxt, $parse_tree);

    # allow parse tree as an optional argument
    if (exists($args{parse_tree}) &&
        defined($args{parse_tree}))
    {
        $parse_tree = $args{parse_tree};
    }
    else
    {
        $sqltxt = $args{statement};
        $parse_tree = $self->Parse(statement => $sqltxt);
    }
    return $plan_status
        unless (defined($parse_tree));

    $plan_status->{phase} = "parse";
    $plan_status->{parse_tree} = $parse_tree;
    $plan_status->{statement}  = $sqltxt;
    
    my $algebra = $self->Algebra(parse_tree => $parse_tree);
    
    return $plan_status
        unless (defined($algebra));
    $plan_status->{phase} = "algebra";
    $plan_status->{algebra} = $algebra;

    my ($tc, $err_status) 
        = $self->TypeCheck(algebra   => $algebra,
                           statement => $sqltxt);

    $plan_status->{phase} = "typecheck";
    $plan_status->{algebra} = $tc;
    $plan_status->{error_status} = $err_status;

    return $plan_status
        if ($err_status);

    ($tc, $err_status) 
        = $self->QueryRewrite(algebra   => $tc,
                              statement => $sqltxt);

    $plan_status->{phase} = "queryrewrite";
    $plan_status->{algebra} = $tc;
    $plan_status->{error_status} = $err_status;

    return $plan_status;

}

sub GetFromWhereEtc
{
    my $self = shift;

    my %required = (
                    algebra   => "no algebra !"
                    );

    my %args = (#%optional,
                @_);

    return undef
        unless (Validate(\%args, \%required));

    $args{dict}  = $self->Dict();

    return $self->{typeCheck}->GetFromWhereEtc(%args);

}

sub SQLWhere2
{
#    whoami;
    my $self = shift;    
    my $dictobj = $self->{dictobj};
    my %args = (@_);

    my $tablename = $args{tablename};
    my $where     = $args{where};

#    greet $where;


    # XXX XXX: filter will complain about "uninitialized" strings

    my $filterstring = '
   $filter = sub {

        no warnings qw(uninitialized); # shut off null string warnings

        my ($tabdef, $rid, $outarr, $get_alias_col, $tc_rownum) = @_;
        return 1
            if (defined($outarr) &&
                ( ';
#                scalar(@{$outarr}) &&

    my $AndPurity = 0;    # WHERE clauses of ANDed predicates may
    my $AndTokens = [];   # be suitable for index lookups, but ORs
                          # can be a problem.  Test for "And Purity".

    if (defined($where->[0]->{sc_tree}->{vx}))
    {
        $filterstring .= $where->[0]->{sc_tree}->{vx}
    }
    else
    {
        # handle NULL/UNDEF
        $filterstring .= ' undef';
    }

    $filterstring .= "));};";

    my $where_text = $where->[0]->{sc_txt};
    $AndPurity     = $where->[0]->{sc_and_purity};

#    greet $filterstring;
#    greet "pure", $AndPurity, @AndTokens;
    $AndTokens = $where->[0]->{sc_index_keys}
       if ($AndPurity);

    my $filter;     # the anonymous subroutine which is the 
                    # result of eval of filterstring

    my $status;

    my ($msg, %earg);
    my $badparse;
    if ($badparse)
    {
        %earg = (self => $self, msg => $msg,
                 severity => 'warn');
                    
        &$GZERR(%earg)
            if (defined($GZERR));
    }
    else
    {
        $status = eval " $filterstring ";
    }

    unless (defined($status))
    {
        $msg = "";
#        warn $@ if $@;
        $msg .= $@ 
            if $@;
        $msg .= "\nbad filter:\n";
        $msg .= $filterstring . "\n";
        $msg .= "\nWHERE clause:\tWHERE " . $where_text . "\n";
        %earg = (self => $self, msg => $msg,
                 severity => 'warn');
                    
        &$GZERR(%earg)
            if (defined($GZERR));

        return undef;
    }
#    greet $filter; 

    my %hh = (idxfilter => $AndTokens);
    $hh{filter} = $filter
        if (defined($filter));
    $hh{where_text} = $where_text;
    $hh{filter_text} = $filterstring;
#    greet %hh;
    return \%hh;
} # end SQLWhere2



END { }       # module clean-up code here (global destructor)

## YOUR CODE GOES HERE

1;  # don't forget to return a true value from the file

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::Plan - Parsing, Planning and Execution

=head1 SYNOPSIS

use Genezzo::Plan;


=head1 DESCRIPTION



=head1 ARGUMENTS

=head1 FUNCTIONS

=over 4

=item Parse

Parse a SQL statement and return a parse tree.

=item Algebra

Take a SQL statement or parse tree and return the corresponding
relational algebra.

=back

=head2 EXPORT

=over 4


=back


=head1 LIMITATIONS


=head1 TODO

=over 4

=item SQLWhere2: need to allow rownum in where clause, which means we
need a rownum rowsource [select * from dual where rownum < 10; ]

=item update pod

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
