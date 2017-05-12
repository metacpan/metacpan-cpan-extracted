# Copyright (C) 2008 Wes Hardaker
# License: Same as perl.  See the LICENSE file for details.
package Ham::Callsign::DB;

use Ham::Callsign::Base;
our @ISA = qw(Ham::Callsign::Base);

our $VERSION = "0.31";

use DBI;
use strict;

sub init {
    my ($self) = @_;

    my $dbtype = $self->{'dbtype'} ||
      'SQLite:' . $ENV{'HOME'} . "/.callsigns.sqlite";
    my $dbargs = $self->{'dbargs'} || '';

    $self->{dbh} = DBI->connect("DBI:$dbtype$dbargs",
				$self->{'user'} || '', $self->{'pass'} || '');
}

sub initialize_dbs {
    my ($self, $dbs) = @_;
    if (!$dbs || ref($dbs) ne 'ARRAY') {
	$dbs = [split(/,\s*/, $self->{'sets'})];
    }
    if ($#$dbs == -1) {
	$dbs = [qw(US DX)];
    }
    foreach my $db (@$dbs) {
	my $havedb = eval "require Ham::Callsign::DB::$db";
	if (!$havedb) {
	    Warn("failed to load Callsign DB support for type '$db'");
	} else {
	    $self->{'dbs'}{$db} = eval "new Ham::Callsign::DB::$db";
	    if (!$self->{'dbs'}{$db}) {
		Warn("failed to initialize a new '$db' database");
		Debug("$@");
	    } else {
		$self->{'dbs'}{$db}{'master'} = $self;
		$self->{'dbs'}{$db}{'dbh'} = $self->{'dbh'};
		push @{$self->{'dblist'}}, $db;
		Debug("loaded callsign DB support for $db\n");
	    }
	}
    }
}

########################################
# main functions

sub create_tables {
    my ($self) = @_;
    foreach my $db (@{$self->{'dblist'}}) {
	$self->{'dbs'}{$db}->do_create_tables();
    }
}

sub load_data {
    my ($self, $place) = @_;
    foreach my $db (@{$self->{'dblist'}}) {
	$self->{'dbs'}{$db}->do_load_data($place);
    }
}

sub lookup {
    my ($self, $callsign) = @_;
    my $ret;
    foreach my $db (@{$self->{'dblist'}}) {
	my $results = $self->{'dbs'}{$db}->do_lookup($callsign);
	push @$ret, @$results if ($results);
    }
    return $ret;
}

########################################
# stubs

# XXX: use caller() and/or AUTOLOAD to do this more generically

sub do_create_tables {
    my ($self) = @_;
    Warn(ref($self) . " does not implement create_tables");
}

sub do_load_data {
    my ($self, $place) = @_;
    Warn(ref($self) . " does not implement load_data");
}

sub do_lookup {
    my ($self, $callsign) = @_;
    Warn(ref($self) . " does not implement lookup");
}



1;

=pod

=head1 NAME

Ham::Callsign::DB

=head1 SYNOPSIS

  use Ham::Callsign::DB;
  my $db = new Ham::Callsign::DB();

  # bootstrap everything and load the US database backend
  $db->initialize_dbs(["US"]);

  # load data from a given file set
  # (not all backends need this)
  $db->load_data("/path/to/fccdownloaddir");

  # search the database and get an array reference of callsign data
  $results = $db->lookup("WS6Z");

  # create a formatter to display the results
  #   current available types:  "Format" and "Dump"
  my $formatter = new Ham::Callsign::Display::Format;

  $formatter->display($results);

  $formatter->display($results, "%{8.8:thecallsign} %{first_name}");

=head1 DESCRIPTION

More details can be found in the cs(1) manual.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

cs(1)

=cut


