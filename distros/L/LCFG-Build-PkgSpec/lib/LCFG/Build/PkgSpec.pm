package LCFG::Build::PkgSpec; # -*-perl-*-
use strict;
use warnings;

# $Id: PkgSpec.pm.in 35434 2019-01-18 10:43:38Z squinney@INF.ED.AC.UK $
# $Source: /var/cvs/dice/LCFG-Build-PkgSpec/lib/LCFG/Build/PkgSpec.pm.in,v $
# $Revision: 35434 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/LCFG-Build-PkgSpec/LCFG_Build_PkgSpec_0_2_7/lib/LCFG/Build/PkgSpec.pm.in $
# $Date: 2019-01-18 10:43:38 +0000 (Fri, 18 Jan 2019) $

our $VERSION = '0.2.7';

use v5.10;

use Data::Structure::Util ();
use DateTime ();
use Email::Address ();
use Email::Valid   ();
use IO::File ();
use Scalar::Util ();

use Moose;
use Moose::Util::TypeConstraints;

# A type and coercion to allow the attribute to be set as either an
# ref to an array or a scalar string.

subtype 'ArrayRefOrString' => as 'ArrayRef[Str]';
coerce  'ArrayRefOrString' => from 'Str' => via { [ split /\s*,\s*/, $_ ] };

subtype 'EmailAddress'
      => as 'Str'
      => where { Email::Valid->address( -address => $_ ) }
      => message { "Address ($_) for report must be a valid email address" };

subtype 'EmailAddressList'
      => as 'ArrayRef[EmailAddress]';

coerce 'EmailAddressList'
      => from 'Str'
      => via { [ map { $_->format } Email::Address->parse($_)] };

coerce 'EmailAddressList'
      => from 'ArrayRef'
      => via { [ map { $_->format } map { Email::Address->parse($_) } @{$_} ] };

subtype 'VersionString'
      => as 'Str'
      => where { $_ =~ m/^\d+\.\d+\.\d+(\.dev\d*)?$/ }
      => message { $_ = 'undef' if !defined $_; "Version string ($_) does not match the expected LCFG format." };

subtype 'ReleaseString'
      => as 'Str'
      => where { $_ =~ m/^\d+/ }
      => message { "Release string ($_) does not match the expected LCFG format." };

has 'name'      => ( is => 'rw', required => 1 );
has 'base'      => ( is => 'rw', default => q{} );
has 'abstract'  => ( is => 'rw' );

has 'version'   => (
    is       => 'rw',
    required => 1,
    isa      => 'VersionString',
    default  => '0.0.0',
);

has 'release'   => (
    is       => 'rw',
    isa      => 'Maybe[ReleaseString]',
    default  => 1,
);

has 'schema'    => (
    is       => 'rw',
    isa      => 'Int',
    default  => 1,
);

has 'group'     => ( is => 'rw');
has 'vendor'    => ( is => 'rw');
has 'license'   => ( is => 'rw');

has 'translate' => (
    is         => 'rw',
    isa        => 'ArrayRef[Str]',
    auto_deref => 1,
);

has 'date' => (
    is         => 'rw',
    isa        => 'Str',
    default    => sub { DateTime->now->strftime('%d/%m/%y %T') },
);

has 'metafile' => (
    is         => 'rw',
    isa        => 'Maybe[Str]',
);

# I would quite like to treat author and platforms as sets but that
# doesn't seem to be available at present.

has 'author' => (
    is         => 'rw',
    isa        => 'EmailAddressList',
    coerce     => 1,
    auto_deref => 1,
    default    => sub { [] },
);

has 'platforms' => (
    is         => 'rw',
    isa        => 'ArrayRefOrString',
    coerce     => 1,
    auto_deref => 1,
    default    => sub { [] },
);

has 'build' => (
    traits     => ['Hash'],
    is         => 'rw',
    isa        => 'HashRef[Str]',
    default    => sub { {} },
    lazy       => 1,
    handles   => {
       exists_in_buildinfo => 'exists',
       ids_in_buildinfo    => 'keys',
       get_buildinfo       => 'get',
       set_buildinfo       => 'set',
    },
);

has 'vcs' => (
    traits     => ['Hash'],
    is         => 'rw',
    isa        => 'HashRef[Str]',
    default    => sub { {} },
    handles   => {
       exists_in_vcsinfo => 'exists',
       ids_in_vcsinfo    => 'keys',
       get_vcsinfo       => 'get',
       set_vcsinfo       => 'set',
    },
);

