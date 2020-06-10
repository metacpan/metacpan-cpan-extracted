package Pod::Weaver::PluginBundle::Author::IOANR 1.201592;

# ABSTRACT: Weave the POD for a IOANR dist

use Moose;
use Pod::Weaver::Config::Assembler;
require Pod::Weaver::Section::Support;
require Pod::Elemental::Transformer::List;
require Pod::Weaver::Plugin::StopWords;

my $bugs_content = <<'END';
Please report any bugs or feature requests through the web interface at {WEB}.
You will be automatically notified of any progress on the request by the system.
END

my $repository_content = <<'END';
The source code is available for from the following locations:
END

sub _exp { Pod::Weaver::Config::Assembler->expand_package($_[0]) }

sub mvp_bundle_config {
    my @plugins;
    push @plugins, (
        ['@Author::IOANR/CorePrep',       _exp('@CorePrep'),       {}],
        ['@Author::IOANR/SingleEncoding', _exp('-SingleEncoding'), {}],
        [
            '@Author::IOANR/List', _exp('-Transformer'),
            {'transformer' => 'List'}
        ],
        ['@Author::IOANR/StopWords', _exp('-StopWords'), {}],

        ['@Author::IOANR/Name',    _exp('Name'),    {}],
        ['@Author::IOANR/Version', _exp('Version'), {}],

        ['@Author::IOANR/Prelude', _exp('Region'), {region_name => 'prelude'}],

        ['@Author::IOANR/Synopsis', _exp('Generic'), {header => 'SYNOPSIS'}],
        [
            '@Author::IOANR/Description', _exp('Generic'),
            {header => 'DESCRIPTION'}
        ],
        ['@Author::IOANR/Overview', _exp('Generic'), {header => 'OVERVIEW'}],
        ['@Author::IOANR/Usage',    _exp('Generic'), {header => 'USAGE'}],
    );

    for my $plugin (
        ['Attributes', _exp('Collect'), {command => 'attr'}],
        ['Methods',    _exp('Collect'), {command => 'method'}],
        ['Functions',  _exp('Collect'), {command => 'func'}],
      )
    {
        $plugin->[2]{header} = uc $plugin->[0];
        push @plugins, $plugin;
    }

    push @plugins,
      (
        ['@Author::IOANR/Leftovers', _exp('Leftovers'), {}],
        [
            '@Author::IOANR/postlude', _exp('Region'),
            {region_name => 'postlude'}
        ],
        [
            '@Author::IOANR/Support',
            _exp('Support'),
            {
                bugs               => 'metadata',
                bugs_content       => $bugs_content,
                repository_content => $repository_content,
                websites           => 'metacpan',
            }
        ],
        ['@Author::IOANR/Authors', _exp('Authors'), {}],
        ['@Author::IOANR/Legal',   _exp('Legal'),   {}],
      );

    return @plugins;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Ioan Rogers

=head1 NAME

Pod::Weaver::PluginBundle::Author::IOANR - Weave the POD for a IOANR dist

=head1 VERSION

version 1.201592

=head1 SEE ALSO

Originally based on L<Pod::Weaver::PluginBundle::NRR>, though I'm sure I copied
it from somewhere else who copied from that one.

=head1 AUTHOR

Ioan Rogers <ioanr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Ioan Rogers.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
