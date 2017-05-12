package HTML::SiteTear::Root;

use strict;
use warnings;
use URI::file;
#use Data::Dumper;

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(source_path
                             source_root_uri
                             resource_folder_name
                             page_folder_name
                             target_path
                             site_root_local_uri
                             site_root_uri
                             allow_abs_link
                             only_subitems));

our $VERSION = '1.45';

=head1 NAME

HTML::SiteTear::Root - a root object in a parent chain.

=head1 SYMPOSIS

  use HTML::SiteTear::Root;

  $root = HTML::SiteTear::Root->new('source_path' => $source_path,
                                    'target_path' => $destination_path);

=head1 DESCRIPTION

An instanece of this module is for a root object in a parent chain and manage a relation tabel of all source pathes and target pathes. Also gives default folder names.

=cut

our $defaultpage_folder_name = 'pages';
our $defaultresource_folder_name = 'assets';

=head1 METHODS

=head2 new

    $root = HTML::SiteTear::Root->new('source_path' => $source_path,
                                      'target_path' => $destination_path);

make a new instance.

=cut

sub new {
    my $class = shift @_;
    my %args = @_;
    my $self = $class->SUPER::new(\%args);
    $self->{'fileMapRef'} = {};
    $self->{'copiedFiles'} = [];
    $self->set_default_folder_names;
    
    if ($self->site_root_path) {
        $self->site_root_path($self->site_root_path);
        if ($self->site_root_uri) {
            $self->allow_abs_link(1);
            $self->site_root_local_uri(URI::file->new($self->site_root_path));
            $self->site_root_uri(URI->new($self->site_root_uri));
        }
    }
    $self->source_root_uri(URI::file->new($self->source_path));
    return $self;
}

sub set_default_folder_names {
    my ($self) = @_;
    $self->resource_folder_name($defaultresource_folder_name);
    $self->page_folder_name($defaultpage_folder_name);
}

=head2 add_to_copyied_files

    $item->add_to_copyied_files($source_path)

Add a file path already copied to the copiedFiles table of the root object of the parent chain.

=cut

sub add_to_copyied_files {
    my ($self, $path) = @_;
    #$path = Cwd::realpath($path);
    push @{$self->{'copiedFiles'}}, $path;
    return $path;
}

=head2 exists_in_copied_files

    $item->exists_in_copied_files($source_path)

Check existance of $source_path in the copiedFiles entry.

=cut

sub exists_in_copied_files {
    my ($self, $path) = @_;
    return grep(/^$path$/, @{$self->{'copiedFiles'}});
}

=head2 add_to_filemap

    $root->add_to_filemap($source_path, $destination_uri);

Add to copyied file information into the internal table "filemap".
A fragment of $destination_uri is dropped.

=cut

sub add_to_filemap {
    my ($self, $source_path, $destination_uri) = @_;
    $destination_uri->fragment(undef);
    $self->{'fileMapRef'}->{$source_path} = $destination_uri;
    return $destination_uri;
}

=head2 exists_in_filemap

    $root->exists_in_filemap($source_path);

check $source_path is entry in FileMap

=cut

sub exists_in_filemap {
    my ($self, $path) = @_;
    return exists($self->{fileMapRef}->{$path});
}

sub item_in_filemap {
    my ($self, $path) = @_;
    return $self->{'fileMapRef'}->{$path};
}

sub exists_in_target_files {
    my ($self, $path) = @_;
    return grep(/^$path$/, values %{$self->{fileMapRef}});
}

=head2 rel_for_mappedfile

    $root->rel_for_mappedfile($source_path, $base_uri);

get relative URI of copied file of $source_path from $base_uri.

=cut

sub rel_for_mappedfile {
    my ($self, $source_path, $base_uri) = @_;
    my $target_uri = $self->{'fileMapRef'}->{$source_path};
    return $target_uri->rel($base_uri);
}

sub source_root_path {
    my $self = shift @_;
    return $self->source_path;
}

sub source_root {
    my $self = shift @_;
    return $self
}

sub site_root_path {
    my $self = shift @_;
    if (@_) {
        my $path = $_[0];
        if (-d $path and $path !~ /\/$/) {
            $path = $path.'/';
        }
        $self->{'site_root_path'} = $path;
    }
    return $self->{'site_root_path'};
}

=head1 SEE ALSO

L<HTML::SiteTear>, L<HTML::SiteTear::Page>, L<HTML::SiteTear::CSS>, L<HTML::SiteTear::Root>

=head1 AUTHOR

Tetsuro KURITA <tkurita@mac.com>

=cut

1;
