package Gtk2::Ex::MindMapView::ArgUtils;

use warnings;
use strict;
use Carp;

use Exporter;

our $VERSION = '0.000001';

our @ISA = qw(Exporter);

our @EXPORT = qw(args_required args_store args_valid arg_default);


sub args_required
{
    my ($attributes_ref, @valid_keys) = @_;

    foreach my $valid_key (@valid_keys)
    {
	if (!defined $attributes_ref->{$valid_key})
	{
	    croak "Missing required argument: $valid_key\n";
	}
    }
}


sub args_store
{
    my ($self, $attributes_ref) = @_;

    my %attributes = %$attributes_ref;

    foreach my $key (keys %attributes)
    {
	$self->{$key} = $attributes{$key};
    }
}


sub args_valid
{
    my ($attributes_ref, @valid_keys) = @_;

    KEY: foreach my $key (keys %$attributes_ref)
    {
	foreach my $valid_key (@valid_keys)
	{
	    next KEY if ($valid_key eq $key);
	}

	croak "Invalid argument: $key\n";
    }
}


sub arg_default
{
    my ($self, $key, $default) = @_;

    if (!defined $self->{$key})
    {
	$self->{$key} = $default;
    }
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Gtk2::Ex::MindMapView::ArgUtils - Argument handling utilites.


=head1 VERSION

This document describes Gtk2::Ex::MindMapView::ArgUtils version 0.0.1


=head1 SYNOPSIS

use Gtk2::Ex::MindMapView::ArgUtils;

  
=head1 DESCRIPTION

This is an internal set of argument handling utilities.


=head1 INTERFACE 

=over

=item args_required ($attributes_ref, @valid_keys)

Complains if a required argument to a module is missing.

=item args_store ($self, $attributes_ref)

Copies arguments from attributes hash to hash referenced by $self.

=item args_valid ($attributes_ref, @valid_keys)

Complains of an invalid or unexpected argument is given.

=item arg_default ($self, $key, $default)

Assigns a default value if one is needed.

=back


=head1 DIAGNOSTICS

=over

=item C<Missing required argument>

The caller omitted an important required argument.

=item C<Invalid argument>

An invalid or unexpected argument was found.

=back


=head1 AUTHOR

James Muir  C<< <hemlock@vtlink.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, James Muir C<< <hemlock@vtlink.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
