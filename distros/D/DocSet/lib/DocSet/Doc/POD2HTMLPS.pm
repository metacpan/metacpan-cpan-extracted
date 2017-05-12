package DocSet::Doc::POD2HTMLPS;

use strict;
use warnings;

use DocSet::Util;
use DocSet::RunTime;

use vars qw(@ISA);
require DocSet::Source::POD;
@ISA = qw(DocSet::Source::POD);

use DocSet::Doc::Common ();
*postprocess = \&DocSet::Doc::Common::postprocess_ps_pdf;

require Pod::POM;
#require Pod::POM::View::HTML;
#my $view_mode = 'Pod::POM::View::HTML';
my $view_mode = 'DocSet::Doc::POD2HTML::View::HTMLPS';

my %split_by = map {"head".$_ => 1} 1..4;

sub convert {
    my ($self) = @_;

    set_render_obj($self);

    my $pom = $self->{parsed_tree};

    my @sections = $pom->content();
    shift @sections; # skip the title

#    foreach my $node (@sections) {
##	my $type = $node->type();
##        print "$type\n";
#	push @body, $node->present($view_mode);
#    }

    my @body = slice_by_head(@sections);

    my $vars = {
                meta => $self->{meta},
                toc  => $self->{toc},
                body => \@body,
                dir  => $self->{dir},
                nav  => $self->{nav},
                last_modified => $self->{timestamp},
               };

    my $tmpl_file = 'page';
    my $mode = $self->{tmpl_mode};
    my $tmpl_root = $self->{tmpl_root};
    $self->{output} = proc_tmpl($tmpl_root, $tmpl_file, $mode, {doc => $vars} );

    unset_render_obj();

}


sub slice_by_head {
    my @sections = @_;
    my @body = ();
    for my $node (@sections) {
        my @next = ();
        # assumption, after the first 'headX' section, there can only
        # be other 'headX' sections
        my $count = scalar $node->content;
        my $id = -1;
        for ($node->content) {
            $id++;
            next unless exists $split_by{ $_->type };
            @next = splice @{$node->content}, $id;
            last;
        }
        push @body, $node->present($view_mode), slice_by_head(@next);
    }
    return @body;
}

1;


package DocSet::Doc::POD2HTML::View::HTMLPS;

use DocSet::RunTime;
use DocSet::Util;

use File::Spec::Functions;
use File::Basename;

use vars qw(@ISA);
require Pod::POM::View::HTML;
@ISA = qw( Pod::POM::View::HTML);

# we want the PDF to be layouted in a way that the chapter title comes
# as h1 and the real h1 sections as h2, h2 as h3, and so on.

sub view_head1 {
    my ($self, $head1) = @_;
    return "<h2>" . $head1->title->present($self) . "</h2>\n\n" .
        $head1->content->present($self);
}

sub view_head2 {
    my ($self, $head2) = @_;
    return "<h3>" . $head2->title->present($self) . "</h3>\n\n" .
        $head2->content->present($self);
}

sub view_head3 {
    my ($self, $head3) = @_;
    return "<h4>" . $head3->title->present($self) . "</h4>\n\n" .
        $head3->content->present($self);
}

sub view_head4 {
    my ($self, $head4) = @_;
    return "<h5>" . $head4->title->present($self) . "</h5>\n\n" .
        $head4->content->present($self);
}

sub view_seq_file {
    my ($self, $path) = @_;
    my $doc_obj = get_render_obj();
    my $base_dir = dirname catfile $doc_obj->{src_root}, $doc_obj->{src_uri};
    my $file = catfile $base_dir, $path;
    #warn "file: $file";

    return qq{<i>$path</i>} unless -e $file;

    # since we cannot link to the text files which should stay as is
    # from ps/pdf, we simply include them inlined
    my $content = '';
    read_file($file, \$content);

    return qq{<i>$path</i>:\n\n<pre>$content</pre>\n\n};
}

# the <pre> section uses class "pre-section", which allows to use a custom
# look-n-feel via the CSS
sub view_verbatim {
    my ($self, $text) = @_;
    for ($text) {
        s/&/&amp;/g;
        s/</&lt;/g;
        s/>/&gt;/g;
    }

    # if the <pre> section is too long ps2pdf fails to generate pdf,
    # so split it into 40 lines chunks.
    my $result = '';
    while ($text =~ /((?:[^\n]*\n?){1,40})/sg) {
        next unless length($1); # skip empty matches
        $result .= qq{<pre class="pre-section">$1</pre>\n};
    }

    return $result;
}



*anchor        = \&DocSet::Doc::Common::pod_pom_html_anchor;
*view_seq_link_transform_path = \&DocSet::Doc::Common::pod_pom_html_view_seq_link_transform_path;

#*view_seq_link = \&DocSet::Doc::Common::pod_pom_html_view_seq_link;

1;



__END__

=head1 NAME

C<DocSet::Doc::POD2HTMLPS> - POD source to PS (intermediate HTML) target converter

=head1 SYNOPSIS



=head1 DESCRIPTION

Implements an C<DocSet::Doc> sub-class which converts a source
document in POD, into an output document in PS (intermediate in HTML).

=head1 METHODS

For the rest of the super class methods see C<DocSet::Doc>.

=over

=item * convert

=back

=head1 Rendering Class

documents using this class are rendered via
C<DocSet::Doc::POD2HTML::View::HTMLPS>, which is a subclass of
C<Pod::POM::View::HTML>.

Since we want the final PDF document which potentially includes many
chapters in it to look more as a book and have a nice Table of
Contents, we need to change the default structure of C<=head1> specs,
so the C<=head1 NAME> becomes a title of the chapter and removed from
the POD source, therefore we need to bump up all the remaining
C<=headX> headers by one. i.e. C<=head1> is rendered as C<=head2>,
C<=head3> as C<=head3>, etc. Therefore we override the super class's
methods C<view_head{1-4}>. In addition we put E<lt>a nameE<gt> anchors
next to the headers so the PDF document can be hyperlinked if the
reader supports this feature.

view_seq_file() is overriden too. Here we search for the file relative
to the location of the document and if we find it we include its
contents since the PDFs are created for making dead tree copies and
therefore linking is not an option. Notice that it's OK to say
FE<lt>/etc/passwdE<gt> since it won't be found unless you actually put
it under the current documents path or put the source document in
the I</> path.

view_verbatim() is overriden: renders the
E<lt>preE<gt>...E<lt>/preE<gt> html, but defines a CSS class
C<pre-section> so the look-n-feel can be adjusted. in addition it
splits text into 40 lines chunks. This solves two problems:

=over

=item *

C<html2ps> tries to fit the whole E<lt>preE<gt>...E<lt>/preE<gt> in a
single page ending up using a very small unreadable font when the text
is long.

=item *

C<ps2pdf> fails to convert ps to pdf if the former includes
E<lt>preE<gt>...E<lt>/preE<gt>, longer than 40 lines in one chunk.

=back

The following rendering methods: anchor() and
view_seq_link_transform_path() are defined in the
C<DocSet::Doc::Common> class and documented there.


=head1 AUTHORS

Stas Bekman E<lt>stas (at) stason.orgE<gt>

=cut

