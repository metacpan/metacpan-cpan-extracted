package DocSet::DocSet;

use strict;
use warnings;

use DocSet::Util;
use DocSet::RunTime;
use DocSet::Cache ();
use DocSet::Doc ();
use DocSet::NavigateCache ();

use File::Spec::Functions;

use vars qw(@ISA);
use DocSet::Config ();
@ISA = qw(DocSet::Config);

########
sub new {
    my $class = shift;
    my $self = bless {}, ref($class)||$class;
    $self->init(@_);
    return $self;
}

sub init {
    my ($self, $config_file, $parent_o, $src_rel_dir) = @_;

    $self->read_config($config_file, $parent_o);

    # are we inside a super docset?
    if ($parent_o and ref($parent_o)) {
        $self->{parent_o} = $parent_o;
        $self->merge_config($src_rel_dir);
    }

    # we assume that the docset was not modified since the last run.
    # if at least one source doc/config file was modified, the docset
    # is considered modified as well and should be rebuild. It's the
    # responsibility of the modified object to set its parent docset
    # status to 'modified'.
    $self->modified(0);

    # currently a given docset is considered to be in the 'modified' state,
    # if any of these conditions is true:
    #
    # 1. the included docset is 'modified':
    # 2. the included chapter is 'modified':
    # 3. the included 'copy as-is' files are 'modified':
    # 4. config.cfg is newer than corresponding index.html
    # 5. the cache file is missing

}

sub scan {
    my ($self) = @_;

    my $src_root = $self->get_dir('src_root');
    my $purge = DocSet::RunTime::get_opts('rebuild_all') ? 1 : 0;
    my $update = 1; # see DocSetCache::new
    # each output mode need its own cache, because of the destination
    # links which are different
    my $mode = $self->get('tmpl_mode');
    my $cache_file = "$src_root/cache.$mode.dat";

    # - create the new cache object for updates
    # - rebuild_all forces  the existing cache's purge
    my $cache = DocSet::Cache->new($cache_file, $update, $purge);
    $self->cache($cache); # add to the docset object

    # a complete rebuild of the docset is done when:
    # - we are told to do so:
    # - if the cache file doesn't exist
    # - or the we failed to retrieve an existing cache
    if (DocSet::RunTime::get_opts('rebuild_all') ||
        $cache->read_error || !$cache->can_read) {
        $self->modified(1);
        $self->rebuild(1);
    }

    # cache the index node meta data
    $cache->index_node(id       => $self->get('id'),
                       stitle   => $self->get('stitle'),
                       title    => $self->get('title'),
                       abstract => $self->get('abstract'),
                       extra    => $self->get('extra'),
                      );

    # croaks if the docset id is duplicated
    $self->check_duplicated_docset_ids();

    # cache the location of the parent node cache
    if (my $parent_o = $self->get('parent_o')) {
        my $parent_src_root   = $parent_o->get_dir('src_root');
        (my $rel2parent_src_root = $src_root) =~ s|\Q$parent_src_root||;
        my $rel_dir = join '/', ("..") x ($rel2parent_src_root =~ tr|/|/|);
        my $parent_cache_path = "$parent_src_root/cache.$mode.dat";
        $cache->parent_node($parent_cache_path,
                            $self->get('id'),
                            $rel_dir);
        $self->set_dir(rel_parent_root => $rel_dir);
    }
    else {
        $self->set_dir(rel_parent_root => '.');
    }

    ###
    # scan the nodes of the current level and cache the meta and other
    # data

    my $hidden = 0;
    my @nodes_by_type = @{ $self->nodes_by_type };
    while (@nodes_by_type) {
        my ($type, $data) = splice @nodes_by_type, 0, 2;
        if ($type eq 'docsets') {
            my $docset = $self->docset_scan_n_cache($data, $hidden);
            $self->modified(1) if $docset->modified();
            $self->object_store($docset)
                if defined $docset and ref $docset;

        } elsif ($type eq 'chapters') {
            my $chapter = $self->chapter_scan_n_cache($data, $hidden);
            if (defined $chapter and ref $chapter) {
                # modified chapter --> modified docset
                $self->modified(1);
                $self->object_store($chapter)
            }
        } elsif ($type eq 'links') {
            $self->link_scan_n_cache($data, $hidden);
            # we don't need to process links
        } elsif ($type eq 'sitemap') {
            $self->sitemap_cache($data, $hidden);
            # we don't need to process links
        } else {
            # nothing
        }

    }

    # the same but for the hidden objects
    $hidden = 1;
    my @hidden_nodes_by_type = @{ $self->hidden_nodes_by_type };
    while (@hidden_nodes_by_type) {
        my ($type, $data) = splice @hidden_nodes_by_type, 0, 2;
        if ($type eq 'docsets') {
            my $docset = $self->docset_scan_n_cache($data, $hidden);
            $self->object_store($docset)
                if defined $docset and ref $docset;

        } elsif ($type eq 'chapters') {
            my $chapter = $self->chapter_scan_n_cache($data, $hidden);
            if (defined $chapter and ref $chapter) {
                # modified chapter --> modified docset
                $self->modified(1);
                $self->object_store($chapter)
            }

        } else {
            # nothing
        }
    }

    $cache->node_groups($self->node_groups);

    # compare whether the config file is newer than the corresponding
    # index.html
    my $dst_root = $self->get_dir('dst_root');
    my $config_file = $self->{config_file};

    my $dst_index = "$dst_root/index.html";
    my ($should_update, $reason) = 
        $self->should_update($config_file, $dst_index);
    $self->modified(1) if $should_update;

    # if @body{qw(top bot)} component files exist, check whether they
    # are newer than the target index.html file
    if (my $body = $self->get('body')) {
        my $src_root = $self->get_dir('src_root');
        for my $sec (qw(top bot)) {
            my $src_file = $body->{$sec};
            next unless $src_file;
            $src_file = catfile $src_root, $src_file;
            my ($should_update, $reason) = 
                $self->should_update($src_file, $dst_index);
            $self->modified(1) if $should_update;
        }
    }

    # sync the cache
    $cache->write;

    # copy non-pod files like images and stylesheets
    #
    # META: though this belongs to the 'render' part, we run it here,
    # since we need to know after the scan() whether the docset is
    # modified. a cleaner, logic-wise, solution would be only to check
    # modification times on files that may need to be copied as-is,
    # but to postpone the copying, if any, only to the render part of
    # the logic. We could also remove here all the files that don't
    # need to be copied, since they didn't change.
    $self->scan_copy_the_rest;

}


