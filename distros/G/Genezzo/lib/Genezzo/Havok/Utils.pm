#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Havok/RCS/Utils.pm,v 1.10 2007/07/16 07:35:22 claude Exp claude $
#
# copyright (c) 2006, 2007 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::Havok::Utils;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(&sql_func_metadump
             &_build_sql_for_user_function
             );

use Genezzo::Util;

use strict;
use warnings;

use Carp;

our $VERSION;
our $MAKEDEPS;

BEGIN {
    $VERSION = do { my @r = (q$Revision: 1.10 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

    my $pak1  = __PACKAGE__;
    $MAKEDEPS = {
        'NAME'     => $pak1,
        'ABSTRACT' => ' ',
        'AUTHOR'   => 'Jeffrey I Cohen (jcohen@cpan.org)',
        'LICENSE'  => 'gpl',
        'VERSION'  =>  $VERSION,
        }; # end makedeps

    $MAKEDEPS->{'PREREQ_HAVOK'} = {
        'Genezzo::Havok::UserFunctions' => '0.0',
    };

    # DML is an array, not a hash

    my $now = 
    do { my @r = (q$Date: 2007/07/16 07:35:22 $ =~ m|Date:(\s+)(\d+)/(\d+)/(\d+)(\s+)(\d+):(\d+):(\d+)|); sprintf ("%04d-%02d-%02dT%02d:%02d:%02d", $r[1],$r[2],$r[3],$r[5],$r[6],$r[7]); };


    my %tabdefs = ();
    $MAKEDEPS->{'TABLEDEFS'} = \%tabdefs;

    my @perl_funcs = qw(
                        alter_ts
                        add_user_function
                        drop_user_function
                        register_havok_package
                        );


    my @ins1;
    # XXX XXX XXX XXX: need "select COUNT(*) from user_functions"
    my $ccnt = 1;
    for my $pfunc (@perl_funcs)
    {
        my $bigstr = "i user_functions $ccnt require $pak1 " 
            . "sql_func_" . $pfunc . " SYSTEM $now 0 HASH $pfunc";
        push @ins1, $bigstr;
        $ccnt++;
    }

    # if check returns 0 rows then proceed with install
    $MAKEDEPS->{'DML'} = [
                          { check => [
                                      "select * from user_functions where xname = \'$pak1\'"
                                      ],
                            install => \@ins1
                            }
                          ];

#    print Data::Dumper->Dump([$MAKEDEPS]);
} # end BEGIN

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

    my $warn = 0;
    if (exists($args{severity}))
    {
        my $sev = uc($args{severity});
        $sev = 'WARNING'
            if ($sev =~ m/warn/i);

        # don't print 'INFO' prefix
        if ($args{severity} !~ m/info/i)
        {
            printf ("%s: ", $sev);
            $warn = 1;
        }

    }
    # XXX XXX XXX
    print __PACKAGE__, ": ",  $args{msg};
#    print $args{msg};
#    carp $args{msg}
#      if (warnings::enabled() && $warn);
    
};

sub MakeYML
{
    use Genezzo::Havok;

    my $makedp = $MAKEDEPS;

    return Genezzo::Havok::MakeYML($makedp);
}

sub getpod
{
    my $bigHelp;
    ($bigHelp = <<'EOF_HELP') =~ s/^\#//gm;
#=head1 Utility_Functions
#
#=head2  add_user_function : add_user_function(module=...,function=...)
#
#To create a user function based upon the function 'somefunc' in
#Genezzo::Contrib::MyModule just use the module and function named
#parameters:
#
#  select add_user_function(
#             'module=Genezzo::Contrib::MyModule',
#             'function=somefunc') from dual;
#
#Simple functions may be defined directly as a single argument which is
#just a function definition (minus the leading "sub").  For example,
#the function foobar just adds two to the argument:
#
#  select add_user_function(
#             'foobar { my $foo = shift; $foo += 2; return $foo}'
#              ) from dual;
#
#More sophisticated functions may need to define the user_function
#table columns as specified in L<Genezzo::Havok::UserFunctions>. 
#Use the help command:
#
#  select add_user_function('help') from dual;
#
#to list the valid parameters
#
#=head2  drop_user_function : drop_user_function(function_name)
#
#Undefine an existing function.
#
#
#=head2  alter_ts : alter_ts(tsname=...,increase_by=..., ...)
#
#Update a tablespace to support large databases. This function
#supercedes the bigdb.sql script.  When called with no arguments:
#
#    select alter_ts() from dual;
#
#the SYSTEM tablespace is set to automatically increase by 50% each
#time it runs out of space, and the buffer cache size is set to 1000
#blocks.  When new datafiles are acquired, they will start at 10M and
#increase by 50% each time they resize.
#
#alter_ts can also take the single argument 'help':
#
#    select alter_ts('help') from dual;
#
#which will cause it to list the named parameters (all of which are optional).
#The parameters are:
#
#  tsname - the tablespace name
#
#  increase_by - the amount to increase the current filesize by
#    when it runs out of free space.  The value may be a percentage,
#    e.g. 50%, or a fixed size like 100M.  If this parameter is set to
#    zero, the tablespace will remain a fixed size.
#
#  filesize - the initial size of a new file when it is added to
#    the tablespace.  Note that this parameter only affects files which are
#    automatically created, not files added with "addfile".
#
#  bufcachesize - the buffer cache size (in number of blocks).
#
#The default settings are equivalent to:
#
#    select alter_ts(
#    'tsname=SYSTEM',
#    'increase_by=50%',
#    'filesize=10M', 
#    'bufcachesize=1000') from dual;
#
#The tsname argument may be specified multiple times -- the increase_by
#and filesize will be applied to each tablespace.
#
#=head2  register_havok_package : register_havok_package(modname=...,version=...)
#
#Havok modules are loaded via the HavokUse function.  The
#register_havok_package function is designed to simplify the update of
#the havok table in order to track the particular version of a
#package.  Currently, there is no requirement that all Havok modules
#register in the havok table, but future versions of Genezzo may
#require this registration, or enforce it automatically as part of the
#HavokUse function.  Note that all registered havok packages must have
#a valid HavokInit function.
#
#  select register_havok_package(
#             'modname=Genezzo::Contrib::MyModule',
#             'version=1.1') from dual;
#
#Use the help command:
#
#  select register_havok_package('help') from dual;
#
#to list the valid parameters
#
#
EOF_HELP

    my $msg = $bigHelp;

    return $msg;

} # end getpod


sub _build_sql_for_user_function
{
    my %required = (
                    xid => "no xid!",
                    xname => "no xname!",
                    args => "no args!"
                    );

    my $now = Genezzo::Dict::time_iso8601();

    my %optional = (
                    xtype => "require",
                    creationdate => $now,
                    owner => "SYSTEM",
                    version => 0
                    );
    my %args = (
                %optional,
		@_);

    # synonyms
    $args{xname} = $args{module} if (exists($args{module}));
    $args{args}  = $args{function} if (exists($args{function}));

    return undef
        unless (Validate(\%args, \%required));

    my $pattern = "\'%s\', " x 7;

    my $bigstr = "insert into user_functions values (" .
        sprintf($pattern,
                $args{xid},
                $args{xtype},
                $args{xname},
                $args{args},

                $args{owner},
                $args{creationdate},
                $args{version});

    $bigstr .= (exists($args{argstyle})) ? 
        sprintf("\'%s\', ", $args{argstyle}) : 'NULL, ';
    $bigstr .= (exists($args{sqlname})) ? 
        sprintf("\'%s\', ", $args{sqlname}) : 'NULL, ';
    $bigstr .= (exists($args{typecheck})) ? 
        sprintf("\'%s\' ", $args{typecheck}) : 'NULL ';

    $bigstr .= ")";

    return $bigstr;
}

sub sql_func_add_user_function
{
    my %args= @_;

    my $dict = $args{dict};
    my $dbh  = $args{dbh};
    my $fn_args = $args{function_args};
    
#    print Data::Dumper->Dump($fn_args);

    my $now = Genezzo::Dict::time_iso8601();

    # list the optional values
    my %nargs = (
                 xtype => "require",
                 creationdate => $now,
                 owner => "SYSTEM",
                 version => 0
                 );

    my $do_help = 0;

    $do_help = 1 unless (scalar(@{$fn_args}));
    
    my $valid = 'xid|xtype|xname|args|owner|creationdate|version'.
        '|argstyle|sqlname|typecheck';

    $valid .= '|module|function'; # additional synonyms

    for my $argi (@{$fn_args})
    {
        # separate key=val pairs into hash args

        my @foo;
        @foo = ($argi =~ m/^(\s*\w+\s*\=\s*)(.*)(\s*)$/)
            if ($argi =~ m/\w+\s*\=/);


        if ($argi =~ m/^\s*($valid)\s*\=/i)
        {
            my $nargtype = $foo[0];
            # remove the spaces and equals ("=");
            $nargtype =~ s/\s//g;
            $nargtype =~ s/\=//g;

            $nargtype = 'xname' if ($nargtype =~ m/^module/i);
            $nargtype = 'args' if ($nargtype =~ m/^function/i);

            $nargs{lc($nargtype)} = $foo[1];
        }
        else
        {
            if (scalar(@{$fn_args}) == 1)
            {
                if ($argi =~ m/^help$/i)
                {
                    $do_help = 1;
                    last;
                }
                elsif ($argi =~ m/^(\s*\w+\s*\{.*\}\s*)/)
                {
                    @foo = ($argi =~ m/^\s*(\w+)\s*(\{.*\})\s*/);
                    {
                        $nargs{xtype} = 'function';
                        $nargs{xname} = $foo[0];                    
                        $nargs{args}  = $foo[1];                    
                    }
                }
            } # end if 1 arg
        }
    } # end for

    if ($do_help)
    {
        my $outi = "Valid arguments are:\n    ";

        $outi .= join(" ",split(/\|/, $valid)) . "\n";

        my $bigexample;
        ($bigexample = <<EOF_EXAMPLE) =~ s/^\#//gm;
#
#To create a user function based upon the function 'somefunc' in 
#Genezzo::Contrib::MyModule just use:
#  select add_user_function(
#             'module=Genezzo::Contrib::MyModule',
#             'function=somefunc') from dual;
EOF_EXAMPLE

        $outi .= $bigexample;
        
        return $outi;
    }

    unless (exists($nargs{xid}))
    {
        my $hashi  = $dict->DictTableGetTable (tname => "user_functions") ;
        my $tv = tied(%{$hashi});

        $nargs{xid} = $dict->DictGetNextVal(tname => "user_functions",
                                            col   => "xid",
                                            tieval => $tv);

    }

    my $bigstr = _build_sql_for_user_function(%nargs);

    return 0 unless(defined($bigstr));

    my $sth =
        $dbh->prepare($bigstr);
    
    return 0
        unless ($sth);


    # insert the function definition in the user_function table
    return 0
        unless ($sth->execute());

    # load the function
    return Genezzo::Havok::UserFunctions::LoadFunction(%nargs);

} 

sub sql_func_drop_user_function
{
    my %args= @_;

    my $dict = $args{dict};
    my $dbh  = $args{dbh};
    my $fn_args = $args{function_args};
    
#    print Data::Dumper->Dump($fn_args);

    for my $argi (@{$fn_args})
    {
        # handle case of a function in a REQUIREd module, or an inline
        # function definition
        my $bigstr = 
            "delete from user_functions" . 
            " where (xtype = \'require\' and ".
            "args = lc(\'sql_func_" . $argi . "\'))" .
            " or (xtype = \'function\' and ".
            "xname = lc(\'" . $argi . "\'))";

        my $sth =
            $dbh->prepare($bigstr);
    
        return 0
            unless ($sth);

        # delete the function definition from the user_function table
        return 0
            unless ($sth->execute());

        no strict 'refs';
        no warnings 'redefine';
        # remove the function from the namespace
        my $uds = "undef &Genezzo::GenDBI::$argi";
        eval " $uds ";
        $uds = "undef &Genezzo::GenDBI::sql_func_" . $argi;
        eval " $uds ";
    }
    return 1;
} # end drop user function


sub sql_func_alter_ts
{
    my %args= @_;

    my $dict = $args{dict};
    my $dbh  = $args{dbh};
    my $fn_args = $args{function_args};
    
    print Data::Dumper->Dump($fn_args);
    
    my %tspaces;
    my $increase_by = "50%";
    my $filesize = "10M";
    my $bc_size  = 1000;
    my $show_help = 0;

    if (scalar(@{$fn_args}) < 1)
    {
        $tspaces{"SYSTEM"} = 1;
    }
    else
    {
        for my $arg (@{$fn_args})
        {
            if ($arg =~ m/^(help|\?)/)
            {
                $show_help = 1;
            } 
            elsif ($arg =~ m/^(ts|tsname|tablespace|tspace)/i)
            {
                my @ggg = split('=',$arg, 2);
                if (2 == scalar(@ggg))
                {
                    $tspaces{$ggg[1]} = 1;
                }
            }
            elsif ($arg =~ m/^(inc)/i) # increase by
            {
                my @ggg = split('=',$arg, 2);
                if (2 == scalar(@ggg))
                {
                    $increase_by = $ggg[1];
                }
            }
            elsif ($arg =~ m/^(bc|buf)/i) # buffer cache size
            {
                my @ggg = split('=',$arg, 2);
                if (2 == scalar(@ggg))
                {
                    $bc_size = $ggg[1];
                }
            }
            elsif ($arg =~ m/^(fil)/i) # file size
            {
                my @ggg = split('=',$arg, 2);
                if (2 == scalar(@ggg))
                {
                    $filesize = $ggg[1];
                }
            }
            else
            {
                my %earg = (#self => $self,
                            severity => 'warn',
                            msg => "invalid argument: $arg\n");

                &$GZERR(%earg)
                    if (defined($GZERR));

                $show_help = 1;
                last;
            }
        } # end for

    }

    if ($show_help)
    {
        my $bigstr = 
            "[tsname=<tablespace name>, [tsname=<tablespace name>] ] , [increase_by=<increase> ] , [filesize=<filesize> ] , [bufcachesize=<bcsize>]";

        return $bigstr;
    }
    
    print join(" ", keys(%tspaces)), "\n";
    print "inc = ", $increase_by, "\n";
    print "bc  = ", $bc_size, "\n";
    print "fil = ", $filesize, "\n";

    my $addfile = "filesize=$filesize increase_by=$increase_by";

    my $sth =
        $dbh->prepare("select pref_value from _pref1 where pref_key=\'bc_size\'");
    my $curr_bc_size;
    
    return 0
        unless ($sth);

    $sth->execute();

    while (1) 
    {
        my @lastfetch = $sth->fetchrow_array();
        
        last
            unless (scalar(@lastfetch));

        $curr_bc_size = shift @lastfetch;
    }
        
    unless ($curr_bc_size && 
            ($curr_bc_size == $bc_size))
    {
        $sth =
            $dbh->prepare("update _pref1 set pref_value=$bc_size where pref_key=\'bc_size\'");
        
        return 0
            unless ($sth);

        $sth->execute();
        
    }

    for my $tsname (keys(%tspaces))
    {
        $sth =
            $dbh->prepare("select tsid from _tspace  where tsname=\'$tsname\'");
        
        next
            unless ($sth);

        $sth->execute();

        my $tsid = undef;

        while (1) 
        {
            my @lastfetch = $sth->fetchrow_array();
        
            last
                unless (scalar(@lastfetch));

            $tsid = shift @lastfetch;
        }
        next
            unless ($tsid);
        
        $sth =
            $dbh->prepare("update _tspace set addfile=\'$addfile\'  where tsid =\'$tsid\'");

        next
            unless ($sth);

        $sth->execute();
        

        $sth =
            $dbh->prepare("update _tsfiles set increase_by=\'$increase_by\'  where tsid =\'$tsid\'");
        
        next
            unless ($sth);

        $sth->execute();
    } # end for each tsname


    return 1;
}

sub sql_func_register_havok_package
{
    my %args= @_;

    my $dict = $args{dict};
    my $dbh  = $args{dbh};
    my $fn_args = $args{function_args};
    
#    print Data::Dumper->Dump($fn_args);

    my $now = Genezzo::Dict::time_iso8601();

    # list the optional values
    my %nargs = (
                 creationdate => $now,
                 owner => "SYSTEM",
                 flag => 0,
                 version => 0
                 );

    my $do_help = 0;

    $do_help = 1 unless (scalar(@{$fn_args}));
    
    my $valid = 'hid|modname|owner|creationdate|flag|version';

    $valid .= '|module'; # additional synonyms

    for my $argi (@{$fn_args})
    {
        # separate key=val pairs into hash args

        my @foo;
        @foo = ($argi =~ m/^(\s*\w+\s*\=\s*)(.*)(\s*)$/)
            if ($argi =~ m/\w+\s*\=/);


        if ($argi =~ m/^\s*($valid)\s*\=/i)
        {
            my $nargtype = $foo[0];
            # remove the spaces and equals ("=");
            $nargtype =~ s/\s//g;
            $nargtype =~ s/\=//g;

            $nargtype = 'modname' if ($nargtype =~ m/^module/i);

            $nargs{lc($nargtype)} = $foo[1];
        }
        else
        {
            if (scalar(@{$fn_args}) == 1)
            {
                if ($argi =~ m/^help$/i)
                {
                    $do_help = 1;
                    last;
                }
            } # end if 1 arg
        }
    } # end for

    my $outi = "";

    unless (exists($nargs{modname}) && length($nargs{modname}))
    {
        if (!$do_help)
        {
            $do_help = 1;
#            my %earg = (#self => $self,
#                        severity => 'warn',
#                        msg => "missing argument: modname\n");
#
#            &$GZERR(%earg)
#                if (defined($GZERR));

            $outi .= "missing argument: modname\n";
        }
    }

    if ($do_help)
    {
        $outi .= "Valid arguments are:\n    ";

        $outi .= join(" ",split(/\|/, $valid)) . "\n";

        my $bigexample;
        ($bigexample = <<EOF_EXAMPLE) =~ s/^\#//gm;
#
#To register a havok package based upon 
#Genezzo::Contrib::MyModule just use:
#  select register_havok_package(
#             'module=Genezzo::Contrib::MyModule') from dual;
EOF_EXAMPLE

        $outi .= $bigexample;
        
        return $outi;
    }

    unless (exists($nargs{hid}))
    {
        my $hashi  = $dict->DictTableGetTable (tname => "havok") ;
        my $tv = tied(%{$hashi});

        $nargs{hid} = $dict->DictGetNextVal(tname => "havok",
                                            col   => "hid",
                                            tieval => $tv);

    }

    # list the basic column names
    my @cnames = qw(hid modname owner creationdate flag version);

    my $bigstr = "insert into havok(";

    $bigstr .= join(', ', @cnames);
    # add the registration date column, which is _now_
    $bigstr .= ", regdate) values (";
    for my $col (@cnames)
    {
        $bigstr .= "\'" . $nargs{$col} . "\', ";
    }
    $bigstr .= "\'" . $now . "\')";

    return 0 unless(defined($bigstr));

    my $sth =
        $dbh->prepare($bigstr);
    
    return 0
        unless ($sth);

    # insert the function definition in the user_function table
    return 0
        unless ($sth->execute());

    return 1;
} 


END { }       # module clean-up code here (global destructor)

## YOUR CODE GOES HERE

1;  # don't forget to return a true value from the file

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::Havok::Utils - general utility functions

=head1 SYNOPSIS

select HavokUse('Genezzo::Havok::Utils') from dual;

=head1 DESCRIPTION

The Havok Utils module defines several general utility functions.

=head1 ARGUMENTS

=head1 FUNCTIONS

=over 4

=item  add_user_function

To create a user function based upon the function 'somefunc' in
Genezzo::Contrib::MyModule just use the module and function named
parameters:

  select add_user_function(
             'module=Genezzo::Contrib::MyModule',
             'function=somefunc') from dual;

Simple functions may be defined directly as a single argument which is
just a function definition (minus the leading "sub").  For example,
the function foobar just adds two to the argument:

  select add_user_function(
             'foobar { my $foo = shift; $foo += 2; return $foo}'
              ) from dual;

More sophisticated functions may need to define the user_function
table columns as specified in L<Genezzo::Havok::UserFunctions>. 
Use the help command:

  select add_user_function('help') from dual;

to list the valid parameters

=item  drop_user_function 

Undefine an existing function.

=item  alter_ts

Update a tablespace to support large databases. This function
supercedes the bigdb.sql script.  When called with no arguments:

    select alter_ts() from dual;

the SYSTEM tablespace is set to automatically increase by 50% each
time it runs out of space, and the buffer cache size is set to 1000
blocks.  When new datafiles are acquired, they will start at 10M and
increase by 50% each time they resize.

alter_ts can also take the single argument 'help':

    select alter_ts('help') from dual;

which will cause it to list the named parameters (all of which are optional).
The parameters are:

=over 6

=item tsname - the tablespace name

=item increase_by - the amount to increase the current filesize by
when it runs out of free space.  The value may be a percentage,
e.g. 50%, or a fixed size like 100M.  If this parameter is set to
zero, the tablespace will remain a fixed size.

=item filesize - the initial size of a new file when it is added to
the tablespace.  Note that this parameter only affects files which are
automatically created, not files added with "addfile".

=item bufcachesize - the buffer cache size (in number of blocks).

=back

The default settings are equivalent to:

    select alter_ts(
    'tsname=SYSTEM',
    'increase_by=50%',
    'filesize=10M', 
    'bufcachesize=1000') from dual;

The tsname argument may be specified multiple times -- the increase_by
and filesize will be applied to each tablespace.

=item  register_havok_package 

Havok modules are loaded via the HavokUse function.  The
register_havok_package function is designed to simplify the update of
the havok table in order to track the particular version of a
package.  Currently, there is no requirement that all Havok modules
register in the havok table, but future versions of Genezzo may
require this registration, or enforce it automatically as part of the
HavokUse function.  Note that all registered havok packages must have
a valid HavokInit function.

  select register_havok_package(
             'modname=Genezzo::Contrib::MyModule',
             'version=1.1') from dual;

Use the help command:

  select register_havok_package('help') from dual;

to list the valid parameters


=back

=head2 EXPORT

=over 4


=back


=head1 LIMITATIONS

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
