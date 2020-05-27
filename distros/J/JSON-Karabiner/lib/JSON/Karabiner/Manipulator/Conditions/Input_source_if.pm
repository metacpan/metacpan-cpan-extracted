package JSON::Karabiner::Manipulator::Conditions::Input_source_if ;
$JSON::Karabiner::Manipulator::Conditions::Input_source_if::VERSION = '0.018';
use strict;
use warnings;
use JSON;
use Carp;
use parent 'JSON::Karabiner::Manipulator::Conditions::Device_if';

sub new {
  my $class = shift;
  my ($type, $value) = @_;
  my $obj = $class->SUPER::new($type, $value);
  $obj->{data}{input_sources} = $value || [],
  return $obj;
}

sub add_input_source {
  my $s = shift;
  my @values = @_;
  croak 'A value for the input_source name is required' unless @values;
  my $hash = { @values };
  #TODO: Validates keys
  push @{$s->{data}{input_sources}}, $hash;

}

# ABSTRACT: definition for Frontmost_application_if condition

1;

__END__

=pod

=head1 NAME

JSON::Karabiner::Manipulator::Conditions::Input_source_if - definition for Frontmost_application_if condition

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
