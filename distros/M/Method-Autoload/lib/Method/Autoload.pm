package Method::Autoload;
use strict;
use warnings;
use UNIVERSAL::require;

our $VERSION='0.02';
our $AUTOLOAD;

=head1 NAME

Method::Autoload - Autoloads methods from a list of packages into the current package

=head1 SYNOPSIS

  package MyPackage;
  use base qw{Method::Autoload}

=head1 DESCRIPTION

The Method::Autoload base class package is used to autoload methods from a list of packages where you may not know what methods are available until run time.  A good use of this package is programming support for user contributed packages or user contributed plugins.

=head1 USAGE

  use MyPackage;
  my $object=MyPackage->new(%hash);    #provides new and initialize methods
  $object->pushPackages("My::Bar");    #appends to "packages" array
  $object->unshiftPackages("My::Foo"); #prepends to "packages" array

  use MyPackage;
  my $object=MyPackage->new(packages=>["My::Foo", "My::Bar"]);
  $object->foo; #from My::Foo
  $object->bar; #from My::Bar

=head1 CONSTRUCTOR

=head2 new

  my $object=MyPackage->new(%hash);
  my $object=MyPackage->new(package=>["My::Package1", "My::Package2"]);

=cut

sub new {
  my $this=shift;
  my $class=ref($this) || $this;
  my $self={};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

=head2 initialize

=cut

sub initialize {
  my $self=shift;
  %$self=@_;
}

=head1 METHODS PUBLIC

=head2 packages

Returns the current list of packages in the "packages" array.

  my @package=$object->packages; #()
  my $package=$object->packages; #[]

=cut

sub packages {
  my $self=shift;
  $self->{"packages"}=[] unless ref($self->{"packages"}) eq "ARRAY";
  return wantarray ? @{$self->{"packages"}} : $self->{"packages"};
}

=head2 pushPackages

Pushes packages on to the "packages" array.

  $object->pushPackages("My::Bar");
  $object->pushPackages(@packages);

=cut

sub pushPackages {
  my $self=shift;
  push @{$self->packages}, @_ if @_;
  return $self->packages;
}

=head2 unshiftPackages

Unshifts packages on to the "packages" array.  Use this if you want to override a "default" package.  Please use with care.

  $object->unshiftPackages("My::Foo");
  $object->unshiftPackages(@packages);

=cut

sub unshiftPackages {
  my $self=shift;
  unshift @{$self->packages}, @_ if @_;
  return $self->packages;
}

=head2 autoloaded

Returns a hash of autoloaded methods and the classes that they came from.

  my %hash=$object->autoloaded; #()
  my $hash=$object->autoloaded; #{}

=cut

sub autoloaded {
  my $self=shift;
  $self->{"autoloaded"}={} unless ref($self->{"autoloaded"}) eq "HASH";
  return wantarray ? @{$self->{"autoloaded"}} : $self->{"autoloaded"};
}

=head1 METHODS PRIVATE

=head2 DESTROY ("Global" method)

We define DESTROY in this package so that it does not call AUTOLOAD but you may overload this method in your package, if you need it.

=cut

sub DESTROY {return "0E0"};

=head2 AUTOLOAD ("Global" method)

AUTOLOAD is a "global" method.  Please review the limitations on inheriting this method.

=cut

sub AUTOLOAD {
  my $self=shift;
  my $method=$AUTOLOAD;
  $method=~s/.*://;
  #warn sprintf("Autoloading Method: %s\n", $method);
  foreach my $class ($self->packages) {
    if ($class->can($method)) {
      #warn(sprintf(qq{Package "%s" is loaded and method "%s" is supported\n}, $class, $method));
      $self->autoload($class, $method);
      last; #for performance and in case another package defines method.
    } else {
      #warn sprintf("Loading Package: %s\n", $class);
      $class->use;
      if ($@) {
        #warn(sprintf(qq{Warning: Failed to use package "%s". Is it installed?\n}, $class));
      } else {
        if ($class->can($method)) {
          $self->autoload($class, $method);
          last; #for performance and in case another package defines method.
        }
      }
    }
  }
  die(sprintf(qq{Error: Could not autoload method "%s" from packages %s.\n},
    $method, join(", ", map {qq{"$_"}} $self->packages)))
      unless $self->can($method);
  return $self->$method(@_);
}

=head2 autoload

  my $subref=$object->autoload($class, $method);

=cut

sub autoload {
  my $syntax=q{Error: autoload syntax $obj->autoload($class, $method)};
  my $self=shift or die($syntax);
  my $class=shift or die($syntax);
  my $method=shift or die($syntax);
  my $sub=join("::", $class, $method);
  #warn sprintf(qq{Importing method "%s" from class "%s"\n}, $method, $class);
  $self->autoloaded->{$method}=$class;
  no strict qw{refs};
  return *$method=\&{$sub};
}

=head1 BUGS

DavisNetworks.com provides support services for all Perl applications including this package.

=head1 SUPPORT

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  STOP, LLC
  domain=>michaelrdavis,tld=>com,account=>perl
  http://www.stopllc.com/

=head1 COPYRIGHT

This program is free software licensed under the...

  The BSD License

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<Class::Std> AUTOMETHOD method, 

=cut

1;
