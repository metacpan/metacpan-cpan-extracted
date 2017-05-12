#!/usr/bin/perl -w

#    Detect::Module - allows autodetection of Perl modules.
#    Copyright (C) 2001  Rudolf Polzer
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Library General Public
#    License as published by the Free Software Foundation; either
#    version 2 of the License, or (at your option) any later version.
#
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Library General Public License for more details.
#
#    You should have received a copy of the GNU Library General Public
#    License along with this library; if not, write to the Free
#    Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

package Detect::Module;

use strict;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
require Exporter;
@ISA = qw(Exporter);
@EXPORT = ();
@EXPORT_OK = qw(Use Require NewRef Load);
%EXPORT_TAGS = (standard => [@EXPORT_OK]);
$VERSION = '1.2';

my $DEBUG = 0;

sub Debug ($)
{
 $DEBUG = $_[0] ? 1 : 0;
}

my %FAIL;

sub Reset
{
 %FAIL = ();
}

sub Use (@)
{
 for (@_)
 {
  if (exists $FAIL{$_})
  {
   print STDERR "Not trying $_ any more\n"
    if $DEBUG;
   next;
  }
  print STDERR "Trying $_\n"
   if $DEBUG;
  if (/[^A-Za-z0-9\_\:\.]/)
  {
   print STDERR "$_ rejected - invalid characters\n"
    if $DEBUG;
   next;
  }
  my $s = $_;
  return $_
   if eval "require $_;";
  $FAIL{$s} = 1;
  print STDERR "$@\n"
   if $DEBUG;
 }
 die "No module of @{[join ', ', @_]} could be found\n";
}

sub Require (@)
{
 goto &Use;
}

sub NewRef (@)
{
 my $constructor = Use @_;
 return sub (@)
 {
  return eval ('new ' . $constructor . ' @_');
 }
}

sub Load (@)
{
 my $name = Use @_;
 $name or                                                  # new in 1.2
  return undef;
 return bless sub ($$)
 {
  no strict 'refs';
  my $n = "${name}::$_[1]";
  if ($_[0] eq 'CODECHECK')                            # changed in 1.2
  {
   eval
   q{
    require 5.6.1;
    return undef unless exists &$n;
    1;
   }
   or do
   {
    return undef unless exists "${name}::"->{$_[1]};
    # not perfect, but works with pre-5.6.1 versions.
   }
  }
  return \&$n if $_[0] eq 'CODE' || $_[0] eq 'CODECHECK';
  return \%$n if $_[0] eq 'HASH';
  return \@$n if $_[0] eq 'ARRAY';
  return \*$n if $_[0] eq 'GLOB' || $_[0] eq 'HANDLE';
  return \$$n if $_[0] eq 'SCALAR';
  die 'Valid type arguments to Detect::Module::Load()-> are SCALAR,GLOB,HANDLE,ARRAY,HASH,CODE,CODECHECK';
 }, 'Detect::Module::Internal';
}

package Detect::Module::Internal;

use strict;
use vars qw($AUTOLOAD);

sub AUTOLOAD (@)
{
 my @l = caller (1);
 my $o = shift;
 my $f;
 die "Undefined subroutine $AUTOLOAD called from $l[1] at line $l[2].\n"
  unless ref ($o) eq __PACKAGE__
     and $AUTOLOAD =~ /^@{[__PACKAGE__]}::(.*)$/
     and $f = $o->('CODECHECK', $1, 1);
 goto &$f;
}

1;

__END__

=head1 NAME

B<Detect::Module> - allows to autodetect Perl modules

=head1 SYNOPSIS

    use Detect::Module qw(:standard);

    my $which = Use 'DB_File', 'SDBM_File';
    # $which now contains the name of the loaded module
    # This is specially useful because the modules have
    # a compatible tie() syntax

    my $constructor = NewRef 'IO::Socket::COOL', 'IO::Socket::INET';
    my $o = $constructor->(PeerAddr => 'localhost:25');
    # $o now contains an object of one of the both modules
    
    my $esc = Load 'URI::Escape';
    $esc->uri_escape (' ') eq '%20';
    ${$esc->('SCALAR', 'x')} = 3;

=head1 DESCRIPTION

This module is used for autodetection of Perl modules. The functions
in this module accept a list of module names, from which the first
one that can be loaded using require() is used.

=head1 USAGE

