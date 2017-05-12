package DocSet::Config;

use strict;
use warnings;

use File::Basename ();
use File::Spec::Functions;

use DocSet::Util;
use DocSet::RunTime ();

use constant TRACE => 1;

# uri extension to MIME type mapping
my %ext2mime = (
    map({$_ => 'text/html' } qw(htm html)),
    map({$_ => 'text/plain'} qw(txt text)),
    map({$_ => 'text/pod'  } qw(pod pm)),
);

my %conv_class = (
    'text/pod'  => {
        'text/html'   => 'DocSet::Doc::POD2HTML',
        'text/htmlps' => 'DocSet::Doc::POD2HTMLPS',
        'text/ps'     => 'DocSet::Doc::POD2PS',
    },
    'text/html' => {
        'text/html'   => 'DocSet::Doc::HTML2HTML',
        'text/htmlps' => 'DocSet::Doc::HTML2HTMLPS',
        'text/ps'     => 'DocSet::Doc::HTML2PS',
    },
    'text/plain' => {
        'text/html'   => 'DocSet::Doc::Text2HTML',
        'text/pdf'    => 'DocSet::Doc::Text2PDF',
    },
);

sub ext2mime {
    my ($self, $ext) = @_;
    exists $ext2mime{$ext} ? $ext2mime{$ext} : undef;
}


sub conv_class {
    my ($self, $src_mime, $dst_mime) = @_;
    # convert
    $self->croak("src_mime is not defined") unless defined $src_mime;
    $self->croak("dst_mime is not defined") unless defined $dst_mime;
    $self->croak("unknown input/output MIME mapping: $src_mime => $dst_mime")
        unless exists $conv_class{$src_mime}{$dst_mime};
    return $conv_class{$src_mime}{$dst_mime};
}


my %node_attr   = map {$_ => 1} qw(chapters docsets links sitemap);
my %hidden_attr = map {$_ => 1} qw(chapters docsets);
# the rest of the valid attributes in addition to 'hidden', 'changes',
# and %node_attr
my %other_attr  = map {$_ => 1} qw(id stitle title abstract body
                                   options copy_glob copy_skip dir
                                   file);
sub read_config {
    my ($self, $config_file, $parent_o) = @_;
    die "Configuration file is not specified" unless defined $config_file;

    $self->{config_file} = $config_file;

    my $package = path2package($config_file);
    $self->{package} = $package;

    $parent_o->croak("can't read $config_file: $!") 
        unless -r $config_file;
    my $content;
    read_file($config_file, \$content);

    eval join '',
        "package $package;",
        $content, ";1;";
    $self->croak("failed to eval config file:\n$@") if $@;

    # parse the attributes of the docset's config file
    no strict 'refs';
    use vars qw(@c);
    *c = \@{"$package\::c"};

#dumper \@c;

    my $current_group = '';
    my $group_size;
    my $non_grouped_node_seen = 0;
    for ( my $i=0; $i < @c; $i +=2 ) {
        my ($key, $val) = @c[$i, $i+1];
        if ($key eq 'group') {
            $self->croak("grouped and non-grouped chapters cannot be mixed")
                if $non_grouped_node_seen;
            # close the previous group by storing the key of its last node
            if ($current_group) {
                push @{ $self->{node_groups} }, $current_group, $group_size;
            }
            # start the new group
            $current_group = $val;
            $group_size = 0;
        }
        elsif ($key eq 'hidden') {
            $self->croak("hidden attribute's value must be an ARRAY reference")
                unless ref $val eq 'ARRAY';
            my @h = @$val;
            for ( my $j=0; $j < @h; $j +=2 ) {
                my ($key1, $val1) = @h[$j, $j+1];
                $self->croak("the 'hidden' attribute can include only: ",
                             join(", ", keys %hidden_attr),
                             "attributes, $key1 is invalid")
                    unless exists $hidden_attr{$key1};
                $self->add_node($key1, $val1, 1);
            }
        }
        elsif ($key eq 'changes') {
            # add as a hidden chapter
            $self->add_node('chapters', $val, 1);
            # by this id we can reach this hidden object from the
            # docset object
            $self->{extra}{$key} = $val;
        }
        elsif (exists $node_attr{$key}) {
            $non_grouped_node_seen = 1 unless $current_group;
            $group_size += $self->add_node($key, $val, 0);
        }
        elsif (exists $other_attr{$key}) {
            $self->{$key} = $val;
            #dumper [$key => $val];
        }
        else {
            #dumper [$key => $val];
            $self->croak("unknown attribute: $key");
        }
    }
    if ($current_group) {
        push @{ $self->{node_groups} }, $current_group, $group_size;
    }

    # - make sure that at least title or stitle were specified
    # - alias one to another if only one was specified
    $self->{title}  = $self->{stitle} unless exists $self->{title};
    $self->{stitle} = $self->{title}  unless exists $self->{stitle};
    $self->croak("Either 'title' or 'stitle' must appear in $config_file")
        unless $self->{title};


    # XXX: some options expansion logic, consider refactoring with
    # similar logic in docset_build 
    # XXX: also this logic should probably go directly to
    # DocSet::Source::POD, which is the only place it's used.
    if ($self->{options}{slides_mode}) {
        $self->{options}{podify_items} = 1;
    }

    # merge_config will adjust this value, for nested docsets
    # so this value is relevant only for the real top parent node
    $self->{dir}{abs_doc_root} = '.';

    $self->{dir}{path_from_base} = '' 
        unless exists $self->{dir}{path_from_base};

    $self->{dir}{src_root} = File::Basename::dirname $config_file;

    if ($self->{dir}{search_paths}) {
        DocSet::RunTime::scan_src_docs($self->{dir}{src_root},
                                       $self->{dir}{search_paths},
                                       $self->{dir}{search_exts}
                                      );
    }

    # dumper $self;

}

