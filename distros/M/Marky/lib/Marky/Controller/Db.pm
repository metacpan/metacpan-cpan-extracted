package Marky::Controller::Db;
$Marky::Controller::Db::VERSION = '0.035';
#ABSTRACT: Marky::Controller::Db - Database controller for Marky

use Mojo::Base 'Mojolicious::Controller';

sub tables {
    my $c  = shift;
    $c->render(template=>'tables');
}

sub options {
    my $c  = shift;
    $c->marky_set_options();
    $c->render(template => 'settings');
}

sub taglist {
    my $c  = shift;
    $c->render(template=>'taglist');
}

sub tagcloud {
    my $c  = shift;
    $c->render(template=>'tagcloud');
}

sub query {
    my $c  = shift;
    $c->marky_do_query();
}

sub tags {
    my $c  = shift;
    $c->marky_do_query();
}

sub add_bookmark {
    my $c  = shift;
    $c->render(template=>'add_bookmark');
}

sub save_bookmark {
    my $c  = shift;
    $c->marky_save_new_bookmark();
    $c->render(template=>'save_bookmark');
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Marky::Controller::Db - Marky::Controller::Db - Database controller for Marky

=head1 VERSION

version 0.035

=head1 SYNOPSIS

    use Marky::Controller::Db;

=head1 DESCRIPTION

Database controller for Marky

=head2 tables

Display the tables

=head2 options

For setting the options of the app.

=head2 taglist

Display the list of tags in the database.

=head2 tagcloud

Display the tags as a tagcloud.

=head2 query

Process a query

=head2 tags

Process a query by tags.

=head2 add_bookmark

Add a bookmark

=head2 save_bookmark

Save a bookmark.

=head1 NAME

Marky::Controller::Db - Database controller for Marky

=head1 VERSION

version 0.035

=head1 AUTHOR

Kathryn Andersen <perlkat@katspace.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kathryn Andersen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
