#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Havok/RCS/SysHelp.pm,v 1.8 2007/07/16 07:36:52 claude Exp claude $
#
# copyright (c) 2007 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::Havok::SysHelp;
use Genezzo::Util;

use strict;
use warnings;
use warnings::register;

use Carp;

our $VERSION;
our $MAKEDEPS;

BEGIN {
    $VERSION = do { my @r = (q$Revision: 1.8 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

    my $pak1  = __PACKAGE__;
    $MAKEDEPS = {
        'NAME'     => $pak1,
        'ABSTRACT' => ' ',
        'AUTHOR'   => 'Jeffrey I Cohen (jcohen@cpan.org)',
        'LICENSE'  => 'gpl',
        'VERSION'  =>  $VERSION,
#        'UPDATED'  => Genezzo::Dict::time_iso8601()
        }; # end makedeps

    $MAKEDEPS->{'PREREQ_HAVOK'} = {
        'Genezzo::Havok' => '0.0',
        'Genezzo::Havok::UserFunctions' => '0.0',
        'Genezzo::Havok::Utils' => '0.0'
    };

    # DML is an array, not a hash

#    my $now = Genezzo::Dict::time_iso8601()
    my $now = 
    do { my @r = (q$Date: 2007/07/16 07:36:52 $ =~ m|Date:(\s+)(\d+)/(\d+)/(\d+)(\s+)(\d+):(\d+):(\d+)|); sprintf ("%04d-%02d-%02dT%02d:%02d:%02d", $r[1],$r[2],$r[3],$r[5],$r[6],$r[7]); };

    my $dml =
        [
#         "i havok 3 $pak1 SYSTEM $now 0 $VERSION"
         ];

    my %tabdefs = 
        ('sys_help' =>  {
            create_table =>  
                'id=n owner=c creationdate=c version=c module=c',           
                dml => $dml
            }
         );
    $MAKEDEPS->{'TABLEDEFS'} = \%tabdefs;

    my @sql_funcs = qw(
                        add_help
                       );

    my @ins1;
    my $ccnt = 1;
    for my $pfunc (@sql_funcs)
    {
        my %attr = (module => $pak1, 
                    function => "sql_func_" . $pfunc,
                    creationdate => $now,
                    argstyle => 'HASH',
                    sqlname => $pfunc);

        my @attr_list;
        while ( my ($kk, $vv) = each (%attr))
        {
            push @attr_list, '\'' . $kk . '=' . $vv . '\'';
        }

        my $bigstr = "select add_user_function(" . join(", ", @attr_list) .
            ") from dual";
        push @ins1, $bigstr;
        $ccnt++;
    }

    # add help for basic_help.  Note that basic_help is loaded by
    # default, so this row acts as a "placeholder".  add_help and
    # havokinit ignore it.
    push @ins1, "select add_help(\'Genezzo::BasicHelp\') from dual";

    # add help for Utils
    push @ins1, "select add_help(\'Genezzo::Havok::Utils\') from dual";

    # register havok module

    push @ins1, "select register_havok_package(" .
        "\'modname=" . $pak1 .  "\', ".
        "\'creationdate=" . $now .  "\', ".
        "\'version=" . $VERSION .  "\'".
        ") from dual";

    # if check returns 0 rows then proceed with install
    $MAKEDEPS->{'DML'} = [
                          { check => [
                                      "select * from user_functions where xname = \'$pak1\'"
                                      ],
                            install => \@ins1
                            }
                          ];

#    print Data::Dumper->Dump([$MAKEDEPS]);
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

sub MakeYML
{
    use Genezzo::Havok;

    my $makedp = $MAKEDEPS;

#    $makedp->{'UPDATED'}  = Genezzo::Dict::time_iso8601();

    return Genezzo::Havok::MakeYML($makedp);
}

sub sql_func_add_help
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
                 version => 0
                 );

    if (scalar(@{$fn_args}) < 1)
    {
        return 0;
    }

    my $valid = 'id|owner|creationdate|version|module';

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

            $nargs{lc($nargtype)} = $foo[1];
        }
        else
        {
            if (scalar(@{$fn_args}) == 1)
            {
                $nargs{module} = $fn_args->[0];
            } # end if 1 arg
            else
            {
                
                return 0;
            }
        }
    } # end for

    unless (exists($nargs{xid}))
    {
        my $hashi  = $dict->DictTableGetTable (tname => "sys_help") ;
        my $tv = tied(%{$hashi});

        $nargs{id} = $dict->DictGetNextVal(tname   => "sys_help",
                                            col    => "id",
                                            tieval => $tv);

    }

    my $pattern = "\'%s\', " x 4;
    $pattern .= "\'%s\'";

    my $bigstr = "insert into sys_help values (" .
        sprintf($pattern,
                $nargs{id},
                $nargs{owner},
                $nargs{creationdate},
                $nargs{version},
                $nargs{module});

    $bigstr .= ")";

    return 0 unless(defined($bigstr));

    my $sth =
        $dbh->prepare($bigstr);
    
    return 0
        unless ($sth);

    # insert the module  in the sys_help table
    return 0
        unless ($sth->execute());

    my $pkg_name = $nargs{module};

    # basic_help is the default help already
    unless ($pkg_name eq 'Genezzo::BasicHelp')
    {
        my $stat = $dict->DictAddHelp($pkg_name);
        return 0
            unless ($stat);
    }

    return 1;
}

