#!perl
use strict;
use warnings;

=head1 SIMPLE CORELIST SERVER DEMO

This module bundles everything that you might need in order to implement
a Froody service.

=head1 THE API

To start with, we provide an API definition in L<Corelist::API>.  We have to provide
an XML description of the publicly facing methods for our service.  In this case, our
API methods are:

  froody.demo.core

=cut

package Corelist::API;
use base qw(Froody::API::XML);

sub xml {
  return <<'XML';
  <spec>
   <methods>
    <method name="froody.demo.core">
    <description>When modules were distributed with core Perl</description>
    <arguments>
      <argument name="modules" type="csv" optional="0" />
    </arguments>
    <response>
      <core_list module_core_list_version="1.23">
         <module name="Foo::Bar" first_in="5.7">
           <distribution perl_version="5.7" module_version="1.2"/>
           <distribution perl_version="5.8" module_version="1.2"/>         
         </module>
         <module name="Foo::Baz" first_in="5.7">
           <distribution perl_version="5.7" module_version="1.2"/>
           <distribution perl_version="5.8" module_version="1.2"/>         
         </module>
         <serveradmin>
           <name>Mark Fowler</name>
           <email>mark@twoshortplanks.com</email>
         </serveradmin>
      </core_list>
    </response>
    </method>
   </methods>
  </spec>
XML
}

=head1 THE IMPLEMENTATION

We implement all the methods in the froody.demo namespace, as defined with Corelist::API

See L<Froody::QuickStart> for an explanation of how this works.

=cut

package Corelist::Implementation;
use base qw(Froody::Implementation);

sub implements { 'Corelist::API' => "froody.demo.core" }

use Module::CoreList;
sub core
{
   my $self = shift;  # not used
   my $args = shift;

   # insert the static server stuff
   my $ds = { 
     serveradmin => { 
       name => "Mark Fowler",
       email => 'mark@twoshortplanks.com',
     },
     module_core_list_version => Module::CoreList->VERSION,
     module => [],
   };
       
   # for each of the modules
   foreach my $module (@{ $args->{modules} })
   {
     my $module_hash = { name => $module, distribution => [] };
        
     # what was the first one?
     if (my $first_in = Module::CoreList->first_release($module))
       { $module_hash->{first_in} = $first_in }
   
     # build the distributions list
     foreach my $dist (sort { $a <=> $b } keys %Module::CoreList::version)
     {
       if (exists $Module::CoreList::version{ $dist }{ $module }) {
         my $version = $Module::CoreList::version{ $dist }{ $module };
         $version = "undef" unless defined $version;
         push @{ $module_hash->{distribution} }, {
           perl_version => $dist,
           module_version => $version,
         };
       }
     }

     push @{ $ds->{module} }, $module_hash;
   }

   return $ds;
}

package main;

use Froody::Server::Standalone;

# Mess with the include path because we have everything in the same file.

$INC{'Corelist/Implementation.pm'} = 'Corelist.pm';
$INC{'Corelist/API.pm'} = 'Corelist.pm';  

=head1 

After we've loaded the implementation, we can start the standalone server.  The
current implementation of the standalone server will walk @INC to discover all
L<Froody::Implementation> subclasses, and register all required implementations.

Once the server has started, you can test the functionality of the server by
using the froody script to connect to the server:

  froody -u'http://localhost:4242/' froody.demo.corelist module=Froody

=cut

my $server = Froody::Server::Standalone->new;
$server->port(4242);
$server->run();

1;
