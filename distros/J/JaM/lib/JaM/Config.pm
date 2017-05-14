# $Id: Config.pm,v 1.2 2001/08/10 20:12:25 joern Exp $

package JaM::Config;

use strict;
use Data::Dumper;
use Carp;

sub dbh 		{ shift->{dbh}		}
sub config		{ shift->{config}	}

sub new {
	my $type = shift;
	my %par = @_;
	my  ($dbh) = @par{'dbh'};

	my %config;
	my $sth = $dbh->prepare (
		"select name, description, value, visible, type
		 from   Config"
	);
	$sth->execute;

	my $href;
	while ( $href = $sth->fetchrow_hashref ) {
		my %entry = %{$href};
		$config{$href->{name}} = \%entry;
		if ( $entry{type} eq 'list' ) {
			$entry{value} = eval $entry{value};
		}
	}

	$sth->finish;

	my $self = {
		dbh    		=> $dbh,
		config		=> \%config,
	};
	
	return bless $self, $type;
}

sub get_value {
	my $self = shift;
	my ($name) = @_;
	my $config = $self->config;
	confess "Unknown config parameter '$name'"
		if not exists $config->{$name};
	return $config->{$name}->{value};
}

sub set_value {
	my $self = shift;
	my ($name, $value) = @_;
	my $config = $self->config;
	confess "Unknown config parameter '$name'"
		if not exists $config->{$name};

	my $db_value = $value;
	$config->{$name}->{value} = $value;

	if ( $config->{$name}->{type} eq 'list' ) {
		my $dump = Dumper($value);
		$dump =~ s/^.VAR.\s*=\s*//;
		$db_value = $dump;
	}
	
	$self->dbh->do (
		"update Config set value=? where name=?", {},
		$db_value, $name
	);
	
	return $value;
}

sub set_temporary {
	my $self = shift;
	my ($name, $value) = @_;
	$self->config->{$name}->{value} = $value;
}

sub entries_by_type {
	my $self = shift;
	my ($type) = @_;
	
	my %result;
	my $config = $self->config;
	my ($k, $v);
	while ( ($k, $v) = each %{$config} ) {
		$result{$k} = $v if $v->{type} eq $type;
	}
	
	return \%result;
}

1;