# child config inherits parts from the parent config
# and adjusts its paths
sub merge_config {
    my ($self, $src_rel_dir) = @_;

    my $parent_o = $self->{parent_o};

    # inherit 'file' attributes if not set in the child 
    my $files = $self->{file} || {};
    while ( my ($k, $v) = each %{ $parent_o->{file}||{} }) {
        $self->{file}{$k} = $v unless $files->{$k};
    }

    # inherit the 'dir' attributes if not set in the child 
    my $dirs = $self->{dir} || {};
    while ( my ($k, $v) = each %{ $parent_o->{dir}||{} }) {
        $self->{dir}{$k} = $v unless exists $dirs->{$k};
    }

    # inherit/override the 'options' attr unless explicitly set
    while ( my ($k, $v) = each %{ $parent_o->{options}||{} }) {
        $self->{options}{$k} = $v unless exists $self->{options}{$k};
    }

    # a chapter object won't set this one
    if ($src_rel_dir) {
        $self->{dir}{src_rel_dir} = $src_rel_dir;

        # append the relative to parent_o's src dir segments
        # META: hardcoded paths!
        for my $k ( qw(dst_html dst_ps dst_split_html) ) {
            $self->{dir}{$k} .= "/$src_rel_dir";
        }

        # only path with no leading ./ or closing /
        $self->{dir}{path_from_base} = join "/", grep /./,
            $self->{dir}{path_from_base}, $src_rel_dir;

        # set path to the abs_doc_root 
        # META: hardcoded paths! (but in this case it doesn't matter,
        # as long as it's set in the config file
        $self->{dir}{abs_doc_root} =
            $self->{dir}{dst_html} =~ m|/|
                ? join('/', ("..") x ($self->{dir}{dst_html} =~ tr|/|/|))
                : '.';
    }

    # inherit the 'copy_skip' attribute if not set in the child
    $self->{copy_skip} ||= $parent_o->{copy_skip} || [];

}


# merge the global run-time options with object scoped options by a
# simple OR, so if any of the sides sets an option to 1, this method
# will return 1 otherwise 0
sub options {
    my ($self, $option) = @_;
    $option ||= '';
    return ($self->{options}{$option} || DocSet::RunTime::get_opts($option))
        ? 1 : 0;
}

