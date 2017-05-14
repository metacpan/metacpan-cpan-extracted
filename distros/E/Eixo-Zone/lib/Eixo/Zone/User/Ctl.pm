package Eixo::Zone::User::Ctl;

use strict;

sub uid_map_get{
	my ($self, $pid, %args) = @_;

	my $f;

	open($f, "/proc/$pid/uid_map") || 

		die("Eixo::Zone::User::Ctl::uid_map: error $!");

	my @data = grep { $_ =~ /[^\s]/} <$f>;

	close $f;

	$self->__formatIn(@data);
}

	sub __formatIn{
		my ($self, @lines) = @_;

		my %data;

		foreach(@lines){

			my ($id_in, $id_out, $length) = $_ =~ /(\d+)\s+(\d+)\s+(\d+)/;

			$data{$id_in} = {
				in=>$id_in,
				out=>$id_out,
				length=>$length
			};

		}

		%data;
	}

1;
