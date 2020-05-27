package JSON::Karabiner::Manipulator::Conditions::Keyboard_type_if ;
$JSON::Karabiner::Manipulator::Conditions::Keyboard_type_if::VERSION = '0.018';
use strict;
use warnings;
use JSON;
use Carp;
use parent 'JSON::Karabiner::Manipulator::Conditions';

sub new {
  my $class = shift;
  my ($type, $value) = @_;
  my $obj = $class->SUPER::new($type, $value);
  $obj->{data} = $value || {},
  return $obj;
}

sub add_keyboard_types {
  my $s = shift;
  my @values = @_;
  croak 'A list of keyboard types is required' unless @values;
  $s->{data}{keyboard_types} =  \@values ;
}

sub add_description {
  my $s = shift;
  my $desc = shift;
  croak ('No description passed.') unless $desc;
  $s->{data}{description} = $desc;

}

sub TO_JSON {
  my $obj = shift;
  my $name = $obj->{def_name};
  my $value = $obj->{data};
  my %super_hash = (%$value, type => $name);
  return { %super_hash };

}
#ABSTRACT: definition for keyboard_type_if condition

1;

__END__

=pod

=head1 NAME

JSON::Karabiner::Manipulator::Conditions::Keyboard_type_if - definition for keyboard_type_if condition

=head1 SYNOPSIS

  use JSON::Karabiner;

=head1 DESCRIPTION

=head3 method1()

=head3 method2()

=head1 VERSION

version 0.018

=head1 AUTHOR

Steve Dondley <s@dondley.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Steve Dondley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
