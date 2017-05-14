#
# This file is part of Dist-Zilla-Plugin-Git
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::Git::Tag;
# ABSTRACT: Tag the new version

our $VERSION = '2.042';

use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw{ Str Bool};
use namespace::autoclean;

sub _git_config_mapping { +{
   changelog => '%{changelog}s',
} }

# -- attributes

has tag_format  => ( ro, isa=>Str, default => 'v%v' );
has tag_message => ( ro, isa=>Str, default => 'v%v' );
has changelog   => ( ro, isa=>Str, default => 'Changes' );
has branch => ( ro, isa=>Str, predicate=>'has_branch' );
has signed => ( ro, isa=>Bool, default=>0 );

with 'Dist::Zilla::Role::BeforeRelease',
    'Dist::Zilla::Role::AfterRelease',
    'Dist::Zilla::Role::Git::Repo';
with 'Dist::Zilla::Role::Git::StringFormatter';
with 'Dist::Zilla::Role::GitConfig';

#pod =method tag
#pod
#pod     my $tag = $plugin->tag;
#pod
#pod Return the tag that will be / has been applied by the plugin. That is,
#pod returns C<tag_format> as completed with the real values.
#pod
#pod =cut

has tag => ( ro, isa => Str, lazy_build => 1, );

sub _build_tag
{
    my $self = shift;
    return $self->_format_string($self->tag_format);
}


# -- role implementation

around dump_config => sub
{
    my $orig = shift;
    my $self = shift;

    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        (map { $_ => $self->$_ } qw(tag_format tag_message changelog branch tag)),
        signed => $self->signed ? 1 : 0,
    };

    return $config;
};

sub before_release {
    my $self = shift;

    # Make sure a tag with the new version doesn't exist yet:
    my $tag = $self->tag;
    $self->log_fatal("tag $tag already exists")
        if $self->git->tag('-l', $tag );
}

sub after_release {
    my $self = shift;

    my @opts;
    push @opts, ( '-m' => $self->_format_string($self->tag_message) )
        if $self->tag_message; # Make an annotated tag if tag_message, lightweight tag otherwise:
    push @opts, '-s'
        if $self->signed; # make a GPG-signed tag

    my @branch = $self->has_branch ? ( $self->branch ) : ();

    # create a tag with the new version
    my $tag = $self->tag;
    $self->git->tag( @opts, $tag, @branch );
    $self->log("Tagged $tag");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Git::Tag - Tag the new version

=head1 VERSION

version 2.042

=head1 SYNOPSIS

In your F<dist.ini>:

    [Git::Tag]
    tag_format  = v%v       ; this is the default
    tag_message = v%v       ; this is the default

=head1 DESCRIPTION

Once the release is done, this plugin will record this fact in git by
creating a tag.  By default, it makes an annotated tag.  You can set
the C<tag_message> attribute to change the message.  If you set
C<tag_message> to the empty string, it makes a lightweight tag.

It also checks before the release to ensure the tag to be created
doesn't already exist.  (You would have to manually delete the
existing tag before you could release the same version again, but that
is almost never a good idea.)

=head2 Plugin options

The plugin accepts the following options:

=over 4

=item * tag_format - format of the tag to apply. Defaults to C<v%v>.

=item * tag_message - format of the tag annotation. Defaults to C<v%v>.
Use S<C<tag_message =>> to create a lightweight tag.
The L<formatting codes|Dist::Zilla::Role::Git::StringFormatter/DESCRIPTION>
used in C<tag_format> and C<tag_message> are documented under
L<Dist::Zilla::Role::Git::StringFormatter>.

=item * time_zone - the time zone to use with C<%d>.  Can be any
time zone name accepted by DateTime.  Defaults to C<local>.

=item * branch - which branch to tag. Defaults to the current branch.

=item * signed - whether to make a GPG-signed tag, using the default
e-mail address's key. Consider setting C<user.signingkey> if C<gpg>
can't find the correct key:

    $ git config user.signingkey 450F89EC

=back

=head1 METHODS

=head2 tag

    my $tag = $plugin->tag;

Return the tag that will be / has been applied by the plugin. That is,
returns C<tag_format> as completed with the real values.

=for Pod::Coverage after_release
    before_release

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Git>
(or L<bug-Dist-Zilla-Plugin-Git@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Git@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
