
package Test::IOC;

use strict;
use warnings;

use base qw/Exporter/;

use Test::Builder;

use IOC::Registry;
use Test::More;

our $VERSION = "0.01";

our @EXPORT = qw(
    locate_service search_service
    locate_container search_container
    service_isa service_is service_can service_is_deeply
    service_exists container_exists
    container_list_is service_list_is
    service_is_literal service_is_prototype service_is_singleton
);

my $t = Test::Builder->new;

my $r = IOC::Registry->instance;

# utility subs

our $err;

sub _try (&) {
    my $s = shift;
    local $@;
    my $r = eval { $s->( @_ ) };
    $err = $@;
    $r;
}

sub locate_service ($) {
    my $path = shift;
    _try { $r->locateService($path) };
}

sub search_for_service ($) {
    my $name = shift;
    $r->searchForService($name);
}

sub locate_container ($) {
    my $path = shift;
    _try { $r->locateContainer($path) }
}

sub search_for_container ($) {
    my $name = shift;
    $r->searchForContainer($name);
}

# basic tests

sub service_exists ($;$) {
    my ( $path, $desc ) = @_;
    $t->ok( defined(locate_service($path)), $desc || "The service '$path' exists in the registry" ) || diag $err;
}

sub container_exists ($;$) {
    my ( $path, $desc ) = @_;
    $t->ok( defined(locate_container($path)), $desc || "The container '$path' exists in the registry" );
}

sub service_alias_ok ($$;$) {
    my ( $real, $alias, $desc ) = @_;
    $desc ||= "The service at '$real' is aliased to '$alias'";

    return $t->is_eq( $real, $r->{service_aliases}{$alias}, $desc );

    # FIXME test it like this:

    # my $real_s  = locate_service($real);
    # my $alias_s = locate_service($alias);

    # return $t->fail("The service '$real' does not exist in the registry") unless defined $real_s;
    # return $t->fail("The service '$alias' does not exist in the registry") unless defined $alias;
    
    # compare true equality of IOC::Service objects or deep equality of the returned services
}

sub container_list_is ($$;$) {
    my ( $path, $spec, $desc ) = @_;
    local $" = ", ";
    $desc ||= "The containers at '$path' are @$spec";

    my @got;

    if ( $path eq "/" ) {
        @got = $r->getRegisteredContainerList;
    } else {
        my $c = locate_container($path) || return $t->fail("Container '$path' does not exist"); 
        @got = $c->getSubContainerList;
    }

    @_ = ( [ sort @got ], [ sort @$spec ], $desc );
    goto &is_deeply;
}

sub service_list_is ($$;$) {
    my ( $path, $spec, $desc ) = @_;
    local $" = ", ";
    $desc ||= "The services at '$path' are @$spec";

    if ( $path eq "/" ) {
        die "Services cannot be added to the registry";
    } else {
        my $c = locate_container($path) || return $t->fail("Container '$path' does not exist"); 

        @_ = ( [ sort $c->getServiceList ], [ sort @$spec ], $desc );
        goto &is_deeply;
    }
}

sub service_is_literal ($;$) {
    my ( $path, $desc ) = @_;
    $desc ||= "'$path' is a literal service";
    local $@;
    $t->ok( eval { get_service_object($path)->isa("IOC::Service::Literal") }, $desc );
}

sub service_is_prototype ($;$) {
    my ( $path, $desc ) = @_;
    $desc ||= "'$path' is a prototype service";
    local $@;
    $t->ok( eval { get_service_object($path)->isa("IOC::Service::Prototype") }, $desc );
}

sub service_is_singleton ($;$) {
    my ( $path, $desc ) = @_;
    $desc ||= "'$path' is a singleton service";
    local $@;
    my $s = get_service_object($path);
    $t->ok( eval {
        $s->isa("IOC::Service")
            and
        !$s->isa("IOC::Service::Literal")
            and
        !$s->isa("IOC::Service::Prototype")
    }, $desc );
}

sub get_service_object ($) {
    my $path = shift;
    $path =~ s{ / ([^/]+) $ }{}x;
    my $name = $1;
    my $c = locate_container($path) || return;
    $c->{services}{$name}; # FIXME yuck
}

# test + utility sub combination

my %tests = (
    is        => \&is,
    isa       => \&isa_ok,
    can       => \&can_ok,
    is_deeply => \&is_deeply,
);

foreach my $test ( keys %tests ) {
    my $test_sub = $tests{$test};

    no strict 'refs';
    *{ "service_$test" } = sub {
        use strict;
        my ( $path, @spec ) = @_;

        my $service = locate_service($path);

        if ( defined $service ) {
            @_ = ( $service, @spec );
            goto $test_sub;
        } else {
            fail( "The service '$path' does not exist in the registry" );
        }
    }
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Test::IOC - Test IOC registries

=head1 SYNOPSIS

    use Test::More;
    use Test::IOC;

    use MyIOCStuff;

    service_exists("/app/log_file");
    service_is_literal("/app/log_file");
    
    service_exists("/app/logger");
    service_is_singleton("/app/logger");
    service_can("/app/logger", qw/warn debug/);

=head1 DESCRIPTION

This module provides some simple facilities to test IOC registries for
correctness.

=head1 CAVEAT

This module is still in development, so use at your own risk. But then 
again, its for tests, so thats not very risky anyway.

=head1 EXPORTS

=over 4

=item service_exists $path

=item container_exists $path

Checks that the path exists in the registry.

=item service_is $path, $spec

=item service_isa $path, $class

=item service_can $path, @methods

=item service_is_deeply $path, $spec

These methods provide tests akin to Test::More's C<is>, C<isa_ok>, C<can_ok>
and C<is_deeply>, except that the first argument is used as a path to fetch
from the registry.

=item service_is_singleton $path

=item service_is_literal $path

=item service_is_prototype $path

Checks that the service constructor class is of the right type for lifecycle
management.

=item service_alias_ok $real, $alias

Check that the path $real has an alias $alias


=item container_list_is $parent_path, \@container_names

=item service_list_is $parent_path, \@service_names

Check that the child elements under $parent_path are as listed in the service
name array reference. The names don't have to be sorte.

=item get_service_object $path

Utility function to get the L<IOC::Service> object (not the service itself) for
a given path.

=item locate_container $path

Utility function to call L<IOC::Registry/locateContainer>.

=item locate_service $path

Utility function to call L<IOC::Registry/locateService>.

=item search_for_container $name

Utility function to call L<IOC::Registry/searchForContainer>.

=item search_for_service $name

Utility function to call L<IOC::Registry/searchForService>.

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it.

=head1 AUTHOR

Yuval Kogman

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
