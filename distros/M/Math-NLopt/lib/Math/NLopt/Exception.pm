package Math::NLopt::Exception;

# ABSTRACT: Basic Exception Classes

use v5.12;
use strict;
use warnings;

#<<<

our $VERSION = '0.11';

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



{
    package Math::NLopt::Exception::Failure;
    use parent -norequire => 'Math::NLopt::Exception';
}

{
    package Math::NLopt::Exception::OutOfMemory;
    use parent -norequire => 'Math::NLopt::Exception';
}

{
    package Math::NLopt::Exception::InvalidArgs;
    use parent -norequire => 'Math::NLopt::Exception';
}

{
    package Math::NLopt::Exception::RoundoffLimited;
    use parent -norequire => 'Math::NLopt::Exception';
}

{
    package Math::NLopt::Exception::ForcedStop;
    use parent -norequire => 'Math::NLopt::Exception';
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

version 0.11

=head1 SYNOPSIS

  use Math::NLopt::Exception;

  croak( Math::NLopt::Exception::Failure->new( "error messsage" ) );

=head1 DESCRIPTION

This is a very simple exception class used by L<Math::NLopt>. Importing
this module also imports the

  Math::NLopt::Exception::Failure
  Math::NLopt::Exception::OutOfMemory
  Math::NLopt::Exception::InvalidArgs
  Math::NLopt::Exception::RoundoffLimited>
  Math::NLopt::Exception::ForcedStop

subclasses.

=head1 CLASS METHODS

=head2 new

  $object = Math::NLopt::Exception->new( $message );

Construct an object containing the following method

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

  https://gitlab.com/djerius/math-nlopt

and may be cloned from

  https://gitlab.com/djerius/math-nlopt.git

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
