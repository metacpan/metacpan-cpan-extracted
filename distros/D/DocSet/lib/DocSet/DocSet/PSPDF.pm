package DocSet::DocSet::PSPDF;

use strict;
use warnings;

use DocSet::Util;
use DocSet::RunTime;
use DocSet::NavigateCache ();

use vars qw(@ISA);
use DocSet::DocSet ();
@ISA = qw(DocSet::DocSet);

# what's the output format
sub trg_ext {
    return 'html'; # in this case 'html' is just an intermediate format
}

sub init {
    my $self = shift;

    $self->SUPER::init(@_);

    # configure PS/PDF specific run-time
    # though, we build ps/pdf the intermediate product is HTML
    $self->set(dst_mime => 'text/htmlps');
    $self->set(tmpl_mode => 'ps');
    $self->set_dir(dst_root => $self->get_dir('dst_ps'));

    note "\n";
    banner("[scan] PS/PDF DocSet: " . $self->get('title') );
}

sub complete {
    my ($self) = @_;

    note "\n";
    banner("[render] PS/PDF DocSet: " . $self->get('title') );

    $self->write_index_file();

    $self->create_ps_book;
    $self->create_pdf_book if get_opts('generate_pdf');
}


# XXX: almost the same code as in ::HTML counterpart, consider
# creating ::Common and re-use
#
# generate the index.html file based on the doc entities it includes,
# in the following order: docsets, books, chapters
#
# Using the same template file create the long and the short index
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

    my %args = 
        (
         nav      => $navigator,
         toc      => \@toc,
         meta     => $meta,
         dir      => $dir,
         version  => $self->get('version')||'',
         date     => get_date(),
         last_modified => get_timestamp(),
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
                src_path     => "$src_root/$src_file",
            );
            $chapter->scan();
            $args{body}{$sec} = $chapter->converted_body();
        }

    }

    my $dst_root  = $self->get_dir('dst_root');
    my $dst_file = "$dst_root/index.html";
    my $mode = $self->get('tmpl_mode');
    my $tmpl_file = 'index';
    my $vars = { doc => \%args };
    my $tmpl_root = $self->get_dir('tmpl');
    my $content = proc_tmpl($tmpl_root, $tmpl_file, $mode, $vars);
    note "+++ Creating $dst_file";
    DocSet::Util::write_file($dst_file, $content);
}

# generate the PS book
####################
sub create_ps_book{
    my ($self) = @_;

    note "+++ Generating a PostScript Book";

    my $html2ps_exec = DocSet::RunTime::can_create_ps();
    my $html2ps_conf = $self->get_file('html2ps_conf');
    my $id = $self->get('id');
    my $dst_root = $self->get_dir('dst_root');
    my $command = "$html2ps_exec -f $html2ps_conf -o $dst_root/${id}.ps ";
    $command .= join " ", map {"$dst_root/$_"} "index.html", $self->trg_chapters;
    note "% $command";
    system $command;

}

# generate the PDF book
####################
sub create_pdf_book{
    my ($self) = @_;

    note "+++ Converting PS => PDF";
    my $dst_root = $self->get_dir('dst_root');
    my $id = $self->get('id');
    my $command = "ps2pdf $dst_root/$id.ps $dst_root/$id.pdf";
    note "% $command";
    system $command;

    # META: can delete the .ps now

}

1;
__END__

=head1 NAME

C<DocSet::DocSet::PSPDF> - A subclass of C<DocSet::DocSet> for generating PS/PDF docset

=head1 SYNOPSIS

See C<DocSet::DocSet>

=head1 DESCRIPTION

This subclass of C<DocSet::DocSet> converts the source docset into PS
and PDF "books". It uses C<html2ps> to generate the PS file, therefore
it uses HTML as its intermediate product, though it uses different
templates than C<DocSet::DocSet::HTML> since PS/PDF doesn't require
the navigation widgets.

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

=item * create_ps_book

Generats a PostScript Book

=item * create_pdf_book

Converts PS into PDF (if I<generate_pdf> runtime option is set)

=back

=head1 AUTHORS

Stas Bekman E<lt>stas (at) stason.orgE<gt>

=cut
