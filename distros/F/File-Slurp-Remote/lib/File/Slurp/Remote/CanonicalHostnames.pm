
package File::Slurp::Remote::CanonicalHostnames;

use strict;
use warnings;
use File::Slurp::Remote::BrokenDNS qw($myfqdn %fqdnify);

sub new
{
	my $pkg = shift;
	return bless {}, $pkg;
}

sub myname
{
	return $myfqdn;
}

sub canonicalize
{
	my ($self, $name) = @_;
	return $myfqdn if $name eq 'localhost';
	return $fqdnify{$name};
}

1;

__END__

=head1 NAME

package File::Slurp::Remote::CanonicalHostnames - a hostname canonicalizer example

=head1 SYNOPSIS

 use File::Slurp::Remote::CanonicalHostnames;

 my $canonicalizer = File::Slurp::Remote:CanonicalHostnames->new();

 my $my_hostname = $canonicalizer->myname;

 my $canonical_hostname = $canonicalizer->canonicalize($hostname);

=head1 DESCRIPTION

Some people use real hostnames with forward and reverse DNS set up correctly.
Other people do not.  Sometimes there is more than one name for a host.  Because
of these variations, L<Proc::JobQueue> cannot depend on any one way to 
figure out if two hostnames are actually the same host.

This package, File::Slurp::Remote::CanonicalHostnames provides an example 
and interface specification for how L<Proc::JobQueue> will ask these 
questions.  L<Proc::JobQueue> will use this package by default, but you can
override this behavior when you create L<Proc::JobQueue> objects and use
a different package that provides the same interface.

File::Slurp::Remote::CannonicalHostnames uses L<File::Slurp::Remote::BrokenDNS>
to do its work.  

=head1 INTERFACE

There following methods are required:

=head1

=over 18

=item new()

The constructor C<new>, takes no arguments.

=item myname()

This must return the local hostname.  This must already be in
canonical form. 

=item canonicalize($hostname)

This returns the canonical form of a hostname.  If there is more than one
way to refer to the same host, all the different ways should return the same
canonical form.

=back

=head1 LICENSE

Copyright (C) 2011 Google, Inc.
This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

