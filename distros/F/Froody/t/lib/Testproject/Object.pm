package Testproject::Object;
use base qw(Froody::Implementation);
sub implements { "Testproject::API" => "testproject.object.*" }

use strict;
use warnings;
use List::Util 'reduce';

sub myget :FroodyMethod(get) {
  return 'myget reached';
}

sub method {
  return {};
}

sub text {

}

sub email { }

sub sum {
  my ($self, $args) = @_;
  return reduce { $a + $b } @{$args->{values}}
}

sub range {
  my ($self, $args) = @_;
  return { value => [$args->{base} - $args->{offset},
         $args->{base} + $args->{offset}
        ] };
}

sub range2 {
  my ($self, $args) = @_;
  return { value => [{ num => $args->{base} - $args->{offset} },
         { num => $args->{base} + $args->{offset} },
        ]};
}

sub extra {
  return { blah => 'bleh' };
}

sub texttest {
  return { next => 100, blah => "foo\nhate\n"};
}

sub params {
  my ($invoker, $args) = @_;
  # do this in 2 steps, because keys %{ undef } doesn't break. Weird.
  # use Data::Dumper; warn Dumper($args);
  my %hash = %{ $args->{the_rest} };
  my $count = scalar keys %hash;
  return $count;
}

sub upload {
  my ($invoker, $args) = @_;
  return -s $args->{file}[0]->filename;
}

1;
