#
# This file is part of Dist-Zilla-PluginBundle-Author-JQUELIN
#
# This software is copyright (c) 2010 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.008;
use strict;
use warnings;

package Dist::Zilla::PluginBundle::Author::JQUELIN;
# ABSTRACT: Build & release a distribution like jquelin
$Dist::Zilla::PluginBundle::Author::JQUELIN::VERSION = '3.005';
use Moose;
use Moose::Autobox;

with 'Dist::Zilla::Role::PluginBundle';
with 'Dist::Zilla::Role::PluginBundle::Config::Slicer';

sub bundle_config {
    my ($self, $section) = @_;
    my $arg   = $section->{payload};

    # params for pod weaver
    $arg->{weaver} ||= 'pod';

    my @dirty = ( "Changes", "dist.ini", "README.mkdn" );
    my @allow_dirty = ( allow_dirty => \@dirty );

    # long list of plugins
    my @wanted = (
        # -- static meta-information
        [ 'Git::NextVersion' => {} ],

        # -- fetch & generate files
        [ GatherDir             => {} ],
        [ 'Test::Compile'       => {
            ':version' => 1.100220
        } ],
        [ PodCoverageTests      => {} ],
        [ PodSyntaxTests        => {} ],
        [ 'Test::ReportPrereqs' => {} ],

        # -- remove some files
        [ PruneCruft   => {} ],
        [ PruneFiles   => { match => '~$' } ],
        [ ManifestSkip => {} ],

        # -- get prereqs
        [ AutoPrereqs => {} ],

        # -- munge files
        [ ExtraTests  => {} ],
        [ NextRelease => {
            ':version'=> 2.101230,
            time_zone => 'Europe/Paris',
        } ],
        [ PkgVersion  => {} ],
        [ ( $arg->{weaver} eq 'task' ? 'TaskWeaver' : 'PodWeaver' ) => {} ],
        [ Prepender   => {
            ':version' => 1.100130
        } ],

        # -- dynamic meta-information
        [ ExecDir                 => {} ],
        [ ShareDir                => {} ],
        [ Bugtracker              => {} ],
        [ Homepage                => {} ],
        [ Repository              => {} ],
        [ 'MetaProvides::Package' => {} ],
        [ MetaConfig              => {} ],

        # -- generate meta files
        [ HelpWanted       => {} ],
        [ License          => {} ],
        [ Covenant         => {} ],
        [ MetaYAML         => {} ],
        [ MetaJSON         => {} ],
        [ ModuleBuild      => {} ],
        [ Readme           => {} ],
        [ ReadmeAnyFromPod => { location => "root", type => "markdown" } ],
        [ Manifest         => {} ], # should come last

        # -- release
        [ CheckChangeLog => {} ],
        [ TestRelease    => {} ],
        [ "Git::Check"   => { @allow_dirty } ],
        [ "Git::Commit"  => { @allow_dirty } ],
        [ "Git::Tag"     => {} ],
        [ "Git::Push"    => {} ],

        [ UploadToCPAN   => {} ],
    );

    # create list of plugins
    my @plugins;
    for my $wanted (@wanted) {
        my ($plugin, $name, $arg);
        if ( scalar(@$wanted) == 2 ) {
            ($plugin, $arg) = @$wanted;
            $name = $plugin;
        } else {
            ($plugin, $name, $arg) = @$wanted;
        }
        my $class = "Dist::Zilla::Plugin::$plugin";
        push @plugins, [ "$section->{name}/$name" => $class => $arg ];
    }

    return @plugins;
}


__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::JQUELIN - Build & release a distribution like jquelin

=head1 VERSION

version 3.005

=head1 SYNOPSIS

In your F<dist.ini>:

    [@Author::JQUELIN]

=head1 DESCRIPTION

This is a plugin bundle to load all plugins that I am using. Check the
code to see exactly what are those plugins.

The following options are accepted:

=over 4

=item * C<weaver> - can be either C<pod> (default) or C<task>, to load
respectively either L<PodWeaver|Dist::Zilla::Plugin::PodWeaver> or
L<TaskWeaver|Dist::Zilla::Plugin::TaskWeaver>.

=back

B<NOTE:> This bundle consumes
L<Dist::Zilla::Role::PluginBundle::Config::Slicer> so you can also
specify attributes for any of the bundled plugins. The option should be
the plugin name and the attribute separated by a dot:

    [@JQUELIN]
    AutoPrereqs.skip = Bad::Module

See L<Config::MVP::Slicer/CONFIGURATION SYNTAX> for more information.

=for Pod::Coverage::TrustPod bundle_config

=head1 SEE ALSO

You can look for information on this module at:

=over 4

=item * CPAN

L<http://metacpan.org/release/Dist-Zilla-PluginBundle-Author-JQUELIN>

=item * See open / report bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-PluginBundle-Author-JQUELIN>

=item * Mailing-list (same as dist-zilla)

L<http://www.listbox.com/subscribe/?list_id=139292>

=item * Git repository

L<http://github.com/jquelin/dist-zilla-pluginbundle-author-jquelin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dist-Zilla-PluginBundle-Author-JQUELIN>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dist-Zilla-PluginBundle-Author-JQUELIN>

=back

See also: L<Dist::Zilla::PluginBundle>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
