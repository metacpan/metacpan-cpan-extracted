use 5.008;
use strict;
use warnings;

package Error::Hierarchy::Internal;
BEGIN {
  $Error::Hierarchy::Internal::VERSION = '1.103530';
}
# ABSTRACT: Base class for internal exceptions

use parent 'Error::Hierarchy';
use constant PROPERTIES => (qw/package filename line/);
sub is_optional { 0 }

sub stringify {
    my $self = shift;
    my $message =
      "Exception: package [%s], filename [%s], line [%s]: " . $self->message;
    sprintf $message => map { defined($self->$_) ? $self->$_ : 'unknown' }
      $self->get_properties;
}
1;


__END__
=pod

=head1 NAME

Error::Hierarchy::Internal - Base class for internal exceptions

=head1 VERSION

version 1.103530

=head1 DESCRIPTION

This class implements the base class for internal exceptions. All internal
exceptions should subclass it. However, you probably shouldn't throw an
exception of this class; rather use
L<Error::Hierarchy::Internal::CustomMessage>.

This class is important so applications can define their own internal
exceptions (opposed to business exceptions) and just catch objects of this
class where appropriate.

=head1 METHODS

=head2 is_optional

Returns 0, so this exception is not optional.

=head2 stringify

Defines how an exception should look like if it is used in a string: The same
as L<Error::Hierarchy>, but it prepends the package, filename and line the
exception occurred in to the given message.

=head1 PROPERTIES

This exception class inherits all properties of L<Error::Hierarchy>.

It has no additional properties.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Error-Hierarchy>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Error-Hierarchy/>.

The development version lives at L<http://github.com/hanekomu/Error-Hierarchy>
and may be cloned from L<git://github.com/hanekomu/Error-Hierarchy>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHOR

Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