sub docset_scan_n_cache {
    my ($self, $src_rel_dir, $hidden) = @_;

    my $src_root = $self->get_dir('src_root');
    my $config_file =  "$src_root/$src_rel_dir/config.cfg";
    my $docset = $self->new($config_file, $self, $src_rel_dir);
    $docset->scan;

    # cache the child docset's meta data
    my $id = $docset->get('id');
    $self->cache->add($id);
    my $meta = {
                stitle   => $docset->get('stitle'),
                title    => $docset->get('title'),
                link     => "$src_rel_dir/index.html",
                abstract => $docset->get('abstract'),
                rel_path => $src_rel_dir,
               };
    $self->cache->set($id, 'meta', $meta, $hidden);

    # add the location of the cache file, so later we can traverse the
    # nodes, by just reading the cache files, which are linked to each
    # other both ways.
    my $mode = $self->get('tmpl_mode');
    my $child_cache_path = "$src_root/$src_rel_dir/cache.$mode.dat";
    $self->cache->set($id, 'child_cache_path', $child_cache_path);

    note "\n"; # mark the end of scan

    return $docset;
}



sub link_scan_n_cache {
    my ($self, $link, $hidden) = @_;
    my %meta = %$link; # make a copy
    my $id = delete $meta{id};
    $meta{title} = $meta{stitle} unless exists $meta{title};
    $meta{stitle} = $meta{title} unless exists $meta{stitle};
    $self->cache->add($id);
    $self->cache->set($id, 'meta', \%meta, $hidden);
}

sub sitemap_cache {
    my ($self, $link, $hidden) = @_;
    my %meta = %$link; # make a copy
    my $id = $meta{id};
    $meta{title}  = $meta{stitle} unless exists $meta{title};
    $meta{stitle} = $meta{title}  unless exists $meta{stitle};
    $self->cache->add($id);
    $self->cache->set($id, 'meta', \%meta, $hidden);

    # we will need to raise this flag to render the doc
    # XXX: consider creating a Sitemap class, so we can handle this
    # generically as chapters and docsets
    $self->{sitemap} = \%meta;
    # see Config::sitemap method
}