# this sub controls the docset's 'modified' attribute which specifies
# whether the docset is in a "dirty" state and need to be rebuilt or
# not.
#
# get/set modified status
# ... if $self->modified();
# $self->modified(1);
sub modified {
    my $self = shift;
    if (@_) {
        my $status = shift;

        # protect from modified status reset (once it's set to any
        #value it cannot be reset to 0), must be a mistake. If we
        # don't check this, it's possible that in one place the object
        # is marked as dirty, but somewhere later a logic mistake
        # resets this value to 0, (non-dirty).
        if (exists $self->{modified} && !$status) {
            $self->croak("Cannot reset the 'modified' status");
        }
        $self->{modified} = $status;
    }
    return $self->{modified};

}

# similar to DocSet::RunTime::get_opts('rebuild_all');
# but can be set for the scope of a single docset (which affects only
# the immediate children)
sub rebuild {
    my $self = shift;
    if (@_) {
        my $status = shift;

        # protect from 'rebuild' status reset (once it's set to any
        #value it cannot be reset to 0), must be a mistake. If we
        # don't check this, it's possible that in one place the object
        # is marked to rebuild the docset, but somewhere later a logic mistake
        # resets this value to 0, (non-dirty).
        if (exists $self->{rebuild} && !$status) {
            $self->croak("Cannot reset the 'rebuild' status");
        }
        $self->{rebuild} = $status;
    }
    return $self->{rebuild};
}

#
# 1. put chapters together, docsets together, links together
# 2. store the normal nodes in the order they were listed in 'ordered_nodes'
# 2. store the hidden nodes in the order they were listed in 'hidden_nodes'
#
# return the number of added items
sub add_node {
    my ($self, $key, $value, $hidden) = @_;

    my @values = ref $value eq 'ARRAY' ? @$value : $value;

    if ($hidden) {
        push @{ $self->{hidden_nodes} }, $key, $_ for @values;
    }
    else {
        push @{ $self->{ordered_nodes} }, $key, $_ for @values;
    }

    return scalar @values;
}

# register the new docset id and verify that it wasn't registered
# before that. Croak if it was registered already.
sub check_duplicated_docset_ids {
    my $self = shift;
    my $id = $self->get('id');
    my @entries = DocSet::RunTime::register('unique_docset_id', $id,
                                           $self->{config_file});
    # should be enough to report only the first returned value, since
    # there can be only one duplicate before this will croak
    $self->croak("Duplicated docset id: '$id'\n",
                 "Used already by $entries[0]") if @entries > 1;
}

# return a list of files potentially to be copied
#
# due to a potentially huge list of files to be copied (e.g. the
# splash library) currently it's assumed that this function is called
# only once. Therefore no caching is done to save memory.
#
# The following conventions are used for $self->{copy_glob}
# 1. Explicitly specified files and directories are copied as is
#    (directories aren't descended into)
# 2. Shell metachars (*?[]) can be used. e.g. if you want to grab
#    directory foo and its contents, make sure to specify foo/*.
sub files_to_scan_copy {
    my $self = shift;

    my $copy_skip_patterns = $self->{copy_skip} || [];
    # build one sub that will match many regex at once.
    my $rsub_filter_out = build_matchmany_sub($copy_skip_patterns);

    my $src_root  = $self->get_dir('src_root');

    # expand $self->{copy_glob}, applying the filter to skip unwanted
    # files
    my @files = 
        grep !$rsub_filter_out->($_),              # skip unwanted
#        grep s|^(?:\./)?||,                        # strip the leading ./
        grep !-d $_,                               # skip empty dirs
        map { -d $_ ? @{ expand_dir($_) } : $_ }   # expand dirs
        map { $_ =~ /[\*\?\[\]]/ ? glob($_) : $_ } # expand globs
        map { "$src_root/$_" }                     # prefix with src_root
            @{ $self->{copy_glob}||[] };

    return \@files;
}

# this functions sets/gets a ref to hash of files that need to be
# copied as is, all the checking were done already. (only the modified
# files will go here)
sub files_to_copy {
    my $self = shift;

    if (@_) {
        $self->{files_to_copy} = shift;
    }
    else {
        return $self->{files_to_copy} || {};
    }

}

