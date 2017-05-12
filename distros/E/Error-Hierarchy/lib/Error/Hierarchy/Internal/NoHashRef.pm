use 5.008;
use strict;
use warnings;

package Error::Hierarchy::Internal::NoHashRef;
BEGIN {
  $Error::Hierarchy::Internal::NoHashRef::VERSION = '1.103530';
}
# ABSTRACT: When you expected a hash reference
use parent 'Error::Hierarchy::Internal::CustomMessage';
1;


__END__
=pod

=head1 NAME

Error::Hierarchy::Internal::NoHashRef - When you expected a hash reference

=head1 VERSION

version 1.103530

=head1 DESCRIPTION

This class implements an exception that is meant to be thrown when you
expected a hash reference but got something else.

=head1 PROPERTIES

This exception class inherits all properties of
L<Error::Hierarchy::Internal::CustomMessage>.

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

