use 5.008;
use strict;
use warnings;
use utf8;

package Pod::Wordlist::Author::TABULO;

our $VERSION = '1.000011';
our $DEBUG   = 0;

use Lingua::EN::Inflect 'PL';
use Path::Tiny qw( path );
use Zest::Author::TABULO::Util::ShareDir qw(dist_file);
use Zest::Author::TABULO::Util::Text qw(lines_utf8_from strip_comments);

use parent qw(Pod::Wordlist);
use Class::Tiny {
    wordlist       => \&_build_wordlist, # override
};

##=== MODULE INIT

#== DELTA: is a default instance -- which ONLY contains words defined here (see INIT code below)
### XXX: wordlist (even if empty) MUST be provided (otherwise => infinite loop!)
my $DELTA = __PACKAGE__->new(
    wordlist => +{},
);

my @teachers = map { dist_file("$_", 'stopwords') // () } ( __PACKAGE__, 'Dist::Zilla::PluginBundle::Author::TABULO' );
$DELTA->learn_stopwords_from($_) for @teachers, "" . <DATA>;

#== ENTIRE: is another default instance -- which ALSO contains words from our SUPER (normally, <Pod::Wordlist>)
### XXX: wordlist (even if empty) MUST be provided (otherwise => infinite loop!)
my $ENTIRE = __PACKAGE__->new(
    wordlist => +{ %{ ; __PACKAGE__->SUPER::new()->wordlist }, %{; $DELTA->wordlist } },
);

##=== Methods (class)
sub delta   {  __PACKAGE__->new( wordlist=> +{ %{ $DELTA->wordlist}   }) }
sub default {  __PACKAGE__->new( wordlist=> +{ %{ $DELTA->wordlist} }) }
sub entire  {  __PACKAGE__->new( wordlist=> +{ %{ $ENTIRE->wordlist}  }) }

##=== Instance methods
sub _build_wordlist {
    return +{ %{ $_[0]->default->wordlist } }; # a copy of DEFAULT wordlist.
}

#pod =method learn_stopwords_from (OVERRIDDEN from parent)
#pod
#pod Like the inherited C<learn_stopwords> method, but this one accepts any number of arguments which will be I<learned> in a loop.
#pod
#pod So, it basically saves you loop.
#pod
#pod =cut
sub learn_stopwords {
    my $self = shift;
    $self->SUPER::learn_stopwords($_) for @_;
}

#pod =method learn_stopwords_from
#pod
#pod Like the inherited C<learn_stopwords> method, but this one also accepts, in addition to simple scalars, any number of things that appear to be capable of providing textual content, such as:
#pod
#pod * simple scalar
#pod * IO::Handle  (which will be read from)
#pod * Any object that I<can> do C<lines_utf8()>, such as and instance of L<Path::Tiny>
#pod
#pod =cut
sub learn_stopwords_from {
    my $self = shift;
    for my $arg (@_) {
        if ( ref($arg) and my $wordlist = eval { $arg->can('wordlist') } ) {
            %{ $self->wordlist } = ( %{ $self->wordlist }, %{ $arg->$wordlist() } );    # learn from another Wordlist
        } else {
            my @content = map { ( strip_comments( lines_utf8_from($_) ) ) } ($arg);
            $self->learn_stopwords($_) for @content;                                    # learn from another source ($scalar, IO::Handle, file (Path::Tiny))
        }
    }
}

1;

# ABSTRACT: Add words for spell checking POD à la TABULO
# CREDITS: Shamelessly adopted from <Pod::Wordlist::hanekomu>

## TODO: Actually document some of the below
#pod =for Pod::Coverage  default  delta  entire
#pod
#pod =pod
#pod
#pod =head1 SYNOPSIS
#pod
#pod     # in some Dist::Zilla::PluginBundle::Foo
#pod
#pod     sub configure {
#pod
#pod         my $stopwords = Pod::Wordlist::Author::TABULO->new;
#pod         $self->add_plugin(
#pod             [ 'Test::PodSpelling' => { stopwords => [ sort keys %{ $stopwords->wordlist } ] } ],
#pod         );
#pod     }
#pod
#pod
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is an EXPERIMENTAL module for my personal use within my authoring workflows (especially with L<Dist::Zilla>).
#pod
#pod It's there because I don't want to lose my time adding the same stopwords in multiple places.
#pod
#pod You shouldn't use this module. Everything in and about it is subject to change without prior notice or deprecation cycles.
#pod
#pod Even if it doesn't manage to eat your cat, it can surely put bad words in your mouth :-)
#pod
#pod Currently, the extra stopwords injected include: some monikers, aliases (e.g. TABULON), CPAN IDs, technical terms,
#pod and other words commonly used (by me) that are not included in the default word list.
#pod
#pod =head1 HOW IT WORKS
#pod
#pod This module sub-classes L<Pod::Wordlist> and overrides its C<wordlist> method, injecting a bunch words to the returned wordlist.
#pod
#pod Unlike L<Pod::Wordlist::hanekomu> (DEPRECATED), this module does NOT do anything behind the scenes:
#pod
#pod Namely, it doesn't directly interact with L<Test::Spelling>. Therefore, merely loading this module will NOT automagically add its stopwords for spell-checking.
#pod
#pod Instead, it just sits there and provides the same API as L<Pod::Wordlist>, augmenting the stopwords provided by that module.
#pod
#pod So, in order to benefit from it, one needs to somehow tell L<Test::Spelling> to actually make use of it (which is construed as a feature).
#pod
#pod First, I thought that could easily be achieved since the L<Dist::Zilla> plugin L<[Test::PodSpelling]|Dist::Zilla::Plugin::Test::PodSpelling> advertises just such a configuration parameter (C<wordlist>) that could have been given within C<dist.ini> or thru a PluginBundle, which is how I intended to use it.
#pod
#pod Apparently not... From what I gather, even though L<Dist::Zilla::Plugin::Test::PodSpelling> does indeed pass the buck ( C<wordlist>) along, the underlying modules (L<Test::PodSpelling> and L<Pod::Spelling>) merely ignore that setting... Perhaps a bug report or a PR is due for at least one of those.authoring.
#pod
#pod Anyhow, in the end, I had to grab the stopwords provided by this module  and shove those into the C<stopwords> parameter of the L<Dist::Zilla> plugin L<[Test::PodSpelling]|Dist::Zilla::Plugin::Test::PodSpelling>. That seems to work like a charm.
#pod
#pod For the moment, this had to be done in my personal L<PluginBundle|Dist::Zilla::PluginBundle::Author::TABULO> since you can't execute code in  C<dist.ini>. It's kind of a shame, but it works!
#pod
#pod =head1 DEFAULT STOPWORD SOURCES (a.k.a. default @teachers)
#pod
#pod By default, this module will acquire its wordlist from any or all of the below sources:
#pod
#pod * $DIST_SHARE_DIR/stopwords (of this distro)
#pod
#pod * <DATA> section (of this module)
#pod
#pod Those sources result in what I call the "I<DELTA>" dictionary (as opposed to the I<ENTIRE> dictionary that would include the wordlist from L<Pod::Wordlist> as well).authoring.ext/Dist-Milla/lib/Dist/Milla.pm
#pod
#pod  Since I<DELTA> is the default, you can get the I<DELTA> dictionary like below :
#pod
#pod     my $lexicon = Pod::Wordlist::Author::TABULO->new();
#pod     $stopwords = $lexicon->wordlist()       # This will get you the I<delta>.
#pod
#pod If you want the I<ENTIRE> wordlist (including also wordlist from L<Pod::Wordlist>), you would have to do:
#pod
#pod C<stopwords> is expected to be a plain text file with whitespace separated words in it.
#pod
#pod     # Line comments are honored
#pod
#pod     So are side comments      # like this
#pod
#pod =head1 CREDITS
#pod
#pod Adopted the initial code from L<Pod::Wordlist::hanekomu> (DEPRECATED), but the mechanism of hooking into the spell-checking is entirely different.
#pod
#pod =head1 SEE ALSO
#pod
#pod * L<Pod::Wordlist>
#pod * L<Test::Spelling>
#pod * L<Dist::Zilla::Plugin::Test::PodSpelling>
#pod
#pod
#pod =cut

=pod

=encoding UTF-8

=for :stopwords Tabulo[n]

=head1 NAME

Pod::Wordlist::Author::TABULO - Add words for spell checking POD à la TABULO

=head1 VERSION

version 1.000011

=head1 SYNOPSIS

    # in some Dist::Zilla::PluginBundle::Foo

    sub configure {

        my $stopwords = Pod::Wordlist::Author::TABULO->new;
        $self->add_plugin(
            [ 'Test::PodSpelling' => { stopwords => [ sort keys %{ $stopwords->wordlist } ] } ],
        );
    }

=head1 DESCRIPTION

This is an EXPERIMENTAL module for my personal use within my authoring workflows (especially with L<Dist::Zilla>).

It's there because I don't want to lose my time adding the same stopwords in multiple places.

You shouldn't use this module. Everything in and about it is subject to change without prior notice or deprecation cycles.

Even if it doesn't manage to eat your cat, it can surely put bad words in your mouth :-)

Currently, the extra stopwords injected include: some monikers, aliases (e.g. TABULON), CPAN IDs, technical terms,
and other words commonly used (by me) that are not included in the default word list.

=head1 METHODS

=head2 learn_stopwords_from (OVERRIDDEN from parent)

Like the inherited C<learn_stopwords> method, but this one accepts any number of arguments which will be I<learned> in a loop.

So, it basically saves you loop.

=head2 learn_stopwords_from

Like the inherited C<learn_stopwords> method, but this one also accepts, in addition to simple scalars, any number of things that appear to be capable of providing textual content, such as:

* simple scalar
* IO::Handle  (which will be read from)
* Any object that I<can> do C<lines_utf8()>, such as and instance of L<Path::Tiny>

=for Pod::Coverage default  delta  entire

=head1 HOW IT WORKS

This module sub-classes L<Pod::Wordlist> and overrides its C<wordlist> method, injecting a bunch words to the returned wordlist.

Unlike L<Pod::Wordlist::hanekomu> (DEPRECATED), this module does NOT do anything behind the scenes:

Namely, it doesn't directly interact with L<Test::Spelling>. Therefore, merely loading this module will NOT automagically add its stopwords for spell-checking.

Instead, it just sits there and provides the same API as L<Pod::Wordlist>, augmenting the stopwords provided by that module.

So, in order to benefit from it, one needs to somehow tell L<Test::Spelling> to actually make use of it (which is construed as a feature).

First, I thought that could easily be achieved since the L<Dist::Zilla> plugin L<[Test::PodSpelling]|Dist::Zilla::Plugin::Test::PodSpelling> advertises just such a configuration parameter (C<wordlist>) that could have been given within C<dist.ini> or thru a PluginBundle, which is how I intended to use it.

Apparently not... From what I gather, even though L<Dist::Zilla::Plugin::Test::PodSpelling> does indeed pass the buck ( C<wordlist>) along, the underlying modules (L<Test::PodSpelling> and L<Pod::Spelling>) merely ignore that setting... Perhaps a bug report or a PR is due for at least one of those.authoring.

Anyhow, in the end, I had to grab the stopwords provided by this module  and shove those into the C<stopwords> parameter of the L<Dist::Zilla> plugin L<[Test::PodSpelling]|Dist::Zilla::Plugin::Test::PodSpelling>. That seems to work like a charm.

For the moment, this had to be done in my personal L<PluginBundle|Dist::Zilla::PluginBundle::Author::TABULO> since you can't execute code in  C<dist.ini>. It's kind of a shame, but it works!

=head1 DEFAULT STOPWORD SOURCES (a.k.a. default @teachers)

By default, this module will acquire its wordlist from any or all of the below sources:

* $DIST_SHARE_DIR/stopwords (of this distro)

* <DATA> section (of this module)

Those sources result in what I call the "I<DELTA>" dictionary (as opposed to the I<ENTIRE> dictionary that would include the wordlist from L<Pod::Wordlist> as well).authoring.ext/Dist-Milla/lib/Dist/Milla.pm

 Since I<DELTA> is the default, you can get the I<DELTA> dictionary like below :

    my $lexicon = Pod::Wordlist::Author::TABULO->new();
    $stopwords = $lexicon->wordlist()       # This will get you the I<delta>.

If you want the I<ENTIRE> wordlist (including also wordlist from L<Pod::Wordlist>), you would have to do:

C<stopwords> is expected to be a plain text file with whitespace separated words in it.

    # Line comments are honored

    So are side comments      # like this

=head1 CREDITS

Adopted the initial code from L<Pod::Wordlist::hanekomu> (DEPRECATED), but the mechanism of hooking into the spell-checking is entirely different.

=head1 SEE ALSO

* L<Pod::Wordlist>
* L<Test::Spelling>
* L<Dist::Zilla::Plugin::Test::PodSpelling>

=head1 AUTHORS

Tabulo[n] <dev@tabulo.net>

=head1 LEGAL

This software is copyright (c) 2022 by Tabulo[n].

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
distro
distros



