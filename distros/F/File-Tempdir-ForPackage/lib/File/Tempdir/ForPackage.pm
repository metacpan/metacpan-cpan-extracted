use 5.006;
use strict;
use warnings;

package File::Tempdir::ForPackage;

our $VERSION = '1.000002';

# ABSTRACT: Easy temporary directories associated with packages.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Carp qw( croak );
use Moo qw( has );
use File::Temp qw();
## no critic (Subroutines::ProhibitCallsToUnexportedSubs)
use constant MINX => File::Temp::MINX;
## use critic

















has package => (
  is   => ro =>,
  lazy => 1,
  default => sub { scalar [ caller 1 ]->[0] },
);


















































has with_version   => ( is => ro =>, lazy => 1, default => sub { undef } );
has with_timestamp => ( is => ro =>, lazy => 1, default => sub { undef } );
has with_pid       => ( is => ro =>, lazy => 1, default => sub { undef } );
has num_random     => (
  is  => 'ro',
  isa => sub {
    return if $_[0] >= MINX();
    croak( "num_random ( $_[0] ) must be >= " . MINX() );
  },
  default => sub { 8 },
);







has '_preserve' => ( is => rw =>, init_arg => 'preserve', lazy => 1, default => sub { 0 } );







has _dir => ( is => 'lazy', clearer => 1, predicate => 1 );

























sub preserve {
  my ( $self, @args ) = @_;
  if ( @args and not $args[0] ) {
    $self->_preserve(0);
    $self->_dir->unlink_on_destroy(1);
    return;
  }
  $self->_preserve(1);
  $self->_dir->unlink_on_destroy(0);
  return 1;
}







sub _clean_pkg {
  my ($package) = @_;
  $package =~ s/::/-/gsmx;
  $package =~ s/[^\w-]+/_/gsmx;
  return $package;
}







sub _clean_ver {
  my ($ver) = @_;
  return 'versionundef' if not defined $ver;
  $ver =~ s/[^v\d_.]+/_/gsmx;
  return $ver;
}







sub _build__dir {
  my ($self) = shift;

  my $template = q{perl-};
  $template .= _clean_pkg( $self->package );

  if ( $self->with_version ) {
    $template .= q{-} . _clean_ver( $self->package->VERSION );
  }
  if ( $self->with_timestamp ) {
    $template .= q{-} . time;
  }
  if ( $self->with_pid ) {
    ## no critic ( ProhibitPunctuationVars )
    $template .= q{-} . $$;
  }
  $template .= q{-} . ( 'X' x $self->num_random );

  my $dir = File::Temp->newdir( TEMPLATE => $template, TMPDIR => 1 );
  if ( $self->_preserve ) {
    $dir->unlink_on_destroy(0);
  }
  return $dir;
}









sub dir {
  my ($self) = shift;
  return $self->_dir . q[];
}
















