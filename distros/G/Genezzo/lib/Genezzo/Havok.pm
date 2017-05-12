#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/RCS/Havok.pm,v 7.19 2007/11/20 07:47:07 claude Exp claude $
#
# copyright (c) 2003-2007 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::Havok;
use Genezzo::Util;
use Genezzo::Dict;

use strict;
use warnings;
use warnings::register;

use Carp;

our $VERSION;
our $MAKEDEPS;

BEGIN {
    $VERSION = do { my @r = (q$Revision: 7.19 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

    my $pak1  = __PACKAGE__;
    $MAKEDEPS = {
        # basic module info - similar to MakeMaker
        'NAME'     => $pak1,
        'ABSTRACT' => ' ',
        'AUTHOR'   => 'Jeffrey I Cohen (jcohen@cpan.org)',
        'LICENSE'  => 'gpl',
        'VERSION'  =>  $VERSION,
#        'UPDATED'  => Genezzo::Dict::time_iso8601()
        }; # end makedeps

    # List the Havok Module prerequisites (*not* perl module prereqs)
    $MAKEDEPS->{'PREREQ_HAVOK'} = {
#        'Text::ParseWords' => '0.0',
    };

    # DML is an array, not a hash

#    my $now = Genezzo::Dict::time_iso8601()
    my $now = 
    do { my @r = (q$Date: 2007/11/20 07:47:07 $ =~ m|Date:(\s+)(\d+)/(\d+)/(\d+)(\s+)(\d+):(\d+):(\d+)|); sprintf ("%04d-%02d-%02dT%02d:%02d:%02d", $r[1],$r[2],$r[3],$r[5],$r[6],$r[7]); };

    my $dml =
        [
         "i havok 1 $pak1 SYSTEM $now 0 $VERSION"
         ];

    # these are the table definitions (i.e. "create table" and
    # "insert" statements) specifically for this Havok module.  If
    # this module requires tables which are owned by another Havok
    # module, it should list that module in PREREQ_HAVOK
    my %tabdefs = 
        ('havok' =>  {
            create_table => 'hid=n modname=c owner=c creationdate=c flag=c version=c regdate=c',
            dml => $dml
            }
         );
    $MAKEDEPS->{'TABLEDEFS'} = \%tabdefs;

    # NOTE: Need to think about this one -- may have DML for the Havok
    # module which is not associated with a table definition.  One
    # example would be a UserExtend-based mdule which just adds new
    # SQL functions to the UserExtend table, but doesn't create any
    # new tables.
#    $MAKEDEPS->{'DML'} = [
#                          { check => [],
#                            install => [] }
#                          ];

#    print Data::Dumper->Dump([$MAKEDEPS]);
}

our $GZERR = sub {
    my %args = (@_);

    return 
        unless (exists($args{msg}));

    if (exists($args{severity}))
    {
        my $sev = uc($args{severity});
        return if ($sev eq 'IGNORE');
    }

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


sub HavokUse
{
    my %optional = (phase => "init");

    my %required = (dict   => "no dictionary!",
                    module => "no module!",
                    dbh    => "no dbh!"
                    );

    my %args = (%optional,
		@_);
#		

#    whoami (%args);

#    print "havokuse: ", join('*',@_), "\n";

    return 0
        unless (Validate(\%args, \%required));

    my $mod1 = $args{module};

    my @mod = split(/::/, $mod1);
    my $fname = pop @mod;
    $fname .= ".yml";

    my @file_list;

    for my $dir (@INC) 
    {
        my @dirs;

        @dirs = ();

        push @dirs, $dir, @mod;

        my $dspec = File::Spec->catfile(@dirs, $fname);

        whisper "dir: $dspec";
#        print "dir: $dspec\n";

        push @file_list, $dspec
            if (-e $dspec);


        last
            if (scalar(@file_list));
    } # end for my dir
        

    return undef
        unless (scalar(@file_list));

    my $inifile = shift @file_list;

    my $outi;
    my $refthing;
    {


        unless (open (INIFILE, "< $inifile" ))
        {
            print "could not open $inifile\n";
            return undef;
        }
        local $/;
        undef $/;
        my $ymlstr = <INIFILE>;
        close (INIFILE);

        $refthing = fakeYMLin($ymlstr);

        $outi = Data::Dumper->Dump([$refthing]);
    }

#    print $args{dict}->time_iso8601(), "\n";
    my $dict = $args{dict};
    return undef
        unless (defined($dict));
    my $dbh = $args{dbh};

    my $preq  = $refthing->{PREREQ_HAVOK};
    if (defined($preq))
    {
        while (my ($kk, $vv) = each (%{$preq}))
        {
            my $stat = HavokUse(module => $kk,
                                dict   => $dict,
                                dbh    => $dbh
                                # XXX XXX: should we propagate phase?

                                );
            unless (defined($stat))
            {
                my %earg = (#self => $self,
                            severity => 'warn',
                            msg => "failed to load prerequisite $kk");

                &$GZERR(%earg)
                    if (defined($GZERR));
                return undef;
            }
        }
    }

    my $tdefs = $refthing->{TABLEDEFS};

    my $do_dml = 0;
    if (defined($tdefs))
    {
        while (my ($kk, $vv) = each (%{$tdefs}))
        {
            # do nothing if table already exists...
            next if ($dict->DictTableExists(tname => $kk,
                                            silent_notexists => 1));

            if (exists($vv->{create_table}))
            {
                $do_dml = 1;
                unless ($dbh->do("ct " . $kk . " " . $vv->{create_table}))
                {
                    my %earg = (#self => $self,
                                severity => 'warn',
                                msg => "failed to create table $kk");

                    &$GZERR(%earg)
                        if (defined($GZERR));
                    return undef;
                }
            }
            if ($do_dml &&
                exists($vv->{dml}))
            {
                my $dml = $vv->{dml};
                for my $stmt (@{$dml})
                {
                    unless ($dbh->do($stmt))
                    {
                        my %earg = (#self => $self,
                                    severity => 'warn',
                                    msg => "failure on statement: $stmt");

                        &$GZERR(%earg)
                            if (defined($GZERR));
                        return undef;
                    }
                } # end for
            }
        }
    } # end if defined tdefs


    if (exists($refthing->{DML})
        && defined($refthing->{DML}))
    {
        my $bigdml = $refthing->{DML};

        for my $d1 (@{$bigdml})
        {
            my $do_install;

            $do_install = 0;

            if (exists($d1->{check})
                && defined($d1->{check}))
            {
                $do_install = 1;
                for my $c1 (@{$d1->{check}})
                {
                    if ($c1 =~ m/^select/i)
                    {
                        my $sth = $dbh->prepare($c1);
    
                        return undef unless ($sth->execute());

                        my @ftchary = $sth->fetchrow_array();
                        # check must be false, ie no rows
                        if (scalar(@ftchary))
                        {
                            $do_install = 0;
                            last;
                        }
                        
                    }
                }
                
                if ($do_install)
                {
                    if (exists($d1->{install})
                        && defined($d1->{install}))
                    {
                        for my $stmt (@{$d1->{install}})
                        {
                            unless ($dbh->do($stmt))
                            {
                                my %earg = (#self => $self,
                                            severity => 'warn',
                                            msg => "failure on statement: $stmt");

                                &$GZERR(%earg)
                                    if (defined($GZERR));
                                return undef;
                    
                            }
                        }
                    }

                }
            }

        }
        

    }

    my $do_reload = 0;
    $do_reload = 1 if ($args{phase} =~ m/^reload/);

  L_do_init:
    if ($do_dml || $do_reload)
    {

        if ($args{phase} =~ m/^(init|reload)$/)
        {
            return undef
                unless Genezzo::Havok::HavokInit(dict => $dict, flag => 0);
        }

    }

    return $outi;

}

sub fakeYMLout
{
    my ($refthing, $nest) = @_;

    $nest = 0
        unless (defined($nest));

    my $leadsp = "";
    if ($nest) 
    {
        $leadsp = " " x (2*$nest);
    }
    
    if (ref($refthing) eq 'SCALAR')
    {
        return $$refthing;
    }
    my $outi = "";
    if (ref($refthing) eq 'HASH')
    {
        $outi = "\n"
            if ($nest);

        for my $kk (sort (keys %{$refthing}))
        {
            my $vv = $refthing->{$kk};
            $outi .= $leadsp . $kk . ':    ' .
                fakeYMLout($vv, $nest + 1) . "\n";
        }
#        $outi .= $leadsp . "\n";
        return $outi;
    }
    if (ref($refthing) eq 'ARRAY')
    {
        $outi = "\n";
        
        for my $vv ( @{$refthing})
        {
            $outi .= $leadsp . '-    ' . 
                fakeYMLout($vv, $nest + 1) . "\n";
        }
 #       $outi .= $leadsp . "\n";
        return $outi;
    }

    # hope its a string
    return $refthing;

}

sub fakeYMLin
{
    my $ymlstr = shift;
#    local $/;
#    undef $/;

#    my $ymlstr = <>;

#    print $ymlstr, "\n";

    my @bigarr = split(/\n/, $ymlstr);

#    print Data::Dumper->Dump(\@bigarr);

    if (scalar(@bigarr) &&
        ($bigarr[0] =~ m/^\#/))
    {
        shift @bigarr;
    }

    my $refthing = _fakeYML_in1(\@bigarr);
    return $refthing;
}

sub _fakeYML_in1
{
    my ($bigarr, $nest) = @_;

    $nest = 0
        unless (defined($nest));

    my $refthing;

    while (1)
    {
        last
            unless scalar(@{$bigarr});

        my $lin1 = shift @{$bigarr};

        unless (defined($refthing))
        {
            my $a_idx = index($lin1, '- ' );
            my $h_idx = index($lin1, ': ' );

#            print $a_idx, " ", $h_idx, " \n";

            # should only match if neither...
            return undef
                if ($a_idx == $h_idx);

            if (($a_idx >= 0) && ($h_idx >= 0))
            {
                if ($a_idx > $h_idx)
                {
                    $refthing = {};
                }
                else
                {
                    $refthing = [];
                }
            }
            elsif ($a_idx >= 0) 
            {
                $refthing = [];
            }
            elsif ($h_idx >= 0)
            {
                $refthing = {};
            }
            else
            {
                return undef
            }

        }

#        print Data::Dumper->Dump([$refthing]), "\n";

        my $len1 = length($lin1);
        $lin1 =~ s/^\s+//; # trim leading spaces
#        print "mismatch\n"
#            unless (($len1 - length($lin1)) == (2 * $nest));

        my @foo;
        if (ref($refthing) eq 'HASH')
        {
            @foo = split(/: /, $lin1, 2);
            last 
                unless (scalar(@foo) > 1);
            my $vv = $foo[1];
            $vv =~ s/^\s+//;  # trim leading spaces
            if (length($vv))
            {
                $refthing->{$foo[0]} = $vv;
            }
            else
            {
                last 
                    unless (scalar(@{$bigarr}));
                
                # get next line
                my $lin2 = $bigarr->[0]; 
                $len1 = length($lin2);
                $lin2 =~ s/^\s+//; # trim leading spaces
                if (($len1 - length($lin2) == 2 * $nest))
                {
                    if (length($lin2))
                    {
                        # if have a key, then this key is undefined
                        $refthing->{$foo[0]} = undef;
                    }
                    else
                    {
                        # if just a blank line, then must be an empty hash
                        shift @{$bigarr};
                        $refthing->{$foo[0]} = {};
                    }
                }
                else
                {
                    $refthing->{$foo[0]} = _fakeYML_in1($bigarr, $nest + 1);
                }
            }
        }
        else
        {
            @foo = split(/- /, $lin1, 2);
            last 
                unless (scalar(@foo) > 1);
            my $vv = $foo[1];
            $vv =~ s/^\s+//;  # trim leading spaces
            if (length($vv))
            {
                push @{$refthing}, $vv;
            }
            else
            {
                last 
                    unless (scalar(@{$bigarr}));
                
                # get next line
                my $lin2 = $bigarr->[0]; 
                $len1 = length($lin2);
                $lin2 =~ s/^\s+//; # trim leading spaces
                if (($len1 - length($lin2)) == (2 * $nest))
                {
                    if (length($lin2))
                    {
                        # if have a key, then this key is undefined
                        push @{$refthing}, undef;
                    }
                    else
                    {
                        # if just a blank line, then must be an empty hash
                        shift @{$bigarr};
                        push @{$refthing}, {};
                    }
                }
                else
                {
                    push @{$refthing}, _fakeYML_in1($bigarr, $nest + 1);
                }
            }

        }

#        print Data::Dumper->Dump(\@foo), "\n";
        


    } # end while    


#    print Data::Dumper->Dump([$refthing]), "\n";
    return $refthing;

}

sub MakeYML
{
#name:         THIS_PACKAGE
#version:      HAVOK_VERSION
#updated:      TODAY
#requires:
#    Genezzo::GenDBI:    0.0
#
#tabledefs:
#    havok:    hid=n modname=c owner=c creationdate=c flag=c version=c regdate=c
#
#dml:
#    -         i havok 1 Genezzo::Havok SYSTEM TODAY 0 HAVOK_VERSION 
#
#license: gpl
#abstract: 
#author: Jeffrey I Cohen (jcohen@cpan.org)

    my $makedp = shift;
    $makedp = $MAKEDEPS
        unless (defined($makedp));

    my $bigYML = "# havok version=$VERSION\n"; 

    $makedp->{'UPDATED'}  = Genezzo::Dict::time_iso8601();

    $bigYML .= fakeYMLout($makedp);
    
#    print $bigYML;

    return $bigYML;
}

# XXX XXX: Note: This method and the associated SQL script are
# deprecated, since all the work is done in HavokUse
sub MakeSQL
{
    my $bigSQL; 
    ($bigSQL = <<EOF_SQL) =~ s/^\#//gm;
#REM Copyright (c) 2004-2007 Jeffrey I Cohen.  All rights reserved.
#REM
#REM 
#select HavokUse('Genezzo::Havok') from dual;
#
#REM HAVOK_EXAMPLE
#REM select * from tab1 where Genezzo::Havok::Examples::isRedGreen(col1);
#REM note that UserExtend usage is deprecated, please use UserFunctions
#select HavokUse('Genezzo::Havok::UserExtend') from dual;
#i user_extend 1 require Genezzo::Havok::Examples isRedGreen SYSTEM TODAY 0
#REM moved soundex to Genezzo::Havok::SQLScalar
#REM i user_extend 2 require Text::Soundex soundex SYSTEM TODAY 0
#
#
#
#commit
#shutdown
#startup
EOF_SQL
    my $now = Genezzo::Dict::time_iso8601();
    $bigSQL =~ s/TODAY/$now/gm;
    $bigSQL =~ s/HAVOK_VERSION/$VERSION/gm;
    $bigSQL = "REM Generated by " . __PACKAGE__ . " version " .
        $VERSION . " on $now\nREM\n" . $bigSQL;

#    print $bigSQL;

#REM select * from tab1 where isBlueYellow(col1)
#i user_extend 3 function isBlueYellow '{return undef unless scalar(@_);   return ($_[0] =~ m/^(blue|yellow)$/i); }' SYSTEM TODAY

    return $bigSQL;
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

#    whoami (%args);

    return 0
        unless (Validate(\%args, \%required));

    my $dict   = $args{dict};
    my $phase  = $args{phase};

    return 1
        unless ($dict->DictTableExists(tname => "havok",
                                       silent_notexists => 1));

    my $hashi  = $dict->DictTableGetTable (tname => "havok") ;

    return 1 # no havok table
        unless (defined ($hashi));

    my $tv = tied(%{$hashi});

    while ( my ($kk, $vv) = each ( %{$hashi}))
    {
        my $getcol  = $dict->_get_col_hash("havok");  
        my $hid     = $vv->[$getcol->{hid}];
        my $modname = $vv->[$getcol->{modname}];
        my $owner   = $vv->[$getcol->{owner}];
        my $dat     = $vv->[$getcol->{creationdate}];
        my $flag    = $vv->[$getcol->{flag}];
        my $verzion = $vv->[$getcol->{version}];

#        greet $vv;

        # check if have right version of this package
        if ($modname eq "Genezzo::Havok")
        {
            unless ($VERSION eq $verzion)
            {
                # XXX XXX: do something
                my $msg = "$modname version mismatch - " .
                    "current version $VERSION " . 
                    "!= $verzion in database table";

                my %earg = (#self => $self,
                            severity => 'warn',
                            msg => $msg);

                &$GZERR(%earg)
                    if (defined($GZERR));
            }
            next;
        }

        unless (eval "require $modname")
        {
            my %earg = (#self => $self,
                        severity => 'warn',
                        msg => "no such package - $modname - for row $hid");

            &$GZERR(%earg)
                if (defined($GZERR));

            next;
        }

        # check if package has GZERR function, and redefine it to use
        # our version (since our version might get redefined to point
        # to parent routine).

        my $gz_err_var = $modname . "::GZERR";
        my $use_gzerr;

        my $s1 = "\$use_gzerr = defined(\$$gz_err_var);";
        eval "$s1";
        greet $s1, $use_gzerr;
        if ($use_gzerr)
        {
            greet "has gzerr!";
            eval "\$$gz_err_var = \$GZERR; "; 
        }

        my %nargs;
        $nargs{dict} = $dict;
        $nargs{flag} = $flag;
        $nargs{version} = $verzion;

        my @stat;
        if ($phase =~ m/^(init|cleanup)$/i)
        {
            my $p2   = ucfirst($phase);
            my $func = $modname . "::" . "Havok" . $p2;
            no strict 'refs' ;
            eval {@stat = &$func(%nargs) };
            if ($@)
            {
                my %earg = (#self => $self,
                            severity => 'warn',
                            msg => "$@\n" .
                            "bad " . lc($phase) . " : $modname");

                &$GZERR(%earg)
                    if (defined($GZERR));
            }
            unless ($stat[0])
            {
                my %earg = (#self => $self,
                            severity => 'warn',
                            msg => "bad return status : $func");

                &$GZERR(%earg)
                    if (defined($GZERR));
            }
        }
        else
        {
            my %earg = (#self => $self,
                        severity => 'warn',
                        msg => "unknown phase - $phase");

            &$GZERR(%earg)
                if (defined($GZERR));
        }

    } # end while

    return 1;
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

Genezzo::Havok - Cry Havok! And Let Slip the Dogs of War!

=head1 SYNOPSIS

use Genezzo::Havok; # Wreak Havok

# in sql
select HavokUse('Genezzo::Havok') from dual;

create table havok (
    hid          number,
    modname      char,
    owner        char,
    creationdate char, 
    flag         char,
    version      char,
    regdate      char
);


=over 4

=item  hid - a unique id number

=item  modname - a havok module name

=item  owner - module owner

=item  creationdate - date of module creation

=item  flag - (user-defined)

=item  version - module version information

=item  regdate - registration date (date of row creation)

=back

=head1 DESCRIPTION

After database startup, the Havok subsystem runs arbitrary
code to modify your Genezzo installation.  

=head2 WHY?

Havok lets you construct novel, sophisticated extensions to Genezzo as
"plug-ins".  The basic Genezzo database kernel can remain small, and
users can download and install additional packages to extend Genezzo's
functionality.  This system also gives you a modular upgrade capability.

=head2 Examples

See L<Genezzo::Havok::UserExtend>, a module that lets users install
custom functions or entire packages.  The Havok regression test,
B<t/Havok1.t>, loads L<Text::Soundex> and demonstrates a soundex
comparison of strings in a table.  You can easily add other string or
mathematical functions.


=head1 ARGUMENTS

=head1 FUNCTIONS

=over 4

=item  HavokInit
Calls the HavokInit for every module in the havok table, supplying a
hash of the dictionary, the flag, and the module version.  The clients
should return an array where the first element is a success code (0 or 1)
and the second is the updated flag (if necessary).

=item  HavokCleanup

=item  HavokUse, MakeYML

Havok modules which have a .yml metadata document can be loaded using
the sql HavokUse function, which (eventually) calls
Genezzo::Havok::HavokUse.  Modules should create a dependency hash
similar to Genezzo::Havok::MAKEDEPS (which is itself similar to the
MakeMaker META.yml) and use Genezzo::Havok::MakeYML to create the
document.  Currently, MakeYML is fake YAML.


=back

=head2 EXPORT

=over 4


=back


=head1 LIMITATIONS

Havok is intended for specialized packages which extend the
fundamental database mechanisms.  If you only want to add new SQL
functions, then you should use L<Genezzo::Havok::UserFunctions>.

Havok is actually spelled "havoc", but I am ignorent.

=head1 TODO

=over 4

=item  extension to support CPAN install via HavokUse

=item  use real YAML vs "fake" yaml documents

=item  Create dictionary initialization havok (vs post-startup havok)

=item  Need some type of first-time registration function.  For
example, if your extension module needs to install new dictionary
tables.  Probably can add arg to havokinit, and add a flag to havok
table to track init status.

=item  Safety/Security: could load modules using Safe package to
restrict their access (not a perfect solution).  May also want to
construct a dictionary wrapper to restrict dictionary capabilities for
certain clients, e.g. let a package read, but not update, certain
dictionary tables.

=item  Force Init/ReInit when new package is loaded.

=item  update module flags if necessary, handle cleanup

=item  use something like L<Sub::Install>, L<Sub::Installer>, or 
L<Hook::WrapSub> to redefine the subroutines in SysHook, etc.

=back

=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

L<perl(1)>.

Copyright (c) 2003-2007 Jeffrey I Cohen.  All rights reserved.

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
