package File::Redirect::lib;

use strict;
use warnings;
use File::Redirect qw(mount);

my $count = 1;

sub import {
	my ( undef, $provider, $request, $root ) = @_;
	$root = '/' unless defined $root;
	my $path = "$provider:" . ($count++);
	mount($provider, $request, $path) or die;
	push @INC, "$path$root";
}

1;

=head1 NAME

File::Redirect::lib - mount and use lib

=head1 DESCRIPTION

   use File::Redirect::lib Zip => '/tmp/Foo-Bar.zip';
   use Foo::Bar;

=cut
