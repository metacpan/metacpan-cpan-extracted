package DocSet::Doc;

use strict;
use warnings;

use DocSet::Util;
use DocSet::RunTime;

use URI;
use File::Spec::Functions;

sub new {
    my $class = shift;
    my $self = bless {}, ref($class)||$class;
    $self->init(@_);
    return $self;
}

sub init {
    my ($self, %args) = @_;
    while (my ($k, $v) = each %args) {
        $self->{$k} = $v;
    }
}

sub scan {
    my ($self) = @_;

    note "+++ Scanning $self->{src_uri}";
    $self->src_read();

    if (my $sub = $self->can('retrieve_meta_data')) {
        $self->$sub();
    }
}

sub render {
    my ($self, $cache) = @_;

    # if the object wasn't stored rescan
    #$self->scan() unless $self->meta;

    my $src_uri       = $self->{src_uri};
    my $dst_path      = $self->{dst_path};

    my $rel_doc_root  = $self->{rel_doc_root};
    my $abs_doc_root  = $self->{abs_doc_root};
    $abs_doc_root .= "/$rel_doc_root"
        if defined $rel_doc_root &&
           length($rel_doc_root) && $rel_doc_root ne '.';

    $abs_doc_root =~ s|^./||; # IE/Mac can't handle path ./../foo

    $self->{dir} = {
        abs_doc_root   => $abs_doc_root,
        rel_doc_root   => $rel_doc_root,
        path_from_base => $self->{path_from_base},
    };

    $self->{nav} = DocSet::NavigateCache->new($cache->path, $src_uri);

    note "Rendering $dst_path";
    $self->convert();
    write_file($dst_path, $self->{output});

    # anything that should be done after the target was written?
    $self->postprocess() if $self->can('postprocess');
}

# read the source and remember the mod time
# sets $self->{content}
#      $self->{timestamp}
sub src_read {
    my ($self) = @_;

    # META: at this moment everything is a file path
    my $src_uri = "file://" . $self->{src_path};
    # Win32: fix the path, or it'll be parsed as hostname
    $src_uri =~ s|\\|/|g;

    my $u = URI->new($src_uri);

    my $scheme = $u->scheme;

    if ($scheme eq 'file') {
        my $path = $u->path;

        my $content = '';
        read_file($path, \$content);
        $self->{content} = \$content;

        # file change timestamp
        # my ($mon, $day, $year) = (localtime ( (stat($path))[9] ) )[4,3,5];
        # $self->{timestamp} = sprintf "%02d/%02d/%04d", ++$mon,$day,1900+$year;
        $self->{timestamp} = scalar localtime;

    }
    else {
        die "$scheme is not implemented yet";
    }

    if (my $sub = $self->can('src_filter')) {
        $self->$sub();
    }


}

sub meta {
    my $self = shift;

    if (@_) {
        $self->{meta} = shift;
    }
    else {
        $self->{meta};
    }
}

sub toc {
    my $self = shift;

    if (@_) {
        $self->{toc} = shift;
    }
    else {
        $self->{toc};
    }
}

# search for the source doc with base $base, and resolve it to a relative 
# to abs_doc_root path and return it 
# if not found return undef
sub transform_src_doc {
    my ($self, $path) = @_;

    if (my $path = find_src_doc($path)) {
        $path = catfile $self->{dir}{abs_doc_root}, $path;
        $path =~ s|/\./|/|; # avoid .././foo links.
        return path2uri($path);
    }

    return undef;
}

require Carp;
sub croak {
    my ($self, @msg) = @_;
    Carp::croak("[render croak] ", @msg, "\n",
                "[src path] $self->{src_path}\n"
               );

}

# abstract methods
#sub src_filter {}



1;
__END__

=head1 NAME

C<DocSet::Doc> - A Base Document Class

=head1 SYNOPSIS

   # e.g. a subclass would do
   use DocSet::Doc::HTML2HTML ();
   my $doc = DocSet::Doc::HTML2HTML->new(%args);
   $doc->scan();
   my $meta = $doc->meta();
   my $toc  = $doc->toc();
   $doc->render();

   # internal methods
   $doc->src_read();
   $doc->src_filter();

=head1 DESCRIPTION

This super class implement core methods for scanning a single document
of a given format and rendering it into another format. It provides
sub-classes with hooks that can change the default behavior. Note that
this class cannot be used as it is, you have to subclass it and
implement the required methods listed later.

=head1 METHODS

=over

=item * new

=item * init

=item * scan

scan the document into a parsed tree and retrieve its meta and toc
data if possible.

=item * render

render the output document and write it to its final destination.

=item * src_read

Fetches the source of the document. The source can be read from
different media, i.e. a file://, http://, relational DB or OCR :)
(but these are left for subclasses to implement :)

A subclass may implement a "source" filter. For example if the source
document is written in an extended POD the source filter may convert
it into a standard POD. If the source includes some template
directives these can be pre-processed as well.

The document's content is coming out of this class ready for parsing
and converting into other formats.

=item * meta

a simple set/get-able accessor to the I<meta> attribute.

=item * toc

a simple set/get-able accessor to the I<toc> attribute

=item * transform_src_doc

  my $doc_src_path = $self->transform_src_doc($path);

search for the source doc with path of C<$path> at the search paths
defined by the configuration file I<search_paths> attribute (similar
to the C<@INC> search in Perl) and if found resolve it to a relative
to C<abs_doc_root> path and return it. If not found return the
C<undef> value.

=back

=head1 ABSTRACT METHODS

These methods must be implemented by the sub-classes:

=over

=item retrieve_meta_data

Retrieve and set the meta data that describes the input document into
the I<meta> object attribute. Various documents may provide different
meta information. The only required meta field is I<title>.

=back

These methods can be implemented by the sub-classes:

=over

=item src_filter

A subclass may want to preprocess the source document before it'll be
processed. This method is called after the source has been read. By
default nothing happens.

=back

=head1 AUTHORS

Stas Bekman E<lt>stas (at) stason.orgE<gt>

=cut
