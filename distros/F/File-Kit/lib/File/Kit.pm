package File::Kit;

use strict;
use warnings;

use File::Kvpar;
use File::Copy qw(copy move);

use vars qw($VERSION);
$VERSION = '0.04';

use constant ADDFILE => 'ADDFILE';
use constant RMVFILE => 'RMVFILE';

sub new {
    my $cls = shift;
    unshift @_, 'path' if @_ % 2;
    my $self = bless {
        'meta'  => {},
        'files' => [],
        'move' => \&move,
        @_,
    }, $cls;
    $self->init;
}

sub path { $_[0]->{'path'} }

sub init {
    my ($self) = @_;
    my $path = $self->path;
    -d $path ? $self->load($path) : $self->create($path) if defined $path;
    return $self;
}

sub load {
    my ($self, $path) = @_;
    my $kitkv   = $self->{'kitkv'}   ||= File::Kvpar->new('<+', "$path/kit.kv");
    my $fileskv = $self->{'fileskv'} ||= File::Kvpar->new('<+', "$path/files.kv");
    $self->{'meta'} = $kitkv->head;
    $self->{'files'} = [ $fileskv->elements ];
    return $self;
}

sub create {
    my ($self, $path) = @_;
    mkdir $path         or die "Can't mkdir $path: $!";
    mkdir "$path/files" or die "Can't mkdir $path/files: $!";
    my $kitkv   = $self->{'kitkv'}   ||= File::Kvpar->new('>+', "$path/kit.kv");
    my $fileskv = $self->{'fileskv'} ||= File::Kvpar->new('>+', "$path/files.kv");
    $kitkv->write($self->{'meta'});
    $self->{'files'} ||= [];
    return $self;
}

sub edit {
    my ($self) = @_;
    $self->{'edits'} ||= [];
    return $self;
}

sub add {
    my $self = shift;
    my $edits = $self->{'edits'} ||= [];
    my @files;
    foreach (@_) {
        if (ref $_) {
            @files % 2 or die;
            push @files, $_;
        }
        else {
            @files % 2 or push @files, {};
            push @files, $_;
        }
    }
    push @files, {} if @files % 2;
    while (@files) {
        my ($path, $meta) = splice @files, 0, 2;
        push @$edits, [ ADDFILE, $path, $meta ];
    }
    return $self;
}

sub save {
    my ($self) = @_;
    my %fh;
    my $fileskv = $self->{'fileskv'};
    my $root = $self->path;
    my $edits = $self->{'edits'} ||= [];
    while (@$edits) {
        local $_ = shift;
        my ($action, @params) = @$_;
        if ($action eq ADDFILE) {
            @params == 2 or die;
            my ($path, $meta) = @params;
            my $name = basename($path);
            $meta->{'origin'} = $path;
            $meta->{'name'  } = $name;
            my $newpath = "$root/files/$name";
            if ($self->{'move'}->($path, $newpath)) {
                $fileskv->append($meta);
            }
            else {
                die;
            }
        }
        elsif ($action eq RMVFILE) {
            die "RMVFILE not yet implemented";
            @params == 1 or die;
            my ($file) = @params;
            my @filemeta = grep { $file eq $_->{'#'} } $fileskv->elements;
            1;
        }
    }
    @{ $self->{'edits'} } = ();
    return $self;
}

sub files {
    my ($self) = @_;
    my $files = $self->{'files'} ||= [];
    return @$files if @$files;
    return @$files = $self->{'kvfiles'}->elements;
}

1;

=pod

=head1 NAME

File::Kit - Gather files and their metadata together in one place

=head1 SYNOPSIS

    $kit = File::Kit->new($dir);
    $kit = File::Kit->create($dir, %meta);
    $kit->add($filepath1, \%filemetadata1, $filepath2, \%filemetadata2, ...);
    @filenames = $kit->files;
    $file = $kit->file($filename);
    $kit->remove(@filepaths);
    $meta = $kit->get(@kitmetadatakeys);
    $kit->set(%kitmetadata);
    $kit->save;

=cut
