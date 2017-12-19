use strict;
use warnings;
package Dist::Zilla::Plugin::Test::PodSpelling; # git description: v2.007004-4-g15c75c6
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: Author tests for POD spelling
# KEYWORDS: plugin test spelling words stopwords typos errors documentation

our $VERSION = '2.007005';

use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';
with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::TextTemplate',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [ ':InstallModules', ':ExecFiles' ],
    },
    'Dist::Zilla::Role::PrereqSource',
);

sub mvp_multivalue_args { return ( qw( stopwords directories ) ) }

sub mvp_aliases { +{
    directory => 'directories',
    stopword => 'stopwords',
} }

has wordlist => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Pod::Wordlist',
);

has spell_cmd => (
    is      => 'ro',
    isa     => 'Str',
    default => '',
);

has stopwords => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    traits  => [ 'Array' ],
    default => sub { [] },
    handles => {
        push_stopwords => 'push',
        uniq_stopwords => 'uniq',
        no_stopwords   => 'is_empty',
    }
);

has directories => (
    isa     => 'ArrayRef[Str]',
    traits  => [ 'Array' ],
    is      => 'ro',
    default => sub { [ qw(bin lib) ] },
    handles => {
        no_directories => 'is_empty',
        print_directories => [ join => ' ' ],
    }
);

has _files => (
    is      => 'rw',
    isa     => 'ArrayRef[Dist::Zilla::Role::File]',
);

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        blessed($self) ne __PACKAGE__ ? ( version => $VERSION ) : (),
        wordlist => $self->wordlist,
        spell_cmd => $self->spell_cmd,
        directories => [ sort @{ $self->directories } ],
        # TODO: should only include manually-configured words
        stopwords => [ sort @{ $self->stopwords } ],
    };

    return $config;
};

sub gather_files {
    my ($self) = @_;

    my $data = $self->merged_section_data;
    return unless $data and %$data;

    my @files;
    for my $name (keys %$data) {
        my $file = Dist::Zilla::File::InMemory->new({
            name    => $name,
            content => ${ $data->{$name} },
        });
        $self->add_file($file);
        push @files, $file;
    }

    $self->_files(\@files);
    return;
}

sub add_stopword {
    my ( $self, $data ) = @_;

    $self->log_debug( 'attempting stopwords extraction from: ' . $data );
    # words must be greater than 2 characters
    my ( $word ) = $data =~ /(\p{Word}{2,})/xms;

    # log won't like an undef
    return unless $word;

    $self->log_debug( 'add stopword: ' . $word );

    $self->push_stopwords( $word );
    return;
}

sub munge_files {
    my ($self) = @_;

    $self->munge_file($_) foreach @{ $self->_files };
    return;
}

sub munge_file {
    my ($self, $file) = @_;

    my $set_spell_cmd = $self->spell_cmd
        ? sprintf("set_spell_cmd('%s');", $self->spell_cmd)
        : undef;

    # TODO - move this into an attribute builder
    foreach my $holder ( split( /\s/xms, join( ' ',
            @{ $self->zilla->authors },
            $self->zilla->copyright_holder,
            @{ $self->zilla->distmeta->{x_contributors} || [] },
        ))
    ) {
        $self->add_stopword( $holder );
    }

    # TODO: we should use the filefinder for the names of the files to check in, rather than hardcoding that list!
    foreach my $file ( @{ $self->found_files } ) {
        # many of my stopwords are part of a filename
        $self->log_debug( 'splitting filenames for more words' );

        foreach my $name ( split( '/', $file->name ) ) {
            $self->add_stopword( $name );
        }
    }

    my $stopwords = $self->no_stopwords
        ? undef
        : join("\n", '__DATA__', sort $self->uniq_stopwords);

    $file->content(
        $self->fill_in_string(
            $file->content,
            {
                name          => __PACKAGE__,
                version       => __PACKAGE__->VERSION,
                wordlist      => \$self->wordlist,
                set_spell_cmd => \$set_spell_cmd,
                stopwords     => \$stopwords,
                directories   => \$self->print_directories,
            }
        ),
    );

    return;
}

