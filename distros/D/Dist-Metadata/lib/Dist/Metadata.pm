# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of Dist-Metadata
#
# This software is copyright (c) 2011 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Dist::Metadata;
# git description: v0.926-3-ge4f15df

our $AUTHORITY = 'cpan:RWSTAUNER';
# ABSTRACT: Information about a perl module distribution
$Dist::Metadata::VERSION = '0.927';
use Carp qw(croak carp);
use CPAN::Meta 2.1 ();
use List::Util qw(first);    # core in perl v5.7.3

# something that is obviously not a real value
sub UNKNOWN () { '- unknown -' } # constant


sub new {
  my $class = shift;
  my $self  = {
    determine_packages => 1,
    @_ == 1 ? %{ $_[0] } : @_
  };

  my @formats = qw( dist file dir struct );
  croak(qq[A dist must be specified (one of ] .
      join(', ', map { "'$_'" } @formats) . ')')
    unless first { $self->{$_} } @formats;

  bless $self, $class;
}


sub dist {
  my ($self) = @_;
  return $self->{dist} ||= do {
    my $dist;
    if( my $struct = $self->{struct} ){
      require Dist::Metadata::Struct;
      $dist = Dist::Metadata::Struct->new(%$struct);
    }
    elsif( my $dir = $self->{dir} ){
      require Dist::Metadata::Dir;
      $dist = Dist::Metadata::Dir->new(dir => $dir);
    }
    elsif ( my $file = $self->{file} ){
      require Dist::Metadata::Archive;
      $dist = Dist::Metadata::Archive->new(file => $file);
    }
    else {
      # new() checks for one and dies without so we shouldn't get here
      croak q[No dist format parameters found!];
    }
    $dist; # return
  };
}


sub default_metadata {
  my ($self) = @_;

  return {
    # required
    abstract       => UNKNOWN,
    author         => [],
    dynamic_config => 0,
    generated_by   => ( ref($self) || $self ) . ' version ' . ( $self->VERSION || 0 ),
    license        => ['unknown'], # this 'unknown' comes from CPAN::Meta::Spec
    'meta-spec'    => {
      version => '2',
      url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
    },
    name           => UNKNOWN,

    # strictly speaking, release_status is also required but
    # CPAN::Meta will figure it out based on the version number.  if
    # we were to set it explicitly, then we would first need to
    # examine the version number for '_' or 'TRIAL' or 'RC' etc.

    version        => 0,

    # optional
    no_index => {
      # Ignore the same directories as PAUSE (https://github.com/andk/pause/blob/master/lib/PAUSE/dist.pm#L758):
        # skip "t" - libraries in ./t are test libraries!
        # skip "xt" - libraries in ./xt are author test libraries!
        # skip "inc" - libraries in ./inc are usually install libraries
        # skip "local" - somebody shipped his carton setup!
        # skip 'perl5" - somebody shipped her local::lib!
        # skip 'fatlib' - somebody shipped their fatpack lib!
      directory => [qw( inc t xt local perl5 fatlib )],
    },
    # provides => { package => { file => $file, version => $version } }
  };
}


sub determine_metadata {
  my ($self) = @_;

  my $dist = $self->dist;
  my $meta = $self->default_metadata;

  # get name and version from dist if dist was able to parse them
  foreach my $att (qw(name version)) {
    my $val = $dist->$att;
    # if the dist could determine it that's better than the default
    # but undef won't validate.  value in $self will still override.
    $meta->{$att} = $val
      if defined $val;
  }

  # any passed in values should take priority
  foreach my $field ( keys %$meta ){
    $meta->{$field} = $self->{$field}
      if exists $self->{$field};
  }

  return $meta;
}


sub determine_packages {
  # meta must be passed to avoid infinite loop
  my ( $self, $meta ) = @_;
  # if not passed in, use defaults (we just want the 'no_index' property)
  $meta ||= $self->meta_from_struct( $self->determine_metadata );

  # should_index_file() expects unix paths
  my @files = grep {
    $meta->should_index_file(
      $self->dist->path_classify_file($_)->as_foreign('Unix')->stringify
    );
  }
    $self->dist->perl_files;

  # TODO: should we limit packages to lib/ if it exists?
  # my @lib = grep { m#^lib/# } @files; @files = @lib if @lib;

  return {} if not @files;

  my $packages = $self->dist->determine_packages(@files);


  foreach my $pack ( keys %$packages ) {

    # Remove any packages that should not be indexed
    if ( !$meta->should_index_package($pack) ) {
      delete $packages->{$pack};
      next;
    }

    unless( $self->{include_inner_packages} ){
      # PAUSE only considers packages that match the basename of the
      # containing file.  For example, file Foo.pm may only contain a
      # package that matches /\bFoo$/.  This is what PAUSE calls a
      # "simile".  All other packages in the file will be ignored.

      # capture file basename (without the extension)
      my ($base) = ($packages->{$pack}->{file} =~ m!([^/]+)\.pm(?:\.PL)?$!);
      # remove if file didn't match regexp or package doesn't match basename
      delete $packages->{$pack}
        if !$base || $pack !~ m{\b\Q$base\E$};
    }
  }

  return $packages;
}


sub load_meta {
  my ($self) = @_;

  my $dist  = $self->dist;
  my @files = $dist->list_files;
  my ( $meta, $metafile );
  my $default_meta = $self->determine_metadata;

  # prefer json file (spec v2)
  if ( $metafile = first { m#^META\.json$# } @files ) {
    $meta = CPAN::Meta->load_json_string( $dist->file_content($metafile) );
  }
  # fall back to yaml file (spec v1)
  elsif ( $metafile = first { m#^META\.ya?ml$# } @files ) {
    $meta = CPAN::Meta->load_yaml_string( $dist->file_content($metafile) );
  }
  # no META file found in dist
  else {
    $meta = $self->meta_from_struct( $default_meta );
  }

  {
    # always include (never index) the default no_index dirs
    my $dir = ($meta->{no_index} ||= {})->{directory} ||= [];
    my %seen = map { ($_ => 1) } @$dir;
    unshift @$dir,
      grep { !$seen{$_}++ }
          @{ $default_meta->{no_index}->{directory} };
  }

  # Something has to be indexed, so if META has no (or empty) 'provides'
  # attempt to determine packages unless specifically configured not to
  if ( !keys %{ $meta->provides || {} } && $self->{determine_packages} ) {
    # respect api/encapsulation
    my $struct = $meta->as_struct;
    $struct->{provides} = $self->determine_packages($meta);
    $meta = $self->meta_from_struct($struct);
  }

  return $meta;
}


sub meta {
  my ($self) = @_;
  return $self->{meta} ||= $self->load_meta;
}


sub meta_from_struct {
  my ($self, $struct) = @_;
  return CPAN::Meta->create( $struct, { lazy_validation => 1 } );
}


sub package_versions {
  my ($self) = shift;
  my $provides = @_ ? shift : $self->provides; # || {}
  return {
    map { ($_ => $provides->{$_}{version}) } keys %$provides
  };
}


sub module_info {
  my ($self, $opts) = @_;
  my $provides = $opts->{provides} || $self->provides;
  $provides = { %$provides }; # break reference

  my $checksums = $opts->{checksum} || $opts->{digest} || [];
  $checksums = [ $checksums ]
    unless ref($checksums) eq 'ARRAY';

  my $digest_cache = {};
  foreach my $mod ( keys %$provides ){
    my $data = { %{ $provides->{ $mod } } }; # break reference

    foreach my $checksum ( @$checksums ){
      $data->{ $checksum } =
        $digest_cache->{ $data->{file} }->{ $checksum } ||=
          $self->dist->file_checksum($data->{file}, $checksum);
    }

    # TODO: $opts->{callback}->($self, $mod, $data, sub { $self->dist->file_content($data->{file}) });

    $provides->{ $mod } = $data;
  }

  return $provides;
}


{
  no strict 'refs'; ## no critic (NoStrict)
  foreach my $method ( qw(
    name
    provides
    version
  ) ){
    *$method = sub { $_[0]->meta->$method };
  }
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS TODO dist dists dir unix checksum checksums
cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc
mailto metadata placeholders metacpan

=head1 NAME

Dist::Metadata - Information about a perl module distribution

=head1 VERSION

version 0.927

=for test_synopsis my $path_to_archive;

=head1 SYNOPSIS

  my $dist = Dist::Metadata->new(file => $path_to_archive);

  my $description = sprintf "Dist %s (%s)", $dist->name, $dist->version;

  my $provides = $dist->package_versions;
  while( my ($package, $version) = each %$provides ){
    print "$description includes $package $version\n";
  }

=head1 DESCRIPTION

This module provides an easy interface for getting various metadata
about a Perl module distribution.

It takes care of the common logic of:

=over 4

=item *

reading a tar file (L<Archive::Tar>)

=item *

finding and reading the correct META file if the distribution contains one (L<CPAN::Meta>)

=item *

and determining some of the metadata if there is no META file (L<Module::Metadata>, L<CPAN::DistnameInfo>)

=back

This is mostly a wrapper around L<CPAN::Meta> providing an easy interface
to find and load the meta file from a F<tar.gz> file.
A dist can also be represented by a directory or merely a structure of data.

If the dist does not contain a meta file
the module will attempt to determine some of that data from the dist.

B<NOTE>: This interface is still being defined.
Please submit any suggestions or concerns.

=head1 METHODS

=head2 new

  Dist::Metadata->new(file => $path);

A dist can be represented by
a tar file,
a directory,
or a data structure.

The format will be determined by the presence of the following options
(checked in this order):

=over 4

=item *

C<struct> - hash of data to build a mock dist; See L<Dist::Metadata::Struct>.

=item *

C<dir> - path to the root directory of a dist

=item *

C<file> - the path to a F<.tar.gz> file

=back

You can also slyly pass in your own object as a C<dist> parameter
in which case this module will just use that.
This can be useful if you need to use your own subclass
(perhaps while developing a new format).

Other options that can be specified:

=over 4

=item *

C<name> - dist name

=item *

C<version> - dist version

=item *

C<determine_packages> - boolean to indicate whether dist should be searched
for packages if no META file is found.  Defaults to true.

=item *

C<include_inner_packages> - When determining provided packages
the default behavior is to only include packages that match the name
of the file that defines them (like C<Foo::Bar> matches C<*/Bar.pm>).
This way only modules that can be loaded (via C<use> or C<require>)
will be returned (and "inner" packages will be ignored).
This mimics the behavior of PAUSE.
Set this to true to include any "inner" packages provided by the dist
(that are not otherwise excluded by another mechanism (such as C<no_index>)).

=back

=head2 dist

Returns the dist object (subclass of L<Dist::Metadata::Dist>).

=head2 default_metadata

Returns a hashref of default values
used to initialize a L<CPAN::Meta> object
when a META file is not found.
Called from L</determine_metadata>.

=head2 determine_metadata

Examine the dist and try to determine metadata.
Returns a hashref which can be passed to L<CPAN::Meta/new>.
This is used when the dist does not contain a META file.

=head2 determine_packages

  my $provides = $dm->determine_packages($meta);

Attempt to determine packages provided by the dist.
This is used when the META file does not include a C<provides>
section and C<determine_packages> is not set to false in the constructor.

If a L<CPAN::Meta> object is not provided a default one will be used.
Files contained in the dist and packages found therein will be checked against
the meta object's C<no_index> attribute
(see L<CPAN::Meta/should_index_file>
and  L<CPAN::Meta/should_index_package>).
By default this ignores any files found in
F<inc/>,
F<t/>,
or F<xt/>
directories.

=head2 load_meta

Loads the metadata from the L</dist>.

=head2 meta

Returns the L<CPAN::Meta> instance in use.

=head2 meta_from_struct

  $meta = $dm->meta_from_struct(\%struct);

Passes the provided C<\%struct> to L<CPAN::Meta/create>
and returns the result.

=head2 package_versions

  $pv = $dm->package_versions();
  # { 'Package::Name' => '1.0', 'Module::2' => '2.1' }

Returns a simplified version of C<provides>:
a hashref with package names as keys and versions as values.

This can also be called as a class method
which will operate on a passed in hashref.

  $pv = Dist::Metadata->package_versions(\%provides);

=head2 module_info

Returns a hashref of meta data for each of the packages provided by this dist.

The hashref starts with the same data as L</provides>
but additional data can be added to the output by specifying options in a hashref:

=over 4

=item C<checksum>

Use the specified algorithm to compute a hex digest of the file.
The type you specify will be the key in the returned hashref.
You can use an arrayref to specify more than one type.

  $dm->module_info({checksum => ['sha256', 'md5']});
  # returns:
  {
    'Mod::Name' => {
      file    => 'lib/Mod/Name.pm',
      version => '0.1',
      md5     => '258e88dcbd3cd44d8e7ab43f6ecb6af0',
      sha256  => 'f22136124cd3e1d65a48487cecf310771b2fd1e83dc032e3d19724160ac0ff71',
    },
  }

See L<Dist::Metadata::Dist/file_checksum> for more information.

=item C<provides>

The default is to start with the hashref returned from L</provides>
but you can pass in an alternate hashref using this key.

=back

Other options may be added in the future.

=head1 INHERITED METHODS

The following methods are available on this object
and simply call the corresponding method on the L<CPAN::Meta> object.

=over 4

=item *

X<name> name

=item *

X<provides> provides

=item *

X<version> version

=back

=for Pod::Coverage name version provides
UNKNOWN

=head1 TODO

=over 4

=item *

More tests

=item *

C<trust_meta> option (to allow setting it to false)

=item *

Guess main module from dist name if no packages can be found

=item *

Determine abstract?

=item *

Add change log info (L<CPAN::Changes>)?

=item *

Subclass as C<CPAN::Dist::Metadata> just so that it has C<CPAN> in the name?

=item *

Use L<File::Find::Rule::Perl>?

=back

=head1 SEE ALSO

=head2 Dependencies

=over 4

=item *

L<CPAN::Meta>

=item *

L<Module::Metadata>

=item *

L<CPAN::DistnameInfo>

=back

=head2 Related Modules

=over 4

=item *

L<MyCPAN::Indexer>

=item *

L<CPAN::ParseDistribution>

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Dist::Metadata

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Dist-Metadata>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-dist-metadata at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Dist-Metadata>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code


L<https://github.com/rwstauner/Dist-Metadata>

  git clone https://github.com/rwstauner/Dist-Metadata.git

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 CONTRIBUTORS

=for stopwords David Steinbrunner Graham Knop Jeffrey Ryan Thalhammer Sawyer X

=over 4

=item *

David Steinbrunner <dsteinbrunner@pobox.com>

=item *

Graham Knop <haarg@haarg.org>

=item *

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=item *

Sawyer X <xsawyerx@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
