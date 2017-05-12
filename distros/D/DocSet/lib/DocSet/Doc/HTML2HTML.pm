package DocSet::Doc::HTML2HTML;

use strict;
use warnings;

use DocSet::Util;

use vars qw(@ISA);
require DocSet::Source::HTML;
@ISA = qw(DocSet::Source::HTML);

use DocSet::Doc::Common ();
*fetch_pdf_doc_ver = \&DocSet::Doc::Common::fetch_pdf_doc_ver;
*fetch_src_doc_ver = \&DocSet::Doc::Common::fetch_src_doc_ver;

sub convert {
    my ($self) = @_;

    my @body = $self->{parsed_tree}->{body};
    my $vars = {
                meta => $self->{meta},
                body => \@body,
                headers => $self->{parsed_tree}{head},
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
}


# need for pluggin docs into index files
sub converted_body {
    my ($self) = @_;

    return $self->{parsed_tree}->{body};
}

1;
__END__

=head1 NAME

C<DocSet::Doc::HTML2HTML> - HTML source to HTML target converter

=head1 SYNOPSIS



=head1 DESCRIPTION

Implements an C<DocSet::Doc> sub-class which converts a source
document in HTML, into an output document in HTML.

=head1 METHODS

For the rest of the super class methods see C<DocSet::Doc>.

=over

=item * convert

=back

=head1 AUTHORS

Stas Bekman E<lt>stas (at) stason.orgE<gt>

=cut
