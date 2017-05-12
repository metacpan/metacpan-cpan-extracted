# Grips::Gripsrc.pm
#
# Copyright (c) 2002 DIMDI <tarek.ahmed@dimdi.de>. All rights reserved.
#
# This module is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself, i.e. under the terms of either the GNU General
# Public License or the Artistic License, as specified in the F<LICENCE> file.
package Grips::Gripsrc;

use Carp;
use strict;
use FileHandle;
use vars qw($VERSION);

$VERSION = "0.01"; # $Id: Gripsrc.pm,v 1.2 2003-02-04 12:19:08 ahmed Exp $

my %gripsrc = ();

sub _readrc
{
 my $host = shift;
 my($home,$file);

 if($^O eq "MacOS") {
   $home = $ENV{HOME} || `pwd`;
   chomp($home);
   $file = ($home =~ /:$/ ? $home . "gripsrc" : $home . ":gripsrc");
 } else {
   # Some OS's don't have `getpwuid', so we default to $ENV{HOME}
   $home = eval { (getpwuid($>))[7] } || $ENV{HOME};
   $file = $home . "/.gripsrc";
 }

 my $fh;
 local $_;

 $gripsrc{default} = undef;

 # OS/2 and Win32 do not handle stat in a way compatable with this check :-(
 unless($^O eq 'os2'
     || $^O eq 'MSWin32'
     || $^O eq 'MacOS'
     || $^O =~ /^cygwin/)
  { 
   my @stat = stat($file);

   if(@stat)
    {
     if($stat[2] & 077)
      {
       carp "Bad permissions: $file";
       return;
      }
     if($stat[4] != $<)
      {
       carp "Not owner: $file";
       return;
      }
    }
  }

 if($fh = FileHandle->new($file,"r"))
  {
   my($mach,$macdef,$tok,@tok) = (0,0);

   while(<$fh>)
    {
     undef $macdef if /\A\n\Z/;

     if($macdef)
      {
       push(@$macdef,$_);
       next;
      }

     s/^\s*//;
     chomp;
     push(@tok, $+)
       while(length && s/^("([^"]*)"|(\S+))\s*//);

TOKEN:
     while(@tok)
      {
       if($tok[0] eq "default")
        {
         shift(@tok);
         $mach = bless {};
   	 $gripsrc{default} = [$mach];

         next TOKEN;
        }

       last TOKEN
            unless @tok > 1;

       $tok = shift(@tok);

       if($tok eq "host")
        {
         my $host = shift @tok;
         $mach = bless {host => $host};

         $gripsrc{$host} = []
            unless exists($gripsrc{$host});
         push(@{$gripsrc{$host}}, $mach);
        }
       elsif($tok =~ /^(id|user|pwd)$/)
        {
         next TOKEN unless $mach;
         my $value = shift @tok;
         # Following line added by rmerrell to remove '/' escape char in .gripsrc
         $value =~ s/\/\\/\\/g;
         $mach->{$1} = $value;
        }
       elsif($tok eq "macdef")
        {
         next TOKEN unless $mach;
         my $value = shift @tok;
         $mach->{macdef} = {}
            unless exists $mach->{macdef};
         $macdef = $mach->{machdef}{$value} = [];
        }
      }
    }
   $fh->close();
  }
}

sub lookup
{
 my($pkg,$mach,$id) = @_;

 _readrc()
    unless exists $gripsrc{default};

 $mach ||= 'default';
 undef $id
    if $mach eq 'default';

 if(exists $gripsrc{$mach})
  {
   if(defined $id)
    {
     my $m;
     foreach $m (@{$gripsrc{$mach}})
      {
       return $m
            if(exists $m->{id} && $m->{id} eq $id);
      }
     return undef;
    }
   return $gripsrc{$mach}->[0]
  }

 return $gripsrc{default}->[0]
    if defined $gripsrc{default};

 return undef;
}

sub id
{
 my $me = shift;

 exists $me->{id}
    ? $me->{id}
    : undef;
}

sub pwd
{
 my $me = shift;

 exists $me->{pwd}
    ? $me->{pwd}
    : undef;
}

sub user
{
 my $me = shift;

 exists $me->{user}
    ? $me->{user}
    : undef;
}

sub iup
{
 my $me = shift;
 ($me->id, $me->user, $me->pwd);
}

1;

__END__

=head1 NAME

Grips::Gripsrc - OO interface to users gripsrc file

=head1 SYNOPSIS

    use Grips::Gripsrc;

    $mach = Grips::Gripsrc->lookup('some.host');
    $id = $mach->id;
    ($id, $user, $pwd) = $mach->iup;

=head1 DESCRIPTION

C<Grips::Gripsrc> is a class implementing a simple interface to the .gripsrc file
used as by the ftp program.

C<Grips::Gripsrc> also implements security checks just like the ftp program,
these checks are, first that the .gripsrc file must be owned by the id and 
second the ownership permissions should be such that only the owner has
read and write access. If these conditions are not met then a warning is
output and the .gripsrc file is not read.

=head1 THE .gripsrc FILE

The .gripsrc file contains id and initialization information used by the
auto-login process.  It resides in the user's home directory.  The following
tokens are recognized; they may be separated by spaces, tabs, or new-lines:

=over 4

=item host name

Identify a remote host name. The auto-login process searches
the .gripsrc file for a host token that matches the remote host
specified.  Once a match is made, the subsequent .gripsrc tokens
are processed, stopping when the end of file is reached or an-
other host or a default token is encountered.

=item default

This is the same as host name except that default matches
any name.  There can be only one default token, and it must be
after all host tokens.  This is normally used as:

    default id anonymous user id@site

thereby giving the user automatic anonymous login to hosts
not specified in .gripsrc.

=item id name

Identify a id on the remote host.  If this token is present,
the auto-login process will initiate a login using the
specified name.

=item user string

Supply a password.  If this token is present, the auto-login
process will supply the specified string if the remote server
requires a password as part of the login process.

=item pwd string

Supply an additional password.  If this token is present,
the auto-login process will supply the specified string
if the remote server requires an additional password.

=item macdef name

Define a macro. C<Grips::Gripsrc> only parses this field to be compatible
with I<ftp>.

=back

=head1 CONSTRUCTOR

The constructor for a C<Grips::Gripsrc> object is not called new as it does not
really create a new object. But instead is called C<lookup> as this is
essentially what it does.

=over 4

=item lookup ( HOST [, ID ])

Lookup and return a reference to the entry for C<HOST>. If C<ID> is given
then the entry returned will have the given login. If C<ID> is not given then
the first entry in the .gripsrc file for C<HOST> will be returned.

If a matching entry cannot be found, and a default entry exists, then a
reference to the default entry is returned.

=back

=head1 METHODS

=over 4

=item id ()

Return the id for the gripsrc entry

=item user ()

Return the user code for the gripsrc entry

=item pwd ()

Return the pwd information for the gripsrc entry

=item iup ()

Return a list of id, user and pwd information fir the gripsrc entry

=back

=head1 AUTHOR

Tarek Ahmed <ahmed@dimdi.de>

=head1 SEE ALSO

L<Grips::Gripsrc>
L<Grips::Cmd>

=head1 COPYRIGHT

Copyright (c) 2002 DIMDI. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
	
Confession: I took most of the stuff of Net::Netrc and converted it to 
this module. Thanks, Graham Barr :-)

=for html <hr>

$Id: Gripsrc.pm,v 1.2 2003-02-04 12:19:08 ahmed Exp $

=cut