sub set {
    my ($self, %args) = @_;
    @{$self}{keys %args} = values %args;
}

sub set_dir {
    my ($self, %args) = @_;
    @{ $self->{dir} }{keys %args} = values %args;
}

sub get {
    my $self = shift;
    return () unless @_;
    my @values = map {exists $self->{$_} ? $self->{$_} : ''} @_;
    return wantarray ? @values : $values[0];
}


sub get_file {
    my $self = shift;
    return () unless @_;
    my @values = map {exists $self->{file}{$_} ? $self->{file}{$_} : ''} @_;
    return wantarray ? @values : $values[0];
}

sub get_dir {
    my $self = shift;

    return () unless @_;

    my @values = ();
    for (@_) {
        if (exists $self->{dir}{$_}) {
            push @values, $self->{dir}{$_}
        }
        else {
            $self->cluck("no entry for dir: $_");
            push @values, '';
        }
    }

    return wantarray ? @values : $values[0];
}

sub nodes_by_type {
    my $self = shift;
    return $self->{ordered_nodes} || [];
}

sub hidden_nodes_by_type {
    my $self = shift;
    return $self->{hidden_nodes} || [];
}

sub node_groups {
    my $self = shift;
    return $self->{node_groups} || [];
}


#sub docsets {
#    my $self = shift;
#    return exists $self->{docsets} ? @{ $self->{docsets} } : ();
#}

#sub links {
#    my $self = shift;
#    return exists $self->{links} ? @{ $self->{links} } : ();
#}

sub sitemap {
    my $self = shift;
    return exists $self->{sitemap} ? $self->{sitemap}  : ();
}

#sub src_chapters {
#    my $self = shift;
#    return exists $self->{chapters} ? @{ $self->{chapters} } : ();
#}

# chapter paths as they go into production
# $self->trg_chapters(@paths) : push a chapter(s) 
# $self->trg_chapters         : retrieve the list
sub trg_chapters {
    my $self = shift;
    if (@_) {
        push @{ $self->{chapters_prod} }, @_;
    } else {
        return exists $self->{chapters_prod} ? @{ $self->{chapters_prod} } : ();
    }

}

# set/get cache
sub cache { 
    my $self = shift;

    if (@_) {
        $self->{cache} = shift;
    }
    $self->{cache};
}

sub path2package {
    my $path = shift;
    $path =~ s|[\W\.]|_|g;
    return "MyDocSet::X$path";
}


sub object_store {
    my ($self, $object) = @_;
    $self->croak("no object passed") unless defined $object and ref $object;
    push @{ $self->{_objects_store} }, $object;
}

sub stored_objects {
    my ($self) = @_;
    return @{ $self->{_objects_store}||[] };
}

# extended error diagnosis
{
    require Carp;
    no strict 'refs';
    for my $sub (qw(carp cluck croak confess)) {
        undef &$sub if \&$sub; # overload Carp's functions
        *$sub = sub {
            my ($self, @msg) = @_;
            &{"Carp::$sub"}("[scan $sub] ", @msg, "\n",
                         "[config file: " . $self->{config_file} . "]\n"
                        );
        };
    }
}

#sub chapter_data {
#   my $self = shift;
#   my $id = shift;

#   if (@_) {
#       $self->{chapter_data}{$id} = shift;
#   }
#   else {
#       $self->{chapter_data}{$id};
#   }
#}

1;
__END__

=head1 NAME

C<DocSet::Config> - A superclass that handles object's configuration and data

=head1 SYNOPSIS

  use DocSet::Config ();
  
  my $mime = $self->ext2mime($ext);
  my $class = $self->conv_class($src_mime, $dst_mime);
  
  $self->read_config($config_file);
  $self->merge_config($src_rel_dir);
  $self->check_duplicated_docset_ids();

  $self->options('slides_mode');

  $self->files_to_scan_copy();
  my @files = $self->files_to_copy(files_to_copy);
  my @files = $self->expand_dir();
  
  $self->set($key => $val);
  $self->set_dir($dir_name => $val);
  $val = $self->get($key);
  $self->get_file($key);
  $self->get_dir($dir_name);
  
