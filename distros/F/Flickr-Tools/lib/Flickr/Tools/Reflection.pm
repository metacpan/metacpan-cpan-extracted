package Flickr::Tools::Reflection;

use Flickr::API::Reflection;
use Types::Standard qw ( InstanceOf );
use Carp;
use Moo;
use strictures;
use namespace::clean;
use 5.010;

with qw(Flickr::Roles::Caching);

our $VERSION = '1.22';

extends 'Flickr::Tools';

has '+_api_name' => (
    is       => 'ro',
    isa      => sub { $_[0] eq 'Flickr::API::Reflection' },
    required => 1,
    default  => 'Flickr::API::Reflection',
);

sub getMethods {
    my ($self, $args) = @_;
    my $methods;
    my $pre_expire = 0;

    $self->_set_cache_hit(1);

    if ( defined( $args->{clear_cache} ) and $args->{clear_cache} ) {
        $pre_expire = 1;
    }

    if (defined($args->{list_type}) and $args->{list_type} =~ m/list/i) {

        $self->_set_cache_key('methods_list');

        $methods = $self->_cache->get( $self->cache_key,
            expire_if => sub { $pre_expire } );

        if ( !defined $methods ) {
            $methods = $self->{_api}->methods_list;
            $self->_set_cache_hit(0);
            $self->_cache->set( $self->cache_key, $methods,
                                $self->cache_duration );
        }
    }
    else {

        $self->_set_cache_key('methods_hash');

        $methods = $self->_cache->get( $self->cache_key,
                                       expire_if => sub { $pre_expire } );
        if ( !defined $methods) {
            $methods = $self->{_api}->methods_hash;
            $self->_set_cache_hit(0);
            $self->_cache->set( $self->cache_key, $methods,
                $self->cache_duration );
        }
    }

    return $methods;
}


sub getMethod {
   my ($self, $args) = @_;
   my $rsp   = {};
   my $pre_expire = 0;

   $self->_set_cache_hit(1);

   if  ($args =~ m/flickr\.[a-z]+\.*/x) {
       my $tmp = { Method => $args };
       $args = $tmp;
   }
   if ( defined( $args->{clear_cache} ) and $args->{clear_cache} ) {
       $pre_expire = 1;
   }

   if (exists($args->{Method})) {

       $self->_set_cache_key( 'Method ' . $args->{Method} );

       $rsp = $self->_cache->get( $self->cache_key,
                                              expire_if => sub { $pre_expire } );
       if ( !defined $rsp) {
           $rsp = $self->{_api}->get_method($args->{Method});
           $self->_set_cache_hit(0);
           $self->_cache->set( $self->cache_key, $rsp,
                               $self->cache_duration );
       }
   }
   else {

       carp 'argument neither a hashref pointing to a method, or the name of a method';

   }
   return $rsp;
}


1;

__END__

=head1 NAME

Flickr::Tools::Reflection - Perl interface to the Flickr::API for Flickr 
method reflection

=head1 VERSION

CPAN:        1.22

Development: 1.22_01


=head1 SYNOPSIS

 use strict;
 use warnings;
 use Flickr::Tools::Reflection;
 use 5.010;


=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head1 DEPENDENCIES

CHI, Perl 5.10 and Moo.

=head1 INCOMPATIBILITIES

None known of, yet.

=head1 BUGS AND LIMITATIONS

Yes

=head1 AUTHOR

Louis B. Moore <lbmoore@cpan.org>

=head1 LICENSE AND COPYRIGHT


Copyright (C) 2015 Louis B. Moore <lbmoore@cpan.org>


This program is released under the Artistic License 2.0 by The Perl Foundation.
L<http://www.perlfoundation.org/artistic_license_2_0>


=cut

