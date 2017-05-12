# Test::Weaken::ExtraBits -- some helpers for Test::Weaken

# Copyright 2008, 2009, 2010 Kevin Ryde

# Test::Weaken::ExtraBits is shared by several distributions.
#
# Test::Weaken::ExtraBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Test::Weaken::ExtraBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.


package Test::Weaken::ExtraBits;
use 5.006;
use strict;
use warnings;

use Exporter;
our @ISA = ('Exporter');
our @EXPORT_OK = qw(ignore_Class_Singleton
                    ignore_DBI_dr
                    ignore_global_function
                    ignore_function
                    ignore_module_functions
                    findrefs);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

use constant DEBUG => 0;

# Return all the slots out of a globref.
sub contents_glob {
  my ($ref) = @_;
  if (ref $ref eq 'GLOB') {
    return map {*$ref{$_}} qw(SCALAR ARRAY HASH CODE IO GLOB FORMAT);
  } else {
    return;
  }
}

# Return the IO slot of a globref.
sub contents_glob_IO {
  my ($ref) = @_;
  ref($ref) eq 'GLOB' || return;
  return  *$ref{IO};
}

sub ignore_Class_Singleton {
  my ($ref) = @_;
  my $class;
  require Scalar::Util;
  return (($class = Scalar::Util::blessed($ref))
          && $ref->isa('Class::Singleton')
          && $class->has_instance
          && $class->instance == $ref);
}

sub ignore_DBI_globals {
  my ($ref) = @_;
  require Scalar::Util;

  if (Scalar::Util::blessed($ref)
      && $ref->isa('DBI::dr')) {
    if (DEBUG) { Test::More::diag ("ignore DBI::dr object -- $ref\n"); }
    return 1;
  }

  return 0;
}

#   require Sub::Identify;
#   my $fullname = Sub::Identify::sub_fullname ($ref);
#   return (defined &$fullname
#           && $ref == \&$fullname);

# =item C<$bool = Test::Weaken::ExtraBits::ignore_global_function ($ref)>
# 
# Return true if C<$ref> is a coderef to a global function like C<sub foo {}>.
#
# A global is identified by the coderef having a name, and the current
# function under that name equal to this coderef.  Plain functions created
# as C<sub foo {}> etc work, but redefinitions or function-creating modules
# like C<Memoize> or C<constant> generally don't.
#
# For reference, the name in a coderef is basically just a string from its
# original creation.  C<Memoize> and similar end up with anonymous
# functions, and C<constant> only ends up with a name under the scalar in
# symtab optimization.
#
sub ignore_global_function {
  my ($ref) = @_;
  ref $ref eq 'CODE' or return;

  # could use Sub::Identify, but B comes with perl already
  require B;
  my $cv = B::svref_2object($ref);
  my $gv = $cv->GV;
  # as per Sub::Identify, for some sort of undefined GV
  return if $gv->isa('B::SPECIAL');

  my $fullname = $gv->STASH->NAME . '::' . $gv->NAME;
  # Test::More::diag "ignore_global_function() fullname $fullname";

  return (defined &$fullname && $ref == \&$fullname);
}

# =item C<$bool = ignore_function ($ref, $funcname, $funcname, ...)>
#
# Return true if C<$ref> is a coderef to any of the given named functions.
#
# Each C<$funcname> is a fully-qualified string like C<Foo::Bar::somefunc>.
# If a function doesn't exist then it's skipped, so it doesn't matter if the
# C<Foo::Bar> package is actually loaded yet, etc.
#
sub ignore_function {
  my $ref = shift;
  ref $ref eq 'CODE' or return;

  while (@_) {
    my $funcname = shift;
    if (defined &$funcname && $ref == \&$funcname) {
      return 1;
    }
  }
  return 0;
}

# =item C<$bool = ignore_module_functions ($ref, $module, $module, ...)>
#
# Return true if C<$ref> is a coderef to any function in any of the given
# modules.
#
# Each C<$module> is a string like C<My::Module>.  If a module doesn't exist
# then it's skipped, so it doesn't matter if the C<My::Module> package is
# actually loaded yet.
#
sub ignore_module_functions {
  my $ref = shift;
  ref $ref eq 'CODE' or return;

  while (@_) {
    my $module = shift;
    my $symtabname = "${module}::";
    no strict 'refs';
    %$symtabname or next;
    foreach my $name (keys %$symtabname) {
      my $fullname = "${module}::$name";
      if (defined &$fullname && $ref == \&$fullname) {
        return 1;
      }
    }
  }
  return 0;
}

1;
__END__

=head1 NAME

Test::Weaken::ExtraBits -- various helpers for Test::Weaken

=head1 SYNOPSIS

 use Test::Weaken::ExtraBits;

=head1 EXPORTS

Nothing is exported by default, but the functions can be requested
individually or with C<:all> in the usual way (see L<Exporter>).

    use Test::Weaken::ExtraBits qw(ignore_Class_Singleton);

=head1 FUNCTIONS

=head2 Ignores

=over 4

=item C<< $bool = Test::Weaken::ExtraBits::ignore_Class_Singleton ($ref) >>

Return true if C<$ref> is the singleton instance of a class using
C<Class::Singleton>.

The current implementation of this function requires C<Class::Singleton>
version 1.04 for its C<has_instance> method.

=item C<< $bool = Test::Weaken::ExtraBits::ignore_DBI_globals ($ref) >>

Return true if C<$ref> is one of the various C<DBI> module global objects.

Currently this means any C<DBI::dr> driver object, one each of which is
created permanently for each driver loaded, and which C<DBI::db> handles
then refer to.

A bug/misfeature of Perl through to at least 5.10.1 on lvalue C<substr>
means certain scratchpad temporaries of DBI "ImplementorClass" strings end
up held alive after C<DBI::db> and C<DBI::st> objects have finished with
them.  These aren't recognised by C<ignore_DBI_globals> currently.
A workaround is to do a dummy C<DBI::db> creation to flush out the old
scratchpad.

=back

=head1 SEE ALSO

L<Test::Weaken>

=cut