has 'orgident' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'org.lcfg'
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub perl_version {
    my ($self) = @_;

    my $perl_version = $self->version;
    if ( $perl_version =~ s/\.dev\d*$// ) {

        # Cannot use a non-numeric in a Perl version string. A "devel"
        # version is signified with a suffix which is an underscore
        # and a release number. See "perldoc version" for details.

        $perl_version = join q{.}, $self->get_major, $self->get_minor, $self->get_micro;
        $perl_version .= q{_} . $self->release;
    }

    return $perl_version;
}

sub deb_version {
    my ($self) = @_;

    my $deb_version = $self->version;

    $deb_version =~ s/[^a-zA-Z0-9~.+-]//;

    return $deb_version;
}

sub get_major {
    my ($self) = @_;

    my $version = $self->version;

    my $major = (split /\./, $version)[0];

    return $major;
}

sub get_minor {
    my ($self) = @_;

    my $version = $self->version;

    my $minor = (split /\./, $version)[1];

    return $minor;
}

sub get_micro {
    my ($self) = @_;

    my $version = $self->version;

    my $micro = (split /\./, $version)[2];

    return $micro;
}

sub pkgident {
  my ($self) = @_;

  my $org  = $self->orgident;
  my $name = $self->fullname;
  my $id = join q{.}, $org, $name;

  return $id;
}

sub fullname {
    my ($self) = @_;

    my $fullname;
    if ( defined $self->base && length $self->base > 0 ) {
        $fullname = join q{-}, $self->base, $self->name;
    }
    else {
        $fullname = $self->name;
    }

    return $fullname;
}

sub deb_name {
    my ($self) = @_;

    # By convention debian package names are lower-case
    my $name = lc $self->fullname;

    # underscores are not permitted, helpfully replace with dashes
    $name =~ s/_/-/g;

    # For safety remove any other invalid characters
    $name =~ s/[^a-z0-9-]//;

    return $name;
}

sub tarname {
    my ( $self, $comp ) = @_;
    $comp ||= 'gz';

    my $packname = join q{-}, $self->fullname, $self->version;
    my $tarname  = $packname . ".tar.$comp";

    return $tarname;
}

sub deb_srctarname {
    my ( $self, $comp ) = @_;
    $comp ||= 'gz';

    my $packname = join q{_}, $self->deb_name, $self->deb_version;
    my $tarname  = $packname . ".orig.tar.$comp";

    return $tarname;
}

sub deb_tarname {
    my ( $self, $comp ) = @_;
    $comp ||= 'gz';

    my $packname = join q{_}, $self->deb_name, $self->deb_version;
    my $tarname  = $packname . "-1.debian.tar.$comp";

    return $tarname;
}

sub deb_dscname {
    my ($self) = @_;

    my $packname = join q{_}, $self->deb_name, $self->deb_version;
    my $dscname  = $packname . "-1.dsc";

    return $dscname;
}

sub rpmspec_name {
    my ( $self, $base ) = @_;

    return $self->fullname . '.spec';
}

sub clone {
    my ($self) = @_;

    require Storable;
    my $clone = Storable::dclone($self);

    return $clone;
}

sub new_from_metafile {
    my ( $class, $file ) = @_;

    if ( !defined $file || !length $file ) {
        die "Error: You need to specify the LCFG meta-data file name\n";
    }
    elsif ( !-f $file ) {
        die "Error: Cannot find LCFG meta-data file '$file'\n";
    }

    require YAML::Syck;
    my $data;
    {
        # Allow true/false, yes/no for booleans
        local $YAML::Syck::ImplicitTyping = 1;

        $data = YAML::Syck::LoadFile($file);

        # We unbless as previously saved metafiles are going to have a
        # blessing. We want all input files treated with the same
        # amount of contempt.

        Data::Structure::Util::unbless($data);
    }

    my $self = $class->new($data);

    $self->metafile($file);

    return $self;
}

