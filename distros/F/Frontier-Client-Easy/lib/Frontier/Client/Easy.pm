package Frontier::Client::Easy;

use strict;
use warnings;
use Frontier::Client;

our $VERSION = 1.03;
our $AUTOLOAD;

sub new {
        my $that  = shift;
        my $class = ref($that) || $that;
        my $self  = {};
        bless $self, $class;
        #Process instantuation arguments
        my %args = @_;
        my $url = $args{'url'} || die "Must provide URL to Frontier server";
        $self->{'server'} = Frontier::Client->new( 'url' => $url, debug=>0  );
        return $self;
}

sub AUTOLOAD {                  #This sub overloads all methods called by storing the method name in $AUTOLOAD for us

        my $self = shift;
        my $type = ref($self);
        my $name = $AUTOLOAD;
        $name =~ s/.*://;                               #Trim down the fully qualified name, just the method
	return unless($name);				#Don't proceed unless we were actually asked to call something
        return $self->{'server'}->call($name,@_);       #Wrap it into a Frontier::Client->call method

}

sub DESTROY {			#Don't allow overload of the destructor
	return;
}

1;
__END__
=pod

=head1 NAME

Frontier::Client::Easy - Perl extension for easy use of Frontier::Client

=head1 SYNOPSIS

	use Frontier::Client::Easy;

	my $object = Frontier::Client::Easy->new(url=>'http://my.frontier.server/cgi-bin/app.cgi');

	print "Calling server method foo(), result is  . " $object->foo()  . "\n";
	print "Calling server method bar(1), result is . " $object->bar(1) . "\n";

	my %hash = (
			fruit	=>	'apple',
			colour	=>	'purple',
			flavour	=>	'chocolate',
	);

	print "Calling server method baz() on my hash, result is, " . $object->baz(\%hash) . "\n";


=head1 DESCRIPTION


Frontier::Client::Easy provides an easy interface to Frontier::Client,
allowing you to call methods directly from the object as opposed to using
the "call()" method of Frontier::Client.

This makes for easy migration from local to remote architectures.

=head1 METHODS

=over

=item new

	my $object = Frontier::Client::Easy->new(url=>$url);

Creates a new Frontier::Client::Easy object, takes a single parameter "url", the URL of the Frontier server.
Will not create the object unless this is provided. 
Does not communicate with the server when the object is created so no error checking is possible
until the first call is made.

All other methods are passed transparently to the server and return the server's response.

=back

=head1 NOTES

=over

Since this module is based on Frontier::Client, methods of Frontier::Client will not be overloaded.

This module will not allow you to directly call methods of Frontier::Client in your code, if you wish
to use such methods you must use $object->{'server'}->$method instead.

As a result of this, this module will not allow you to directly create XML-RPC-specific datatypes
of Frontier::Client, again, you must use $object->{'server'}->$datatype to do this.

=back

=head1 AUTHOR

David J. Freedman <lochii AT convergence DOT cx>

=head1 COPYRIGHT

Copyright (c) 2008 Convergence Inc.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms as perl itself.

=head1 SEE ALSO

Frontier::Client(3)
perl(1)

=cut

