package Env::ShellWords;

use strict;
use warnings;
use Text::ParseWords qw( shellwords );

# ABSTRACT: Environment variables for arguments as array
our $VERSION = '0.01'; # VERSION


sub TIEARRAY
{
  my($class, $name) = @_;
  bless \$name, $class;
}

sub FETCH
{
  my($self, $key) = @_;
  my @list = shellwords($ENV{$$self});
  $list[$key];
}

sub _render
{
  my($self, @list) = @_;
  $ENV{$$self} = join ' ', map {
    my $value = $_;
    $value = '' unless defined $value;
    $value =~ s/(\s)/\\$1/g;
    $value eq '' ? "''" : $value;
  } @list;
}

sub STORE
{
  my($self, $key, $value) = @_;
  my @list = shellwords($ENV{$$self});
  $list[$key] = $value;
  _render($self, @list);
  $value;
}

sub FETCHSIZE
{
  my($self) = @_;
  my @list = shellwords($ENV{$$self});
  $#list + 1;
}

sub STORESIZE
{
  my($self, $count) = @_;
  my @list = shellwords($ENV{$$self});
  $#list = $count - 1;
  _render($self, @list);
  return;
}

sub CLEAR
{
  my($self) = @_;
  _render($self);
  return;
}

sub PUSH
{
  my($self, @values) = @_;
  _render($self, shellwords($ENV{$$self}), @values);
  return;
}

sub POP
{
  my($self) = @_;
  my @list = shellwords($ENV{$$self});
  my $value = pop @list;
  _render($self, @list);
  return $value;
}

sub SHIFT
{
  my($self) = @_;
  my($value, @list) = shellwords($ENV{$$self});
  _render($self, @list);
  return $value;
}

sub UNSHIFT
{
  my($self, @values) = @_;
  _render($self, @values, shellwords($ENV{$$self}));
  return;
}

sub SPLICE
{
  my($self, $offset, $length, @values) = @_;
  my @list = shellwords($ENV{$$self});
  my @ret = splice @list, $offset, $length, @values;
  _render($self, @list);
  @ret;
}

sub DELETE
{
  my($self, $key) = @_;
  my @list = shellwords($ENV{$$self});
  my $value = delete $list[$key];
  _render($self, @list);
  return $value;
}

sub EXISTS
{
  my($self, $key) = @_;
  my @list = shellwords($ENV{$$self});
  return exists $list[$key];
}

sub EXTEND {} # do nothing!

sub import
{
  my $caller = caller;
  my(undef, @vars) = @_;
  foreach my $var (@vars)
  {
    if($var =~ s/^\@//)
    {
      no strict 'refs';
      tie my @list, __PACKAGE__, $var;
      *{"${caller}::${var}"} = \@list;
    }
    else
    {
      require Carp;
      Carp::croak("Env::ShellWords does not work with $var");
    }
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Env::ShellWords - Environment variables for arguments as array

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 # Tie Interface
 use Env::ShellWords;
 tie my @CFLAGS,   'CFLAGS';
 tie my @LDFLAGS,  'LDFLAGS';

 # same thing with import interface:
 use Env::ShellWords qw( @CFLAGS @LDFLAGS );
 
 # usage:
 $ENV{CFLAGS} = '-DBAR=1';
 unshift @CFLAGS, '-I/foo/include';
 push @CFLAGS, '-DFOO=Define With Spaces';
 
 # now:
 # $ENV{CFLAGS} = '-I/foo/include -DBAR=1 -DFOO=Define\\ With\\ Spaces';
 
 unshift @LDFLAGS, '-L/foo/lib';
 push @LDFLAGS, '-lfoo';

=head1 DESCRIPTION

This module provides an array like interface to environment variables
that contain flags.  For example Autoconf can uses the environment
variables like C<CFLAGS> or C<LDFLAGS>, and this allows you to manipulate
those variables without doing space quoting and other messy mucky stuff.

The intent is to use this from L<alienfile> to deal with hierarchical
prerequisites.

=head1 CAVEATS

Not especially fast.  C<undef> gets mapped to the empty string C<''>
since C<undef> doesn't have a meaning as an argument in a string.

=head1 SEE ALSO

L<Env>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
