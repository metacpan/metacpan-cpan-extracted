package JSAN::Shell;

# Provides the main functionality for the JSAN CLI installer

use strict;
use warnings;

use base 'Class::Accessor::Fast';
use File::Spec ();
use File::Path ();
use File::Temp ();
use Cwd;
use JSAN::Indexer;
use LWP::Simple;

our $VERSION = '0.05';
our $SHELL;

__PACKAGE__->mk_accessors(qw[_index my_mirror]);

sub new {
    return $SHELL if $SHELL;
    my ($class) = shift;
    my $self = $class->SUPER::new({@_});
    $self->my_mirror('http://openjsan.org') unless $self->my_mirror;
    return $SHELL = $self;
}

sub index {
    my ($self) = @_;
    return $self->_index if $self->_index;
    $self->_index(JSAN::Indexer->new);
    return $self->_index;
}

sub install {
    my ($self, $lib, $prefix) = @_;
    die "You must supply a prefix to install to" unless $prefix;
    $prefix = File::Spec->rel2abs($prefix);
    File::Path::mkpath($prefix);
    my $library = $self->index->library->retrieve($lib);
    die "No such library $lib" unless $library;

    die "$lib is up to date: " . $library->version . "\n"
      if $self->_check_uptodate($library, $prefix);

    my $release = $library->release;

    my $deps = $release->meta->requires;
    foreach my $dep ( @{$deps} ) {
        eval { $self->install($dep->{name}, $prefix) };
    }

    my $link = join '', $self->my_mirror, $release->source;
    my $dir  = File::Temp::tempdir(CLEANUP => 0);
    my $file = (split /\//, $link)[-1];
    print $release->source . " -> $dir/$file\n";
    my $tarball = LWP::Simple::get($link);
    die "Downloading dist [$link] failed." unless $tarball;
    
    my $pwd = getcwd();
    chdir "$dir";
    print "Unpacking $file\n";
    open DIST, "> $file" or die $!;
    print DIST $tarball;
    close DIST;
    `tar xzvf $file`;

    print "Installing libraries to $prefix\n";
    chdir $release->srcdir;
    `cp -r lib/* $prefix`;

    chdir $pwd;
}

sub index_create {
    my ($self) = @_;
    my $mirror = join '/', $self->my_mirror, 'index.yaml';
    JSAN::Indexer->create_index_db($mirror);
}

sub index_get {
    my ($self) = @_;
    my $rc = LWP::Simple::mirror($self->my_mirror . "/index.sqlite", $JSAN::Indexer::INDEX_DB);
    die "Could not mirror index" unless -e $JSAN::Indexer::INDEX_DB;
    print "Downloaded index.\n";
}

sub _check_uptodate {
   my ($self, $library, $prefix) = @_;
   my $lib = $library->name;
   $lib =~ s[\.][/]g;
   $lib = "$prefix/$lib.js";

   if ( -e $lib ) {
       open LIB, $lib or die "Up to date check failed for " . $library->name;
       while (<LIB>) {
           my ($version) = $_ =~ /VERSION\s*(?:=|:)\s*[^\d._]*([\d._]+)/;
           next unless $version;
           return 1 if $version eq $library->version;
       }
       close LIB;
   }
   return;
}

1;

__END__

=head1 NAME

JSAN::Shell -- JavaScript Archive Network (JSAN) Shell Backend

=head1 AUTHOR

Casey West <F<casey@geeknest.com>>.

Adam Kennedy <F<adam@ali.as>>, L<http://ali.as>

=head1 COPYRIGHT

  Copyright (c) 2005 Casey West.  All rights reserved.
  This module is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

=cut

