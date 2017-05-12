package Decl::Util;

use warnings;
use strict;
use base qw(Exporter);
use vars qw(@EXPORT);

@EXPORT = qw(car cdr popcar splitcar lazyiter escapequote hh_set hh_get);

=head1 NAME

Decl::Util - some utility functions for the declarative framework - automatically included for generated code.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This class is a lightweight set of utilities to make things easier throughout C<Decl>.  I'm not yet sure what will end up here, but my
rule of thumb is that it's extensions I'd like to be able to use in code generators as well.

=head2 Lazy Lispy lists: car(), cdr(), popcar(), splitcar()

I like Higher-Order Perl, really I do - but his head/tail streams are really just car and cdr, so I'm hereby defining car and cdr as lazy-evaluated streams
throughout the language.  Nodes are arrayrefs.  Clean and simple, no object orientation required.

=cut

sub car ($) { return undef unless ref $_[0] eq 'ARRAY'; $_[0]->[0] }
sub cdr ($) {
   my ($s) = @_;
   return undef unless ref $s eq 'ARRAY';
   $s->[1] = $s->[1]->() if ref $s->[1] eq 'CODE';
   $s->[1];
}
sub popcar ($) {
   my $p = car($_[0]);
   $_[0] = cdr($_[0]);
   return $p;
}
sub splitcar ($) { @{$_[0]}; }

=head2 lazyiter($iterator)

Takes any coderef (but especially an L<Iterator::Simple>) and builds a stream out of it.  Invokes the coderef once to get the
first value in the stream.

=cut

sub lazyiter {
   my $i = shift;
   my $value = $i->();
   return unless defined $value;
   [$value, sub { lazyiter ($i); }]
}

=head2 escapequote($string, $quote)

Returns a new string with C<$quote> escaped (by default, '"' is escaped) by means of a backslash.

=cut

sub escapequote {
   my ($string, $quote) = @_;
   $quote = '"' unless $quote;
   $string =~ s/($quote)/\\$1/g;
   $string
}

=head2 Hierarchical values a la CSS: hh_set(hash, name, value), hh_get (hash, name), and prepare_hierarchical_value as a helper

You know how CSS lets you specify something like C<font-size: 8> as well as something more like C<font: {size: 8}>?  These functions give
you something similar using hierarchically nested hashrefs.  They allow you to mix types of addressing:

   hh_set($h, 'border-left', 'my value');
   hh_set($h, 'border', 'right: val1; top: val2');
   
   # { 'border' => {'left'  => 'my value',
   #                'right' => 'val1',
   #                'top'   => 'val2'
   #               }
   # }
   
Clear?  Then you can use C<hh_get> to retrieve 'border' or 'border-left' by digging down into the hashref hierarchy.

Separators for names can be anything in -./

=cut

sub prepare_hierarchical_value {
   my ($hash, $name) = @_;
   $hash->{$name} = {} unless defined $hash->{$name};
   if (not ref $hash->{$name}) {
      my $newhash = {'*' => $hash->{$name}};
      $hash->{$name} = $newhash;
   }
   return $hash->{$name};
}

sub hh_set {
   my ($hash, $name, $value) = @_;

   unless (ref $name) {
      my @s = split /[.\-\/]/, $name;
      $name = \@s;
   }
   
   my ($first, @rest) = @$name;
   if (@rest) {
      hh_set (prepare_hierarchical_value ($hash, $first), \@rest, $value);
   } else {
      if ($value =~ /:/) {
         foreach (split / *; */, $value) {
            hh_set (prepare_hierarchical_value ($hash, $first), split / *: */);
         }
      } elsif (ref $hash->{$first}) {
         $hash->{$first}->{'*'} = $value;
      } else {
         $hash->{$first} = $value;
      }
   }
}

sub hh_get {
   my ($hash, $name) = @_;
   
   unless (ref $name) {
      my @s = split /[.\-\/]/, $name;
      $name = \@s;
   }
   my ($first, @rest) = @$name;
   return $hash->{$first} unless @rest;
   hh_get ($hash->{$first}, \@rest);
}


=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-decl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Decl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Decl::Util
