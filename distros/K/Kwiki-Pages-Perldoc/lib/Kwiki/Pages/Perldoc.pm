package Kwiki::Pages::Perldoc;
use Kwiki::Pages -Base;
use Kwiki::Installer -base;
our $VERSION = '0.12';

const page_class => 'Kwiki::Page::Perldoc';

sub init {
    super;
    $self->hub->config->add_file('pages.yaml');
}

sub all {
    map {
        $self->new_page($_)
    } grep {
        s/\.pod$//;
    }
    map {
        $_->filename;
    } io($self->current->database_directory)->all_files;
}

sub all_ids_newest_first {
    my $path = $self->current->database_directory;
    grep {
        chomp; 
        s/\.pod$//;
    } `ls -1t $path`;
}   


package Kwiki::Page::Perldoc;
use base 'Kwiki::Page';
use Kwiki ':char_classes';

sub file_path {
    join '/', $self->database_directory, $self->id . '.pod';
}

package Kwiki::Pages::Perldoc;
__DATA__

=head1 NAME

Kwiki::Pages - Kwiki Perldoc Pages

=head1 SYNOPSIS

=head1 DESCRIPTION

This is the page database module that supports http://perldoc.kwiki.org.
It is meant to access the pod files directly out of a Perl source
distribution. You also need Kwiki::Formatter::Pod.

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__config/pages.yaml__
database_directory: /usr/share/perl/5.8.4/pod
formatter_class: Kwiki::Formatter::Pod
