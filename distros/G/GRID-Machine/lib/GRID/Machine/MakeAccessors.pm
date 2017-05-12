package GRID::Machine::MakeAccessors;
use strict;
use warnings;

=head1 NAME 

GRID::Machine::MakeAccessors - Home Made "Make accessors" for a Class

=head1 METHODS

=head2 sub make_accessors

   GRID::Machine::MakeAccessors::make_accessors($package, @legalattributes)

Builds getter-setters for each attribute

=head2 sub make_constructor

   GRID::Machine::MakeAccessors::make_constructor($package, %legalattributes)
   
=cut

sub make_accessors { # Install getter-setters 
  my $package = caller;

  no strict 'refs';
  for my $sub (@_) {
    *{$package."::$sub"} = sub {
      my $self = shift;

      $self->{$sub} = shift() if @_;
      return $self->{$sub};
    };
  }
}

sub make_constructor { # Install constructor
  my $package = caller;
  my %legal = @_;

  no strict 'refs';
  *{$package."::new"} = sub {
      my $class = shift || die "Error: Provide a class\n";
      my %args = (%legal, @_);

      my $a = "";
      die "Illegal arg  $a\n" if $a = first { !exists $legal{$_} } keys(%args);

      bless \%args, $class;
  };
}

1;