sub new_from_cfgmk {
    my ( $proto, $file ) = @_;

    if ( !defined $file || !length $file ) {
        die "Error: You need to specify the LCFG config file name\n";
    }
    elsif ( !-f $file ) {
        die "Error: Cannot find LCFG config file '$file'\n";
    }

    my %translator = (
         COMP         => 'name',
         DESCR        => 'abstract',
         V            => 'version',
         R            => 'release',
         SCHEMA       => 'schema',
         GROUP        => 'group',
         AUTHOR       => 'author',
         ORGANIZATION => 'vendor',
         DATE         => 'date',
     );

    my %spec;

    my $in = IO::File->new( $file, 'r' ) or die "Could not open $file: $!\n";

    while ( defined ( my $line = <$in> ) ) {
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;

        while ( $line =~ m{^(.*?)\\$} ) {
            my $extra = <$in>;
            $line = $1 . $extra;
        }

        if ( $line =~ m/^([^=]+)=(.+)$/ ) {
            my ( $key, $value ) = ( $1, $2 );
            if ( exists $translator{$key} ) {
                $spec{ $translator{$key} } = $value;
            }
            elsif ( $key eq 'PLATFORMS' ) {
                my @platforms = split /,\s*/, $value;
                $spec{platforms} = [@platforms];
            }
            elsif ( $key eq 'NAME' ) {
                my $compname;
                if ( $value =~ m/^(.+?)-(.+?)$/ ) {
                    ( $spec{base}, $compname ) = ( $1, $2 );
                }
                else {
                    $compname = $value;
                }

                if ( $compname ne '$(COMP)' ) {
                    $spec{name} = $compname;
                }
            }
        }

    }

    $in->close;

    my $pkgspec;
    if ( !ref $proto ) {
        $spec{license} = 'GPLv2';
        $spec{vendor} ||= 'University of Edinburgh';
        $spec{vcs} = { logname => 'ChangeLog' };
        $spec{build} = { gencmake => 1 };
        $spec{translate} = [ '*.cin' ];
        $pkgspec = $proto->new(\%spec);
    }
    elsif ( defined Scalar::Util::blessed($proto) && $proto->isa(__PACKAGE__) ) {
        $pkgspec = $proto;
        for my $key ( keys %spec ) {
            $pkgspec->$key($spec{$key});
        }
    }
    else {
        die "Error: new_from_cfgmk method called on wrong class or object\n";
    }

    return $pkgspec;
}

sub save_metafile {
    my ( $self, $file ) = @_;

    $file ||= $self->metafile;

    if ( !defined $file || !length $file ) {
        die "Error: You need to specify the LCFG config file name\n";
    }

    require YAML::Syck;
    {
        local $YAML::Syck::SortKeys = 1;
        my $dump = \%{$self};
        delete $dump->{metafile};
        YAML::Syck::DumpFile( $file, $dump );
    }

    return;
}

sub dev_version {
    my ($self) = @_;

    $self->update_release;

    my $dev_version = 'dev' . $self->release;

    $dev_version = join q{.}, $self->get_major, $self->get_minor,
                              $self->get_micro, $dev_version;

    $self->version($dev_version);

    return $self->version;
}

sub update_release {
    my ($self) = @_;

    my $release = $self->release;

    if ( !defined $release ) {
        $release = 1;
    }
    else {
        $release++;
    }

    $self->release($release);

    return;
}

sub update_date {
    my ($self) = @_;

    my $now = DateTime->now->strftime('%d/%m/%y %T');

    $self->date($now);

    return;
}

sub update_major {
    my ($self) = @_;
    return $self->_update_version('major');
}

sub update_minor {
    my ($self) = @_;
    return $self->_update_version('minor');
}

sub update_micro {
    my ($self) = @_;
    return $self->_update_version('micro');
}

sub _update_version {
    my ( $self, $uptype ) = @_;

    my $major = $self->get_major;
    my $minor = $self->get_minor;
    my $micro = $self->get_micro;

    if ( $uptype eq 'major' ) {
        $major++;
        $minor = 0;
        $micro = 0;
    }
    elsif ( $uptype eq 'minor' ) {
        $minor++;
        $micro = 0;
    }
    elsif ( $uptype eq 'micro' ) {
        $micro++;
    }
    else {
        die "Unknown version update-type: $uptype\n";
    }

    my $newver = join q{.}, $major, $minor, $micro;

    my $rel = $self->release;
    my $newrel;
    if ( defined $rel ) {
        if ( $rel =~ m/^\d+(.*)$/ ) {
            $newrel = q{1} . $1;
        }
        else {
            die "Release string, '$rel', does not match expected format\n";
        }
    }
    else {
        $newrel = 1;
    }

    # Only update the attributes if everything else has succeeded
    # (i.e. we got this far in the code).

    $self->version($newver);
    $self->release($newrel);
    $self->update_date();

    return;
}

1;
__END__

=head1 NAME

LCFG::Build::PkgSpec - Object-oriented interface to LCFG build metadata

=head1 VERSION

This documentation refers to LCFG::Build::PkgSpec version 0.2.7

