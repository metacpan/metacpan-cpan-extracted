package JavaScript::Dependency::Manager;
{
  $JavaScript::Dependency::Manager::VERSION = '0.001002';
}

# ABSTRACT: Manage your JavaScript dependencies

use Moo;
use Sub::Quote;
use Tie::IxHash;
use autodie;

has lib_dir => (
  is       => 'ro',
  required => 1,
);

has recurse => (
  is      => 'ro',
  default => quote_sub q{ 0 },
);

has scan_files => (
  is      => 'ro',
  default => quote_sub q{ 1 },
);

has _scanned_files => (
  is => 'rw',
);

# hashref where the provision (what a file provides) is the key,
# and an arrayref of the files that provide the feature are the value
has provisions => (
  is => 'ro',
  default => quote_sub q{ {} },
);

# hashref where the filename is the key, and the value is required provisions in
# an arrayref
has requirements => (
  is => 'ro',
  default => quote_sub q{ {} },
);

sub file_list_for_provisions {
  my ($self, $provisions) = @_;

  if ($self->scan_files && !$self->_scanned_files) {
    for my $dir (@{$self->lib_dir}) {
      $self->_scan_dir($dir);
    }
    $self->_scanned_files(1);
  }

  my %ret;
  tie %ret, 'Tie::IxHash';
  for my $requested_provision (@$provisions) {
    my $files = $self->_files_providing($requested_provision);

    # for now we just use the first file
    my $file = $files->[0];
    if (my $requirements = $self->_direct_requirements_for($file)) {
      $ret{$_} = 1 for $self->file_list_for_provisions($requirements);
    }
    $ret{$file} = 1;
  }

  return keys %ret;
}

sub _scan_dir {
  my ($self, $dir) = @_;
  my $dh;
  opendir $dh, $dir;
  my @files = grep { $_ ne '.' && $_ ne '..' } readdir $dh;
  for (@files) {
    my $fqfn = "$dir/$_";
    $self->_scan_dir($fqfn) if $self->recurse && -d $fqfn;
    $self->_scan_file($fqfn) if -f $fqfn;
  }
}

sub _scan_file {
  my ($self, $file) = @_;
  return unless $file =~ /\.js$/;
  open my $fh, '<', $file;
  while (<$fh>) {
    if (m[//\s*provides:\s*(\S+)]) {
      $self->provisions->{$1} ||= [];
      push @{$self->provisions->{$1}}, $file
    } elsif (m[//\s*requires:\s*(\S+)]) {
      $self->requirements->{$file} ||= [];
      push @{$self->requirements->{$file}}, $1
    }
  }
}

sub _files_providing {
  my ($self, $provision) = @_;

  $self->provisions->{$provision}
    or die "no such provision '$provision' found!";
}

sub _direct_requirements_for {
  my ($self, $file) = @_;

  $self->requirements->{$file}
}


1;

# This code was written at the Tallulah Travel Center in Louisiana

__END__

=pod

=head1 NAME

JavaScript::Dependency::Manager - Manage your JavaScript dependencies

=head1 VERSION

version 0.001002

=head1 SYNOPSIS

First, annotate your javascript files with C<provides> and/or C<requires>:

 // provides: Ack
 // requires: underscore
 var Ack = _.throttle(function(foo) {
   alert('ACK! ' + foo)
 }, 100)

 // etc, etc

Now you can use C<JavaScript::Dependency::Manager> to automatically create a
list of files needed for a given L</provision>.

 use JavaScript::Dependency::Manager;

 my $mgr = JavaScript::Dependency::Manager->new(
   lib_dir => ['root/js/lib'],
   provisions => {
     underscore => ['root/js/lib/underscore/underscore.js'],
   },
 );

 my @files = $mgr->file_list_for_provisions(['Lynx.ui.form.MWHY']);

Note that I manually set a provision above.  That's because C<underscore> is an
external library, so I shouldn't edit it's source to set it's provisions.

=head1 DESCRIPTION

This module simply helps you automatically create a list of necessary files
based on a list of "modules", which are merely your way of identifying
functions, objects, classes, or whatever else that you would like to load. It
will correctly order the list of files to load based on your defined
requirements.

=head1 TERMS

=head2 requirement

A C<requirement> is simply a B<module> that a given B<file> needs to run.

=head2 provision

A C<provision> is simply a B<module> that a given B<file> has within it.

=head1 METHODS

=head2 file_list_for_provisions

 my @files = $mgr->file_list_for_provisions(['Foo', 'Bar'])

This method returns a list of files needed to load a list of provisions.

=head1 ATTRIBUTES

=head2 lib_dir

B<required>.  An C<ArrayRef> of directories to scan to create the list of
L</requirement>s and L</provision>s.

=head2 recurse

B<False> by default.  Set to true if you want the tool to recurse into
subdirectories of the L</lib_dir>.

=head2 scan_files

B<True> by default.  Set to false if you want the tool not to scan files at
all, but instead use a provided list of L</requirement>s and L</provision>s.

=head1 DEDICATION

C<JavaScript::Dependency::Manager> module is dedicated to my namesake, Arthur
Dale Schmidt.  He was my grandfather as well as the inventor of a chemical
called Sand Control 60 (SC60,) which was used in oil fields to reduce the
need to redrill entire wells due to sand clogging.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
