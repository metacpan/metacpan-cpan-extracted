package Gtk2::Net::LDAP::Widgets::DistinguishedName;
#---[ pod head ]---{{{

=head1 NAME

Gtk2::Net::LDAP::Widgets::DistinguishedName - helper class for DN processing

=head1 SYNOPSIS

    This class is mostly used by other components to analyze and process LDAP 
    Distinguished Names and isn't meant to be used directly. Read the source in 
    case of any needs to do that.

=cut

#---}}}
use utf8;
use strict;
use vars qw(@ISA $VERSION);

use Net::LDAP;
use Net::LDAP::Util qw(ldap_explode_dn);
use Data::Dumper;

#@ISA = qw(Gtk2::TreeView);

our $VERSION = "2.0.1";

our $dntext;
our $dn;

use overload
q{""} => 'to_string';

# by OLO
# czw mar 17 17:51:34 CET 2005
# Constructor:
sub new {
  my $class = shift;
  my $self = {};
  $self->{dntext} = shift;
  $self->{dn} = _dn_normalize($self->{dntext});

  bless $self, $class;
}

# by OLO
# czw mar 17 17:51:20 CET 2005
# Conversion of self to string:
sub to_string {
  my $self  = shift;
  return $self->{dntext};
}

#---[ sub isDescendant ]---{{{

=head2 isDescendant

=over 4

=item isDescendant ( possible_ancestor )

Checks whether this DN is a child of another DN (possible_ancestor).

C<possible_ancestor> a distinguished name being tested for ancestorness in 
relation to current DN :)

=back

=cut
sub isDescendant($) {
  my $self  = shift;
  my $possible_ancestor = shift;
  my $mydn = $self->{dn};
  my $hisdn = $possible_ancestor->{dn};

  #print "Testing if $mydn is a child of $hisdn...\n";
  if (rindex($mydn, $hisdn) > 0) {
    #print "...it is.\n";
    return 1;
  } else {
    #print "...it isn't.\n";
    return 0;
  }
}
#---}}}

#---[ sub getRdn ]---{{{

=head2 getRdn

=over 4

=item getRdn ( possible_ancestor )

Returns the RDN of this DN in relation to a potential ancestor's DN ( the C<possible_ancestor> argument).
If the C<possible_ancestor> isn't an ancestor in fact, the returned RDN will be empty.

C<possible_ancestor> a distinguished name of potential ancestor

=back

=cut
sub getRdn($) {
  my $self  = shift;
  my $possible_ancestor = shift;
  if (! defined($possible_ancestor)) {
    $possible_ancestor = Gtk2::Net::LDAP::Widgets::DistinguishedName->new('');
  }
  my $mydn = $self->{dn};
  my $hisdn = $possible_ancestor->{dn};
  my $rdn = '';

  if (rindex($mydn, $hisdn) > 0) {
    # we're a descendant
    #print "$mydn is a descendant of $hisdn\n";

    # compute the RDN:
    $rdn = substr($mydn, 0, rindex($mydn, $hisdn));
    #print " ...so its RDN is $rdn\n";
  }
  $rdn =~ s/,+$//;
  $rdn =~ s/^,+//;
  return $rdn;
}
#---}}}

#---[ sub getLength ]---{{{

=head2 getLength

=over 4

=item getLength ( )

Returns the count of RDN components that this DN consists of.

=back

=cut
sub getLength {
  my $self  = shift;
  my @exploded_dn = @{ ldap_explode_dn($self->{dn}) };
  return scalar(@exploded_dn);
}
#---}}}

#---[ sub compareTo ]---{{{

=head2 compareTo

=over 4

=item compareTo ( )

Compares this DN and another DN using normalized forms of both. Return values
meanings are the same as with the "eq" Perl operator.

=back

=cut
sub compareTo($) {
  my $self = shift;
  my $him = shift;
  return ($self->{dn} eq $him->{dn});
}
#---}}}


# by OLO
# czw kwi 14 09:46:05 CEST 2005
# internal function used to normalize DNs for proper DN comparisons
sub _dn_normalize {
  my $dn = shift;
  $dn = lc($dn);
  $dn =~ s/\s//g;
  $dn = Net::LDAP::Util::canonical_dn($dn, casefold => 'lower');
  return $dn;
}

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

