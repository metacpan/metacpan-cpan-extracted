package Locale::TextDomain::OO::Extract::Process::Plugin::MO; ## no critic (TidyCode)

use strict;
use warnings;
use Carp qw(confess);
use Encode qw(find_encoding);
use Locale::MO::File;
use Locale::TextDomain::OO::Util::ExtractHeader;
use Locale::TextDomain::OO::Util::JoinSplitLexiconKeys;
use Moo;
use MooX::StrictConstructor;
use MooX::Types::MooseLike::Base qw(HashRef Str);
use namespace::autoclean;

our $VERSION = '2.007';

has category => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    default => q{},
);

has domain => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    default => q{},
);

has language => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    default => 'i-default',
);

has project => (
    is  => 'rw',
    isa => sub {
        my $project = shift;
        defined $project
            or return;
        return Str->($project);
    },
);

has lexicon_ref => (
    is      => 'rw',
    isa     => HashRef,
    lazy    => 1,
    default => sub { {} },
);

sub clear {
    my $self = shift;

    $self->category( q{} );
    $self->domain( q{} );
    $self->language('i-default');
    $self->project(undef);
    $self->lexicon_ref( {} );

    return;
}

sub slurp {
    my ( $self, $filename ) = @_;

    defined $filename
        or confess 'Undef is not a name of a mo file';
    my $mo = Locale::MO::File->new( filename => $filename );
    $mo->read_file;
    my $messages_ref = $mo->get_messages;

    my $header = Locale::TextDomain::OO::Util::ExtractHeader
        ->instance
        ->extract_header_msgstr(
            $messages_ref->[0]->{msgstr}
            || confess "No header found in file $filename",
        );
    my $encode_obj = find_encoding( $header->{charset} );
    my $nplurals   = $header->{nplurals};
    my $plural     = $header->{plural};

    my $decode_code = sub {
        my $text = shift;
        #
        defined $text
            or return;
        length $text
            or return q{};
        #
        return $encode_obj->decode($text);
    };

    my $key_util = Locale::TextDomain::OO::Util::JoinSplitLexiconKeys->instance;
    my $index = 0;
    for my $message_ref ( @{$messages_ref} ) {
        $self
            ->lexicon_ref
            ->{
                $key_util->join_lexicon_key({
                    category => $self->category,
                    domain   => $self->domain,
                    language => $self->language,
                    project  => $self->project,
                })
            }
            ->{
                $key_util->join_message_key({
                    msgctxt      => scalar $decode_code->( $message_ref->{msgctxt} ),
                    msgid        => scalar $decode_code->( $message_ref->{msgid} ),
                    msgid_plural => scalar $decode_code->( $message_ref->{msgid_plural} ),
                })
            } = {
                (
                    $index++
                        ? ()
                        : (
                            nplurals => $nplurals,
                            plural   => $plural,
                        )
                ),
                (
                    exists $message_ref->{msgstr_plural}
                        ? (
                            msgstr_plural => [
                                map {
                                    scalar $decode_code->( $message_ref->{msgstr_plural}->[$_] );
                                }
                                0 .. ( $nplurals - 1 )
                            ]
                        )
                        : ( msgstr => scalar $decode_code->( $message_ref->{msgstr} ) )
                ),
            };
    }

    return;
}

sub spew {
    my ( $self, $filename ) = @_;

    defined $filename
        or confess 'Undef is not a name of a mo file';

    my $key_util = Locale::TextDomain::OO::Util::JoinSplitLexiconKeys->instance;
    my $lexicon_key = $key_util
        ->instance
        ->join_lexicon_key({
            category => $self->category,
            domain   => $self->domain,
            language => $self->language,
            project  => $self->project,
        });
    my $messages_ref = $self->lexicon_ref->{$lexicon_key}
        or confess sprintf
            'No lexicon found for category "%s", domain "%s", language "%s" and project "%s"',
            $self->category,
            $self->domain,
            $self->language
            ( defined $self->project ? $self->project : 'undef' );

    my $header = Locale::TextDomain::OO::Util::ExtractHeader
        ->instance
        ->extract_header_msgstr(
            $messages_ref->{ q{} }->{msgstr}
            || confess 'No header set.',
        )
        or confess sprintf
            'No header found in lexicon of category "%s", domain "%s", language "%s" and project "%s"',
                $self->category,
                $self->domain,
                $self->language,
                ( defined $self->project ? $self->project : 'undef' );
    my $charset    = $header->{charset};
    my $encode_obj = find_encoding($charset);
    my $nplurals   = $header->{nplurals};

    my $message_ref = $self
        ->lexicon_ref
        ->{
            $key_util->join_lexicon_key({
                category => $self->category,
                domain   => $self->domain,
                language => $self->language,
                project  => $self->project,
            })
        };

    my %mo_key_of
        = map { $_ => undef }
        qw( msgctxt msgid msgid_plural msgstr msgstr_plural );
    my $mo = Locale::MO::File->new(
        filename => $filename,
        encoding => $charset,
        messages => [
            map { ## no critic (ComplexMappings)
                my $return_ref = $key_util->join_message( $_, $message_ref->{$_} );
                delete @{$return_ref}{
                    grep {
                        ! exists $mo_key_of{$_};
                    } keys %{$return_ref}
                };
                $return_ref;
            }
            sort
            keys %{$message_ref}
        ],
    );
    $mo->write_file;

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Locale::TextDomain::OO::Extract::Process::Plugin::MO - MO file plugin

$Id: MO.pm 683 2017-08-22 18:41:42Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/extract/trunk/lib/Locale/TextDomain/OO/Extract/Process/Plugin/MO.pm $

=head1 VERSION

2.007

=head1 SYNOPSIS

see
L<Locale::TextDomain::OO::Extract::Process|Locale::TextDomain::OO::Extract::Process>

=head1 DESCRIPTION

MO file plugin

=head1 SUBROUTINES/METHODS

=head2 method new

=head2 rw attribute category, domain, language

The type is Str, defaults to q{} but language to 'i-default'.

=head2 rw attribute project

The type is Undef or Str.

=head2 method lexicon_ref

The type is HashRef, defaults to {}.

=head2 method slurp

Read MO file into lexicon_ref.

    $self->slurp($filename);

=head2 method spew

Write MO file from lexicon_ref.

Unless no header is set method spew throws an exception.

    $self->spew($filename);

=head2 method clear

Back to defaults to run the next file.

    $self->clear;

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run the *.pl files.

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Carp|Carp>

L<Encode|Encode>

L<Locale::MO::File|Locale::MO::File>

L<Locale::TextDomain::OO::Util::ExtractHeader|Locale::TextDomain::OO::Util::ExtractHeader>

L<Locale::TextDomain::OO::Util::JoinSplitLexiconKeys|Locale::TextDomain::OO::Util::JoinSplitLexiconKeys>

L<Moo|Moo>

L<MooX::StrictConstructor|MooX::StrictConstructor>

L<MooX::Types::MooseLike::Base|MooX::Types::MooseLike::Base>

L<namespace::autoclean|namespace::autoclean>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

not known

=head1 SEE ALSO

L<Locale::TextDomain::OO::Extract::Process|Locale::TextDomain::OO::Extract::Process>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014 - 2017,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
