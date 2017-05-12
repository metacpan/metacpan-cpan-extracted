use strict;
use warnings;
package Method::Assert;
BEGIN {
  $Method::Assert::VERSION = '0.0.1';
}

# ABSTRACT: Ensure instance and class methods are called properly

use Scalar::Util qw(blessed);
use Carp qw(confess);

sub import {
    my $package = caller();

    confess("Importing into package 'main' makes no sense") if $package eq 'main';

    my $class_method = sub {
        confess("Method invoked as a function")                       if     @_ == 0;
        confess("Class method invoked as an instance method")         if     blessed( $_[0] );
        confess("Invocant is a reference, not a simple scalar value") if     ref($_[0]);
        confess("Invocant '$_[0]' is not a subclass of '$package'")   unless $_[0]->isa($package);
        return @_    if wantarray;         # list   context
        return shift if defined wantarray; # scalar context
        return;                            # void   context
    };

    my $instance_method = sub {
        confess("Method invoked as a function")                                           if     @_ == 0;
        confess("Method not invoked as an instance method")                               unless blessed( $_[0] );
        confess("Invocant of class '" . ref($_[0]) . "' is not a subclass of '$package'") unless $_[0]->isa($package);
        return @_    if wantarray;         # list   context
        return shift if defined wantarray; # scalar context
        return;                            # void   context
    };

    {
        no strict 'refs';
        *{ $package . '::class_method' } = $class_method;
        *{ $package . '::instance_method' } = $instance_method;
    }

    return 1;
}


1;

__END__
=pod

=encoding utf-8

=head1 NAME

Method::Assert - Ensure instance and class methods are called properly

=head1 VERSION

version 0.0.1

=head1 SYNOPSIS

    package MyClass;

    use Method::Assert;
    use Carp qw(confess);

    sub new {
        my ($class, @args) = &class_method;
        my $self = {};
        bless $self, $class;
        $self->_init(@args);
        return $self;
    }

    sub _init {
        my ($self, @args) = @_; # Perl Critic prefers it this way
        &instance_method;       # still works
        ...
    }

    sub get_output_filename {
        &instance_method;
        return shift->{'output_filename'};
    }

    sub set_output_filename {
        my $self = &instance_method;
        confess("No parameter specified") unless @_;
        confess("File already exists") if -e $_[0];
        $self->{'output_filename'} = $_[0];
        return $self;
    }

=head1 DESCRIPTION

This module will export the two functions named below into the namespace of
the package using it. These two functions are useful to do typical checks at
the start of functions that are supposed to be either class or instance
methods.

B<Always remember to call these functions as C<&class_method> and
C<&instance_method>, or else they will not work properly!>

If you call them as C<class_method()> or C<instance_method()> a new version
of @_ will be initialized, and manipulation of @_ will not work properly.

=head1 FUNCTIONS

=head2 class_method

Use this function to check that the sub is called as a class method. If the
sub is called as a function, or as an instance method this function will
die.

If called in scalar context, will shift of the first argument of the @_
array and return that value. If called in list or void context it will not
change @_.

=head2 instance_method

Use this function to check that the sub is called as an instance method. If
the sub is called as a function, or as a class method this function will
die.

If called in scalar context, will shift of the first argument of the @_
array and return that value. If called in list or void context it will not
change @_.

=head1 CAVEATS

The two functions can NOT be called by the fully qualified method name
because they are generated as closures in the calling package's namespace
during import(). Writing C<use Method::Assert ()> will cause import() not to
be executed, which doesn't not make sense. See the section on I<import> in
C<perldoc -f use> for more information.

=head1 SEMANTIC VERSIONING

This module uses semantic versioning concepts from L<http://semver.org/>.

=head1 SEE ALSO

=over 4

=item *

L<Method::Signatures>

=item *

L<Devel::Declare>

=item *

L<MooseX::Method::Signatures>

=item *

L<MooseX::Declare>

=back

=for :stopwords CPAN AnnoCPAN RT CPANTS Kwalitee diff

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Method::Assert

=head2 Websites

=over 4

=item *

Search CPAN

L<http://search.cpan.org/dist/Method-Assert>

=item *

AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Method-Assert>

=item *

CPAN Ratings

L<http://cpanratings.perl.org/d/Method-Assert>

=item *

CPAN Forum

L<http://cpanforum.com/dist/Method-Assert>

=item *

RT: CPAN's Bug Tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Method-Assert>

=item *

CPANTS Kwalitee

L<http://cpants.perl.org/dist/overview/Method-Assert>

=item *

CPAN Testers Results

L<http://cpantesters.org/distro/M/Method-Assert.html>

=item *

CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Method-Assert>

=item *

Source Code Repository

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<git://github.com/robinsmidsrod/Method-Assert.git>

=back

=head2 Bugs

Please report any bugs or feature requests to C<bug-method-assert at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Method-Assert>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

  Robin Smidsrød <robin@smidsrod.no>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Robin Smidsrød.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

