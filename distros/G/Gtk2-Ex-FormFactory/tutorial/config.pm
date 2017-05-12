# $Id: config.pm,v 1.1 2005/07/04 13:46:36 joern Exp $

package Music::Config;

use strict;

sub get_dbi_source		{ shift->{dbi_source}			}
sub get_dbi_username		{ shift->{dbi_username}			}
sub get_dbi_password		{ shift->{dbi_password}			}
sub get_dbi_test_message	{ shift->{dbi_test_message}		}

sub set_dbi_source		{ shift->{dbi_source}		= $_[1]	}
sub set_dbi_username		{ shift->{dbi_username}		= $_[1]	}
sub set_dbi_password		{ shift->{dbi_password}		= $_[1]	}
sub set_dbi_test_message	{ shift->{dbi_test_message}	= $_[1]	}

sub get_filename		{ "music.conf" }

sub get_connection_data {
	my $self = shift;
	return ($self->get_dbi_source,
		$self->get_dbi_username,
		$self->get_dbi_password);
}

sub get_db_connection_ok	{ shift->{db_connection_ok}		}
sub set_db_connection_ok	{ shift->{db_connection_ok}	= $_[1]	}

sub new {
	my $class = shift;
	
	my $filename = $class->get_filename;

	my $self;
	if ( -f $filename ) {
		$self = do $filename;
	} else {
		$self = bless {
			db_connection_ok	=> 0,
			dbi_source		=> "dbi:mysql:gtk2ff",
			dbi_username		=> "",
			dbi_password		=> "",
		}, $class;
	}
	
	$Music::Config::instance = $self;
	
	return $self;
	
}

sub test_db_connection {
	my $self = shift;
	require DBI;
	my $dbh = eval { DBI->connect($self->get_connection_data) };
	my $ok = $dbh?1:0;
	$self->set_db_connection_ok($ok);
	$dbh->disconnect if $dbh;
	if ( $ok ) {
		require "model.pm" if $ok;
		$self->set_dbi_test_message("<b>Connection Ok</b>");
	} else {
		$self->set_dbi_test_message("<b>$DBI::errstr</b>");
	}
	return $ok;
}

sub save {
	my $self = shift;
	
	require Data::Dumper;
	require FileHandle;
	
	my $dd = Data::Dumper->new ( [$self], ['self'] );
	$dd->Indent(1);
	my $data = $dd->Dump;

	my $file = $self->get_filename;
	my $fh   = FileHandle->new;

	open ($fh, ">$file") or die "can't write $file";
	print $fh $data;
	close $fh;
	
	1;
}

1;

