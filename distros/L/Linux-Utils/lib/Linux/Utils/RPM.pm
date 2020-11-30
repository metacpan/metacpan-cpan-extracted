package Linux::Utils::RPM;
$Linux::Utils::RPM::VERSION = '0.002';
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Data::Printer alias => 'pdump';
use Kavorka 'method';

with
  'Util::Medley::Roles::Attributes::Spawn',
  'Util::Medley::Roles::Attributes::String';

=head1 NAME

Linux::Utils::RPM - Wrapper class for the 'rpm' command.

=head1 VERSION

version 0.002

=cut

=head1 SYNOPSIS

  $rpm = Linux::Utils::RPM->new;
  
  $aref = $rpm->queryAll(rpmName => $rpmName);

=cut

########################################################

=head1 ATTRIBUTES

none

=head1 METHODS

=head2 queryAll

Query all installed packages.

Returns: ArrayRef[Str]

=over

=item usage:

 $aref = $rpm->queryAll([rpmName => $rpmName]);
 
=item args:

=over

=item rpmName [Str] (optional)

The name of the rpm package to query.  This arg can contain wildcards.

=back

=back

=cut

method queryAll (Str :$rpmName) {

	my @cmd;
	push @cmd, 'rpm';
	push @cmd, '--query';
	push @cmd, '--all';
	push @cmd, $rpmName if $rpmName;

	my ( $stdout, $stderr, $exit ) =
	  $self->Spawn->capture( cmd => \@cmd, wantArrayRef => 1 );
	if ($exit) {
		confess $stderr;
	}

	return $stdout;
}

=head2 queryFileOwner

Query for the package owner of a given file.

Returns: Str|Undef

=over

=item usage:

 $owner = $rpm->queryFileOwner(file => $file);
 
=item args:

=over

=item file [Str] 

The name of the file you wish to search with.

=back

=back

=cut

method queryFileOwner (Str :$file!) {

    my @cmd;
    push @cmd, 'rpm';
    push @cmd, '--query';
    push @cmd, '--file';
    push @cmd, $file;

    my ( $stdout, $stderr, $exit ) =
      $self->Spawn->capture( cmd => \@cmd, wantArrayRef => 0 );
    if ($exit) {
        confess $stderr;
    }

    return $stdout;
}

=head2 queryList

List files in package.

Returns: ArrayRef[Str]

=over

=item usage:

 $aref = $rpm->queryList(rpmName => $rpmName);
 
=item args:

=over

=item rpmName [Str] (required)

The name of the rpm package to query.

=back

=back

=cut

method queryList (Str :$rpmName!) {

	my @cmd;
	push @cmd, 'rpm';
	push @cmd, '--query';
	push @cmd, '--list';
	push @cmd, $rpmName;

	my ( $stdout, $stderr, $exit ) =
	  $self->Spawn->capture( cmd => \@cmd, wantArrayRef => 1 );
	if ($exit) {
		confess $stderr;
	}

	return $stdout;
}

#################################################################3

__PACKAGE__->meta->make_immutable;

1;
