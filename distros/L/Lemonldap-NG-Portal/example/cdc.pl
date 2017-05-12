#!/usr/bin/perl

#==============================================================================
# Script to manage SAML Cross Domain Cookie
#
# Part of LemonLDAP::NG project
#==============================================================================

use strict;
use Lemonldap::NG::Portal::CDC;

# Create portal
my $portal = Lemonldap::NG::Portal::CDC->new();

# Process
my $result = $portal->process();
my $values = $portal->{cdc_values};

# Very simple page displaying cookie content
print $portal->header('text/html; charset=utf-8');
print $portal->start_html('Cross Domain Cookie');
print $portal->h1("Cross Domain Cookie");
if ( defined $values ) {
    print $portal->p($_) foreach (@$values);
}
else {
    print $portal->p("No cookie found");
}
print $portal->end_html();

exit;
