#! perl

# Data.pm -- Multi-purpose definition of config data
# Author          : Johan Vromans
# Created On      : Sat Oct 24 21:30:54 2009
# Last Modified By: Johan Vromans
# Last Modified On: Wed Mar 16 20:22:16 2011
# Update Count    : 17
# Status          : Unknown, Use with caution!

use strict;
use warnings;

package EB::Config::Data;

use EB;

my $data =
    [
       { section => "cpy",
	 tag => N__("Bedrijfsgegevens"),
	 keys =>
	 [
	  { name => "name", tag => N__("Naam"), type => 'string', value => undef },
	  { name => "id", tag => N__("Administratienummer"), type => 'string', value => undef },
	  { name => "address", tag => N__("Adres"), type => 'string', value => undef },
	  { name => "zip", tag => N__("Postcode"), type => 'string', value => undef },
	  { name => "city", tag => N__("Plaats"), type => 'string', value => undef },
	  { name => "taxreg", tag => N__("Fiscaal nummer"), type => 'string', value => undef },
	 ],
       },
       { section => "general",
	 tag => N__("Algemeen"),
	 keys =>
	 [
	  { name => "admdir", tag => N__("Folder voor administraties"), type => 'folder', value => '$HOME/.eekboek/admdir' },
	  { name => "wizard", tag => N__("Forceer wizard"), type => 'bool', value => undef },
	 ],
       },
       { section => "prefs",
	 tag => N__("Voorkeursinstellingen"),
	 keys =>
	 [
	  { name => "journal", tag => N__("Toon journaalpost na elke boeking"), type => 'bool', value => undef },
	 ],
       },
       { section => "Database",
	 keys =>
	 [
	  { name => "name", tag => N__("Naam"), type => 'string', value => undef },
	  { name => "driver", tag => N__("Driver"), type => 'choice', value => undef,
	    choices => [ qw(SQLite PostgreSQL) ],
	    values => [ qw(sqlite postgres) ],
	  },
	  { name => "user", tag => N__("Gebruikersnaam"), type => 'string', value => undef },
	  { name => "password", tag => N__("Toegangscode"), type => 'string', value => undef },
	  { name => "host", tag => N__("Server systeem"), type => 'string', value => undef },
	  { name => "port", tag => N__("Server poort"), type => 'int', value => undef },
	 ],
       },
       { section => "Strategy", tag => N__("Strategie"),
	 keys =>
	 [
	  { name => "round", tag => N__("Afrondingsmethode"), type => 'choice', value => undef,
	    choices => [ qw(IEEE Bankers POSIX) ],
	    values => [ qw(ieee bankers posix) ],
	  },
	  { name => "bkm_multi", tag => N__("Meervoudig afboeken"), type => 'bool', value => undef },
	  { name => "iv_vc", tag => N__("BTW correcties"), type => 'bool', value => undef },
	 ],
       },
       { section => "shell", tag => N__("Shell"),
	 keys =>
	 [
	  { name => "prompt", tag => N__("Prompt"), type => 'string', value => undef },
	  { name => "userdefs", tag => N__("Eigen uitbreidingen"), type => 'string', value => undef },
	 ],
       },
       { section => "Format", tag => N__("Formaten"),
	 keys =>
	 [
	  { name => "numfmt", tag => N__("Getalformaat"), type => 'choice', value => undef,
	    choices => [ "12345,99 (decimaalkomma)",
			 "12345.99 (decimaalpunt)",
			 "12.345,99 (duizendpunt + decimaalkomma)",
			 "12,345.99 (duizendkomma + decimaalpunt)" ],
	    values => [ "12345,99", "12345.99", "12.345,99", "12,345.99" ],
	  },
	  { name => "date", tag => N__("Datumformaat"), type => 'choice', value => undef,
	    choices => [ "2008-05-31 (ISO)", "31-05-2008 (NEN)", "31-05 (NEN, verkort)" ],
	    values => [ "YYYY-MM-DD", "DD-MM-YYYY", "DD-MM" ],
	  },
	 ],
       },
       { section => "text", tag => N__("Tekstrapporten"),
	 keys =>
	 [
	  { name => "numwidth", tag => N__("Kolombreedte voor getallen"), type => 'slider',
	    range => [5, 20, 9], value => undef, }
	 ],
       },
       { section => "html", tag => N__("HTML rapporten"),
	 keys =>
	 [
	  { name => "cssdir", tag => N__("Style sheets"), type => 'folder', value => undef, },
	 ],
       },
       { section => "csv", tag => N__("CSV rapporten"),
	 keys =>
	 [
	  { name => "separator", tag => N__("Scheidingsteken"), type => 'choice', value => undef,
	    choices => [ ", (komma)", "; (puntkomma)", ": (dubbelpunt)", "Tab", ],
	    values  => [ ",", ";", ":", "\t", ],
	  },
	 ],
       },
       { section => "security", tag => N__("Beveiliging"),
	 keys =>
	 [
	  { name => "override_security_for_vista", tag => N__("Beveiliging voor MS Vista uitschakelen"),
	    type => 'bool', value => undef, },
	 ],
       },
    ];

sub get_data {			# class method
    return bless $data;
}

sub get_name {
    my ($self) = $_;
    "EekBoek";
}

sub get_site_url {
    my ($self) = $_;
    "http://www.eekboek.nl/";
}

sub get_help_url {
    my ($self) = @_;
    $self->get_site_url . "docs/config.html";
}

sub get_topic_help_url {
    my ($self, $section, $key) = @_;
    $self->get_help_url . "#" . join("_", map { lc } $section, $key );
}

unless ( caller ) {
    require YAML;
    # Use Bless to reorder the data a bit.
    foreach ( @$data ) {
	YAML::Bless($_)->keys([qw(section tag keys)]);
	foreach ( @{$_->{keys}} ) {
	    my %h = map { $_ => 1 } keys %$_;
	    delete @h{qw(name tag type value)};
	    YAML::Bless($_)->keys([qw(name tag type value), keys(%h)]);
	}
    }
    warn YAML::Dump($data);
}

1;
