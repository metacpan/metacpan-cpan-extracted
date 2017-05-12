use 5.008;
use strict;
use warnings;

package Error::Hierarchy::Internal::AbstractMethod;
BEGIN {
  $Error::Hierarchy::Internal::AbstractMethod::VERSION = '1.103530';
}
# ABSTRACT: Exception for unimplemented methods
use parent qw(Error::Hierarchy::Internal Class::Accessor);
__PACKAGE__->mk_accessors(qw(method));
use constant default_message => 'called abstract method [%s]';
use constant PROPERTIES      => ('method');

sub init {
    my $self = shift;

    # because we call SUPER::init(), which uses caller() to set
    # package, filename and line of the exception, *plus* we don't want
    # to report the abstract method that threw this exception itself,
    # rather we want to report its caller, i.e. the one that called the
    # abstract method. So we use +2.
    local $Error::Depth = $Error::Depth + 2;
    $self->method((caller($Error::Depth))[3]) unless defined $self->method;
    $self->SUPER::init(@_);
}
1;


__END__
=pod

=head1 NAME

Error::Hierarchy::Internal::AbstractMethod - Exception for unimplemented methods

=head1 VERSION

version 1.103530

=head1 SYNOPSIS

  # the following all do the same:

  sub not_there_yet {
      Error::Hierarchy::Internal::AbstractMethod->throw;
  }

  # or:

  sub not_there_yet_either {
      Error::Hierarchy::Internal::AbstractMethod->
          throw(method => 'not_there_yet_either');
  }

  # or:

  use base 'Class::Accessor::Complex';
  __PACKAGE__->mk_abstract_accessors(qw(not_there_yet));

=head1 DESCRIPTION

This class implements an exception that is meant to be thrown when an
unimplemented method is called.

=head1 METHODS

=head2 method

Name of the unimplemented method. If it is not given, then the name of the
method that has thrown this exception is taken from the call stack.

=head2 init

Initializes a newly constructed exception object.

=head1 PROPERTIES

This exception class inherits all properties of L<Error::Hierarchy::Internal>.

Additionally it defines the C<method> property.

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