=head1 SYNOPSIS

   my $spec = LCFG::Build::PkgSpec->new( name    => "foo",
                                         version => "0.0.1" );

   $spec->schema(2);

   $spec->save_metafile("./lcfg.yml");

   my $spec2 =
    LCFG::Build::PkgSpec->new_from_metafile("./lcfg.yml");

   print "Package name is: " . $spec2->name . "\n";

   $spec2->update_major();

   $spec->save_metafile("./lcfg.yml");

=head1 DESCRIPTION

This class provides an object-oriented interface to the LCFG build
tools metadata file. All simple fields are available through attribute
accessors. Specific methods are also provided for querying and
modifying the more complex data types (e.g. lists and hashes).

This class has methods for carrying out specific procedures related to
tagging releases with the LCFG build tools. It also has methods for
handling the old format LCFG build configuration files.

More information on the LCFG build tools is available from the website
http://www.lcfg.org/doc/buildtools/

=head1 ATTRIBUTES

=over

=item name

This is the name of the project or LCFG component. In the case of the
component think of it as the "foo" part of "lcfg-foo". When an object
is created this field MUST be specified, there is no default value.

=item base

This is only really meaningful in terms of LCFG components, in which
case it is the "lcfg" part of "lcfg-foo" or the "dice" part of
"dice-foo". This is optional and the default value is an empty string.

=item abstract

This is a short description of the project, it is optional and there
is no default.

=item version

This is the version of the project, it is required and if not
specified at object creation time it will default to '0.0.0'. Due to
backwards compatibility reasons this version must be in 3 integer
parts separated with the period character. Any attempt to set it
otherwise will result in an error being thrown.

=item release

This is the release number for a project and is directly related to
the release field used for RPMs and Debian packages. It is optional
and defaults to 1. If used, the first character of the release field
MUST be an integer, after that you can put in whatever you like.

=item schema

This is only really meaningful in terms of LCFG components. It is the
schema number of the defaults file which specifies the details for the
supported resources. It is optional and will default to 1.

=item group

This is the software group into which this project best fits, it is
mainly provided for RPM specfile generation support
(e.g. "Development/Libraries"). It is optional and has no default
value.

=item vendor

This matches the "Vendor" field used in RPMs, it is optional and has
no default value.

=item orgident

This is an identifier for your organisation which is based on the
reversed form of your domain name, C<com.example> or C<org.example>
for example. No validation is done to check if this is the reversal of
a real domain name, you can use whatever you want, the default value
is C<org.lcfg>. This is used by the C<pkgident> method as part of the
process of generating MacOSX packages.

=item license

This is the short string used in RPMs to specify the license for the
project. This field is optional and there is no default value.

=item date

This is used to show the date and time at which the project version
was last altered. If not specified it will default to the current date
and time in the format 'DD/MM/YY HH:MM:SS'.

=item author

This is the name (or list of names) of the project author(s). The
default value is an empty list. You should note that calling this
accessor with no arguments returns a list not a scalar value. See
below for convenience methods provided for accessing and managing the
information contained with the list.

=item platforms

This is the list of supported platforms for the project. The default
value is an empty list. You should note that calling this accessor
with no arguments returns a list not a scalar value. See below for
convenience methods provided for accessing and managing the
information contained with the list.

=item vcs

This is a reference to a hash containing details of the version
control system used for the project. This is optional and defaults to
an empty hash. See below for convenience methods provided for
accessing and managing the information contained with the hash.

=back

=head1 SUBROUTINES/METHODS

=over

=item fullname

Returns the full name of the package, if the 'base' attribute is
specified then this will be a combination of base and package name
separated with a hyphen, e.g. 'lcfg-foo'. If no base is specified then
this is just the package name, e.g. 'foo'.

=item deb_name

Returns a name for the package which is safe for use as a Debian
package name. Debian package names must not contain the C<_>
(underscore) character so those are replace with hyphens, also by
convention the name is lower-cased. Any invalid characters (not in the
set C<[a-zA-Z0-9-]>) are simply removed.

=item deb_version

Returns a version for the package which is safe for use with Debian
packages. Typically this will be identical to the standard C<version>
string. Debian package versions must only contain characters in the
set C<[a-zA-Z0-9~.+-]>, any invalid characters are simply removed

=item deb_tarname

Returns the name of the debian source package tarfile which would be
generated for this version of the package. This combines the full name
and the version, for example, C<lcfg-foo_1.0.1-1.debian.tar.gz>. Note
that the LCFG build tools will only actually generate this file when a
project contains a C<debian> sub-directory.

=item deb_dscname

