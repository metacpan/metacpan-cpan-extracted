#!/usr/bin/perl
# Base.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

# see POD after __END__

package File::Attributes::Base;
use strict;
use warnings;
use Carp;

sub new {
    my $class = shift;
    my $self = \my $foo;
    bless $self, $class;
    return $self;
}

sub priority {
    my $self = shift;
    return 0;
}

sub applicable {
    my $self     = shift;
    my $filename = shift;
    return 0;
} 

1;
__END__

=head1 NAME

File::Attributes::Base - Base class for File::Attributes

=head1 SYNOPSIS

Currently, this class works like a pragma.  If something inherits from
it, File::Attributes will assume it is trying to implement some sort of
file attribute accessor.

   package File::Attributes::MyAccessMethod;
   use base 'File::Attributes::Base';

   sub priority { 5 }

   sub applicable {
     my $self = shift;
     my $file = shift;
     eval {
       $self->list($file);
     }
     return 1 if !$@;
     return 0;
   }

   sub list {
     my $self = shift;
     ...
   }
   ...
   1;

=head1 METHODS

=head2 new

Creates an instance.  You probably don't need to override this in your
subclass.

=head2 priority

Called to determine the order in which various subclasses should be
used to get or set an attribute.  Classes will be called from highest
priority to lowest priority until an attribute is successfully
accessed.  The priority returned should be an integer between 0 and
10.  1 is reserved for access methods that will work on any system,
like L<File::Attributes::Simple|File::Attributes::Simple>.  10 should
be used for plugins that will work for any file on any filesystem for
a specific OS.  5 should be used for plugins that may or may not work,
like UNIX extended filesystem attributes on UNIX-like systems; see
L<File::Attributes::Extended|File::Attributes::Extended>.

A priority of 0 indicates that the module should not be used at all.

=head2 applicable($filename)

Called to determine if this attribute access method works with
C<$filename>.  Some systems have syscalls for attribute access that
may be called on any file, but will fail if the "use attributes"
option isn't set on that file's filesystem.  In this case,
C<applicable> can return false so that an alternate access method is
tried.

This method will return true (1) if the class can access attributes for C<$filename> and false (0) otherwise.

=head1 METHODS THAT SUBCLASSES SHOULD IMPLEMENT

... but aren't required to, because C<< $instance->can('method') >> will tell
whoever's using the module that you're not implementing that method.

=head2 get($file, $attribute)

Return the value of $attribute on C<$file>.  Throw an exception if
something bad happens, like C<$file> doesn't exist, or the filesystem
doesn't support your type of attribute.

=head2 set($file, $key, $value)

Set the attribute C<$key> to C<$value> on C<$file>.  Again, if
something bad happpens, C<croak>; don't return undef!

=head2 unset($file, $attribute)

Unset the attribute called C<$attribute>.  You probably shouldn't
throw an exception if C<$attribute> is already undefined, but if it
makes sense in your context, feel free to.

=head2 list($file)

Return a list of all attributes that C<$file> has.

=head2 applicable

Override this so you can return true, otherwise your module will be
useless.

=head1 AUTHOR

Jonathan Rockway C<< <jrockway@cpan.org> >>.

=head1 BUGS

Report to RT; see L<File::Attributes/BUGS>.