sub HavokInit
{
#    whoami;
    my %optional = (phase => "init");
    my %required = (dict  => "no dictionary!",
                    flag  => "no flag"
                    );

    my %args = (%optional,
		@_);
#		
    my @stat;

    push @stat, 0, $args{flag};
#    whoami (%args);

    return @stat
        unless (Validate(\%args, \%required));

    my $dict   = $args{dict};
    my $phase  = $args{phase};

    return @stat
        unless ($dict->DictTableExists(tname => "sys_help",
                                       silent_notexists => 1));

    my $hashi  = $dict->DictTableGetTable (tname => "sys_help") ;

    return @stat # no User Extensions
        unless (defined ($hashi));

    my $tv = tied(%{$hashi});

    while ( my ($kk, $vv) = each ( %{$hashi}))
    {
        my $getcol = $dict->_get_col_hash("sys_help");  
        my $id    = $vv->[$getcol->{id}];
        my $owner  = $vv->[$getcol->{owner}];
        my $dat    = $vv->[$getcol->{creationdate}];
        my $modname  = $vv->[$getcol->{module}];

        # basic_help is the default help already
        unless ($modname eq 'Genezzo::BasicHelp')
        {
            $dict->DictAddHelp($modname);
        }

    } # end while

    $stat[0] = 1; # ok!
    return @stat;
}

sub HavokCleanup
{
#    whoami;
    return HavokInit(@_, phase => "cleanup");
}

END { }       # module clean-up code here (global destructor)

## YOUR CODE GOES HERE

1;  # don't forget to return a true value from the file

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::Havok::SysHelp - load the sys_help table

=head1 SYNOPSIS

 # don't say "use Genezzo::Havok::SysHelp".  Update the
 # dictionary havok table:

select HavokUse('Genezzo::Havok::SysHelp') from dual;


=head1 DESCRIPTION

The sys_help table loads the help files for additional Genezzo modules.

create table sys_help (
    id   number,
    owner char, 
    creationdate char,
    version char,
    module char
    );

=over 4

=item id - a unique id number
  
=item owner - owner of the package 

=item creationdate - date row was created

=item version

=item module - module name

=back

=head2 Example:

  select 
    add_user_function(
      'module=Genezzo::Havok::Examples')
  from dual;

=head1 ARGUMENTS

=head1 FUNCTIONS

=head2 EXPORT

=over 4


=back


=head1 LIMITATIONS

=head1 TODO

=over 4

=item unload/reload help as well

=back

=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

L<perl(1)>.

Copyright (c) 2007 Jeffrey I Cohen.  All rights reserved.

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
