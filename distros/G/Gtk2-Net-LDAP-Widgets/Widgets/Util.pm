package Gtk2::Net::LDAP::Widgets::Util;
#---[ pod head ]---{{{

=head1 NAME

Gtk2::Net::LDAP::Widgets::Util - helper functions

=head1 SYNOPSIS

    This module contains various helper functions and isn't meant to be used 
    directly. Read the source in case of any needs to do that.

=cut

#---}}}

require Exporter;
our @ISA     = qw(Exporter);
our @EXPORT  = qw(filter_trim_outer_parens);
our $VERSION = "2.0.1";

use strict 'vars';

#---[ sub filter_trim_outer_parens ]---{{{

=head2 filter_trim_outer_parens

=over 4

=item filter_trim_outer_parens ( filter )

Trims superfluous outside parentheses from an LDAP filter, e.g. ((uid=olo)) 
will be changed to uid=olo

C<filter> string representation of LDAP filter to trim parentheses from.

=back

=cut
sub filter_trim_outer_parens {
  my $filter = shift;
  while ($filter =~ /^\(.*\)$/) {
    $filter =~ s/^\((.*)\)$/$1/;
  }
  return $filter;
}
#---}}}

1;
__END__

#---[ pod end ]---{{{

=head1 SEE ALSO

L<Gtk2::Net::LDAP::Widgets>
L<Gtk2>
L<Net::LDAP>

=head1 AUTHOR

Aleksander Adamowski, E<lt>cpan@olo.org.plE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005,2008 by Aleksander Adamowski

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. 

=cut

#---}}}