sub chapter_scan_n_cache {
    my ($self, $src_file, $hidden) = @_;

    my $id = $src_file;
    $self->cache->add($id);

    my $trg_ext = $self->trg_ext();

    my $src_root      = $self->get_dir('src_root');
    my $dst_root      = $self->get_dir('dst_root');
    my $abs_doc_root  = $self->get_dir('abs_doc_root');
    my $src_path      = "$src_root/$src_file";

    my $src_ext = filename_ext($src_file)
        or die "cannot get an extension for $src_file [$src_path]";
    my $src_mime = $self->ext2mime($src_ext)
        or die "unknown extension: $src_ext [$src_path]";
    (my $basename = $src_file) =~ s/\.$src_ext$//;

    # destination paths
    my $rel_dst_path = "$basename.$trg_ext";
    $rel_dst_path =~ s|^\./||; # strip the leading './'
    my $dst_path  = "$dst_root/$rel_dst_path";

    my $rel_doc_root = $rel_dst_path =~ m|/|
        ? join('/', ("..") x ($rel_dst_path =~ tr|/|/|))
        : '.';

    # push to the list of final chapter paths e.g. used by PS/PDF
    # build, which needs all the non-hidden chapters
    $self->trg_chapters($rel_dst_path) unless $hidden;

    ### to rebuild or not
    my ($should_update, $reason) = $self->should_update($src_path, $dst_path);
    if (!$should_update) {
        note "--- $src_file: skipping ($reason)";
        return undef;
    }

    ### init
    note "+++ $src_file: processing ($reason)";
    my $dst_mime = $self->get('dst_mime');
    my $conv_class = $self->conv_class($src_mime, $dst_mime);
    require_package($conv_class);

    my $chapter = $conv_class->new(
         docset         => $self,
         tmpl_mode      => $self->get('tmpl_mode'),
         tmpl_root      => $self->get_dir('tmpl'),
         src_root       => $src_root,
         dst_root       => $dst_root,
         src_uri        => $src_file,
         src_path       => $src_path,
         dst_path       => $dst_path,
         rel_dst_path   => $rel_dst_path,
         rel_doc_root   => $rel_doc_root,
         abs_doc_root   => $abs_doc_root,
         path_from_base => $self->get_dir('path_from_base'),
        );

    $chapter->scan();

    # cache the chapter's meta and toc data
    $self->cache->set($id, 'meta', $chapter->meta, $hidden);
    $self->cache->set($id, 'toc',  $chapter->toc,  $hidden);

    return $chapter;

}

####################
sub scan_copy_the_rest {
    my ($self) = @_;

    my @scan_copy_files = @{ $self->files_to_scan_copy() };

    return unless @scan_copy_files;

    my %to_copy = ();

    my $src_root = $self->get_dir('src_root');
    my $dst_root = $self->get_dir('dst_root');
    note "+++ Scanning the copy as-is files. Comparing $src_root with $dst_root";
    foreach my $src_path (@scan_copy_files){
        my $dst_path = $src_path;
#        # some OSs's File::Find returns files with no dir prefix root
#        # (that's what ()* is for
#        $dst_path =~ s/(?:$src_root)*/$dst_root/; 
        $dst_path =~ s/\Q$src_root/$dst_root/;

        # to rebuild or not to rebuild
        my ($should_update, $reason) = 
            $self->should_update($src_path, $dst_path);
        if (!$should_update) {
            note "--- skipping cp $src_path $dst_path ($reason)";
            next;
        }
        $self->modified(1); # dirty state
        note "+++ processing $src_path => $dst_path ($reason)";
        $to_copy{$src_path} = $dst_path;
    }

    $self->files_to_copy(\%to_copy);
}

sub render {
    my ($self) = @_;

    # if the docset wasn't modified, don't render the docset
    return unless $self->modified();

    $self->copy_the_rest;

    my $src_root = $self->get_dir('src_root');

    # each output mode need its own cache, because of the destination
    # links which are different
    my $mode = $self->get('tmpl_mode');
    my $path = "$src_root/cache.$mode.dat";
    my $cache = DocSet::Cache->new($path);

    die "Failed to read cache from $path: " . $cache->read_error
        if $cache->read_error;

    # render the objects no matter what kind are they
    for my $obj ($self->stored_objects) {
        $obj->render($cache);
    }

    $self->complete;

}

