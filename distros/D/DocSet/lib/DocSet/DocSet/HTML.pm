package DocSet::DocSet::HTML;

use strict;
use warnings;

use File::Spec::Functions;

use DocSet::Util;
use DocSet::NavigateCache ();

use vars qw(@ISA);
use DocSet::DocSet ();
@ISA = qw(DocSet::DocSet);

# what's the output format
sub trg_ext {
    return 'html';
}

sub init {
    my $self = shift;

    $self->SUPER::init(@_);

    # configure HTML specific run-time
    $self->set(dst_mime => 'text/html');
    $self->set(tmpl_mode => 'html');
    $self->set_dir(dst_root => $self->get_dir('dst_html'));

    note "\n";
    banner("[scan] HTML DocSet: " . $self->get('title') );
}

sub complete {
    my ($self) = @_;

    note "\n";
    banner("[render] HTML DocSet: " . $self->get('title') );

    $self->write_sitemap_file() if $self->sitemap;

    $self->write_index_file();
}

# generate the sitemap.html of the docset below the current root
##################################
sub write_sitemap_file {
    my ($self) = @_;

    my $cache = $self->cache;

    my $dir = {
        abs_doc_root   => $self->get_dir('abs_doc_root'),
        rel_doc_root   => $self->get_dir('rel_parent_root'),
        path_from_base => $self->get_dir('path_from_base'),
    };

    my $meta = $self->sitemap;
    my $file = exists $meta->{link} ? $meta->{link} : "sitemap.html";
    my $navigator = DocSet::NavigateCache->new($self->cache->path, $meta->{id});
    my %args = (
         nav      => $navigator,
         meta     => $meta,
         dir      => $dir,
         version  => $self->get('version')||'',
         date     => get_date(),
         last_modified => get_timestamp(),
    );

    my $dst_root  = $self->get_dir('dst_html');
    my $dst_file = "$dst_root/$file";
    my $mode = $self->get('tmpl_mode');
    my $tmpl_file = 'sitemap';
    my $vars = { doc => \%args };
    my $tmpl_root = $self->get_dir('tmpl');
    my $content = proc_tmpl($tmpl_root, $tmpl_file, $mode, $vars);
    note "+++ Creating $dst_file";
    DocSet::Util::write_file($dst_file, $content);
}

# generate the index.html based on the doc entities it includes, in
# the following order: docsets, books, chapters
#
# XXX: Using the same template file create the long and the short index
# html files
##################################
sub write_index_file {
    my ($self) = @_;

    my @toc  = ();
    my $cache = $self->cache;

    # TOC
    my @node_groups = @{ $self->node_groups };
    my @ids = $cache->ordered_ids;

    # create the toc while skipping over hidden files
    if (@node_groups && @ids) {
        # index's toc is built from groups of items' meta data
        while (@node_groups) {
            my ($title, $count) = splice @node_groups, 0, 2;
            push @toc, {
                group_title => $title,
                subs  => [map {$cache->get($_, 'meta')} 
                          grep !$cache->is_hidden($_), 
                          splice @ids, 0, $count],
            };
        }
    }
    else {
        # index's toc is built from items' meta data
        for my $id (grep !$cache->is_hidden($_), $cache->ordered_ids) {
            push @toc, $cache->get($id, 'meta');
        }
    }

    my $dir = {
        abs_doc_root   => $self->get_dir('abs_doc_root'),
        rel_doc_root   => $self->get_dir('rel_parent_root'),
        path_from_base => $self->get_dir('path_from_base'),
    };

    my $meta = {
         id       => $self->get('id'),
         stitle   => $self->get('stitle'),
         title    => $self->get('title'),
         abstract => $self->get('abstract'),
    };

    my $navigator = DocSet::NavigateCache->new($self->cache->path,
                                               $self->get('id'));
    my %args = (
         nav      => $navigator,
         toc      => \@toc,
         meta     => $meta,
         dir      => $dir,
         version  => $self->get('version')||'',
         date     => get_date(),
         last_modified => get_timestamp(),
         pdf_doc  => $self->pdf_doc,
    );

    # plaster index top and bottom docs if defined (after converting them)
    if (my $body = $self->get('body')) {
        my $src_root = $self->get_dir('src_root');
        my $dst_mime = $self->get('dst_mime');

        for my $sec (qw(top bot)) {
            my $src_file = $body->{$sec};
            next unless $src_file;

            my $src_ext = filename_ext($src_file)
                or die "cannot get an extension for $src_file";
            my $src_mime = $self->ext2mime($src_ext)
                or die "unknown extension: $src_ext";
            my $conv_class = $self->conv_class($src_mime, $dst_mime);
            require_package($conv_class);

            my $chapter = $conv_class->new(
                tmpl_mode    => $self->get('tmpl_mode'),
                tmpl_root    => $self->get_dir('tmpl'),
                src_uri      => $src_file,
                src_path     => catfile($src_root, $src_file),
            );
            $chapter->scan();
            $args{body}{$sec} = $chapter->converted_body();
        }

    }

    my $dst_root  = $self->get_dir('dst_html');
    my $dst_file = "$dst_root/index.html";
    my $mode = $self->get('tmpl_mode');
    my $tmpl_file = 'index';
    my $vars = { doc => \%args };
    my $tmpl_root = $self->get_dir('tmpl');
    my $content = proc_tmpl($tmpl_root, $tmpl_file, $mode, $vars);
    note "+++ Creating $dst_file";
    DocSet::Util::write_file($dst_file, $content);
}

# search for a pdf version in the parallel tree and copy it to
# the same dir as the html version (we link to it from the html)
sub pdf_doc {
    my $self = shift;

    my $id = $self->get('id');
    my $dst_path = catfile $self->get_dir('dst_root'), "$id.pdf";
    my $src_path = catfile $self->get_dir('dst_ps')  , "$id.pdf";

#print "TRYING $dst_path $src_path \n";

    my %pdf = ();
    if (-e $src_path) {
        copy_file($src_path, $dst_path);
        %pdf = (
            size => format_bytes(-s $dst_path),
            link => filename($dst_path),
        );
#        gzip_file($dst_path);
#        my $gzip_path = "$dst_path.gz";
#        %pdf = (
#            size => format_bytes(-s $gzip_path),
#            link => filename($gzip_path),
#        );
    }
#dumper \%pdf;

    return \%pdf;

}


1;
__END__

=head1 NAME

C<DocSet::DocSet::HTML> - A subclass of C<DocSet::DocSet> for generating HTML docset

=head1 SYNOPSIS

See C<DocSet::DocSet>

=head1 DESCRIPTION

This subclass of C<DocSet::DocSet> converts the source docset into a
set of HTML documents linking its items with autogenerated
I<index.html>.

=head2 METHODS

See the majority of the methods in C<DocSet::DocSet>

=over

=item * trg_ext

  $self->trg_ext();

returns the extension of the target files. I<html> in the case of this
sub-class.

=item * init

  $self->init(@_);

calls C<DocSet::DocSet::init> and then initializes its own HTML output
specific settings.

=item * complete

see C<DocSet::DocSet>

=item * write_index_file

  $self->write_index_file();

creates I<index.html> file linking all the items of the docset
together.

=back

=head1 AUTHORS

Stas Bekman E<lt>stas (at) stason.orgE<gt>

=cut