sub register_prereqs {
    my $self = shift;
    $self->zilla->register_prereqs(
        {
            type  => 'requires',
            phase => 'develop',
        },
        'Test::Spelling' => '0.12',
    );
    return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

#pod =pod
#pod
#pod =for Pod::Coverage gather_files mvp_multivalue_args mvp_aliases munge_files munge_file register_prereqs
#pod
#pod =head1 SYNOPSIS
#pod
#pod In C<dist.ini>:
#pod
#pod     [Test::PodSpelling]
#pod
#pod or:
#pod
#pod     [Test::PodSpelling]
#pod     directory = docs
#pod     wordlist = Pod::Wordlist
#pod     spell_cmd = aspell list
#pod     stopword = CPAN
#pod     stopword = github
#pod     stopword = stopwords
#pod     stopword = wordlist
#pod
#pod If you're using C<[ExtraTests]> it must come after C<[Test::PodSpelling]>,
#pod it's worth noting that this ships in the C<[@Basic]> bundle so you may have to
#pod remove it from that first.
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is a plugin that runs at the L<gather files|Dist::Zilla::Role::FileGatherer> stage,
#pod providing the file:
#pod
#pod   xt/author/pod-spell.t - a standard Test::Spelling test
#pod
#pod L<Test::Spelling> will be added as a develop prerequisite.
#pod
#pod =method add_stopword
#pod
#pod Called to add stopwords to the stopwords array. It is used to determine if
#pod automagically detected words are valid and print out debug logging for the
#pod process.
#pod
#pod =attr directories (or directory)
#pod
#pod Additional directories you wish to search for POD spell checking purposes.
#pod C<bin> and C<lib> are set by default.
#pod
#pod =attr wordlist
#pod
#pod The module name of a word list you wish to use that works with
#pod L<Test::Spelling>.
#pod
#pod Defaults to L<Pod::Wordlist>.
#pod
#pod =attr spell_cmd
#pod
#pod If C<spell_cmd> is set then C<set_spell_cmd( your_spell_command );> is
#pod added to the test file to allow for custom spell check programs.
#pod
#pod Defaults to nothing.
#pod
#pod =attr stopwords
#pod
#pod If stopwords is set then C<< add_stopwords( <DATA> ) >> is added
#pod to the test file and the words are added after the C<__DATA__>
#pod section.
#pod
#pod C<stopword> or C<stopwords> can appear multiple times, one word per line.
#pod
#pod Normally no stopwords are added by default, but author names appearing in
#pod C<dist.ini> are automatically added as stopwords so you don't have to add them
#pod manually just because they might appear in the C<AUTHORS> section of the
#pod generated POD document. The same goes for contributors listed under the
#pod 'x_contributors' field on your distributions META file.
#pod
#pod =cut

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::PodSpelling - Author tests for POD spelling

=head1 VERSION

version 2.007005

=head1 SYNOPSIS

In C<dist.ini>:

    [Test::PodSpelling]

or:

    [Test::PodSpelling]
    directory = docs
    wordlist = Pod::Wordlist
    spell_cmd = aspell list
    stopword = CPAN
    stopword = github
    stopword = stopwords
    stopword = wordlist

If you're using C<[ExtraTests]> it must come after C<[Test::PodSpelling]>,
it's worth noting that this ships in the C<[@Basic]> bundle so you may have to
remove it from that first.

=head1 DESCRIPTION

This is a plugin that runs at the L<gather files|Dist::Zilla::Role::FileGatherer> stage,
providing the file:

  xt/author/pod-spell.t - a standard Test::Spelling test

L<Test::Spelling> will be added as a develop prerequisite.

=head1 ATTRIBUTES

=head2 directories (or directory)

Additional directories you wish to search for POD spell checking purposes.
C<bin> and C<lib> are set by default.

=head2 wordlist

The module name of a word list you wish to use that works with
L<Test::Spelling>.

Defaults to L<Pod::Wordlist>.

=head2 spell_cmd

If C<spell_cmd> is set then C<set_spell_cmd( your_spell_command );> is
added to the test file to allow for custom spell check programs.

Defaults to nothing.

=head2 stopwords

If stopwords is set then C<< add_stopwords( <DATA> ) >> is added
to the test file and the words are added after the C<__DATA__>
section.

C<stopword> or C<stopwords> can appear multiple times, one word per line.

Normally no stopwords are added by default, but author names appearing in
C<dist.ini> are automatically added as stopwords so you don't have to add them
manually just because they might appear in the C<AUTHORS> section of the
generated POD document. The same goes for contributors listed under the
'x_contributors' field on your distributions META file.

=head1 METHODS

=head2 add_stopword

Called to add stopwords to the stopwords array. It is used to determine if
automagically detected words are valid and print out debug logging for the
process.

=for Pod::Coverage gather_files mvp_multivalue_args mvp_aliases munge_files munge_file register_prereqs

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Test-PodSpelling>
(or L<bug-Dist-Zilla-Plugin-Test-PodSpelling@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Test-PodSpelling@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHORS

=over 4

=item *

Caleb Cushing <xenoterracide@gmail.com>

=item *

Marcel Gruenauer <hanekomu@gmail.com>

=back

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Randy Stauner Graham Knop David Golden Harley Pig Alexandr Ciornii Breno G. de Oliveira

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Randy Stauner <rwstauner@cpan.org>

=item *

Graham Knop <haarg@haarg.org>

=item *

David Golden <dagolden@cpan.org>

=item *

Harley Pig <harleypig@gmail.com>

=item *

Alexandr Ciornii <alexchorny@gmail.com>

=item *

Breno G. de Oliveira <garu@cpan.org>

=back

=head1 COPYRIGHT AND LICENCE

This software is Copyright (c) 2010 by Karen Etheridge.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__DATA__
___[ xt/author/pod-spell.t ]___
use strict;
use warnings;
use Test::More;

# generated by {{ $name }} {{ $version }}
use Test::Spelling 0.12;
use {{ $wordlist }};

{{ $set_spell_cmd }}
{{ $stopwords ? 'add_stopwords(<DATA>);' : undef }}
all_pod_files_spelling_ok( qw( {{ $directories }} ) );
{{ $stopwords }}
