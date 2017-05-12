package Kwiki::Search::Spotlight;
use Kwiki::Search -Base;
our $VERSION = '0.01';

sub register {
    super;
    my $reg = shift;
    $reg->add(hook => 'page:store', post => 'update_index');
}

sub update_index {
    my $search = $self->hub->search;
    my $page_name = $self->id;
    my $dir = $search->plugin_directory;
    io($dir)->mkpath;
    system "/bin/cp database/${page_name} ${dir}/${page_name}.txt";
}

sub perform_search {
    my $search = $self->cgi->search_term;
    my $dir = io($self->plugin_directory)->absolute;
    [ map {
        s/$dir\///;
        s/\.txt$//;
        $self->hub->pages->new_page($_);
    } split(/\n/,`/usr/bin/mdfind -onlyin $dir "$search"`)];
}

__END__

=head1 NAME

Kwiki::Search::Spotlight - Use Spotlight as Kwiki search engine

=head1 DESCRIPTION

This Kwiki plugin requires Mac OS 10.4 (Tiger) to work.  It use
metadata command line executables to index your Kwiki pages and to
performa search.

=head1 SEE ALSO

Spotlight: http://www.apple.com/macosx/features/spotlight/

mdfind

=head1 COPYRIGHT

Copyright 2005 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
