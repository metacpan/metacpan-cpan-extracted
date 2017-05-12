package Kwiki::Search::Plucene;
use Kwiki::Search -Base;
use Plucene::Simple;
our $VERSION = '0.03';

field plucy => {},
    -init => q{Plucene::Simple->open($self->index_path)};

sub register {
    super;
    my $reg = shift;
    $reg->add(hook => 'page:store', post => 'update_index');
    $self->build_index;
}

sub build_index {
    my $cmd = $self->hub->command;
    $cmd->msg("Building Plucene Index...\n");
    for($self->hub->pages->all) {
        $cmd->msg("  - Indexing " . $_->id . "\n");
        $self->update_page($_);
    }
    $self->plucy->optimize;
    $cmd->msg("Done\n");
}

sub perform_search {
    [map {$self->pages->new_page($_)} $self->plucy->search($self->cgi->search_term)]
}

sub index_path {
    $self->plugin_directory . '/plucene_index';
}

sub update_index {
    $self->hub->load_class('search')->update_page($self);
}

sub update_page {
    my $page = shift;
    $self->plucy->delete_document($page->id,$page->content)
        if(-d $self->index_path);
    $self->plucy->index_document($page->id,$page->content);
}

=head1 NAME

Kwiki::Search::Plucene - Plucene powered Kwiki search engine

=head1 DESCRIPTION

This plugin is intend to be an alternative of Kwiki::Search, which use
a simple 'grep' upon search, and will be slow after the number of
pages grow larger and larger.

It use L<Plucene::Simple> to index page content upon saving.  Plucene is
a Perl port of the Lucene search engine.

Note that, by each time you do a C<"kwiki -update">, plucene index
will be rebuilt. This would help current running sites to build
plucene index for the very first time.

=head1 SEE ALSO

L<Plucene::Simple>, L<Plucene>, L<Kwiki>

=head1 COPYRIGHT

Copyright 2005 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
