package JSON::Karabiner::Manipulator::Conditions::Variable_if ;
$JSON::Karabiner::Manipulator::Conditions::Variable_if::VERSION = '0.017';
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

sub add_variable {
  my $s = shift;
  my $name = shift;
  my $value = shift;
  croak 'A variable name is required' unless $name;
  croak 'A value for the varaible name is required' unless $value;
  #TODO: Validates keys
  if ($value =~ /^\d+$/) {
    $value = $value + 0;
  }
  $s->{data}{name} = $name;
  $s->{data}{value} = $value;

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
# ABSTRACT: definition for Frontmost_application_if condition

1;

__END__

=pod

=head1 NAME

JSON::Karabiner::Manipulator::Conditions::Variable_if - definition for Frontmost_application_if condition

=head1 SYNOPSIS

  use JSON::Karabiner;

=head1 DESCRIPTION

=head3 method1()

=head3 method2()

=head1 VERSION

version 0.017

=head1 AUTHOR

Steve Dondley <s@dondley.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Steve Dondley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
