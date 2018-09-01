package File::ShareDir::Dist::Install;

use strict;
use warnings;
use 5.008001;
use base qw( Exporter );
use Carp qw( croak );
use File::Spec;

our @EXPORT = qw( install install_dir install_config_get install_config_set );

# ABSTRACT: Install per-dist shared files
our $VERSION = '0.07'; # VERSION


sub install_dir
{
  my($dist_name) = @_;
  croak "Not a valid dist_name: undef" unless defined $dist_name;
  croak "Not a valid dist_name: $dist_name" unless $dist_name =~ /^[A-Za-z0-9_][A-Za-z0-9_-]*$/;
  "blib/lib/auto/share/dist/$dist_name";
}


sub _mkpath
{
  my($dist_name) = @_;
  require File::Path;
  File::Path::mkpath(install_dir($dist_name), { verbose => 0, mode => 0755 });
}

sub install
{
  my($source_dir, $dist_name) = @_;
  ($source_dir, $dist_name) = @ARGV unless defined $source_dir || defined $dist_name;
  croak "No such directory: undef" unless defined $source_dir;
  croak "No such directory: $source_dir" unless -d $source_dir;
  my $dest_dir = install_dir $dist_name;

  # Can I just say...
  # File::Find has a terrible terrible terrible interface.
  my @files = do {
    require Cwd;
    require File::Find;
    my $save = Cwd::getcwd();
    chdir($source_dir) || die "unable to chdir $source_dir";
    my @list;
    File::Find::find(sub {
      return unless -f $_;
      push @list, $File::Find::name;
    }, File::Spec->curdir);
    chdir $save;
    @list;
  };

  require File::Basename;
  require File::Path;
  require File::Copy;

  foreach my $file (@files)
  {
    my $from = File::Spec->catfile($source_dir, $file);
    my $to   = File::Spec->catfile($dest_dir, $file);
    my $dir  = File::Basename::dirname($to);
    File::Path::mkpath($dir, { verbose => 0, mode => 0755 });
    File::Copy::cp($from, $to) || die "Copy failed $from => $to: $!";
  }
}


sub install_config_get
{
  my($dist_name) = @_;
  my $fn = File::Spec->catfile(install_dir($dist_name), 'config.pl');
  if(-e $fn)
  {
    my $fh;
    open($fh, '<', $fn) || die "error reading $fn $!";
    my $pl = do { local $/; <$fh> };
    close $fh;
    my $config = eval $pl;
    die $@ if $@;
    return $config;
  }
  else
  {
    return {};
  }
}


sub install_config_set;
sub install_config_set
{
  my($dist_name, $one, $two) = @_;
  ($dist_name, $one, $two) = @ARGV unless defined $dist_name && defined $one;
  if(defined $two)
  {
    my($key, $value) = ($one, $two);
    my $config = install_config_get $dist_name;
    $config->{$key} = $value;
    return install_config_set $dist_name, $config;
  }
  else
  {
    my($config) = ($one);
    croak "config is not a hash!" unless ref $config eq 'HASH';
    require Data::Dumper;
    my $dd = Data::Dumper
      ->new([$config],['x'])
      ->Indent(1)
      ->Terse(0)
      ->Purity(1)
      ->Sortkeys(1)
      ->Dump;
    my $fh;
    _mkpath($dist_name);
    my $fn = File::Spec->catfile(install_dir($dist_name), 'config.pl');
    open($fh, '>', $fn) || die "error writing $fn $!";
    print $fh 'do { my ';
    print $fh $dd;
    print $fh '$x;}';
    close $fh;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::ShareDir::Dist::Install - Install per-dist shared files

=head1 VERSION

version 0.07

=head1 SYNOPSIS

 use File::ShareDir::Dist;
 install_config_set 'Foo-Bar-Baz' => {
   key1 => 'value1';
   key2 => 'value2';
 };

=head1 DESCRIPTION

This is L<File::ShareDir::Dist>'s install-time companion.
Unlike L<File::ShareDir::Install> it does not integrate with EUMM out of the box,
possibly a feature or a bug depending on your point of view.  Provides a simple
interface for getting and setting the dist configuration at install time.  The
dist config is just a C<config.pl> in the share directory that contains a hash
that can be read at runtime.

=head1 FUNCTIONS

=head2 install_dir

 my $dir = install_dir $dist_name;

Returns the directory for the share dir at install time.  This will be of the form
C<blib/lib/auto/share/dist/...>.

=head2 install

 install $source_dir, $dist_name;
 % perl -MFile::ShareDir::Dist= -e install $source_dir $dist_name

Install the given source directory to the dist share dir C<$dist_name>.
Can be called from Perl, or at the command-line as shown.

=head2 install_config_get

 my $config = install_config_get $dist_name;

Get the config for the dist.

=head2 install_config_set

 install_config_set $dist_name, $config;
 install_config_set $dist_name, $key => $value;
 % perl -MFile::ShareDir::Dist= -e install_config_set $dist_name $key $value

Set the config for the dist.  Can be a hash, which REPLACES the existing config,
a key/value pair which adds to the config.  Can also be run at the command-line
as shown.

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Yanick Champoux (yanick)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017,2018 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
