package DocSet::Doc::POD2HTML;

use strict;
use warnings;

use File::Spec::Functions;
use File::Basename ();

use DocSet::Util;
use DocSet::RunTime;

require Pod::POM;
my $view_mode = 'DocSet::Doc::POD2HTML::View::HTML';

use DocSet::Doc::Common ();
*fetch_pdf_doc_ver = \&DocSet::Doc::Common::fetch_pdf_doc_ver;
*fetch_src_doc_ver = \&DocSet::Doc::Common::fetch_src_doc_ver;

use vars qw(@ISA);
require DocSet::Source::POD;
@ISA = qw(DocSet::Source::POD);

my %split_by = map {"head".$_ => 1} 1..4;

sub convert {
    my ($self) = @_;

    set_render_obj($self);

    my $pom = $self->{parsed_tree};

    my @sections = $pom->content();
    shift @sections; # skip the title

#    my @body = ();
#    foreach my $node (@sections) {
##	my $type = $node->type();
##        print "$type\n";
#	push @body, $node->present($view_mode);
#    }

    
    #dumper $sections[$#sections];

    my @body = slice_by_head(@sections);

    my $vars = {
                meta => $self->{meta},
                toc  => $self->{toc},
                body => \@body,
                headers => {},
                dir  => $self->{dir},
                nav  => $self->{nav},
                last_modified => $self->{timestamp},
                pdf_doc  => $self->fetch_pdf_doc_ver,
                src_doc  => $self->fetch_src_doc_ver,
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


package DocSet::Doc::POD2HTML::View::HTML;

use vars qw(@ISA);
require Pod::POM::View::HTML;
@ISA = qw( Pod::POM::View::HTML);

use DocSet::RunTime;

use File::Spec::Functions;
use File::Basename;

sub view_head1 {
    my ($self, $head1) = @_;
    return "<h1>" . $self->anchor($head1->title) . "</h1>\n\n" .
        $head1->content->present($self);
}

sub view_head2 {
    my ($self, $head2) = @_;
    return "<h2>" . $self->anchor($head2->title) . "</h2>\n\n" .
        $head2->content->present($self);
}

sub view_head3 {
    my ($self, $head3) = @_;
    return "<h3>" . $self->anchor($head3->title) . "</h3>\n\n" .
        $head3->content->present($self);
}

sub view_head4 {
    my ($self, $head4) = @_;
    return "<h4>" . $self->anchor($head4->title) . "</h4>\n\n" .
        $head4->content->present($self);
}

sub view_seq_file {
    my ($self, $path) = @_;
    my $doc_obj = get_render_obj();
    my $base_dir = dirname catfile $doc_obj->{src_root}, $doc_obj->{src_uri};
    my $file = catfile $base_dir, $path;
    #warn "file: $file";

    # XXX: may need to test the location at dest_path, not src, to
    # make sure that the file actually gets copied
    return -e $file ? qq{<a href="$path">$path</a>} : qq{<i>$path</i>};
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

    return qq{<pre class="pre-section">$text</pre>\n};
}


#sub view_for {
#    my $self = shift;
#    my ($for) = @_;
#    return $self->SUPER::view_for(@_) if $for->format() =~ /\bhtml\b/;
#    if ($for->format() =~ /\btt2\b/) {
#        my $text = $for->text();
#print "$text\n";
#return $text;
##        "WHOOOOOOOOOOOOOOOOOOOOOOO";   
##        $self->parse_sequence($text);
#    }
#}

*anchor        = \&DocSet::Doc::Common::pod_pom_html_anchor;
*view_seq_link_transform_path = \&DocSet::Doc::Common::pod_pom_html_view_seq_link_transform_path;

#*view_seq_link = \&DocSet::Doc::Common::pod_pom_html_view_seq_link;

#use DocSet::Util;
## META: temp override
## the one in superclass screws up URLs in L<>: L<http://foo.bar.com>
## should view_seq_text be called at all on these parts?
#sub view_seq_text {
#    my ($self, $text) = @_;
#dumper $self;
##print $self->[CMD];
#    return $text;
#}

1;



__END__

=head1 NAME

C<DocSet::Doc::POD2HTML> - POD source to HTML target converter

=head1 SYNOPSIS



=head1 DESCRIPTION

Implements an C<DocSet::Doc> sub-class which converts a source
document in POD, into an output document in HTML.

=head1 METHODS

For the rest of the super class methods see C<DocSet::Doc>.

=over

=item * convert

=back

=head1 Rendering Class

documents using this class are rendered via
C<DocSet::Doc::POD2HTML::View::HTML>, which is a subclass of
C<Pod::POM::View::HTML>.

C<view_head{1-4}()> are overridden to add the E<lt>a nameE<gt> anchors
next to the headers for proper hyperlinking.

view_seq_file() is overriden too. Here we search for the file relative
to the location of the document and if we find it we link to it
otherwise the default behaviour applies (the file path is turned into
italics).

view_verbatim() is overriden: renders the
E<lt>preE<gt>...E<lt>/preE<gt> html, but defines a CSS class
C<pre-section> so the look-n-feel can be adjusted.

The following rendering methods: anchor() and
view_seq_link_transform_path() are defined in the
C<DocSet::Doc::Common> class and documented there.

=head1 AUTHORS

Stas Bekman E<lt>stas (at) stason.orgE<gt>

=cut

