# Declare our package
package Games::AssaultCube::Log::Line::StartupText;

# import the Moose stuff
use Moose;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

extends 'Games::AssaultCube::Log::Line::Base';

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__
=head1 NAME

Games::AssaultCube::Log::Line::StartupText - Describes the StartupText event in a log line

=head1 ABSTRACT

Describes the StartupText event in a log line

=head1 DESCRIPTION

This module holds the "StartupText" event data from a log line. Normally, you would not use this class directly
but via the L<Games::AssaultCube::Log::Line> class.

This line is emitted when the AC server starts up and includes a variety of lines.

=head2 Attributes

Those attributes hold information about the event. As this class extends the L<Games::AssaultCube::Log::Line::Base>
class, you can also use it's attributes too.

No extra attributes for this event.

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
