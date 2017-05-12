package HTML::SiteTear;

use 5.008;
use strict;
use warnings;
use File::Basename qw(basename fileparse);
use File::Spec;
use File::Path 2.0 qw(make_path);
use File::Find;
use Cwd;
use Carp;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors( qw(source_path
                             site_root_path
                             site_root_url
                             target_path
                             member_files) );

use HTML::SiteTear::Root;
use HTML::SiteTear::Page;

# use Data::Dumper;

=head1 NAME

HTML::SiteTear - Make a separated copy of a part of the site

=head1 VERSION

Version 1.46

=cut

our $VERSION = '1.46';

=head1 SYMPOSIS

 use HTML::SiteTear;

 $p = HTML::SiteTear->new("/dev1/website/index.html");
 $p->copy_to("/dev1/website2/newindex.html");

=head1 DESCRIPTION

This module is to make a separated copy of a part of web site in local file system. All linked files (HTML file, image file, javascript, cascading style shieet) from a source HTML file will be copied under a new page.

This module is useful to make a destributable copy of a part of a web site.

=head1 METHODS

=head2 new

    $p = HTML::SiteTear->new($source_path);
    
    $p = HTML::SiteTear->new('source_path' => $source_path,
                             'site_root_path' => $root_path,
                             'site_root_url' => $url);

    $p = HTML::SiteTear->new('source_path' => $source_dir,
                             'member_files' => \@pathes);

Make an instance of this module. The path to source HTML file "$source_path" is required as an arguemnt. See L</ABSOLUTE LINK> about 'site_root_path' and 'site_root_url' parameters

=cut

our @DEFAULT_HTML_SUFFIXES = qw(.html .htm .xhtml);

sub new {
    my $class = shift @_;
    my $self;
    if (@_ == 1) {
        $self = bless {'source_path' => shift @_}, $class;

    } else {
        my %args = @_;
        $self = $class->SUPER::new(\%args);
    }
    
    $self->source_path or croak "source_path is not specified.\n";
    (-e $self->source_path) or croak $self->source_path." is not found.\n";
        
    if (-d $self->source_path) {
        unless (File::Spec->file_name_is_absolute($self->source_path)) {
            my $cwd = fix_dir_path(cwd);
            $self->source_path(
                URI::file->new($self->source_path)->abs($cwd)->file);
        }
        
        unless ($self->member_files) {
            my @htmlfiles;
            my $wanted = sub {
                my $name = $_; 
                if (grep {$name =~ /\Q$_\E$/} @DEFAULT_HTML_SUFFIXES) {
                    push @htmlfiles, $File::Find::name;
                }
            };
            find($wanted, $self->source_path);
            if (@htmlfiles) {
                $self->member_files(\@htmlfiles);
            } else {
                croak "Can't find HTML files under $self->source_path.\n";
            }
        }
        $self->source_path(fix_dir_path($self->source_path));
        
    } else {
        if ($self->member_files) {
            croak $self->source_path.
                    " is not a directory. Must be a directory.\n";
        }    
    }
        
    return $self;
}

sub page_filter {
    my ($class, $module) = @_;
    return HTML::SiteTear::Page->page_filter($module);
}

=head2 copy_to

    $p->copy_to($destination_path);

Copy $source_path into $destination_path. All linked file in $source_path will be copied into directories under $destination_path

=cut

sub copy_to {
    #print "start copy_to in SiteTear.pm\n";
    my ($self, $destination_path) = @_;
    my $source_path = $self->source_path;
    if ($self->member_files) {
        return $self->copy_to_dir($destination_path);
    }

    if (-e $destination_path){
        if (-d $destination_path) {
            $destination_path = File::Spec->catfile($destination_path,
                                               basename($source_path));
        }
    } else {
        my ($name, $dir) = fileparse($destination_path);
        make_path($dir);
        unless ($name) {
            $destination_path = File::Spec->catfile($dir,
                                                basename($source_path));
        }
    }
    
    $self->target_path($destination_path);
    my $root = HTML::SiteTear::Root->new(%$self);
    my $new_source_page = HTML::SiteTear::Page->new(
                                        'parent' => $root,
                                        'source_path' => $source_path);
    $new_source_page->linkpath(basename($destination_path) );
    #$new_source_page->link_uri(URI::file->new(Cwd::abs_path($destination_path)));
    $new_source_page->link_uri(URI::file->new_abs($destination_path));
    $new_source_page->copy_to_linkpath;
    return $new_source_page;
}

sub fix_dir_path {
    my ($path) = @_;
    return File::Spec->catfile($path, File::Spec->curdir);
}

sub copy_to_dir {
    my ($self, $destination_path) = @_;
    if (-e $destination_path){
        unless (-d $destination_path) {
            croak $destination_path."is not directory.\n";
        }
    }

    $destination_path = fix_dir_path($destination_path);
    
    $self->target_path($destination_path);
    my $root = HTML::SiteTear::Root->new(%$self);
    my $source_root_uri = $root->source_root_uri;
    my $dest_uri = URI::file->new_abs($destination_path);
    my @results = map {
        my $a_member_file = do {
            if (File::Spec->file_name_is_absolute($_)) {
                $_;
            }else {
                URI::file->new($_)
                    ->abs($self->source_path)->file;
            }};
        my $page = HTML::SiteTear::Page->new('parent' => $root,
                                             'source_path' => $a_member_file);
        my $rel_from_source_root = $page->source_uri->rel($source_root_uri);
        my $abs_from_dest = $rel_from_source_root->abs($dest_uri);
        $page->link_uri($abs_from_dest);
        $page->copy_to_linkpath;
        $page;
    } @{$self->member_files};
    return \@results;
}

=head1 ABSOLUTE LINK

The default behavior of HTML::SiteTear follows all of links in HTML files. In some case, there are links should not be followd. For example, if theare is a link to the top page of the site, all of files in the site will be copyied. Such links should be converted to absolute links (e.g. "http://www.....").

To convert links should not be followed into absolute links,

=over

=item *

Give parameters of 'site_root_path' and 'site_root_url' to L</new> method.

=over

=item 'site_root_path'

A file path of the root of the site in the local file system.

=item 'site_root_url'

A URL corresponding to 'site_root_path' in WWW.

=back

=item *

Relative links to upper level files from 'source_path' are automatically converted to absolute links.

=item *

To indicate links should be conveted to absolute links, enclose links in HTML files with specail comment tags <!-- begin abs_link --> and <!-- end abs_link -->

=back

=head1 AUTHOR

Tetsuro KURITA <tkurita@mac.com>

=cut

1;
