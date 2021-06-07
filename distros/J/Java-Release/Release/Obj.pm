package Java::Release::Obj;

use strict;
use warnings;

use Error::Pure qw(err);
use List::MoreUtils qw(none);
use Mo qw(default coerce is required);

our $VERSION = 0.06;

# Computer architecture
has arch => (
	is => 'ro',
	required => 1,
);

# Interim version.
has interim => (
	is => 'ro',
);

# Operating system.
has os => (
	is => 'ro',
	required => 1,
);

# Patch version.
has patch => (
	is => 'ro',
);

# Release version.
has release => (
	is => 'ro',
	required => 1,
);

# Update version.
has update => (
	is => 'ro',
);

# Version.
sub version {
	my ($self, $type) = @_;

	if ($type && none { $type eq $_ } qw(old new)) {
		err "Bad version type. Possible values are 'new' or 'old'.",
			'type', $type;
	}
	$type //= 'new';

	my $version = $self->release;

	# Version like 'release'.'interim'.'update'.'patch'
	if ($type eq 'new') {
		if ($self->update) {
			if ($self->interim) {
				$version .= '.'.$self->interim;
			} else {
				$version .= '.0';
			}
			$version .= '.'.$self->update;
			if ($self->patch) {
				$version .= '.'.$self->patch;
			}
		}

	# Version like 'release'u'update'
	} else {
		if ($self->interim || $self->patch) {
			err 'Cannot create old version of version with '.
				'interim or patch value.';
		}
		if ($self->update) {
			$version .= 'u'.$self->update;
		}
	}

	return $version;
}

# Version name.
sub version_name {
	my $self = shift;

	my $version_name = 'Java '.$self->release;
	if ($self->interim) {
		$version_name .= ' Major '.$self->interim;
	}
	if ($self->update) {
		$version_name .= ' Update '.$self->update;
	} else {
		$version_name .= ' GA';
	}

	return $version_name;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Java::Release::Obj - Data object for Java::Release.

=head1 SYNOPSIS

 use Java::Release::Obj;

 my $obj = Java::Release::Obj->new(%params);
 my $arch = $obj->arch
 my $interim = $obj->interim;
 my $os = $obj->os;
 my $patch = $obj->patch;
 my $release = $obj->release;
 my $update = $obj->update;
 my $version = $obj->version($type);
 my $version_name = $obj->version_name;

=head1 METHODS

=head2 C<constructor>

 my $obj = Java::Release::Obj->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<arch>

Architecture.

Parameter is required.

=item * C<interim>

Interim version number.

Parameter is optional.

Default values is undef.

=item * C<os>

Operating system.

Parameter is required.

=item * C<patch>

Patch version number.

Parameter is optional.

Default values is undef.

=item * C<release>

Release version number.

Parameter is required.

=item * C<update>

Update version number.

Parameter is optional.

Default values is undef.

=back

=head2 C<arch>

 my $arch = $obj->arch

Get architecture.

Returns string.

=head2 C<interim>

 my $interim = $obj->interim;

Get interim version number.

Returns integer.

=head2 C<os>

 my $os = $obj->os;

Get operating system.

Returns string.

=head2 C<patch>

 my $patch = $obj->patch;

Get patch version number.

Returns integer.

=head2 C<release>

 my $release = $obj->release;

Get release version number.

Returns integer.

=head2 C<update>

 my $update = $obj->update;

Get update version number.

Returns integer.

=head2 C<version>

 my $version = $obj->version($type);

Get version of release in short notation. There are two possibilities for C<$type>: 'new' (12.0.3) and 'old' (12u3)
string.

Returns string.

=head2 C<version_name>

 my $version_name = $obj->version_name;

Get version of release in character notation. There are two possibilities to write: new and old
version.

Returns string.

=head1 ERRORS

 version():
         Bad version type. Possible values are 'new' or 'old'.
                 type: %s
         Cannot create old version of version with interim or patch value.

=head1 EXAMPLE

 use strict;
 use warnings;

 use Data::Printer;
 use Java::Release::Obj;

 my $obj = Java::Release::Obj->new(
         arch => 'i386',
         os => 'linux',
         release => 1,
 );

 p $obj;

 # Output like:
 # Java::Release::Obj  {
 #     Parents       Mo::Object
 #     public methods (0)
 #     private methods (0)
 #     internals: {
 #         arch      "i386",
 #         os        "linux",
 #         release   1
 #     }
 # }

=head1 DEPENDENCIES

L<Error::Pure>,
L<List::MoreUtils>,
L<Mo>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Java-Release>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2021 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.06

=cut
