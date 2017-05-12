use 5.008;
use strict;
use warnings;

package Error::Hierarchy::Internal::DBI::DBH;
BEGIN {
  $Error::Hierarchy::Internal::DBI::DBH::VERSION = '1.103530';
}
# ABSTRACT: DBI-related exception
use parent 'Error::Hierarchy::Internal::DBI::H';

# DBI exceptions store extra values, but don't use them in the message string.
# They are marked as properties, however, so generic exception handling code
# can introspect them.
__PACKAGE__->mk_accessors(
    qw(
      auto_commit db_name statement row_cache_size
      )
);
use constant PROPERTIES => (qw(auto_commit db_name statement row_cache_size));
1;


__END__
=pod

=head1 NAME

Error::Hierarchy::Internal::DBI::DBH - DBI-related exception

=head1 VERSION

version 1.103530

=head1 DESCRIPTION

This class is part of the DBI-related exceptions. It is internal and you're
not supposed to use it.

=head1 PROPERTIES

This exception class inherits all properties of
L<Error::Hierarchy::Internal::DBI::H>.

It has the following additional properties.

=over 4

=item C<auto_commit>

=item C<db_name>

=item C<statement>

=item C<row_cache_size>

=back

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

