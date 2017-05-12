use strict;
use warnings;
package Dist::Zilla::Plugin::Keywords; # git description: v0.006-22-g3b1a3ad
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: Add keywords to metadata in your distribution
# KEYWORDS: plugin distribution metadata cpan-meta keywords

our $VERSION = '0.007';

use Moose;
with 'Dist::Zilla::Role::MetaProvider',
    'Dist::Zilla::Role::PPI' => { -version => '5.009' };
use Moose::Util::TypeConstraints;
use MooseX::Types::Moose 'ArrayRef';
use MooseX::Types::Common::String 'NonEmptySimpleStr';
use Encode ();
use namespace::autoclean;

my $word = subtype NonEmptySimpleStr,
    where { !/\s/ };

my $wordlist = subtype ArrayRef[$word];
coerce $wordlist, from ArrayRef[NonEmptySimpleStr],
    via { [ map { split /\s+/, $_ } @$_ ] };


sub mvp_aliases { +{ keyword => 'keywords' } }
sub mvp_multivalue_args { qw(keywords) }

has keywords => (
    is => 'ro', isa => $wordlist,
    coerce => 1,
    lazy => 1,
    default => sub {
        my $self = shift;
        my @keywords = $self->keywords_from_file($self->zilla->main_module);
        \@keywords;
    },
);

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        keywords => $self->keywords,
        blessed($self) ne __PACKAGE__ ? ( version => $VERSION ) : (),
    };
    return $config;
};

sub metadata
{
    my $self = shift;

    my $keywords = $self->keywords;
    return {
        @$keywords ? ( keywords => $keywords ) : ()
    };
}

sub keywords_from_file
{
    my ($self, $file) = @_;

    my $document = $self->ppi_document_for_file($file);

    my $keywords;
    $document->find(
        sub {
            die if $_[1]->isa('PPI::Token::Comment')
                and ($keywords) = $_[1]->content =~ m/^\s*#+\s*KEYWORDS:\s*(.+)$/m;
        }
    );
    return if not $keywords;

    if (not eval { Dist::Zilla::Role::PPI->VERSION('6.003') })
    {
        # older Dist::Zilla::Role::PPI passes encoded content to PPI
        $keywords = Encode::decode($file->encoding, $keywords, Encode::FB_CROAK);
    }

    $self->log_debug('found keyword string in main module: ' . $keywords);
    return split /\s+/, $keywords;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Keywords - Add keywords to metadata in your distribution

=head1 VERSION

version 0.007

=head1 SYNOPSIS

In your F<dist.ini>:

    [Keywords]
    keyword = plugin
    keyword = tool
    keywords = development Dist::Zilla

Or, in your F<dist.ini>:

    [Keywords]

And in your main module:

    # KEYWORDS: plugin development tool

=head1 DESCRIPTION

This plugin adds metadata to your distribution under the C<keywords> field.
The L<CPAN meta specification|CPAN::Meta::Spec/keywords>
defines this field as:

    A List of keywords that describe this distribution. Keywords must not include whitespace.

=for Pod::Coverage metadata mvp_aliases mvp_multivalue_args keywords_from_file

=head1 CONFIGURATION OPTIONS

=head2 C<keyword>, C<keywords>

One or more words to be added as keywords. Can be repeated more than once.
Strings are broken up by whitespace and added as separate words.

If no configuration is provided, the main module of your distribution is
scanned for the I<first> C<# KEYWORDS:> comment.

=head1 SEE ALSO

=over 4

=item *

L<CPAN::Meta::Spec/keywords>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Keywords>
(or L<bug-Dist-Zilla-Plugin-Keywords@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Keywords@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
