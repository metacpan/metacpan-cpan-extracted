package Dicom::DCMTK::DCMQRSCP::Config;

# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Utils qw(set_params);

# Version.
our $VERSION = 0.03;

# Constructor.
sub new {
	my ($class, @params) = @_;
	my $self = bless {}, $class;

	# Defaults.
	$self->_default;

	# Comment.
	$self->{'comment'} = 1;

	# Process params.
	set_params($self, @params);

	# Object.
	return $self;
}

# Parse configuration.
sub parse {
	my ($self, $data) = @_;
	$self->_default;
	my $stay = 0;
	foreach my $line (split m/\n/ms, $data) {
		if ($line =~ m/^\s*#/ms || $line =~ m/^\s*$/ms) {
			next;
		}
		if (($stay == 0 || $stay == 1)
			&& $line =~ m/^\s*(\w+)\s*=\s*"?(\w+)"?\s*$/ms) {

			$stay = 1;
			$self->{'global'}->{$1} = $2;

		# Begin of host table.
		} elsif ($stay == 1
			&& $line =~ m/^\s*HostTable\s+BEGIN\s*$/ms) {

			$stay = 2;

		# End of host table.
		} elsif ($stay == 2 
			&& $line =~ m/^\s*HostTable\s+END\s*$/ms) {

			$stay = 1;

		# Host in host table.
		} elsif ($stay == 2
			&& $line =~ m/^\s*(\w+)\s*=\s*\(([\d\.\w\s,]+)\)\s*$/ms) {

			$self->{'host_table'}->{$1} = [split m/\s*,\s*/ms, $2];

		# Symbolic names in host table.
		} elsif ($stay == 2
			&& $line =~ m/^\s*(\w+)\s*=\s*([\w\s,]+)\s*$/ms) {

			$self->{'host_table_symb'}->{$1}
				= [split m/\s*,\s*/ms, $2];

		# Begin of AE table.
		} elsif ($stay == 1 && $line =~ m/^\s*AETable\s+BEGIN\s*$/ms) {
			$stay = 3;

		# End of AE table
		} elsif ($stay == 3 && $line =~ m/^\s*AETable\s+END\s*$/ms) {
			$stay = 1;

		# AE item.
		} elsif ($stay == 3
			&& $line =~ m/^\s*(\w+)\s+([\/\w]+)\s+(\w+)\s+\(([^)]+)\)\s+(.*)$/ms) {

			my ($maxStudies, $maxBytesPerStudy)
				= split m/\s*,\s*/ms, $4;
			$self->{'ae_table'}->{$1} = {
				'StorageArea' => $2,
				'Access' => $3,
				'Quota' => {
					'maxStudies' => $maxStudies,
					'maxBytesPerStudy' => $maxBytesPerStudy,
				},
				'Peers' => $5,
			};

		# Begin of vendor table
		} elsif ($stay == 1
			&& $line =~ m/^\s*VendorTable\s+BEGIN\s*$/ms) {

			$stay = 4;

		# End of vendor table.
		} elsif ($stay == 4
			&& $line =~ m/^\s*VendorTable\s+END\s*$/ms) {

			$stay = 1;

		# Item in vendor table.
		} elsif ($stay == 4
			&& $line =~ m/^\s*"([^"]+)"\s*=\s*(\w+)\s*$/ms) {

			$self->{'vendor_table'}->{$2} = $1;
		}
	}
	return;
}

# Serialize to configuration.
sub serialize {
	my $self = shift;
	my @data;
	$self->_serialize_global(\@data);
	$self->_serialize_hosts(\@data);
	$self->_serialize_vendors(\@data);
	$self->_serialize_ae(\@data);
	return join "\n", @data;
}

# Set variables to defaults.
sub _default {
	my $self = shift;
	
	# AE table.
	$self->{'ae_table'} = {};

	# Global parameters.
	$self->{'global'} = {
		'NetworkTCPPort' => undef,
		'MaxPDUSize' => undef,
		'MaxAssociations' => undef,
		'UserName' => undef,
		'GroupName' => undef,
	};

	# Host table.
	$self->{'host_table'} = {};

	# Host table symbolic names.
	$self->{'host_table_symb'} = {};

	# Vendor table.
	$self->{'vendor_table'} = {};

	return;
}