You may include most functions using the export tag
':standard' like shown in the synopsis. Otherwise you call them like
Detect::Module::Use(). Only Debug() and Reset() cannot be exported.

=over 4

=item B<Use @ModuleList>, B<Require @ModuleList>

These work like require() except they are executed at run time and all
modules in @ModuleList are tried until an existing module is found.
If no such module exists, these subs die(). The modules in the list
are tried from left to right. Module names have to contain B<::> as path
separator. Of course the @INC path is used to find the modules
(the built-in require() is used to load the modules).

There is no difference between Use() and Require(). To achieve
compile-time execution, enclose the Use() call in a BEGIN block.

The return value is the name of the module that has been loaded.

Once loading a module has failed, it is never tried again. So using these
subs multiple times does not result in performance impacts (Perl checks
if a module is already loaded). But you should use this to access multiple
functions of this package:

    # Load the module
    my $mod = Use (...);
    # I need the object:
    my $obj = Load $mod;
    # This does not have performance impacts because $mod is already
    # loaded and Perl checks %INC!

You can circumvent this behaviour by calling Detect::Module::Reset which
clears the %FAIL-Cache.

There is a trick to catch cases where a module is _not_ found:

    # Try loading
    unless (my $mod = Use (..., 0))
    {
     print "Module not found\n";
     print "Using workaround instead...\n";
    }

This relies upon the fact that a B<require 0> always succeeds. But this works
B<only> with Use(), Require() and Load()!

=item B<NewRef @ModuleList>

This one works exactly like Use() except that a reference to the
constructor (or better: to a sub that calls the module's constructor)
is returned. The returned sub reference calls B<new Module::Name @_>,
where Module::Name is the name of the module loaded.

=item B<Load @ModuleList>

This one returns a blessed object with the following capabilities:

=over 4

=item *

B<$o-E<gt>(SCALAR =E<gt> 'x')> returns a reference to $x of the module.

=item *

B<$o-E<gt>(ARRAY =E<gt> 'x')> returns a reference to @x of the module.

=item *

B<$o-E<gt>(HASH =E<gt> 'x')> returns a reference to %x of the module.

=item *

B<$o-E<gt>(CODE =E<gt> 'x')> returns a reference to &x of the module.

=item *

B<$o-E<gt>(CODECHECK =E<gt> 'x')> returns a reference to &x of the module,
or B<undef> if &x does not exist.

=item *

B<$o-E<gt>(GLOB =E<gt> 'x')> returns a reference to *x of the module. HANDLE
is a synonym to GLOB.

=item *

B<$o-E<gt>m(@args)> calls the function m() of the module with @args.

=back

B<CHANGED> since Detect::Module version 1.2: Load() now returns undef if
no module was found and '0' was a possible name.

=item B<Debug $Flag>

Debugging output is switched on when $Flag is true. Debugging output is
printed on STDERR and consists of lines like:

=over 4

=item *
B<'Trying Module::Name'>

=item *
B<'x; `rm -rf /` rejected - invalid characters'>

=item *
B<the $@ contents after a failed require()>

=back

=item B<Reset>

Clears the hash %FAIL which contained all failed require() attempts. This may
be useful when using mod_perl in Apache.

=back

=head1 AUTHOR

Written by Rudolf Polzer, Germany (rpolzer@durchnull.de).

=head1 KNOWN BUGS

=over 4

=item *

Load() uses symbolic references (therefore I use no strict 'subs').
Doing the same with eval() leads to more obfuscated code.

=item *

The sub returned by Load() return references instead of tied variables.
This makes accessing package variables harder, but not impossible.

=item *

You cannot directly call AUTOLOAD() using the object returned by Load().
Use B<$o-E<gt>(CODE =E<gt> 'AUTOLOAD')-E<gt>(@args)> instead.

=item *

When calling an undefined sub using the object returned by Load(), you can
get error messages without line numbers and package names (so you do not know
where the error occured). This only happens when you call the undefined sub
from the main program, not from a sub.

=back

=head1 REPORTING BUGS or FIXING THE ONES ABOVE

Report bugs to me (rpolzer@durchnull.de).

=head1 COPYRIGHT

(c) 2001 Rudolf Polzer. This is free software, copying and modifications
are allowed as long as this copyright notice remains. There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE.

=head1 SEE ALSO

perlfunc(1) for use(), require() and do()

=cut
