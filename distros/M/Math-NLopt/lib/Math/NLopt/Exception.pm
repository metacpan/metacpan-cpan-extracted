package Math::NLopt::Exception;

# ABSTRACT: Basic Exception Classes

use v5.12;
use strict;
use warnings;

#<<<

our $VERSION = '0.14';

#>>>


use overload
  q{""}    => \&message,
  bool     => sub { 1 },
  fallback => 1;









sub new {
    my $class   = shift;
    my $message = shift;
    return bless \$message, $class;
}










sub message {
    my $self = shift;
    return $$self;
}











sub throw {
    my $class = shift;
    require Carp;
    Carp::croak( $class->new( @_ ) );
}


BEGIN {
    my @Exceptions = qw(
      Failure
      ForcedStop
      ImproperType
      InternalError
      InvalidArgs
      InvalidDimensions
      InvalidReturn
      InvalidUse
      MissingParameter
      OutOfMemory
      RoundoffLimited
    );

    ## no critic (StringyEval)
    eval(
        join( q{},
            ( map { "{ package ${\__PACKAGE__}::$_; our \@ISA = ('${ \__PACKAGE__ }') }" } @Exceptions ),
            '1;' ),
    ) or die( 'internal error' );
}
1;

#
# This file is part of Math-NLopt
#
# This software is Copyright (c) 2024 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Math::NLopt::Exception - Basic Exception Classes

=head1 VERSION

version 0.14

=head1 SYNOPSIS

  use Math::NLopt::Exception;

  Math::NLopt::Exception::Failure->throw( "error messsage" ) );

=head1 DESCRIPTION

This is a very simple exception class used by
L<Math::NLopt>. Importing this module provides the following classes,
which correspond to NLopt failures and user callback errors.

  Math::NLopt::Exception::Failure
  Math::NLopt::Exception::ForcedStop
  Math::NLopt::Exception::ImproperType
  Math::NLopt::Exception::InternalError
  Math::NLopt::Exception::InvalidArgs
  Math::NLopt::Exception::InvalidDimensions
  Math::NLopt::Exception::InvalidReturn
  Math::NLopt::Exception::InvalidUse
  Math::NLopt::Exception::MissingParameter
  Math::NLopt::Exception::OutOfMemory
  Math::NLopt::Exception::RoundoffLimited

=head1 CLASS METHODS

=head2 new

  $object = Math::NLopt::Exception->new( $message );

Construct an object containing the following method

=head2 throw

   $class->throw( ... );

Equivalent to

   croak( $class->new( ...) )

=head1 METHODS

=head2 message

  $message = $object->message

retrieve an object's message

=head1 OVERLOADS

The exception object overloads the stringify operation using the
L</message> method.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-math-nlopt@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Math-NLopt>

=head2 Source

Source is available at

  https://codeberg.org/djerius/p5-Math-NLopt

and may be cloned from

  https://codeberg.org/djerius/p5-Math-NLopt.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Math::NLopt|Math::NLopt>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
