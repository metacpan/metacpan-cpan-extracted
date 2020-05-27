package JSON::Karabiner::Manipulator::Conditions::Event_changed_if ;
$JSON::Karabiner::Manipulator::Conditions::Event_changed_if::VERSION = '0.018';
use strict;
use warnings;
use JSON;
use Carp;
use parent 'JSON::Karabiner::Manipulator::Conditions::Variable_if';

sub new {
  my $class = shift;
  my ($type, $value) = @_;
  my $obj = $class->SUPER::new($type, $value);
  $obj->{data} = $value || {},
  return $obj;
}

sub add_value {
  my $s = shift;
  my $value = shift;
  $value = $value eq 'true' ? JSON::true : JSON::false;
  croak 'A value for the varaible name is required' unless $value;
  #TODO: Validates args
  $s->{data}{value} = $value;

}

# ABSTRACT: definition for event_changed_if condition

1;

__END__

=pod

=head1 NAME

JSON::Karabiner::Manipulator::Conditions::Event_changed_if - definition for event_changed_if condition

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
