package Dist::Zilla::PluginBundle::Author::OpusVL::ToCPAN;

use Moose;
use 5.014;

with (
    'Dist::Zilla::Role::PluginBundle::Easy',
    'Dist::Zilla::Role::PluginBundle::PluginRemover',
    'Dist::Zilla::Role::PluginBundle::Config::Slicer',
);

our $VERSION = '0.013';

sub configure {
    my $self = shift;
    my $remove = $self->payload->{ $self->plugin_remover_attribute } || [];

    $self->add_bundle('@Author::OpusVL', {
        '-remove' => [ 'CPAN::Mini::Inject::REST', 'Repository', @$remove ],
        mcpani_host => 'fake',
    });

    $self->add_plugins(qw(
        UploadToCPAN
        GitHub::Meta
    ));
}
__PACKAGE__->meta->make_immutable;
no Moose;
1;
__END__

=encoding utf8

=head1 NAME

Dist::Zilla::PluginBundle::Author::OpusVL::ToCPAN - Standard behaviour for OpusVL modules being released publicly to CPAN

=head1 SYNOPSIS

This is L<Dist::Zilla::PluginBundle::Author::OpusVL> with local CPAN and git
repo defaults altered to use the real CPAN and Github instead.

In your F<dist.ini>:

    [@Author::OpusVL::ToCPAN]

If you don't want the standard generated README filter that out,

    [@Filter]
    -bundle = @Author::OpusVL::ToCPAN
    -remove = Readme
    -remove = ReadmeFromPod

=head1 DESCRIPTION

This generally implements the workflow that OpusVL modules use as documented
with the L<Dist::Zilla::PluginBundle::Author::OpusVL> bundle (in this distribution).

The difference is that github is assumed to be used for the source code repository
and the bug tracking is wired up accordingly.

Releases will go to CPAN (so ensure you have a ~/.pause file setup).

=head1 BUGS

Currently it does have a test for permissions on PAUSE, but it's very rudimentary
and doesn't deal with checking COMAINT is setup correctly.