Returns the name of the debian source control (dsc) file which would
be generated for this version of the package. This combines the full
name and the version, for example, C<lcfg-foo_1.0.1-1.dsc>. Note that
the LCFG build tools will only actually generate this file when a
project contains a C<debian> sub-directory.

=item pkgident

This returns a string formed by the concatenation of the C<orgident>
and C<fullname> values, joined with a period character,
C<com.example.lcfg-client> for example. This is used as the identifier
name for MacOSX packages.

=item rpmspec_name

This returns the name of the RPM specfile for the project. This is
just based on the full name with a C<.spec> suffix
(e.g. C<lcfg-foo.spec>).

=item tarname

Returns the standard LCFG name of the tarfile which would be generated
for this version of the package. This combines the full name and the
version, for example, C<lcfg-foo_1.0.1.orig.tar.gz>

=item new_from_metafile($file)

Create a new object which represents the LCFG build metadata stored in
the YAML file.

=item save_metafile($file)

Save the object data into the LCFG metadata file.

=item new_from_cfgmk($file)

Create from the old-style LCFG config.mk a new object which represents
the LCFG build metadata.

=item perl_version

This returns the package version as a string in a style which is safe
for use in Perl modules. If this is a development release the C<dev>
suffix is replaced with the value of the release. This is done because
Perl versions are not permitted to contain non-numeric characters.

=item get_major

Get just the major (first) part of the package version.

=item get_minor

Get just the minor (middle) part of the package version.

=item get_micro

Get just the micro (last) part of the package version.

=item update_major

Increment by one the first (largest) part of the version. This will
also reset the second and third parts of the version to 0 (zero) and
the release field to 1. For example, version 1.2.3 would become 2.0.0
and the release field would go from 5 to 1.

=item update_minor

Increment by one the second (middle) part of the version.  This will
also reset the third part of the version to 0 (zero) and the release
field to 1. For example, version 1.2.3 would become 1.3.0 and the
release field would go from 5 to 1.

=item update_micro

Increment by one the third (smallest) part of the version field. This
will also reset the release field to 1. For example, version 1.2.3
would become 1.2.4 and the release field would go from 5 to 1.

=item update_date

Update the date attribute to the current time, this is set to the
format 'DD/MM/YY HH:MM::SS'. You should not normally need to call this
method, it is called at the end of the update_micro, update_minor and
update_major methods to show when the version update occurred.

=item update_release

This method updates the release field by incrementing the value. If it
was not previously defined then it will be set to one.

=item dev_version

This method converts the version to the development format. If it is
not already present an C<.dev> string is appended to the version
string along with the value of the release field. The release field is
also incremented. For example, the first dev version for C<1.2.3>
would be C<1.2.3.dev1> and the second would be C<1.2.3.dev2>.

=item add_author

A convenience method for adding new authors to the list of project
authors. Note that this does not prevent an author being added
multiple times.

=item add_platform

A convenience method for adding new platforms to the list of
supported platforms for this project. Note that this does not prevent
a platform being added multiple times.

=item exists_in_vcsinfo($key)

A convenience method to see if a particular key exists in the
version-control information.

=item ids_in_vcsinfo

A convenience method to get a list of all the keys in the
version-control information.

=item get_vcsinfo($key)

A convenience method to get the data associated with a particular key
in the version-control information.

=item set_vcsinfo($key, $value)

A convenience method to set the data associated with a particular key
in the version-control information.

=item exists_in_buildinfo($key)

A convenience method to see if a particular key exists in the
build information.

=item ids_in_buildinfo

A convenience method to get a list of all the keys in the
build information.

=item get_buildinfo($key)

A convenience method to get the data associated with a particular key
in the build information.

=item set_buildinfo($key, $value)

A convenience method to set the data associated with a particular key
in the build information.

=back

=head1 DEPENDENCIES

This module is L<Moose> powered. It also requires
L<Data::Structure::Util>, L<DateTime> and if you want to parse and
write LCFG metadata files you will need L<YAML::Syck>.

=head1 SEE ALSO

lcfg-cfg2meta(1), lcfg-pkgcfg(1), LCFG::Build::Tools(3)

=head1 PLATFORMS

This is the list of platforms on which we have tested this
software. We expect this software to work on any Unix-like platform
which is supported by Perl.

ScientificLinux5, ScientificLinux6

=head1 BUGS AND LIMITATIONS

There are no known bugs in this application. Please report any
problems to bugs@lcfg.org, feedback and patches are also always very
welcome.

=head1 AUTHOR

Stephen Quinney <squinney@inf.ed.ac.uk>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2008-2019 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
