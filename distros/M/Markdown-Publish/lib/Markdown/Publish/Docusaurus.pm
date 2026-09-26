#
#  This file is part of Markdown::Publish.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#
package Markdown::Publish::Docusaurus;


#  Compiler pragma and package variables
#
use strict qw(vars);
use vars qw($VERSION @ISA);
use warnings;


#  Parent and supporting packages
#
use Markdown::Publish ();
use Markdown::Publish::Constant;
use Cwd qw(abs_path);
use File::Path qw(make_path);
use File::Spec;
use JSON::PP qw(encode_json);


#  Inheritance and version information
#
@ISA=qw(Markdown::Publish);
$VERSION='1.003';


#  Done
#
1;


#======================================================================================================================


sub prepare {

    my ($self)=@_;
    my ($temporary_dn, $docs_dn, $pages_ar)=$self->prepare_docs();
    $self->promote_home($docs_dn, $pages_ar);
    my $navigation_ar=$self->navigation($docs_dn, $pages_ar);
    my $site_dn=File::Spec->catdir($temporary_dn, 'docusaurus');
    my $site_docs_dn=File::Spec->catdir($site_dn, 'docs');
    make_path($site_docs_dn);
    $self->copy_tree($docs_dn, $site_docs_dn);
    $self->normalize_node_markdown($site_docs_dn);
    my @items=map {{
        type  => 'doc',
        id    => $_->{'id'},
        label => $_->{'title'}
    }} @{$navigation_ar};
    my $version=$self->option('version', 'latest');
    my $package_hr={
        scripts      => {
            build => 'docusaurus build',
            start => 'docusaurus start --no-open'
        },
        dependencies => {
            '@docusaurus/core'           => $version,
            '@docusaurus/preset-classic' => $version
        }
    };
    $self->write_file(File::Spec->catfile($site_dn, 'package.json'), encode_json($package_hr));
    my ($config_fn, $extend_fn)=$self->configuration_files();
    my $prepared_config_fn;
    if (defined($config_fn) && length($config_fn)) {
        die "Docusaurus configuration not found: $config_fn\n" unless -f $config_fn;
        $prepared_config_fn=abs_path($config_fn);
    }
    else {
        my $generated="{\n  title: ".
            encode_json($self->option('name', 'Documentation')).
            ",\n  url: 'http://localhost',\n  baseUrl: ".
            encode_json($self->site_base('/')).
            ",\n  onBrokenLinks: 'warn',\n".
            "  markdown: { format: 'detect' },\n".
            "  presets: [['classic', { docs: { routeBasePath: '/', sidebarPath: require.resolve('./sidebars.js') }, blog: false }]],\n}";
        my $config;
        if (defined($extend_fn)) {
            die "Docusaurus configuration extension not found: $extend_fn\n"
                unless -f $extend_fn;
            my $context_hr=$self->configuration_context($pages_ar, $navigation_ar);
            my $authored_fn=abs_path($extend_fn);
            $config="const generated = $generated;\n".
                "const context = ".encode_json($context_hr).";\n".
                "const loaded = require(".encode_json($authored_fn).");\n".
                "const extend = loaded.default || loaded;\n".
                "if (typeof extend !== 'function') throw new Error('Docusaurus config_extend must export a function');\n".
                "const configured = extend(generated, context);\n".
                "if (configured && typeof configured.then === 'function') throw new Error('Docusaurus config_extend must be synchronous');\n".
                "if (!configured || typeof configured !== 'object' || Array.isArray(configured)) throw new Error('Docusaurus config_extend must return a configuration object');\n".
                "module.exports = configured;\n";
        }
        else {
            $config="module.exports = $generated;\n";
        }
        $prepared_config_fn=File::Spec->catfile($site_dn, 'docusaurus.config.js');
        $self->write_file($prepared_config_fn, $config);
    }
    $self->write_file(File::Spec->catfile($site_dn, 'sidebars.js'),
        "module.exports = { docs: ".encode_json(\@items)." };\n");
    return ($temporary_dn, $site_dn, $prepared_config_fn);

}


