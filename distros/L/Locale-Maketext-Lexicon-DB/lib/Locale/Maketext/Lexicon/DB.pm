package Locale::Maketext::Lexicon::DB;
{
  $Locale::Maketext::Lexicon::DB::VERSION = '1.141830';
}
# ABSTRACT: Dynamically load lexicon from a database table

use Locale::Maketext::Lexicon::DB::Handle;
use Moose;
use namespace::autoclean;
use Locale::Maketext 1.22;
use Log::Log4perl qw(:easy);


has dbh => (
    is          => 'ro',
    isa         => 'Object',
    required    => 1,
);

has cache => (
    is          => 'ro',
    isa         => 'Object',
    predicate   => 'has_cache',
);

has cache_expiry_seconds => (
    is          => 'ro',
    isa         => 'Int',
    default     => 60 * 5,
);

has lex => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has auto => (
    is          => 'ro',
    isa         => 'Bool',
    default     => 0,
);

has language_mappings => (
    is          => 'ro',
    isa         => 'HashRef[ArrayRef]',
    required    => 1,
);


{
    my $instance;

    sub get_handle {
        my $class = shift;
        my @requested_langs = @_;

        $instance ||= $class->new;

        @requested_langs = Locale::Maketext->_ambient_langprefs
            unless @requested_langs;

        TRACE('Languages asked for: ' . join (', ', @requested_langs));

        my $langs = [];
        for (@requested_langs) {
            if (defined $class->new->language_mappings->{ lc $_ }) {
                $langs = $class->new->language_mappings->{ lc $_ };
                last;
            }
        }

        TRACE('Lexicon will be searched for languages: ' . join(', ', @{ $langs }) );

        return Locale::Maketext::Lexicon::DB::Handle->new(
            _parent => $instance,
            langs   => $langs
        );
    }
}


sub clear_cache {
    my $class = shift;

    my $self = $class->new;

    if (defined $self->cache) {
        for (values %{ $self->language_mappings }) {
            $self->cache->delete( $self->_cache_key_for_langs($_) );
        }

        return 1;
    }

    return;
}

sub _cache_key_for_langs {
    my $self = shift;

    return join(
        '.',
        'lexicon',
        $self->lex,
        @{ shift() }
    )
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Locale::Maketext::Lexicon::DB - Dynamically load lexicon from a database table

=head1 VERSION

version 1.141830

=head1 SYNOPSIS

    package MyApp::Maketext;

    use Moose;
    use DBI;
    use Cache::Memcached::Fast;

    BEGIN { extends 'Locale::Maketext::Lexicon::DB'; }

    has '+dbh' => (
        builder => '_build_dbh',
    );

    sub _build_dbh {
        my $self = shift;

        return DBI->connect( ... );
    }

    has '+cache' => (
        builder => '_build_cache',
    );

    sub _build_cache {
        my $self = shift;

        return Cache::Memcached::Fast->new({
            servers => [ ... ],
        });
    }

    has '+cache_expiry_seconds' => (
        default => 3_600,
    );

    has '+lex' => (
        default => 'myapp',
    );

    has '+auto' => (
        default => 1,
    );

    has '+language_mappings' => (
        default => sub {
            {
                en_gb   => [qw(en_gb en)],
                en_us   => [qw(en_us en)],
                en      => [qw(en)],
            }
        },
    );


    package main;

    my $handle = MyApp::Maketext->get_handle('en_gb');
    # or, to use the environment to get the language from locale settings:
    # my $handle = MyApp::Maketext->get_handle;

    print $handle->maketext('ui.homepage.title', $name);

=head1 DESCRIPTION

This module enables you to crate a L<Locale::Maketext> lexicon in your database. The lexicon is
compiled when C<get_handle> is called on the class. If a cache is defined then the lexicon is
retrieved from the cache instead of hitting the database each time. A class method is provided to
clear the cache i.e. to invalidate it if the lexicon in the DB changes.

=head1 METHODS

=head2 get_handle ([@languages])

Returns a L<Locale::Maketext::Lexicon::DB::Handle> for this lexicon. if C<@languages> are not
supplied then inspects the environment to get the set locale.

=head2 clear_cache

Clears the cache (if set) for this lexicon. Used to invalidate the cache if the database has
changed.

=head1 DATABASE TABLE

Your database should be in this format (this DDL is for SQLite).

    CREATE TABLE lexicon (
        id INTEGER PRIMARY KEY NOT NULL,
        lang VARCHAR NOT NULL,
        lex VARCHAR NOT NULL,
        lex_key TEXT NOT NULL,
        lex_value TEXT NOT NULL
    );

=over 4

=item id

The primary key for the table

=item lang

The locale string for the language for this entry

=item lex

A key to identify the entire lexicon in the table. This enables you to set define more than one
lexicon in the table

=item lex_key

The key for the lexicon entry. This is the value passed to the C<maketext> method on the handle

=item lex_value

The value for the lexicon entry

=back

=head1 AUTHOR

Pete Smith <pete@cubabit.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Pete Smith.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
