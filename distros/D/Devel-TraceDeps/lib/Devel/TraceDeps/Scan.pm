package Devel::TraceDeps::Scan;
$VERSION = v0.0.3;

use warnings;
use strict;
use Carp;


use Class::Accessor::Classy;
with 'new';
no  Class::Accessor::Classy;

=head1 NAME

Devel::TraceDeps::Scan - frontend and data access

=head1 SYNOPSIS

  my $scan = Devel::TraceDeps::Scan->load($filehandle);

=cut

=head1 Acquisition


=head2 scan

  my $scan = Devel::TraceDeps::Scan->scan(file => $filename, %opts);

=cut

sub scan {
  my $me = shift;
  my (%opts) = @_;

  my @cmd;
  if(my $file = $opts{file}) {
    @cmd = ($file);
  }
  elsif(my $code = $opts{code}) {
    @cmd = ('-e' => $code);
  }
  else {
    croak("must have something (code|file) to scan");
  }

  # bah IPC::Cmd gives me invalid free or something
  open(my $fh, '-|', $^X, '-MDevel::TraceDeps', @cmd) or
    croak("cannot run @cmd $!");

  my $self = $me->load($fh);
  return($self);
} # end subroutine scan definition
########################################################################

=head1 Retrieval

=head2 load

C<$source> may be a filename, or a reference to an open filehandle or
string.

  my $scan = Devel::TraceDeps::Scan->load($source);

=cut

sub load {
  my $package = shift;
  my ($source) = @_;

  my $self = ref($package) ? $package : $package->new;

  my $fh;
  if(my $r = ref($source)) {
    if($r eq 'GLOB' or
      $source =~ m/=GLOB\(0x[0-9a-f]+\)$/ or
      eval {overload::Method($source, '<>')}
    ) {
      $fh = $source;
    }
    else {
      open($fh, '<', $source) or die "open string failed $!";
    }
  }
  else {
    open($fh, '<', $source) or die "open file '$source' failed $!";
  }

  $self->{order} ||= [];
  $self->{store} ||= {};

  my $pack;
  my $current;
  while(my $line = <$fh>) {
    chomp($line);
    my ($mod, $rest) = split(/  /, $line, 2);
    #warn "$mod|$rest\n";
    if(length($mod)) {
      push(@{$self->{order}}, $mod) unless($self->{store}{$mod});
      $current = '';
      $pack = $mod;
    }
    else {
      if($rest eq '-----') {
        $current = Devel::TraceDeps::Scan::Item->new(by => $pack);
        push(@{$self->{store}{$pack}}, $current);
        next;
      }
      my ($key, $val) = split(/: /, $rest, 2);
      # pretend every .pm was loaded with the :: form
      $val =~ s#/+#::#g if($key eq 'req' and $val =~ s/\.pm$//);
      $current or croak("out-of-sequence in $pack");
      $current->{$key} = $val;
    }
  }
  return($self);
} # end subroutine load definition
########################################################################

=head1 Querying the Data

=head2 callers

The list of all packages which called use(), require(), or do().

  my @callers = $scan->callers;

=cut

sub callers {
  my $self = shift;
  return(@{$self->{order}});
} # end subroutine callers definition
########################################################################

=head2 items

Return all of the use/require/do events.

  my @items = $scan->items;

=cut

sub items {
  my $self = shift;
  return(map({@{$self->{store}{$_}}} $self->callers));
} # end subroutine items definition
########################################################################

=head2 items_for

Return all of the use/require/do events for a given package.

  my @items_for = $scan->items_for($caller);

=cut

sub items_for {
  my $self = shift;
  my ($pack) = @_;

  my $array = $self->{store}{$pack} or return();
  return(@$array);
} # end subroutine items_for definition
########################################################################

=head2 required

A unique list of use/require/do items.

  my @required = $scan->required;

=cut

sub required {
  my $self = shift;

  my @out;
  my %seen;
  foreach my $item ($self->items) {
    my $key = $item->req || $item->did;
    $seen{$key} and next;
    $seen{$key} = 1;
    push(@out, $item);
  }
  return(@out);
} # end subroutine required definition
########################################################################

=head2 loaded

Everything from required() which did not fail to load.

  my @loaded = $scan->loaded;

=cut

sub loaded {
  my $self = shift;
  return(grep({not $_->fail} $self->required));
} # end subroutine loaded definition
########################################################################


=head1 Item objects

C<Devel::TraceDeps::Scan::Item> objects are returned by several of the
above methods.  The have the following attributes:

=over

=item by

The package which required this item (caller).

=item trace

A string of sequence numbers indicating the tree of this call.

=item file

Filename from caller().

=item line

Line number from caller().

=item req

The require()d module filename (as found in C<keys %INC> -- e.g.  'use
Foo::Bar' would appear as 'Foo/Bar.pm'.)

This will typically be a relative path (within @INC), but might be
absolute or ever relative to './' (depending on how use/require/do was
called.

=item ver

Item is a requirement for a minimum perl version.  If 'req' is empty,
look here.

=item did

The argument to do("filename").

=item fail

True if the require() failed.  This probably means that the file does
not exist (e.g. C<eval {require thing}> or C<do("whatever")>)

=item err

Any $@ or $! found.

=back

=cut

{
package Devel::TraceDeps::Scan::Item;
use Class::Accessor::Classy;
with 'new';
ro qw(
  by
  trace
  req
  ver
  did
  file
  line
  fail
  err
);
no  Class::Accessor::Classy;
}

=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2008 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