# Serialize AE titles.
sub _serialize_ae {
	my ($self, $data_ar) = @_;
	if (! keys %{$self->{'ae_table'}}) {
		return;
	}
	if ($self->{'comment'}) {
		if (@{$data_ar}) {
			push @{$data_ar}, '';
		}
		push @{$data_ar}, '# AE Table.';
	}
	push @{$data_ar}, 'AETable BEGIN';
	foreach my $key (sort keys %{$self->{'ae_table'}}) {
		my $storage_area = $self->{'ae_table'}->{$key}->{'StorageArea'};
		my $access = $self->{'ae_table'}->{$key}->{'Access'};
		my $peers = $self->{'ae_table'}->{$key}->{'Peers'};
		my $max_studies = $self->{'ae_table'}->{$key}->{'Quota'}
			->{'maxStudies'};
		my $max_bytes_per_study = $self->{'ae_table'}->{$key}
			->{'Quota'}->{'maxBytesPerStudy'};
		push @{$data_ar}, "$key $storage_area $access ".
			"($max_studies, $max_bytes_per_study) $peers";
	}
	push @{$data_ar}, 'AETable END';
	return;
}

# Serialize global parameters.
sub _serialize_global {
	my ($self, $data_ar) = @_;
	if (! map { defined $self->{'global'}->{$_} ? $_ : () }
		keys %{$self->{'global'}}) {

		return;
	}
	if ($self->{'comment'}) {
		if (@{$data_ar}) {
			push @{$data_ar}, '';
		}
		push @{$data_ar}, '# Global Configuration Parameters.';
	}
	foreach my $key (sort keys %{$self->{'global'}}) {
		if (! defined $self->{'global'}->{$key}) {
			next;
		}
		my $value = $self->{'global'}->{$key};
		if ($value !~ m/^\d+$/ms) {
			$value = '"'.$value.'"';
		}
		push @{$data_ar}, $key.' = '.$value;
	}
	return;
}

# Serialize hosts table.
sub _serialize_hosts {
	my ($self, $data_ar) = @_;
	if (! keys %{$self->{'host_table'}}) {
		return;
	}
	if ($self->{'comment'}) {
		if (@{$data_ar}) {
			push @{$data_ar}, '';
		}
		push @{$data_ar}, '# Host Table.';
	}
	push @{$data_ar}, 'HostTable BEGIN';
	foreach my $key (sort keys %{$self->{'host_table'}}) {
		my ($ae, $host, $port) = @{$self->{'host_table'}->{$key}};
		push @{$data_ar}, "$key = ($ae, $host, $port)";
	}
	foreach my $key (sort keys %{$self->{'host_table_symb'}}) {
		push @{$data_ar}, "$key = ".
			(join ", ", @{$self->{'host_table_symb'}->{$key}});
	}
	push @{$data_ar}, 'HostTable END';
	return;
}

