#
# This file is part of MediaWikiUtils
#
# This software is copyright (c) 2014 by Natal Ngétal.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package MediaWikiUtils::Cmd::Convert;
{
  $MediaWikiUtils::Cmd::Convert::VERSION = '0.141410';
}

use strict;
use warnings;

use Moo;
extends 'MediaWikiUtils::Common';

use MooX::Cmd;
use MooX::Options;

use Types::Standard qw( Str );

use Carp;

use pQuery;
use Text::Unaccent::PurePerl qw(unac_string);

#ABSTRACT: A tools provide few method to convert MediaWiki to another wiki engine

option 'directory' => (
    is       => 'ro',
    format   => 's',
    default  => sub { '.' },
    doc      => 'The directory where store static files (default current directory)'
);

option 'category' => (
    is          => 'ro',
    negativable => 1,
    doc         => 'Keep the stucture create directory with category name'
);

has '_category_name' => (
    is       => 'rw',
    isa      => Str,
    init_arg => undef
);

sub execute {
    my ( $self ) = @_;

    if ( $self->category ) {
        my $all_categories = $self->_mediawiki->list({
            action => 'query',
            list   => 'allcategories'
        });

        foreach my $category (@{$all_categories}) {
            my $all_categories_articles = $self->_mediawiki->list({
                action  => 'query',
                list    => 'categorymembers',
                cmtitle => 'Category:' . $category->{'*'}
            });
            $self->_create_category($category->{'*'});

            foreach my $page (@{$all_categories_articles}) {
                $self->_create_page($page);
            }
        }
    }
    else {
        my $all_articles = $self->_mediawiki->list({
            action => 'query',
            list   => 'allpages'
        });

        foreach my $page (@{$all_articles}) {
            $self->_create_page($page);
        }
    }

    return;
}

sub _create_page {
    my ( $self, $page ) = @_;

    my $article = $self->_mediawiki->get_page({
        title => $page->{title}
    });

    my $title    = $page->{title};
    my $response = $self->_user_agent->post(
        'http://johbuc6.coconia.net/mediawiki2dokuwiki.php',
        [mediawiki => $article->{'*'}]
    );
    my $file = $self->_generate_file_name($title);

    if ( ! $response->is_success ) {
        carp "Request for $title failed: " . $response->status_line;
        return;
    }

    print 'Export the page ' . $page->{title} . " in the $file", "\n";
    pQuery($response->content)
        ->find('textarea[name=dokuwiki]')
        ->each(sub {
            my $count = shift;
            $self->_write_file($file, pQuery($_)->html());
    });

    return;
}

sub _generate_file_name {
    my ( $self, $title ) = @_;

    $title =~ s/\s/_/g;
    $title =~ s/'/_/g;

    return unac_string($title) . '.txt';
}

sub _write_file {
    my ( $self, $file, $content ) = @_;

    my $path = ( $self->category )
        ? $self->_category_name . "/$file"
        : $self->directory . "/$file";
    my $fh = IO::File->new($path, "w");

    if ( defined($fh) ) {
        print $fh $content;

        undef $fh;
    }

    return;
}

sub _create_category {
    my ( $self, $category_name ) = @_;

    $category_name =~ s/\s/_/g;
    $category_name =~ s/'/_/g;

    my $category = $self->directory . "/$category_name";
    $self->_category_name($category);
    mkdir($category) unless -e $category;

    return;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MediaWikiUtils::Cmd::Convert - A tools provide few method to convert MediaWiki to another wiki engine

=head1 VERSION

version 0.141410

=head1 SYNOPSIS

    mwu convert --username mediawiki_user --password my_password --url http://mediawiki.com/api.php --directory $HOME/data

=head1 DESCRIPTION

To convert a mediawiki to another wiki engine, at the moment the only converter
supported is dokuwiki.
Use the title of the page to create the file name.

=head1 AUTHOR

Natal Ngétal

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Natal Ngétal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
