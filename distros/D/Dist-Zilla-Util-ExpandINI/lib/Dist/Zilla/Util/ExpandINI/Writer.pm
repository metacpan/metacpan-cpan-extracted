use 5.006;
use strict;
use warnings;

package Dist::Zilla::Util::ExpandINI::Writer;

our $VERSION = '0.003003';

# ABSTRACT: An order-preserving INI Writer

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Config::INI::Writer 0.024;
use parent 'Config::INI::Writer';
use Carp qw(croak);





sub is_valid_section_name {
  my ( undef, $name ) = @_;
  return $name !~ m{
    (?:    # Dont capture
      \n   # Newlines may not occur in a section name
      |
      \s;  # Comments may not occur in a section name
      |
      ^\s  # Leading whitespace is illegal in a section name
      |
      \s$  # Trailing whitespace is illegal in a section name
    )
  }msx;
}

sub preprocess_input {
  my ( undef, $input_data ) = @_;
  my @out;
  my $i = 0;
  for my $ini_record ( @{$input_data} ) {
    $i++;
    if ( $ini_record->{name} and '_' eq $ini_record->{name} ) {
      push @out, '_', $ini_record;
      next;
    }
    if ( not $ini_record->{package} ) {
      croak("Entry $i lacks package component");
    }
    my $kn = $ini_record->{package};
    if ( $ini_record->{name} and $ini_record->{package} ne $ini_record->{name} ) {
      $kn .= q[ / ] . $ini_record->{name};
    }
    push @out, $kn, $ini_record;
    next;
  }
  return \@out;
}

sub validate_input {
  my ( $self, $input ) = @_;

  my %seen;

  my @input_copy = @{$input};

  while (@input_copy) {
    my ( $name, $ini_record ) = splice @input_copy, 0, 2;

    if ( $seen{$name}++ ) {
      Carp::croak "multiple declarations found of $name";
    }

    Carp::croak "illegal section name '$name'"
      if not $self->is_valid_section_name($name);

    my @props_copy = @{ $ini_record->{lines} };

    while (@props_copy) {
      my ( $property, $value ) = splice @props_copy, 0, 2;

      Carp::croak "property name '$property' contains illegal character"
        if not $self->is_valid_property_name($property);

      Carp::croak "value for $name.$property contains illegal character"
        if defined $value and not $self->is_valid_value($value);

    }
  }
  return;
}

sub stringify_section_data {
  my ( $self, $ini_record ) = @_;
  my $output = q[];
  $output .= q[;] . $_ . qq[\n] for @{ $ini_record->{comment_lines} };
  $output .= $self->SUPER::stringify_section_data( $ini_record->{lines} );
  return $output;
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::ExpandINI::Writer - An order-preserving INI Writer

=head1 VERSION

version 0.003003

=for Pod::Coverage is_valid_section_name

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
