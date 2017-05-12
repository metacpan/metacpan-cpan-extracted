package Dist::Zilla::Plugin::NoSmartCommentsTests;

# ABSTRACT: Make sure no Smart::Comments escape into the wild

use Moose;
use namespace::autoclean;
use MooseX::AttributeShortcuts;

use autobox::Core;

extends 'Dist::Zilla::Plugin::InlineFiles';

with
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [qw { :InstallModules :ExecFiles :TestFiles }],
    },
    'Dist::Zilla::Role::TextTemplate',
    'Dist::Zilla::Role::PrereqSource',
    ;

=method register_prereqs

Registers a 'develop' phase requirement for L<Test::NoSmartComments> with the
L<Dist::Zilla> object.

=cut

sub register_prereqs {
    my $self = shift @_;

    $self->zilla->register_prereqs(
        { phase => 'develop' },
        'Test::NoSmartComments' => 0,
    );

    return;
}

around merged_section_data => sub {
    my ($orig, $self) = (shift, shift);

    ### invoke the original to get the sections...
    my $data = $self->$orig(@_);

    ### bail if no data...
    return unless $data;

    ### munge each section with our template engine...
    my %stash = ( files => [ map { $_->name } $self->found_files->flatten ] );
    do { $data->{$_} = \( $self->fill_in_string(${$data->{$_}}, { %stash }) ) }
        for $data->keys;

    ### $data
    return $data;
};

__PACKAGE__->meta->make_immutable;
!!42;

=head1 SYNOPSIS

    ; In C<dist.ini>:
    [Test::NoSmartComments]

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following file:

  xt/release/no-smart-comments.t - test to ensure no Smart::Comments

=head1 NOTE

The name of this plugin has turned out to be somewhat misleading, I'm afraid:
we don't actually test for the _existance_ of smart comments, rather we
ensure that Smart::Comment is not used by any file checked.

=head1 SEE ALSO

Smart::Comments

Test::NoSmartComments

=cut

__DATA__
___[ xt/release/no-smart-comments.t ]___
#!/usr/bin/env perl

use strict;
use warnings;

use Test::More 0.88;

eval "use Test::NoSmartComments";
plan skip_all => 'Test::NoSmartComments required for checking comment IQ'
    if $@;

{{ foreach my $file (@files) { $OUT .= qq{no_smart_comments_in("$file");\n} } }}
done_testing();
