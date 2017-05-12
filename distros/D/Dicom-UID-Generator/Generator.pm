package Dicom::UID::Generator;

# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Utils qw(set_params);
use DateTime::HiRes;
use English;
use Readonly;

# Version.
our $VERSION = 0.01;

# Constants.
Readonly::Scalar our $EMPTY_STR => q{};

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Library number.
	$self->{'library_number'} = undef;

	# Model number.
	$self->{'model_number'} = undef;

	# Serial number.
	$self->{'serial_number'} = undef;

	# TimeZone.
	$self->{'timezone'} = 'Europe/Prague';

	# UID counter.
	$self->{'uid_counter'} = 0;

	# Process parameters.
	set_params($self, @params);

	return $self;
}

# Create series instance UID.
sub create_series_instance_uid {
	my $self = shift;
	return $self->create_uid($self->_root_uid.'.1.3');
}

# Create SOP instance UID.
sub create_sop_instance_uid {
	my $self = shift;
	return $self->create_uid($self->_root_uid.'.1.4');
}

# Create study instance UID.
sub create_study_instance_uid {
	my $self = shift;
	return $self->create_uid($self->_root_uid.'.1.2');
}

# Create UID.
sub create_uid {
	my ($self, $prefix) = @_;
	my $uid = $prefix;
	$uid .= '.'.$PID;
	$uid .= '.'.DateTime::HiRes->now->set_time_zone($self->{'timezone'})
		->strftime('%Y%m%d%H%M%S%3N');
	$self->{'uid_counter'}++;
	$uid .= '.'.$self->{'uid_counter'};
	return $uid;
}

# Add part of UID.
sub _add_part {
	my ($self, $uid_part_sr, $part) = @_;
	if (defined $self->{$part}) {
		if (${$uid_part_sr} ne $EMPTY_STR) {
			${$uid_part_sr} .= '.';
		}
		${$uid_part_sr} .= $self->{$part};
	}
	return;
}

# Get root UID.
sub _root_uid {
	my $self = shift;
	my $uid_part = $EMPTY_STR;
	$self->_add_part(\$uid_part, 'library_number');
	$self->_add_part(\$uid_part, 'model_number');
	$self->_add_part(\$uid_part, 'serial_number');
	return $uid_part;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Dicom::UID::Generator - DICOM UID generator.

=head1 SYNOPSIS

 use Dicom::UID::Generator;
 my $obj = Dicom::UID::Generator->new(%params);
 my $uid = $obj->create_series_instance_uid;
 my $uid = $obj->create_sop_instance_uid;
 my $uid = $obj->create_study_instance_uid;
 my $uid = $obj->create_uid($prefix);

=head1 METHODS

=over 8

=item C<new(%params)>

 Constructor.

=over 8

=item * C<library_number>

 DICOM library number.
 Default value is undef.

=item * C<model_number>

 Device model number.
 Default value is undef.

=item * C<serial_number>

 Device serial number.
 Default value is undef.

=item * C<timezone>

 Time zone for time in UID..
 Default value is 'Europe/Prague'.

=item * C<uid_counter>

 UID counter number for part of final UID.
 Default value is 0.

=back

=item C<create_series_instance_uid()>

 Get DICOM Series Instance UID.
 Returns string.

=item C<create_sop_instance_uid()>

 Get DICOM SOP Instance UID.
 Returns string.

=item C<create_study_instance_uid()>

 Get DICOM Study Instance UID.
 Returns string.

=item C<create_uid($prefix)>

 Get DICOM UID defined by prefix.
 Returns string.

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
 use Dicom::UID::Generator;

 # Object.
 my $obj = Dicom::UID::Generator->new(
       'library_number' => 999,
       'model_number' => '001',
       'serial_number' => 123,
 );

 # Get Series Instance UID.
 my $series_instance_uid = $obj->create_series_instance_uid;

 # Get Study Instance UID.
 my $study_instance_uid = $obj->create_study_instance_uid;

 # Get SOP Instance UID.
 my $sop_instance_uid = $obj->create_sop_instance_uid;

 # Print out.
 print "Study Instance UID: $study_instance_uid\n";
 print "Series Instance UID: $series_instance_uid\n";
 print "SOP Instance UID: $sop_instance_uid\n";

 # Output like:
 # Study Instance UID: 999.001.123.1.2.976.20160825112022726.2
 # Series Instance UID: 999.001.123.1.3.976.20160825112022647.1
 # SOP Instance UID: 999.001.123.1.4.976.20160825112022727.3

 # Comments:
 # 999 is DICOM library number.
 # 001 is device model number.
 # 123 is device serial number.
 # 1.2, 1.3, 1.4 are hardcoded resolutions of DICOM UID type.
 # 976 is PID of process.
 # 20160825112022726 is timestamp.
 # last number is number of 'uid_counter' parameter.

=head1 DEPENDENCIES

L<Class::Utils>,
L<DateTime::HiRes>,
L<English>,
L<Readonly>,

=head1 SEE ALSO

=over

=item L<Task::Dicom>

Install the Dicom modules.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/Dicom-UID-Generator>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © Michal Špaček 2016
 BSD 2-Clause License

=head1 VERSION

0.01

=cut
