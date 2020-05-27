package JSON::Karabiner::Manipulator::Conditions::Frontmost_application_if ;
$JSON::Karabiner::Manipulator::Conditions::Frontmost_application_if::VERSION = '0.018';
use strict;
use warnings;
use JSON;
use Carp;
use parent 'JSON::Karabiner::Manipulator::Conditions';

sub new {
  my $class = shift;
  my ($type, $value) = @_;
  my $obj = $class->SUPER::new($type, $value);
  $obj->{data} = $value || [],
  return $obj;
}

sub add_bundle_identifiers {
  my $s = shift;
  my @identifiers = @_;
  croak ('No identifier regular expressions passed.') unless @identifiers;
  push @{$s->{data}}, { bundle_identifiers => [ @identifiers ] };

}

sub add_file_paths {
  my $s = shift;
  my @files = @_;
  croak ('No file path regular expressions passed.') unless @files;
  push @{$s->{data}}, { file_paths => [ @files ] };

}

sub add_description {
  my $s = shift;
  my $desc = shift;
  croak ('No file path regular expressions passed.') unless $desc;
  push @{$s->{data}}, { description => $desc };

}
# ABSTRACT: definition for Frontmost_application_if condition

1;

__END__

=pod

=head1 NAME

JSON::Karabiner::Manipulator::Conditions::Frontmost_application_if - definition for Frontmost_application_if condition

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
