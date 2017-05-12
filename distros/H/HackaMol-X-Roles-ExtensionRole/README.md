HackaMol-X-Roles-ExtensionRole
=====================

VERSION
========
developer version 0.011
Available for testing from cpan.org:

please see *[HackaMol::X::Roles::ExtensionRole on MetaCPAN](https://metacpan.org/release/DEMIAN/HackaMol-X-Roles-ExtensionRole) for formatted documentation.

SYNOPSIS
========

       package HackaMol::X::SomeExtension;
       use Moose;
    
       with qw(HackaMol::X::Roles::ExtensionRole);
    
       sub _build_map_in{
         my $sub_cr = sub { return (@_) };
         return $sub_cr;
       }
    
       sub _build_map_out{
         my $sub_cr = sub { return (@_) };
         return $sub_cr;
       }
    
       sub BUILD {
         my $self = shift;
    
         if ( $self->has_scratch ) {
             $self->scratch->mkpath unless ( $self->scratch->exists );
         }
       }
    
       no Moose;
       1;


DESCRIPTION
============

The HackaMol::X::Roles::ExtensionRole includes methods and attributes that are useful for building extensions
with code reuse.  This role will improve as extensions are written and needs arise.  This role is flexible
and can be encapsulated and rigidified in extensions.  Advanced use of extensions should still be able to 
access this flexibility to allow tinkering with internals!  Consumes HackaMol::Roles::ExeRole and HackaMol::Roles::PathRole
... ExeRole may be removed from core and wrapped in here.

