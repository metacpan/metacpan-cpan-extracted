package Haul;
use strict;
use Cwd;
use CPAN::DistnameInfo;
use File::Basename;
use File::Copy;
use File::Path;
use IPC::Run3;
use Module::Depends::Intrusive;
use vars qw($VERSION);
$VERSION = '2.24';

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  $self->_init(@_);
  return $self;
}

sub fetch {
  my $self = shift;
  my $what = shift;
  my $prefix;
  if (exists $self->{modules}->{$what}) {
    $prefix = $self->{modules}->{$what};
#  } elsif (exists $self->{distributions}->{$what}) {
#    $prefix = $self->{distributions}->{$what};
  } else {
    die "Could not find $what";
  }
  my $path = "authors/id/" . $prefix;
  my $filename = $self->_fetch($path);
  return $filename;
}

sub extract {
  my $self = shift;
  my $what = shift;
  my $filename = $self->fetch($what);

  my $d = CPAN::DistnameInfo->new($filename);
  my $dir = $d->distvname;

  return $dir if -d $dir;

  if ($filename =~ /\.tar\.gz$/ || $filename =~ /\.tgz$/) {
    $self->_extract_aux("tar xzf ../$filename", $dir);
  }

  die "failed to extract" unless -d $dir;
  return $dir;
}

sub _extract_aux {
  my $self = shift;
  my $command = shift;
  my $dir = shift;

  mkdir "test";
  chdir "test";
  system($command);

  my @dirs = grep { -d $_ } <*>;
  my @files = grep { -f $_ } <*>;
  if (@files) {
    chdir "..";
    move("test", $dir);
    return;
  }
  if (scalar(@dirs) == 1) {
    move($dirs[0], "../$dir");
    rmdir "test";
    chdir "..";
    return;
  } else {
    chdir "..";
    move("test", $dir);
    return;
  }
}

sub install {
  my $self = shift;
  my $what = shift;
  my $dir = $self->extract($what);
  my $perl = $self->perl;

  my $deps = Module::Depends::Intrusive->new->dist_dir($dir)->find_modules;
  my $requires = $deps->requires;

  foreach my $module (keys %$requires) {
    my $version = $requires->{$module};
    my $installed = $self->installed($module);
    next if defined $installed && $version <= $installed;
#    warn "need to install $module ($version > $installed)";
    $self->install($module);
    $installed = $self->installed($module);
    next if defined $installed && $version <= $installed;
    die "failed to install $module";
  }

  my $cwd = cwd;
  chdir $dir;
  if (-f "Makefile.PL") {
    $self->run($perl, "Makefile.PL");
    $self->run("make");
    $self->run("make", "test");
    $self->run("make", "install");
    my $installed = $self->installed($what);
    die "$what failed to install" unless $installed;
  } else {
    die "need code here to install $dir";
  }
  chdir $cwd;
}

sub run {
  my $self = shift;
  my @commands = @_;
  my($out, $err);
#  warn "(@commands)\n";
  run3 [@commands], \undef, \$out, \$err;
#warn "[STDERR: $err]\n";
  return($out, $err);
}

sub installed {
  my $self = shift;
  my $module = shift;
  my $perl = $self->perl;

  my $code;

  if ($module eq 'perl') {
    $code = qq(print "VERSION IS $]\n");
  } else {
    $code = qq(use $module; print 'VERSION IS ' . \$${module}::VERSION . "\n");
  }

  my $command = "$perl -e '$code'";

  my($in, $out, $err);
  run3 [$perl, '-e', $code], \$in, \$out, \$err;

  return if $err;
  my($version) = $out =~ /VERSION IS (.+)\n/;
  return $version || "0E0";
}

sub _init {
  my($self, %conf) = @_;

  $self->perl($conf{perl} || $^X);
  $self->_parse_packages_details;
}

sub perl {
  my($self, $perl) = @_;
  if (defined $perl) {
    die "perl not at $perl" unless -f $perl;
    $self->{perl} = $perl;
  } else {
    return $self->{perl};
  }
}

sub _parse_packages_details {
  my $self = shift;
  my $filename = $self->_fetch("modules/02packages.details.txt.gz");
  open(IN, "zcat $filename |");
  # skip the header
  while(my $line = <IN>) {
    last if $line eq "\n";
  }
  while(my $line = <IN>) {
    chomp $line;
    my($module, $moduleversion, $prefix) = split ' ', $line;
    die "$line = $module/$moduleversion/$prefix" unless defined $prefix;
    $self->{modules}->{$module} = $prefix;
#    my $d = CPAN::DistnameInfo->new($prefix);
#    my $dist = $d->dist;
#    my $distversion = $d->version;
#    my $distvname = $d->distvname;
#    next unless $dist;
#    next unless $distversion; # ignore stupid packages
#    $self->{distributions}->{$dist} = $prefix;
  }
  close(IN);
}

sub _fetch {
  my $self = shift;
  my $path = shift;
  my $basename = basename($path);
  my $url = "http://www.cpan.org/$path";

  if ($path =~ m{/perl-5\.}) {
    die "do not install perl";
  }

  unless (-f $basename) {
    system("wget -N $url");
  }
  die "Error fetching $url" unless -f $basename;
  return $basename;
}

1;

__END__

=head1 NAME

Haul - Haul packages off CPAN and do things with them

=head1 SYNOPSIS

  use Haul;
  my $h = Haul->new;

  # report whether a module is installed
  my $version = $h->installed("Acme::Colour");

  # fetch a package from CPAN
  my $filename = $h->fetch("Acme::Colour");

  # fetch and extract a package from CPAN
  my $dir = $h->extract("Acme::Colour");

  # install a module from CPAN (and its deps)
  $h->install("Acme::Colour");

=head1 DESCRIPTION

This module knows about CPAN modules. It can report whether a module
is installed, can retrieve packages off CPAN that relate to a module,
extract them into a directory for you, and even install modules and
all their dependencies.

There are existing tools which do this job, but they are very
complicated and only deal with the current perl program. Haul can deal
with an external perl program, and so is ideal for build systems, SDK
building and automated CPAN testing.

Throughout this module, we use module names (such as "Acme::Colour")
instead of package names (such as "Acme-Colour"). Later releases may be
more featureful.

=head1 METHODS

=head2 new

This is the constructor. It takes an optional argument, which is the
path to the perl program to install modules to.

  my $h = Haul->new;
  my $h = Haul->new(perl => "/home/acme/perl583/bin/perl");

=head2 installed

This method reports the version number of an installed module. It
returns undef if the module is not installed.

  if ($h->installed("Acme::Colour") { ... }

=head2 fetch

Downloads the package related to a module and returns the path to it.

  my $filename = $h->fetch("Acme::Colour");

=head2 extract

Downloads the package related to a module, extracts it into a
directory and returns you the path to it.

  my $dir = $h->extract("Acme::Colour");

=head2 install

Downloads the package related to a module, and installs it (and its
dependencies). Make sure you have appropriate permissions.

  $h->install("Acme::Colour");

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright (C) 2004, Leon Brocard

This module is free software; you can redistribute it or modify it under
the same terms as Perl itself.
