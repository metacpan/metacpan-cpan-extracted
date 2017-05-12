use 5.008;
use strict;
use warnings;

package Error::Hierarchy::Internal::CustomMessage;
BEGIN {
  $Error::Hierarchy::Internal::CustomMessage::VERSION = '1.103530';
}
# ABSTRACT: Custom internal exception
use parent 'Error::Hierarchy::Internal';
__PACKAGE__->mk_accessors(qw(custom_message));
use constant default_message => '%s';
use constant PROPERTIES      => ('custom_message');
1;


__END__
=pod

=head1 NAME

Error::Hierarchy::Internal::CustomMessage - Custom internal exception

=head1 VERSION

version 1.103530

=head1 SYNOPSIS

  Error::Hierarchy::Internal::CustomMessage->throw(custom_message => '...');

=head1 DESCRIPTION

This class implements an exception that can be thrown whenever you want to
indicate that an internal error has occurred but there is no specific
exception for it.

=head1 METHODS

=head2 custom_message

The string that is used when the exception object is stringified.

=head1 PROPERTIES

This exception class inherits all properties of L<Error::Hierarchy::Internal>.

Additionally it defines the C<custom_message> property.

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

