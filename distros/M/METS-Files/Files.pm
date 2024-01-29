package METS::Files;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use METS::Parse::Simple;
use Readonly;

Readonly::Scalar our $EMPTY_STR => q{};

our $VERSION = 0.03;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# METS Data.
	$self->{'mets_data'} = undef;

	# Process parameters.
	set_params($self, @params);

	# Check METS data.
	if (! defined $self->{'mets_data'}) {
		err "Parameter 'mets_data' is required.";
	}
	$self->{'_mets'} = METS::Parse::Simple->new->parse($self->{'mets_data'});

	# Compute prefix.
	$self->{'_prefix'} = $EMPTY_STR;
	if (exists $self->{'_mets'}->{'xmlns:mets'}) {
		$self->{'_prefix'} = 'mets:';
	}

	return $self;
}

# Get img files.
sub get_use_files {
	my ($self, $use) = @_;

	my @files;
	if (exists $self->{'_mets'}->{$self->{'_prefix'}.'fileSec'}
		&& exists $self->{'_mets'}->{$self->{'_prefix'}.'fileSec'}
		->{$self->{'_prefix'}.'fileGrp'}) {

		foreach my $mets_file_grp_hr (@{$self->{'_mets'}
			->{$self->{'_prefix'}.'fileSec'}
			->{$self->{'_prefix'}.'fileGrp'}}) {

			if ($mets_file_grp_hr->{'USE'} eq $use) {
				foreach my $file_hr (@{$mets_file_grp_hr
					->{$self->{'_prefix'}.'file'}}) {

					push @files, $file_hr
						->{$self->{'_prefix'}.'FLocat'}
						->{'xlink:href'};
				}
			}
		}
	}

	return @files;
}

sub get_use_types {
	my $self = shift;

	# Get file types.
	my @file_types;
	if (exists $self->{'_mets'}->{$self->{'_prefix'}.'fileSec'}
		&& exists $self->{'_mets'}->{$self->{'_prefix'}.'fileSec'}
			->{$self->{'_prefix'}.'fileGrp'}) {

		foreach my $mets_file_grp_hr (@{$self->{'_mets'}
			->{$self->{'_prefix'}.'fileSec'}
			->{$self->{'_prefix'}.'fileGrp'}}) {

			push @file_types, $mets_file_grp_hr->{'USE'};
		}
	}

	return @file_types;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

METS::Files - Class for METS files manipulation.

=head1 SYNOPSIS

 use METS::Files;

 my $obj = METS::Files->new(
         'mets_data' => $mets_data,
 );
 my @files = $obj->get_use_files($use);
 my @types = $obj->get_use_types;

=head1 METHODS

=head2 C<new>

 my $obj = METS::Files->new(
         'mets_data' => $mets_data,
 );

Constructor.

=over 8

=item * C<mets_data>

METS data.

Parameter is required.

=back

Returns instance of object.

=head2 C<get_use_files>

 my @files = $obj->get_use_files($use);

Get "USE" files defined by C<$use> variable.

Returns array with files.

=head2 C<get_use_types>

 my @types = $obj->get_use_types;

Get "USE" types.

Returns array with types.

=head1 ERRORS

 new():
	 Parameter 'mets_data' is required.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE1

=for comment filename=extract_mets_files.pl

 use strict;
 use warnings;

 use Data::Printer;
 use METS::Files;
 use Perl6::Slurp qw(slurp);

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 mets_file\n";
         exit 1;
 }
 my $mets_file = $ARGV[0];

 # Get mets data.
 my $mets_data = slurp($mets_file);

 # Object.
 my $obj = METS::Files->new(
         'mets_data' => $mets_data,
 );

 # Get files.
 my $files_hr;
 foreach my $use ($obj->get_use_types) {
         $files_hr->{$use} = [$obj->get_use_files($use)];
 }

 # Dump to output.
 p $files_hr;

 # Output without arguments like:
 # Usage: __SCRIPT__ mets_file

=head1 EXAMPLE2

=for comment filename=extract_mets_files_inline.pl

 use strict;
 use warnings;

 use Data::Printer;
 use METS::Files;

 # Example METS data.
 my $mets_data = <<'END';
 <?xml version="1.0" encoding="UTF-8"?>
 <mets xmlns:xlink="http://www.w3.org/TR/xlink">
   <fileSec>
     <fileGrp ID="IMGGRP" USE="Images">
       <file ID="IMG00001" CREATED="2006-06-20T12:00:00" ADMID="IMGPARAM00001" MIMETYPE="image/tiff" SEQ="1" SIZE="5184000" GROUPID="1">
         <FLocat LOCTYPE="URL" xlink:href="file://./003855/003855r.tif" />
       </file>
       <file ID="IMG00002" CREATED="2006-06-20T12:00:00" ADMID="IMGPARAM00002" MIMETYPE="image/tiff" SEQ="2" SIZE="5200228" GROUPID="2">
         <FLocat LOCTYPE="URL" xlink:href="file://./003855/003855v.tif" />
       </file>
     </fileGrp>
     <fileGrp ID="PDFGRP" USE="PDF">
       <file ID="PDF00001" CREATED="2006-06-20T12:00:00" ADMID="IMGPARAM00001" MIMETYPE="text/pdf" SEQ="1" SIZE="251967" GROUPID="1">
         <FLocat LOCTYPE="URL" xlink:href="file://./003855/003855r.pdf" />
       </file>
       <file ID="PDF00002" CREATED="2006-06-20T12:00:00" ADMID="IMGPARAM00002" MIMETYPE="text/pdf" SEQ="2" SIZE="172847" GROUPID="2">
         <FLocat LOCTYPE="URL" xlink:href="file://./003855/003855v.pdf" />
       </file>
     </fileGrp>
   </fileSec>
 </mets>
 END

 # Object.
 my $obj = METS::Files->new(
         'mets_data' => $mets_data,
 );

 # Get files.
 my $files_hr;
 foreach my $use ($obj->get_use_types) {
         $files_hr->{$use} = [$obj->get_use_files($use)];
 }

 # Dump to output.
 p $files_hr;

 # Output:
 # \ {
 #     Images   [
 #         [0] "file://./003855/003855r.tif",
 #         [1] "file://./003855/003855v.tif"
 #     ],
 #     PDF      [
 #         [0] "file://./003855/003855r.pdf",
 #         [1] "file://./003855/003855v.pdf"
 #     ]
 # }


=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<METS::Parse::Simple>,
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/METS-Files>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2015-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
