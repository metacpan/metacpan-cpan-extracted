#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Havok/RCS/UserFunctions.pm,v 1.5 2006/12/03 09:47:47 claude Exp claude $
#
# copyright (c) 2004, 2005, 2006 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::Havok::UserFunctions;
use Genezzo::Util;

use strict;
use warnings;
use warnings::register;

use Carp;

our $VERSION;
our $MAKEDEPS;

BEGIN {
    $VERSION = do { my @r = (q$Revision: 1.5 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

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
    };

    # DML is an array, not a hash

#    my $now = Genezzo::Dict::time_iso8601()
    my $now = 
    do { my @r = (q$Date: 2006/12/03 09:47:47 $ =~ m|Date:(\s+)(\d+)/(\d+)/(\d+)(\s+)(\d+):(\d+):(\d+)|); sprintf ("%04d-%02d-%02dT%02d:%02d:%02d", $r[1],$r[2],$r[3],$r[5],$r[6],$r[7]); };

    my $dml =
        [
         "i havok 2 $pak1 SYSTEM $now 0 $VERSION"
         ];

    my %tabdefs = 
        ('user_functions' =>  {
            create_table =>  
                'xid=n xtype=c xname=c args=c owner=c creationdate=c version=c argstyle=c sqlname=c typecheck=c',           
                dml => $dml
            }
         );
    $MAKEDEPS->{'TABLEDEFS'} = \%tabdefs;

    $MAKEDEPS->{'DML'} = [
                          { check => [],
                            install => [] }
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

sub LoadFunction
{
    my %optional;

    my %required = (
                    xid          => "no xid!",
                    xtype        => "no xtype!",
                    xname        => "no xname!",
                    owner        => "no owner!",
                    creationdate => "no creationdate!",
                    args         => "no args!"
                    );

    my %args = (%optional,
                @_);

    return 0
        unless (Validate(\%args, \%required));

    my $xid    = $args{xid};
    my $xtype  = $args{xtype};
    my $xname  = $args{xname};
    my $owner  = $args{owner};
    my $dat    = $args{creationdate};
    my $xargs  = $args{args};

    if ($xtype =~ m/^require$/i)
    {
        unless (eval "require $xname")
        {
            my %earg = (#self => $self,
                        msg => "no such package - $xname - for table user_functions, row $xid");
            
            &$GZERR(%earg)
                if (defined($GZERR));
            
            return 0;
        }
        
        # check if package has GZERR function, and redefine it to use
        # our version (since our version might get redefined to point
        # to parent routine).
        
        my $gz_err_var = $xname . "::GZERR";
        my $use_gzerr;
        
        my $s1 = "\$use_gzerr = defined(\$$gz_err_var);";
        eval "$s1";
        greet $s1, $use_gzerr;
        
        no strict 'refs';
        no warnings 'redefine';
        
        my @inargs;
        
        if ($xargs =~ m/\s/)
        {
            @inargs = split(/\s/, $xargs);
        }
        else
        {
            push @inargs, $xargs;
        }
        
        
        for my $fname (@inargs)
        {
            # Note: add functions to "main" namespace...
            
            my $mainf = "Genezzo::GenDBI::" . $fname;
            my $packf =  $xname . "::" . $fname;
            
            my $func = "sub " . $mainf ;
            $func .= "{ " ;
            
            if ($use_gzerr)
            {
                greet "has gzerr!";
                $func .= "local \$$gz_err_var = \$Genezzo::Havok::UserFunctions::GZERR; "; 
                greet $func;
            }
            
            $func .= $packf . '(@_); }';
            
#            whisper $func;
            
#            eval {$func } ;
            eval " $func " ;
            if ($@)
            {
                my %earg = (#self => $self,
                            msg => "$@\nbad function : $func");
                
                &$GZERR(%earg)
                    if (defined($GZERR));
            }
            
        }
        
        
    }
    elsif ($xtype =~ m/^function$/i)
    {
        my $doublecolon = "::";
        
        unless ($xname =~ m/$doublecolon/)
        {
            # Note: add functions to "main" namespace...
            
            $xname = "Genezzo::GenDBI::" . $xname;
        }
        
        my $func = "sub " . $xname . " " . $xargs;
        
#            whisper $func;
        
#            eval {$func } ;
        eval " $func " ;
        if ($@)
        {
            my %earg = (#self => $self,
                        msg => "$@\nbad function : $func");
            
            &$GZERR(%earg)
                if (defined($GZERR));
        }
    }
    else
    {
        my %earg = (#self => $self,
                    msg => "unknown user extension - $xtype");
        
        &$GZERR(%earg)
            if (defined($GZERR));
    }
    
    return 1;

} # end LoadFunction

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
        unless ($dict->DictTableExists(tname => "user_functions",
                                       silent_notexists => 1));

    my $hashi  = $dict->DictTableGetTable (tname => "user_functions") ;

    return @stat # no User Extensions
        unless (defined ($hashi));

    my $tv = tied(%{$hashi});

    while ( my ($kk, $vv) = each ( %{$hashi}))
    {
        my $getcol = $dict->_get_col_hash("user_functions");  
        my $xid    = $vv->[$getcol->{xid}];
        my $xtype  = $vv->[$getcol->{xtype}];
        my $xname  = $vv->[$getcol->{xname}];
        my $owner  = $vv->[$getcol->{owner}];
        my $dat    = $vv->[$getcol->{creationdate}];
        my $xargs  = $vv->[$getcol->{args}];

        my $lv = LoadFunction(
                              xid => $xid,
                              xtype => $xtype,
                              xname => $xname,
                              owner => $owner,
                              creationdate => $dat,
                              args => $xargs
                              );

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

Genezzo::Havok::UserFunctions - load the user_functions table

=head1 SYNOPSIS

 # don't say "use Genezzo::Havok::UserFunctions".  Update the
 # dictionary havok table:

select HavokUse('Genezzo::Havok::UserFunctions') from dual;


=head1 DESCRIPTION

NOTE: this module replaces L<Genezzo::Havok::UserExtend>.

The module L<Genezzo::XEval::Prepare> constructs a function call
interface based upon information from the user_functions table:

create table user_functions (
    xid   number,
    xtype char,
    xname char,
    args  char,
    owner char, 
    creationdate char,
    version char,
    argstyle char,
    sqlname char,
    typecheck char
    );

=over 4

=item xid - a unique id number
  

=item  xtype - the string "require" or "function"


=item xname - if xtype = "require", then xname is a package name, like
"Text::Soundex".  if xtype = "function", xname is a function name.  A
function name may be qualified with a package.


=item args - if xtype = "require", an (optional) blank-separated list
of functions to import to the default Genezzo namespace.  if xtype =
"function", supply an actual function body in curly braces.

=item owner - owner of the package or function

=item creationdate - date row was created

=item version

=item argstyle - if set to HASH, pass a hash of the dictionary, the
dbh, and the array ref function_args, else the function is just passed
an array of the function arguments.

=item sqlname - currently UNUSED.  Will be used to distinguish the
perl function name from the SQL function name

=item typecheck - currently UNUSED.  Will be used to distinguish a
supplied type-checking function from a purely SQL execution function.

=back

=head2 Example:

insert into user_functions values (1, 'require', 'Genezzo::Havok::Examples',  
'isRedGreen', 'SYSTEM', '2004-09-21T12:12');

The row causes UserFunctions to "require Genezzo::Havok::Examples", and
it imports "isRedGreen" into the default Genezzo namespace* (actually,
it creates a stub function that calls
Genezzo::Havok::Examples::isRedGreen").

An easier method is to use add_user_function, which is defined in
L<Genezzo::Havok::Utils>.  The equivalent command to load the
isRedGreen function is:

  select 
    add_user_function(
      'module=Genezzo::Havok::Examples',
      'function=isRedGreen')
  from dual;

=head1 ARGUMENTS

=head1 FUNCTIONS

=head2 EXPORT

=over 4


=back


=head1 LIMITATIONS

=head1 TODO

=over 4

=item use "sqlname" and "typecheck" attributes in user_functions table

=item Need to fix "import" mechanism so can load specific functions
into Genezzo::GenDBI namespace, versus creating stub functions.
Use "import" and "export_to_level".

=item Could just load Acme::Everything and we'd be done...

=item Need function "type" information so can validate argument lists,
determine return type of function.  If pass named args, have
"TypeCheck" and "Execute" modes for sql_function.  Or have typecheck
function pass back name/ref to execute function, since it may change
depending on argument types.

=back

=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

L<perl(1)>.

Copyright (c) 2004, 2005, 2006 Jeffrey I Cohen.  All rights reserved.

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
