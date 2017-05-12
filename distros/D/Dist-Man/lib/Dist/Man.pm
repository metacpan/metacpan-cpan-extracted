package Dist::Man;
# vi:et:sw=4 ts=4

use warnings;
use strict;
use Carp qw( croak );

=head1 NAME

Dist::Man - a simple starter kit for any module

=head1 VERSION

version 0.0.6

=cut

our $VERSION = '0.0.7';

=head1 SYNOPSIS

Nothing in here is meant for public consumption.  Use F<pl-dist-man>
from the command line.

    pl-dist-man create --module=Foo::Bar,Foo::Bat \
        --author="Andy Lester" --email=andy@petdance.com

=head1 DESCRIPTION

This is the core module for Dist::Man.  If you're not looking to extend
or alter the behavior of this module, you probably want to look at
L<pl-dist-man> instead.

Dist::Man is used to create a skeletal CPAN distribution, including basic
builder scripts, tests, documentation, and module code.  This is done through
just one method, C<create_distro>.

=head1 METHODS

=head2 Dist::Man->create_distro(%args)

C<create_distro> is the only method you should need to use from outside this
module; all the other methods are called internally by this one.

This method creates orchestrates all the work; it creates distribution and
populates it with the all the requires files.

It takes a hash of params, as follows:

    distro  => $distroname,      # distribution name (defaults to first module)
    modules => [ module names ], # modules to create in distro
    dir     => $dirname,         # directory in which to build distro
    builder => 'Module::Build',  # defaults to ExtUtils::MakeMaker
                                 # or specify more than one builder in an
                                 # arrayref

    license => $license,  # type of license; defaults to 'perl'
    author  => $author,   # author's full name (required)
    email   => $email,    # author's email address (required)

    verbose => $verbose,  # bool: print progress messages; defaults to 0
    force   => $force     # bool: overwrite existing files; defaults to 0

=head1 PLUGINS

Dist::Man itself doesn't actually do anything.  It must load plugins that
implement C<create_distro> and other methods.  This is done by the class's C<import>
routine, which accepts a list of plugins to be loaded, in order.

For more information, refer to L<Dist::Man::Plugin>.

=cut

sub import {
    my $class = shift;
    my @plugins = ((@_ ? @_ : 'Dist::Man::Simple'), $class);
    my $parent;

    while (my $child = shift @plugins) {
        eval "require $child";

        croak "couldn't load plugin $child: $@" if $@;

        ## no critic
        no strict 'refs'; #Violates ProhibitNoStrict
        push @{"${child}::ISA"}, $parent if $parent;
        use strict 'refs';
        ## use critic

        if ( @plugins && $child->can('load_plugins') ) {
            $parent->load_plugins(@plugins);
            last;
        }
        $parent = $child;
    }

    return;
}

=head1 AUTHORS

Shlomi Fish, L<http://www.shlomifish.org/> (while disclaiming any implicit
or explicit claims on the code).

Andy Lester, C<< <petdance at cpan.org> >>

Ricardo Signes, C<< <rjbs at cpan.org> >>

C.J. Adams-Collier, C<< <cjac at colliertech.org> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dist::Man

You can also look for information at:

=over 4

=item * Source code at Berlios.de

B<FILL IN>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dist-Man>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dist-Man>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Man>

=item * Search CPAN

L<http://search.cpan.org/dist/Dist-Man/>

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-dist-man at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 LICENSE

Copyright 2005-2009 Andy Lester, Ricardo Signes and C.J. Adams-Collier,
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 ADDITIONAL MODIFICATION TERMS

Modified by Shlomi Fish, 2009 - all rights disclaimed - may be used under
any of the present or future terms of Module-Starter.

=cut

1;
