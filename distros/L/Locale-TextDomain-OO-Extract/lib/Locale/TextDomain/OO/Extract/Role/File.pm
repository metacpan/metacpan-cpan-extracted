package Locale::TextDomain::OO::Extract::Role::File; ## no critic (TidyCode)

use strict;
use warnings;
use Locale::TextDomain::OO::Util::JoinSplitLexiconKeys;
use Locale::Utils::PlaceholderMaketext;
use Moo::Role;
use MooX::Types::MooseLike::Base qw(ArrayRef Bool HashRef Str);
use namespace::autoclean;

our $VERSION = '2.007';

has category => (
    is      => 'rw',
    isa     => Str,
    default => q{},
);

has domain => (
    is      => 'rw',
    isa     => Str,
    default => q{},
);

has project => (
    is  => 'rw',
    isa => sub {
        my $value = shift;
        defined $value
            or return;
        Str->($value);
        return;
    },
);

has category_stack => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub { [] },
);

has domain_stack => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub { [] },
);

has filename => (
    is       => 'rw',
    isa      => Str,
    lazy     => 1,
    default  => 'unknown',
    clearer  => '_clear_filename',
);

has lexicon_ref => (
    is      => 'rw',
    isa     => HashRef,
    lazy    => 1,
    default => sub { {} },
);

has is_maketext_format_gettext => (
    is  => 'ro',
    isa => Bool,
);

sub clear {
    my $self = shift;

    $self->category( q{} );
    $self->domain( q{} );
    $self->project(undef);
    $self->category_stack([]);
    $self->domain_stack([]);
    $self->_clear_filename;

    return;
}

my $list_if_length = sub {
    my ($item, @list) = @_;

    defined $item or return;
    length $item or return;

    return @list;
};

sub add_message {
    my ($self, $msg_ref) = @_;

    my $key_util = Locale::TextDomain::OO::Util::JoinSplitLexiconKeys->instance;
    my $format_util
        = $self->is_maketext_format_gettext
        && Locale::Utils::PlaceholderMaketext->new;

    # build the lexicon part
    my $lexicon_key = $key_util->join_lexicon_key({(
        map {
            $_ => $msg_ref->{$_};
        } qw( category domain project )
    )});
    my $lexicon
        = $self->lexicon_ref->{$lexicon_key}
        ||= {
            q{} => {
                msgstr => {
                    nplurals => 2,
                    plural   => 'n != 1',
                }
            },
        };

    # build the message part
    my $msg_key = $key_util->join_message_key({
        $format_util
        ? (
            msgid => $format_util->maketext_to_gettext( $msg_ref->{msgid} ),
            (
                map {
                    $_ => $msg_ref->{$_};
                } qw( msgctxt msgid_plural )
            ),
        )
        : (
            map {
                $_ => $msg_ref->{$_};
            } qw( msgctxt msgid msgid_plural )
        )
    });
    if ( exists $lexicon->{$msg_key} ) {
        $lexicon->{$msg_key}->{reference}->{ $msg_ref->{reference} } = undef;
        return;
    }
    $lexicon->{$msg_key} = {
        $list_if_length->( $msg_ref->{automatic}, automatic => $msg_ref->{automatic} ),
        reference => { $msg_ref->{reference} => undef },
    };

    return;
}

1;

__END__

=head1 NAME
Locale::TextDomain::OO::Extract::Role::File - Gettext file related stuff

$Id: File.pm 683 2017-08-22 18:41:42Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/extract/trunk/lib/Locale/TextDomain/OO/Extract/Role/File.pm $

=head1 VERSION

2.007

=head1 DESCRIPTION

Role for gettext file related stuff.

=head1 SYNOPSIS

    with 'Locale::TextDomain::OO::Extract::Role::File';

=head1 SUBROUTINES/METHODS

=head2 method category

Set/get the default category.

=head2 method domain

Set/get the default domain.

=head2 method project

Set/get the default project.

=head2 method filename

Set/get the filename for reference.

=head2 method lexicon_ref

Set/get the extracted data as lexicon data structure.

=head2 method is_maketext_format_gettext

Set/get a boolean if the lexicon has %1 or [_1] for maketext placeholders.

=head2 method clear

Clears category, domain. project, category_stack, domain_stack and filename.
That is important before extract the next file.

=head2 method add_message

    $extractor->add_message({
        category     => 'my category', # or q{} or undef
        domain       => 'my domain',   # or q{} or undef
        reference    => 'dir/file.ext:123',
        automatic    => 'my automatic comment',
        msgctxt      => 'my context'   # or q{} or undef
        msgid        => 'my singular',
        msgid_plural => 'my plural',   # or q{} or undef
    });

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run this *.pl files.

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Locale::TextDomain::OO::Util::JoinSplitLexiconKeys|Locale::TextDomain::OO::Util::JoinSplitLexiconKeys>

L<Locale::Utils::PlaceholderMaketext|Locale::Utils::PlaceholderMaketext>

L<Moo::Role|Moo::Role>

L<MooX::Types::MooseLike::Base|MooX::Types::MooseLike::Base>

L<namespace::autoclean|namespace::autoclean>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

none

=head1 SEE ALSO

L<Locale::TextDoamin::OO|Locale::TextDoamin::OO>

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
