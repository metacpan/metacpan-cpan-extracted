package DocSet::Doc::Common;

use File::Spec::Functions;
use DocSet::Util;
use DocSet::RunTime;

# See  HTML2HTMLPS.pm or POD2HTMLPS.pm
sub postprocess_ps_pdf {
    my $self = shift;

    # convert to ps
    my $html2ps_exec = DocSet::RunTime::can_create_ps();
    my $html2ps_conf = $self->{docset}->get_file('html2ps_conf');
    my $dst_path     = $self->{dst_path};

    (my $dst_base  = $dst_path) =~ s/\.html//;

    my $dst_root = $self->{dst_root};
    my $command = "$html2ps_exec -f $html2ps_conf -o ${dst_base}.ps ${dst_base}.html";
    note "% $command";
    system $command;

    # convert to pdf
    $command = "ps2pdf ${dst_base}.ps ${dst_base}.pdf";
    note "% $command";
    system $command;

    # META: can delete the .ps now

}



# search for a pdf version in the parallel tree and copy/gzip it to
# the same dir as the html version (we link to it from the html)
sub fetch_pdf_doc_ver {
    my $self = shift;

    my $dst_path = $self->{dst_path};
    $dst_path =~ s/html$/pdf/;

    my $pdf_path = $dst_path;

    my $docset = $self->{docset};
    my $ps_root = $docset->get_dir('dst_ps');
    my $html_root = $docset->get_dir('dst_html');

    $pdf_path =~ s/^$html_root/$ps_root/;

#print "TRYING $dst_path $pdf_path \n";

    my %pdf = ();
    # if in the pdf tree (rel_pdf) there is nothing to copy
    if (-e $pdf_path && $pdf_path ne $dst_path) {
        copy_file($pdf_path, $dst_path);
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

# search for the source version in the source tree and copy/gzip it to
# the same dir as the html version (we link to it from the html)
sub fetch_src_doc_ver {
    my $self = shift;
    #$self->src_uri

    my $dst_path = catfile $self->{dst_root}, $self->{src_uri};
    my $src_path = catfile $self->{src_root}, $self->{src_uri};

    # the source file may have the same extension as the dest file, so
    # add a new extension. This will also be useful for doing patches.
    $dst_path .= ".orig";

#print "TRYING $dst_path $src_path \n";

    my %src = ();
    if (-e $src_path) {
        copy_file($src_path, $dst_path);
        %src = (
            size => format_bytes(-s $dst_path),
            link => filename($dst_path),
        );
#        gzip_file($dst_path);
#        my $gzip_path = "$dst_path.gz";
#        %src = (
#            size => format_bytes(-s $gzip_path),
#            link => filename($gzip_path),
#        );
    }
#dumper \%src;

    return \%src;
}

sub pod_pom_html_view_seq_link_transform_path {
    my ($self, $path) = @_;

    $path =~ s|::|/|g;
    my $doc_obj = get_render_obj();

    my $res_path = $doc_obj->transform_src_doc($path);
    unless ($res_path) {
        # report broken links if we were told to
        if (DocSet::RunTime::get_opts('validate_links')) {
            print "!!! Broken link $doc_obj->{src_path}: [$path]\n";
        }
        return undef;
    }

    $res_path =~ s/\.[^.]+$/.html/;
#    print "$res_path\n";
    return $res_path;
}


#sub make_href {
#    my ($url, $title) = @_;

#    if (!defined $url) {
#        return defined $title ? "<i>$title</i>"  : '';
#    }

#    $title = $url unless defined $title;
#print "$url, $title\n";
#    return qq{<a href="$url">$title</a>};
#}

sub pod_pom_html_anchor {
    my ($self, $title) = @_;
    my $anchor = "$title";
    $anchor =~ s/^\s*|\s*$//g; # strip leading and closing spaces
    $anchor =~ s/\W/_/g;
    my $link = $title->present($self);

    # die on duplicated anchors
    my $render_obj = get_render_obj();
    $render_obj->{__seen_anchors}{$anchor}++;
    $render_obj->croak("a duplicated anchor: '$anchor'\nfor title: '$title'\n")
        if $render_obj->{__seen_anchors}{$anchor} > 1;

    return qq{<a name="$anchor"></a><a href="#toc_$anchor">$link</a>};
}





1;
__END__

=head1 NAME

C<DocSet::Doc::Common> - Common functions used in C<DocSet::Doc> subclasses

=head1 SYNOPSIS

...

=head1 DESCRIPTION

Implements functions and bits of code which otherwise needed to be
duplicated in many modules. These functions couldn't be put into the
base class C<DocSet::Doc>. Certainly we could devise one more
subclassing level but for now this gentle mix of inheritance and
inclusion is doing its job just fine.

=head1 METHODS

=over

=item * postprocess_ps_pdf

  $self->postprocess_ps_pdf()

renders ps and pdf version of a the current doc

=item * fetch_pdf_doc_ver

  %pdf_data = %{ $self->fetch_pdf_doc_ver() }

search for a pdf version of the same document in the parallel tree
(usually the I<dst_html> tree) and copy it to the same dir as the
html version. Later we link to it from the html version of the
document if the pdf version is found in the same directory as the html
one.

The function returns a reference to a hash with the keys: I<size> --
for the size of the file and the location of the file relative
to the current document (it's in the same directory after all).

=item * fetch_src_doc_ver

similar to fetch_pdf_doc_ver() but works with the source version of
the document.

  %src_data = %{ $self->fetch_src_doc_ver() }

fetch the source version of the same document in the parallel tree
(usually the I<src> tree) and copy it to the same dir as the html
version. Later we link to it from the html version of the document if
the source version is found in the same directory as the html
one. Notice that we add a I<.orig> extension, because otherwise the
rendered version of the source document may have the same full name as
the source file (e.g. if the source was I<.html> and destination one
is I<.html> too).

The function returns a reference to a hash with the keys: I<size> --
for the size of the source file and the location of the file relative
to the current document (it's in the same directory after all).

=item * pod_pom_html_view_seq_link_transform_path

  my $linked_doc_path = 
      $self->pod_pom_html_view_seq_link_transform_path($src_path)

this is an implementation of the view_seq_link_transform_path()
callback used in C<Pod::POM::HTML::view_seq_link()>, using the
C<DocSet::Doc>'s transform_src_doc() method over pre-scanned cache of
the source documents the C<$src_path> is resolved into the path in the
generated docset. So for example a the resource C<devel::help> in
LE<lt>devel help doc|devel::helpL<gt> could get resolved as
I<mydocs/devel/help.html>. For more info see the documentation for
C<DocSet::Doc::transform_src_doc()>.

Notice that since this method is a callback hook, it uses the runtime
singleton function C<DocSet::RunTime::get_render_obj()> to retrieve
the current document object.

=item * pod_pom_html_anchor

  my $anchor = $self->pod_pom_html_anchor($title);

this is a common function that takes the C<$title> Pod::POM object,
converts it into a E<lt>a nameE<gt> html anchor and returns it.

=back


=head1 AUTHORS

Stas Bekman E<lt>stas (at) stason.orgE<gt>

=cut