sub run_once_in {
  my ( $self, $options, $code ) = @_;
  $code = $options unless defined $code;
  require File::pushd;
  {
    ## no critic (Variables::ProhibitUnusedVarsStricter)
    my $marker = File::pushd::pushd( $self->dir );
    $code->( $self->dir );
  }

  # Dir POP.
  $self->_clear_dir;
  return $self;
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Tempdir::ForPackage - Easy temporary directories associated with packages.

=head1 VERSION

version 1.000002

=head1 DESCRIPTION

This is mostly an interface wrapper for C<File::Temp::tempdir>, stealing code from C<File::Tempdir>;

=over 4

=item * I constantly forget how C<File::Tempdir> works

=item * I often want a C<tempdir> with the name of the package working with it enshrined in the path

=item * I constantly forget the magic glue syntax to get a folder inside a system C<tempdir> with a custom prefix and a user defined length of random characters.

=back

And this is designed to solve this simply.

use File::TempDir::ForPackage;

  my $tempdir = File::TempDir::ForPackage->new( package => __PACKAGE__ , use_version => 1 );
  my $dir = $tempdir->dir();

do shit in `$dir`
$dir on Linux will be something like /tmp/perl-Some-Package-maybewith-a-VERSION-AFG14561/
so if it crashes and leaves a C<tempdir> behind, you will know who left that C<tempdir> behind and have a way of cleaning it up.

When C<$tempdir> is destroyed, C<$dir> will be cleaned;

Additionally:

  $dir->run_once_in(sub{
    ...
  });

Is there for people who don't trust scope auto-cleansing and want to know when the directory is reaped.

Additionally, this code can be run in a tight loop creating and destroying lots of similarly named temporary directories without risk of conflict.

  for my $i ( 0 .. 30  ) {
    $dir->run_once_in(sub {
      system 'find $PWD';
    });
  }

This emits something like:

  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-PzH4BD
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-5h8nkG
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-UXKt4S
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-Lqg2aW
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-DkNeq6
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-jRI_zF
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-j0_Gt1
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-iX1ddT
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-ZmvikK
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-QNGOUF
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-6wssvL
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-ZmwZxl
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-wIzRTs
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-xetCym
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-8Y0vyX
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-Zlqt6X
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-U5Z_Sa
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-sKmow1
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-rUND95
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-XjPSGF
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-ec8sZZ
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-_4NBwX
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-xM9i6l
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-p3FhJf
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-Zv0sso
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-rP8cAi
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303496-408662-iade0x
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303497-408662-fsDDPy
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303497-408662-FeCcfZ
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303497-408662-ta5yfg
  /tmp/perl-File-Tempdir-ForPackage-versionundef-1343303497-408662-rdcQhF

Except of course, with a package of your choosing, and possibly that packages version.

=head1 METHODS

=head2 C<preserve>

Toggle the preservation of the C<tempdir> after it goes out of scope or is otherwise indicated for cleaning.

  $instance->preserve(); # tempdir is now preserved after cleanup
  $instance->preserve(0); # tempdir is purged at cleanup
  $instance->preserve(1); # tempdir is preserved after cleanup

Note that in C<run_once_in>, a new C<tempdir> is created and set for this modules consumption for each run of C<run_once_in>,
regardless of this setting. All this setting will do, when set, will prevent each instance being reaped from the file system.

Thus:

  $dir->preserve(1);
  for( 1..10 ){
    $dir->run_once_in(sub{

    });
  }

Will create 10 temporary directories on your file system and not reap them.

=head2 C<dir>

Return a path string to the created temporary directory

  my $path = $instance->dir

=head2 C<run_once_in>

Vivifies a temporary directory for the scope of the passed sub.

  $instance->run_once_in(sub{
    # temporary directory is created before this code runs.
    # Cwd::getcwd is now inside the temporary directory.
  });

  # temporary directory is reset, and possibly reaped.

You can call this method repeatedly, and you'll get a separate temporary directory each time.

=head1 ATTRIBUTES

=head2 C<package>

The package to report as being associated with.
This really can be any string, as its sanitized and then used as a path part.

If not specified, will inspect C<caller>

  my $instance = CLASS->new(
    package => 'Something::Here',
    ...
  );

Note: If you want C<with_version> to work properly, specifying a valid package name will be helpful.

=head2 C<with_version>

Include the version from C<< package->VERSION() >> in the C<tempdir> path.

Defaults to false.

  my $instance = CLASS->new(
    ...
    with_version => 1,
  );

=head2 C<with_timestamp>

Include C<time> in the C<tempdir> path.

Defaults to false.

  my $instance = CLASS->new(
    ...
    with_timestamp => 1,
  );

=head2 C<with_pid>

Include C<$$> in the C<tempdir> path.

Defaults to false.

  my $instance = CLASS->new(
    ...
    with_pid => 1,
  );

=head2 C<num_random>

The number of characters of randomness to include in the C<tempdir> template.

Defaults to 8. Must be no lower than 4.

  my $instance = CLASS->new(
    ...
    num_random => 5,
  );

=head1 PRIVATE ATTRIBUTES

=head2 C<_preserve>

Internal C<boolean> for tracking the _preserve state.

=head2 C<_dir>

Internal C<File::Tempdir> path.

=head1 PRIVATE METHODS

=head2 C<_build__dir>

Builder method for _dir which creates a temporary directory based on the passed parameters.

=head1 PRIVATE FUNCTIONS

=head2 C<_clean_pkg>

Scrape garbage out of the 'package' field for use in file system tokens.

=head2 C<_clean_ver>

Scrape garbage out of versions for use in file system tokens.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
