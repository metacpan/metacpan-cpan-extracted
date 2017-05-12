package Gtk2::Net::LDAP::Widgets;

our $VERSION = "2.0.1";
sub Version { $VERSION; }

require 5.005;

use strict;
use Gtk2::Net::LDAP::Widgets::LdapEntrySelector;
use Gtk2::Net::LDAP::Widgets::LdapEntryView;
use Gtk2::Net::LDAP::Widgets::LdapTreeSelector;
use Gtk2::Net::LDAP::Widgets::LdapTreeView;

1;

__END__

=head1 NAME

Gtk2::Net::LDAP::Widgets - LDAP-related widget library for Gtk2

=head1 SYNOPSIS

    use Gtk2::Net::LDAP::Widgets;

    my $entryPopup = Gtk2::Net::LDAP::Widgets::LdapEntrySelector->new ($parent_window,
      $ldap_source,
      'dc=example,dc=com',
      'objectClass=inetorgperson',
      'init_interactive_filter' => 'smith',
      'single_selection' => 1,
      'interactive_filter_type' => 'simple'
    );
    $entryPopup->signal_connect (response => sub {
      my ($popup, $response) = @_;
      if($response =~ 'accept') {
        print "Selected entry DN: ".$entryPopup->get_dn;
      } else {
				print "No existing entry selected.\n";
      }
      $_[0]->destroy;
      });
    $entryPopup->show_all;

=head1 DESCRIPTION

This is an object oriented collection of LDAP-related Gtk2 widgets.

Featured classes currently include windows and views that allow the user to 
select or pick entries that result from an LDAP search.

See also:

L<Gtk2::Net::LDAP::Widgets::LdapEntrySelector>
L<Gtk2::Net::LDAP::Widgets::LdapTreeSelector>
L<Gtk2::Net::LDAP::Widgets::LdapTreeView>

=head1 AUTHORS

Original author: Aleksander Adamowski <cpan@olo.org.pl>

=head1 COPYRIGHT AND LICENSE

Copyright 2005,2008 by Aleksander Adamowski

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. 

=cut