#XXX  my @docsets = $self->docsets();
#XXX  my @links = $self->links();
#XXX  my @chapters = $self->src_chapters();
  my @chapters = $self->trg_chapters();
  
  my $sitemap = $self->sitemap();
  
  $self->cache($cache); 
  my $cache = $self->cache(); 
  
  $package = $self->path2package($path);
  $self->object_store($object);
  my @objects = $self->stored_objects();

=head1 DESCRIPTION

This objects lays in the base of the DocSet class and provides
configuration and internal data storage/retrieval methods.

At the end of this document the generic configuration file is
explained.

=head2 METHODS

META: to be completed (see SYNOPSIS meanwhile)

=over

=item * ext2mime

=item * conv_class

=item * read_config

=item * merge_config

=item * options

=item * files_to_copy

=item * expand_dir

=item * set

=item * set_dir

=item * get

=item * get_file

=item * get_dir

=item * docsets

=item * links

=item * src_chapters

=item * trg_chapters

=item * cache 

=item * path2package

=item * object_store

=item * stored_objects

=back

=head1 CONFIGURATION FILE

Each DocSet has its own configuration file.

=head2 Structure

Currently the configuration file is a simple perl script that is
expected to declare an array C<@c> with all the docset properties in
it. Later on more configuration formats will be supported.

We use the C<@c> array because some of the configuration attributes
may be repeated, so the hash datatype is not suitable here. Otherwise
this array looks exactly like a hash:

  key1 => val1,
  key2 => val2,
  ...
  keyN => valN

Of course you can declare any other perl variables and do whatevery
you want, but after the config file is run, it should have C<@c> set.

Don't forget to end the file with C<1;>.

=head2 Declare once attributes

The following attributes must be declared at least in the top-level
I<config.cfg> file:

=over

=item * dir

     dir => {
 	     # the resulting html files directory
 	     dst_html   => "dst_html",
 	     
 	     # the resulting ps and pdf files directory (and special
 	     # set of html files used for creating the ps and pdf
 	     # versions.)
 	     dst_ps     => "dst_ps",
 	     
 	     # the resulting split version html files directory
 	     dst_split_html => "dst_split_html",
 	     
             # location of the templates relative to the root dir
             # (searched left to right)
             tmpl       => [qw(tmpl/custom tmpl/std tmpl)],

             # search path for pods, etc. must put more specific paths first!
             search_paths => [qw(
                 docs/2.0/api/mod_perl-2.0
                 docs/2.0/api/ModPerl-Registry
                 docs/2.0
                 docs/1.0
             )],
             # what extensions to search for
             search_exts => [qw(pod pm html)],

 	    },	

=item * file

     file => {
	      # the html2ps configuration file
	      html2ps_conf  => "conf/html2ps.conf",
	     },

=back

Generally you should specify these only in the top-level config file,
and only specify these again in sub-level config files, if you want to
override things for the sub-docset and its successors.

=head2 DocSet must attributes

The following attributes must be declared in every docset configuration:

=over

=item * id

a unique id of the docset. The uniquness should be preserved across
any parallel docsets.

=item * stitle

the short title of the docset, used in the menu and the navigation
breadcrumb. If it's not specified the I<title> attribute is used
instead.

=item * title

the title of the docset. If it's not specified the I<stitle> attribute
is used instead.

=item * abstract

a short abstract

=back


=head2 DocSet Components

Any DocSet components can be repeated as many times as wanted. This
allows to mix various types of nodes and still have oredered the way
you want. You can have a chapter followed by a docset and followed by
a few more chapters and ended with a link.

The value of each component can be either a single item or a reference
to an array of items.

=over

=item * docsets

the docset can recursively include other docsets, simply list the
directories the other docsets can be found in (where the I<config.cfg>
file can be found)

=item * chapters

Each chapter can be specified as a path to its source document.

=item * links