####################
sub copy_the_rest {
    my ($self) = @_;

    my %copy_files = %{ $self->files_to_copy };

    return unless %copy_files;

    my $src_root = $self->get_dir('src_root');
    my $dst_root = $self->get_dir('dst_root');
    note "+++ Copying the non-processed files from $src_root to $dst_root";
    while (my ($src_path, $dst_path) = each %copy_files) {
        note "+++ cp $src_path $dst_path";
        copy_file($src_path, $dst_path);
    }
}


# an abstract method
sub complete {}

# die with the error, and supply the context in which the error has happened
sub error {
    my $self = shift;

    my @context;
    push @context, "config file: $self->{config_file}";

    die map({"!!! err: $_\n"} @_),
        "in context:\n", map({"\t$_\n"} @context);

}

sub should_update {
    my ($self, $src_path, $dst_path) = @_;

    unless (-e $src_path) {
        $self->error("cannot find $src_path");
    }

    # to rebuild or not to rebuild
    my $not_modified = 
        (-e $dst_path and -M $dst_path < -M $src_path) ? 1 : 0;

    my $reason = $not_modified ? 'not modified' : 'modified';
    if ($self->rebuild()) {
        return (1, "$reason / forced");
    }
    else {
        return (!$not_modified, $reason);
    }

}

1;
__END__

=head1 NAME

C<DocSet::DocSet> - An abstract docset generation class

=head1 SYNOPSIS

  use DocSet::DocSet::HTML ();
  my $docset = DocSet::DocSet::HTML->new($config_file);
  
  # must start from the abs root
  chdir $abs_root;
  
  # must be a relative path to be able to move the generated code from
  # location to location, without adjusting the links
  $docset->set_dir(abs_root => ".");
  $docset->scan;
  $docset->render;

  my $should_update = $self->should_update($src_path, $dst_path);

=head1 DESCRIPTION

C<DocSet::DocSet> processes a docset, which can include other docsets,
documents and links. In the first pass it scans the linked to it
documents and other docsets and caches this information and the
objects for a later peruse. In the second pass the stored objects are
rendered. And the docset is completed.

This class cannot be used on its own and has to be subclassed and
extended, by the sub-classes which has a specific to input and output
formats of the documents that need to be processed. It handles only
the partial functionality which doesn't require format specific
knowledge.

=head2 METHODS

This class inherits from C<DocSet::Config> and you will find the
documentation of methods inherited from this class in its pod.

The following "public" methods are implemented in this super-class:

=over

=item * new

  $class->new($config_file, $parent_o, $src_rel_dir);

=item * init

  $self->init($config_file, $parent_o, $src_rel_dir);

=item * scan

  $self->scan();

Scans the docset for meta data and tocs of its items and caches this
information and the item objects.

=item * scan_copy_the_rest

  $self->scan_copy_the_rest()

Process the files that should be copied as is without processing
(i.e. images, css files, etc). If any of the items have a timestamp
newer than the corresponding copy in the target destination, the whole
docset will be rebuilt.

Only files that were modified will be copied during the render phase.

=item * render

  $self->render();

Calls the render() method of each of the stored objects and creates an
index page linking all the items.

=item * copy_the_rest

  $self->copy_the_rest()

Copies the files which aren't processed (i.e. images, css files, etc.)
and were modified as-is.

=item * should_update

  my $should_update = $self->should_update($src_path, $dst_path);

Compare the timestamps/existance of src and dst paths and return
(true, reason) if src is newer than dst otherwise return (false,
reason)

If rebuild_all runtime is on, this always returns (true, reason)

=back

=head2 ABSTRACT METHODS

The following methods should be implemented by the sub-classes.

=over

=item * parse

=item * retrieve_meta_data

=item * convert

=item * complete

  $self->complete();

put here anything that should be run after all the items have been
rendered and all the meta info has been collected. i.e. generation of
the I<index> file, to link to all the links and the parent node if
such exists.

=back

=head1 AUTHORS

Stas Bekman E<lt>stas (at) stason.orgE<gt>

=cut
