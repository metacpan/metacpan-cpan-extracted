package Decl::DefaultFilters;

use warnings;
use strict;
use Decl::Util;
use Decl::Node;
use Data::Dumper;


=head1 NAME

Decl::DefaultFilters - implements some default filters for the Decl language.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This isn't really an object module; it's just a place to register the default filters.

=head1 DEFAULT FILTERS

=head2 hex_filter()

Called with a string containing hex digits, packs them by pairs into a binary string.

=cut

sub hex_filter {
   my $value = shift;
   $value =~ s/[^0-9a-fA-F]//g;
   pack ('H*', $value);
}

=head2 urlencode, urldecode

I considered just defining these in HTML::Declarative, but heck, they're useful for testing and not so
big.

I considered CPAN's URI::Encode - but I didn't want another dependency for such a small amount of code.

Source: http://code.activestate.com/recipes/577450-perl-url-encode-and-decode/

=cut

sub urlencode {
    my $s = shift;
    $s =~ s/ /+/g;
    $s =~ s/([^A-Za-z0-9\+-])/sprintf("%%%02X", ord($1))/seg;
    return $s;
}

sub urldecode {
    my $s = shift;
    $s =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
    $s =~ s/\+/ /g;
    return $s;
}

=head2 init_default_filters()

Called on initialization of the Decl module.

=cut

sub init_default_filters {
   Decl->register_filter ('hex',       \&hex_filter, 'Decl::DefaultFilters');
   Decl->register_filter ('urlencode', \&urlencode,  'Decl::DefaultFilters');
   Decl->register_filter ('urldecode', \&urldecode,  'Decl::DefaultFilters');
}

=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-decl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Decl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Decl::DefaultFilters