# Serialize vendors table.
sub _serialize_vendors {
	my ($self, $data_ar) = @_;
	if (! keys %{$self->{'vendor_table'}}) {
		return;
	}
	if ($self->{'comment'}) {
		if (@{$data_ar}) {
			push @{$data_ar}, '';
		}
		push @{$data_ar}, '# Vendor Table.';
	}
	push @{$data_ar}, 'VendorTable BEGIN';
	foreach my $key (sort keys %{$self->{'vendor_table'}}) {
		my $desc = '"'.$self->{'vendor_table'}->{$key}.'"';
		push @{$data_ar}, "$desc = $key";
	}
	push @{$data_ar}, 'VendorTable END';
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Dicom::DCMTK::DCMQRSCP::Config - Perl class for reading/writing DCMTK dcmqrscp configuration file.

=head1 SYNOPSIS

 use Dicom::DCMTK::DCMQRSCP::Config;
 my $obj = Dicom::DCMTK::DCMQRSCP::Config->new(%parameters);
 $obj->parse($data);
 my $data = $obj->serialize;

=head1 METHODS

=over 8

=item C<new(%parameters)>

Constructor.

=over 8

=item * C<ae_table>

 AE table.
 Default value is {}.

=item * C<comment>

 Flag, that means comments in serialize() output.
 Default value is 1.

=item * C<global>

 Global parameters.
 Default value is {
         'NetworkTCPPort' => undef,
         'MaxPDUSize' => undef,
         'MaxAssociations' => undef,
         'UserName' => undef,
         'GroupName' => undef,
 };

=item * C<host_table>

 Host table.
 Default value is {}.

=item * C<host_table_symb>

 Host table symbolic names.
 Default value is {}.

=item * C<vendor_table>

 Vendor table.
 Default value is {}.

=back

=item C<parse($data)>

 Parse $data, which contains dcmqrscp configuration data.
 Returns undef.

=item C<serialize()>

 Serialize object to DCMTK dcmqrscp configuration data.
 Returns string with dcmqrscp configuration data.

=back

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Dicom::DCMTK::DCMQRSCP::Config;

 # Object.
 my $obj = Dicom::DCMTK::DCMQRSCP::Config->new(
         'ae_table' => {
                 'ACME_PUB' => {
                         'Access' => 'R',
                         'Peers' => 'ANY',
                         'Quota' => {
                                 'maxBytesPerStudy' => '24mb',
                                 'maxStudies' => '10',
                         },
                         'StorageArea' => '/dicom/ACME_PUB',
                 },
                 'ACME_PRV' => {
                         'Access' => 'RW',
                         'Peers' => 'Acme',
                         'Quota' => {
                                 'maxBytesPerStudy' => '24mb',
                                 'maxStudies' => '10',
                         },
                         'StorageArea' => '/dicom/ACME_PRV',
                 },
         },
         'comment' => 1,
         'global' => {
                 'GroupName' => 'dcmtk',
                 'MaxAssociations' => 20,
                 'MaxPDUSize' => 8192,
                 'NetworkTCPPort' => 104,
                 'UserName' => 'dcmtk',
         },
         'host_table' => {
                 'Acme_1' => [
                         'ACME_DN1',
                         'acme',
                         10001
                 ],
                 'Acme_2' => [
                         'ACME_DN2',
                         'acme',
                         10001
                 ],
                 'Acme_3' => [
                         'ACME_DN3',
                         'acme',
                         10001
                 ],
         },
         'host_table_symb' => {
                 'Acme' => [
                         'Acme_1',
                         'Acme_2',
                         'Acme_3',
                 ],
         },
         'vendor_table' => {
                 'Acme' => 'ACME CT Company',
         },
 );

 # Serialize and print
 print $obj->serialize."\n";

 # Output:
 # # Global Configuration Parameters.
 # GroupName = "dcmtk"
 # MaxAssociations = 20
 # MaxPDUSize = 8192
 # NetworkTCPPort = 104
 # UserName = "dcmtk"
 # 
 # # Host Table.
 # HostTable BEGIN
 # Acme_1 = (ACME_DN1, acme, 10001)
 # Acme_2 = (ACME_DN2, acme, 10001)
 # Acme_3 = (ACME_DN3, acme, 10001)
 # Acme = Acme_1, Acme_2, Acme_3
 # HostTable END
 # 
 # # Vendor Table.
 # VendorTable BEGIN
 # "ACME CT Company" = Acme
 # VendorTable END
 # 
 # # AE Table.
 # AETable BEGIN
 # ACME_PRV /dicom/ACME_PRV RW (10, 24mb) Acme
 # ACME_PUB /dicom/ACME_PUB R (10, 24mb) ANY
 # AETable END

=head1 DEPENDENCIES

L<Class::Utils>.

=head1 SEE ALSO

=over

=item L<Task::Dicom>

Install the Dicom modules.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/Dicom-DCMTK-DCMQRSCP-Config>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2014-2015 Michal Špaček
 BSD 2-Clause License

=head1 VERSION

0.03

=cut
