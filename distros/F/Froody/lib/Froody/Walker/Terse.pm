package Froody::Walker::Terse;
use base 'Froody::Walker::Driver';
use strict;
use warnings;

use Encode qw(encode);

use Froody::Logger;

my $logger = get_logger('froody.walker.terse');

=head1 NAME

Froody::Walker::Terse - read and write Terse data.

=head1 SYNOPSIS

=head1 DESCRIPTION

Turn what Implementation class returns into the structure
L<Froody::Response> expects.

=over

=cut

=item text_only_spec( path )

returns true if the spec at this location specifies that there
is _only_ text content in this node.

=back

=cut

sub text_only_spec {
  my ($self, $path) = @_;
  my $spec = $self->spec_for_xpath($path);
  return 1 unless $spec;
  warn "No spec for $path" unless $spec;
  return 0 if (@{$spec->{elts}} || @{$spec->{attr}});
  return 1;
}



sub init_source {
  my ($self, $source) = @_;
  return $source;
}

sub init_target {
  my ($self, $path, $parent) = @_;
  my $target = {};
  # the target should have listref slots where we're expecting lists,
  # in case no elements get added to those lists later.
  if (my $spec = $self->spec_for_xpath($path)) {
    for (@{ $spec->{elts} }) {
      # initialize an empty list if we're expecting a list at all
      my $elt_spec = $self->spec_for_xpath( $path ."/". $_ );
      next unless $elt_spec;
      $target->{$_} = [] if $elt_spec->{multi};
    }
  }
  return $target;
}

sub validate_source {
  my ($self, $source, $path) = @_;
  
  #use Carp; Carp::cluck;
  
  my $spec = $self->spec_for_xpath($path);
  my $method = $self->walker->method || '<unknown>';
  
  if (!ref $source) {
    $logger->warn("Returned unexpected text at '$path' for structure '$method'.")
      unless $spec->{text};
    return 1;
  }
  
  my %keys = map { $_ => 1 } keys %$source;
  
  foreach (@{ $spec->{attr} } , @{$spec->{elts}}) {
    delete $keys{$_};
  }
  delete $keys{-text} if $spec->{text};
  
  for (keys %keys) {
    $logger->warn("unknown key '$_' defined within a terse structure at '$path' for structure '$method'.");
  }
  return !keys %keys;
}

sub read_attribute {
  my ($self, $source, $path, $attr) = @_;
  return ref($source) ? $source->{$attr} : undef;
}

sub read_text {
  my ($self, $source, $xpath_key) = @_;
  return ref $source ? $source->{-text} : $source;
}

sub child_sources {
  my ($self, $source, $xpath, $element) = @_;
    
  my $stuff = $source->{$element};
  $stuff = [] unless defined $stuff;
  
  return @{ $stuff } if ref $stuff eq 'ARRAY';
  return ( $stuff );
}

sub write_attribute {
  my ($self, $target, $path, $attr, $value) = @_;
  $target->{$attr} = $value;
  return $target;
}

sub write_text {
  my ($self, $target, $path, $value) = @_;
  if ($self->text_only_spec($path)) {
    return $value;
  } else {
    $target->{-text} = $value;
    return $target;
  }
}


sub add_child_to_target {
  my ($self, $target, $xpath, $element, $child) = @_;
  if (ref ($target->{$element}) eq 'ARRAY') {
    push @{ $target->{$element} }, $child;
  } else {
    $target->{$element} = $child;
  }
  return $target;
}

=head1 BUGS

None known.

Please report any bugs you find via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Froody>

=head1 AUTHOR

Copyright Fotango 2005.  All rights reserved.

Please see the main L<Froody> documentation for details of who has worked
on this project.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Froody>, L<Froody::Walker>

=cut

1;