sub normalize_backend_markdown {

    my ($self, $fn, $markdown)=@_;
    return $self->title_frontmatter($fn, $markdown);

}


sub heading_anchor_required {

    return 1;

}


sub admonition_type {

    my ($self, $kind)=@_;
    my %map=(note => 'note', tip => 'tip', warning => 'warning',
        important => 'warning', caution => 'caution');
    return $map{$kind} || $kind;

}


sub build {

    my ($self)=@_;
    my $output_dn=File::Spec->rel2abs($self->option('output', $MARKDOWN_PUBLISH_OUTPUT_DN));
    my (undef, $site_dn, $config_fn)=$self->prepare();
    $self->npm_install($site_dn);
    $self->system_in_dir($site_dn, $self->option('npm', 'npm'),
        'run', 'build', '--', '--config', $config_fn, '--out-dir', $output_dn);
    return $output_dn;

}


sub serve {

    my ($self)=@_;
    my (undef, $site_dn, $config_fn)=$self->prepare();
    $self->npm_install($site_dn);
    my $host=$self->option('host', $MARKDOWN_PUBLISH_HOST);
    my $port=$self->option('port', $MARKDOWN_PUBLISH_PORT);
    $host='127.0.0.1' unless defined($host);
    $port=3001 unless defined($port);
    return $self->system_in_dir($site_dn, $self->option('npm', 'npm'),
        'run', 'start', '--', '--config', $config_fn,
        '--host', $host, '--port', $port);

}
__END__

=begin markdown

# NAME

Markdown::Publish::Docusaurus - publish distribution documentation with Docusaurus

# SYNOPSIS

```perl
use Markdown::Publish::Docusaurus;
my $publish_or=Markdown::Publish::Docusaurus->new({sources => ['doc']});
$publish_or->build();
```

# DESCRIPTION

This engine assembles documents and an ordered sidebar in a temporary
Docusaurus project. Set `config` to an authored Docusaurus configuration, or
let the engine create one. `npm`, `version`, `host`, `port`, and `output`
customise operation. `prepare` returns the temporary root, project directory,
and configuration path; `build` returns the site directory; `serve` runs the
foreground server. For generated configuration, `base` sets Docusaurus's
`baseUrl`. An authored configuration remains authoritative.

Set `config_extend` to a CommonJS module exporting a synchronous function that
accepts `(config, context)` and returns the Docusaurus configuration to use.
The context contains the generated publication name, base, output, pages, and
navigation. `config` and `config_extend` cannot be combined.

```javascript
module.exports = (config) => ({
  ...config,
  onBrokenLinks: 'throw',
});
```

# SEE ALSO

`Markdown::Publish`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of Markdown::Publish.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>


=end markdown


=head1 NAME

Markdown::Publish::Docusaurus - publish distribution documentation with Docusaurus


=head1 SYNOPSIS


 use Markdown::Publish::Docusaurus;
 my $publish_or=Markdown::Publish::Docusaurus->new({sources => ['doc']});
 $publish_or->build();

=head1 DESCRIPTION

This engine assembles documents and an ordered sidebar in a temporary
Docusaurus project. Set C<config> to an authored Docusaurus configuration, or
let the engine create one. C<npm>, C<version>, C<host>, C<port>, and C<output>
customise operation. C<prepare> returns the temporary root, project directory,
and configuration path; C<build> returns the site directory; C<serve> runs the
foreground server. For generated configuration, C<base> sets Docusaurus's
C<baseUrl>. An authored configuration remains authoritative.

Set C<config_extend> to a CommonJS module exporting a synchronous function that
accepts C<(config, context)> and returns the Docusaurus configuration to use.
The context contains the generated publication name, base, output, pages, and
navigation. C<config> and C<config_extend> cannot be combined.


 module.exports = (config) => ({
   ...config,
   onBrokenLinks: 'throw',
 });

=head1 SEE ALSO

C<Markdown::Publish>


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.

=cut