The docset supports hyperlinks. Each link must be declared as a hash
reference with keys: I<id>, I<link>, I<title> and I<abstract>.

If you want to link to an external resource start the link, with URI
(e.g. C<http://>). But this attribute also works for local links, for
example, if the same generated page should be linked from more than
one place, or if there is some non parsed object that needs to be
linked to after it gets copied via I<copy_glob> attribute in the same
or another docset.

=item * sitemap

Sitemap is a special kind of chapter rendered by calling the
C<sitemap> template, which usually traverses the caches and builds a
nested tree of all documents in the docset and below it. Note that if
using this attribute in the inner docsets, it'll work the same as
using it in the outmost docset, but the tree will show only the from
the inner docset and below it. DWIM.

The specification is exactly like the I<links> attribute, but there
can be only one sitemap entry per config file, therefore its value is
a reference to a hash with the same keys as the I<links> nodes. In the
example below you can see how it get specified. The only thing to
think about is the link entry:

  link     => 'sitemap.html',

which says where the file will be generated relative to the directory
I<config.cfg> resides in. So normally you will just use the same entry
as the one in the example that follows.

As we mentioned, the autogenerated sitemap will be automatically
linked together with chapters, docsets and links, depending on where
the I<sitemap> attribute has been added in the configuration file.  Of
course if you desire to link to the sitemap in a different way, you
can always define it in the I<hidden> container, as it'll be explained
later.

=item * changes

  changes => 'Changes.pod',

The I<changes> attribute accepts a single element which is a source
chapter for the changes file. The only difference from the I<hidden>
chapter is that it's possible to access directly to its navigation
object from within the index templates, via:

  [%
    changes_id = doc.nav.index_node.extra.changes;
    IF changes_id;
       changes_nav = doc.nav.by_id(changes_id);
  -%]

Now C<changes_nav> points to the changes chapter, similar to
C<doc.nav>. So for example you can retrieve a link to it as:

  changes_nav.meta.link

or the title as:

  changes_nav.meta.title

This element was added as an improvement over the inclusion of the
I<Changes.pod> chapter or alike along with all other chapters because
usually people don't want to see changes and when the docset pdf is
created huge changes files can be an unwanted burden, so now if this
attribute is included, the pdf for the docset won't include this file
in it.

=back

This is an example:

     docsets =>  ['docs', 'cool_docset'],
  
     chapters => [
         qw(
            about/about.html
           )
     ],
  
     docsets => [
         qw(
            download
           )
     ],
  
     chapters => 'foo/bar/zed.pod',
  
     changes => 'Changes.pod',
  
     links => [
         {
          id       => 'asf',
          link     => 'http://apache.org/foundation/projects.html',
          title    => 'The ASF Projects',
          abstract => "There many other ASF Projects",
         },
     ],
  
     sitemap => {
         id       => 'sitemap',
         link     => 'sitemap.html',
         title    => "The Site Map",
         abstract => "You reach any document on our site from this sitemap",
     },

Since normally books consist of parts which group chapters by a common
theme, we support this feature as well. So the index can now be
generated as:

  part I: Installation
  * Starting
  * Installing

  part II: Troubleshooting
  * Debugging
  * Errors
  * ASF
  * Offline Help

This happens only if this feature is used, otherwise a plain flat toc
is used: to enable this feature simply splice nodes with declaration
of a new group using the I<group> attribute:

  group => 'Installation',
  chapters => [qw(start.pod install.pod)],

  group => 'Troubleshooting',
  chapters => [qw(debug.pod errors.pod)],
  links    => [
         {
          id       => 'asf',
          link     => 'http://apache.org/foundation/projects.html',
          title    => 'The ASF Projects',
          abstract => "There many other ASF Projects",
         },
  ],
  chapters => ['offline_help.pod'],


=head2 Hidden Objects


I<docsets> and I<chapters> can be marked as hidden. This means that
they will be normally processed but won't be linked from anywhere.

Since the hidden objects cannot belong to any group and it doesn't
matter when they are listed in the config file, you simply put one or
more I<docsets> and I<chapters> into a special attribute I<hidden>
which of course can be repeated many times just like most of the
attributes.

For example:

  ...
  chapters => [qw(start.pod install.pod)],
  hidden => {
      chapters => ['offline_help.pod'],
      docsets  => ['hidden_docset'],
  },
  ...

The cool thing is that the hidden I<docsets> and I<chapters> will see
all the unhidden objects, so those who know the "secret" URL will be
able to navigate back to the non-hidden objects transparently. 

This feature could be useful for example to create pages normally not
accessed by users. For example if you want to create a page used for
the Apache's I<ErrorDocument> handler, you want to mark it hidden,
because it shouldn't be linked from anywhere, but once the user hit it
(because a non-existing URL has been entered) the user will get a
perfect page with all the proper navigation widgets (I<menu>, etc) in
it.

=head2 Options

Sometimes you want different docsets to be run under different command
line options. This is impossible to accomplish from the command line,
therefore the options that are different from the default can be set
inside the I<config.cfg> files. For example if we have a project which
includes two docsets: one to be rendered as slides and the other as
handouts. Since the slides mode is off by default, all we need to do
is to add:

    options => {
        slides_mode => 1,
    },

in the I<config.cfg> file of that docset. Now when the whole project
is built without specifying the slides mode on the command line, this
docset and its sub-docsets will be built using the slides mode. Of
course sub-sets can override their parent's setting, for example in
our example by saying:

    options => {
        slides_mode => 0,
    },

Note that merging of the global (command line options) and local
(docset specific options) is done using the OR operator, meaning that
if either of the two or both set an option, it's set. Otherwise it's
not set. This works in that way, because the command line options only
turn options on, they don't turn them off.

Therefore with our example, if the slides mode will be turned on the
command line, the whole project will be built in the slides mode. So
essentially the command line options override the local options.

META: currently the merging happens only in C<DocSet::Source::POD>,
other places only check the global command line options. This can be
adjusted as needed, without breaking anything. To find out the list of
options see C<%options> in I<bin/docset_build>.

=head2 Copy unmodified

Usually the generated UI includes images, CSS files and of course some
files must be copied without any modifications, like files including
pure code, archives, etc. There are two attributes to handle this:

=over

=item * copy_glob

Accepts a reference to an array of files and directories to copy. The
items of the array are run through glob(), therefore wild characters
can be used to match only certain files. But be careful since if you
say:

   images/*

and there are some hidden files (and dirs) that need to be copied,
they won't be copied, since C<*> doesn't match them.

For example:

     # non-pod/html files or dirs to be copied unmodified
     copy_glob => [
         qw(
            style.css
            images
           )
     ],

will copy the file I<style.css> and all the files and directories
under the I<images/> directory into the parallel tree at the
destination directory.

=item * copy_skip

While I<copy_glob> allows specifying complete dirs with potentially
many nested sub-dirs to be copied, this becomes inconvenient if we
want to copy all but a few files in these directories. The
I<copy_skip> rule comes to help. It accepts a reference to an array of
regular expressions that will be applied to each candidate to be
copied as suggested by the I<copy_glob> attribute. If the regular
expression matches the file won't be copied.

One of the useful examples would be:

     copy_skip => [
         '(?:^|\/)CVS(?:\/|$)', # skip cvs control files
         '#|~',                 # skip emacs backup files
     ],

META: does copy_skip apply to all sub-docsets, if sub-docsets specify
their own copy_glob?

Make sure to escape C</> chars.

=back


=head2 Extra Features

If you want in the index file include a special top and bottom
sections in addition to the linked list of the docset contents, you
can do:

     body => {
         top => 'index_top.html',
         bot => 'index_bot.html',
     },

any of I<top> and I<bot> sub-attributes are optional.  If these source
docs are for example in HTML, they have to be written in a proper
HTML, so the parser will be able to extract the body. Of course these
can be POD or other formats as well. But all is taken from these files
are their bodies, so the title and other meta-data are ignored.

=head1 AUTHORS

Stas Bekman E<lt>stas (at) stason.orgE<gt>


=cut

