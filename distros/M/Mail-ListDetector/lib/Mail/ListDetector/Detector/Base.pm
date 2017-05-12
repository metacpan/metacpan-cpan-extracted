package Mail::ListDetector::Detector::Base;

use strict;
use warnings;

sub new {
  my $proto = shift;
  my $data = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  $self->{'data'} = $data;

  bless ($self, $class);
  return $self;
}

sub match {
  die "This method must be implemented by a subclass\n";
}

1;

__END__

=head1 NAME

Mail::ListDetector::Detector::Base - base class for mailing list detectors

=head1 SYNOPSIS

  use Mail::ListDetector::Detector::Base;

=head1 DESCRIPTION

Abstract base class for mailing list detectors, should not be
instantiated directly.

=head1 METHODS

=head2 new()

Provides a simple constructor for the class. Accepts an optional data
argument and stores that argument in the object if it is supplied.

=head2 match()

This just dies, and should be implemented in any subclass.

=head1 BUGS

No known bugs.

=head1 AUTHOR

Michael Stevens - michael@etla.org.

