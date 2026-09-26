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
package Markdown::Publish::VitePress;


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
    $self->normalize_node_markdown($docs_dn);
    my $version=$self->option('version', 'latest');
    my $package_hr={
        type         => 'module',
        dependencies => {vitepress => $version}
    };
    $self->write_file(File::Spec->catfile($temporary_dn, 'package.json'),
        encode_json($package_hr));
    my $config_dn=File::Spec->catdir($docs_dn, '.vitepress');
    make_path($config_dn);
    my ($config_fn, $extend_fn)=$self->configuration_files();
    my $prepared_config_fn;
    if (defined($config_fn) && length($config_fn)) {
        die "VitePress configuration not found: $config_fn\n" unless -f $config_fn;
        $prepared_config_fn=abs_path($config_fn);
    }
    else {
        my @items=map {
            my $link=$_->{'id'} eq 'index' ? '/' : '/'.$_->{'id'};
            "          { text: ".encode_json($_->{'title'}).
                ", link: ".encode_json($link)." }"
        } @{$navigation_ar};
        my $generated="{\n  title: ".
            encode_json($self->option('name', 'Documentation')).
            ",\n  base: ".encode_json($self->site_base('/')).
            ",\n  themeConfig: {\n    sidebar: [\n".
            join(",\n", @items)."\n    ]\n  }\n}";
        my $config;
        if (defined($extend_fn)) {
            die "VitePress configuration extension not found: $extend_fn\n"
                unless -f $extend_fn;
            my $context_hr=$self->configuration_context($pages_ar, $navigation_ar);
            my $authored_fn=abs_path($extend_fn);
            $config="import { pathToFileURL } from 'node:url';\n\n".
                "const generated = $generated;\n".
                "const context = ".encode_json($context_hr).";\n".
                "const extend = (await import(pathToFileURL(".
                encode_json($authored_fn).").href)).default;\n".
                "if (typeof extend !== 'function') throw new Error('VitePress config_extend must export a default function');\n".
                "const configured = await extend(generated, context);\n".
                "if (!configured || typeof configured !== 'object' || Array.isArray(configured)) throw new Error('VitePress config_extend must return a configuration object');\n".
                "export default configured;\n";
        }
        else {
            $config="export default $generated;\n";
        }
        $prepared_config_fn=File::Spec->catfile($config_dn, 'config.mts');
        $self->write_file($prepared_config_fn, $config);
    }
    return ($temporary_dn, $docs_dn, $prepared_config_fn);

}


sub admonition_type {

    my ($self, $kind)=@_;
    my %map=(note => 'info', tip => 'tip', warning => 'warning',
        important => 'warning', caution => 'warning');
    return $map{$kind} || $kind;

}


sub build {

    my ($self)=@_;
    my $output_dn=File::Spec->rel2abs($self->option('output', $MARKDOWN_PUBLISH_OUTPUT_DN));
    my ($temporary_dn, $docs_dn, $config_fn)=$self->prepare();
    $self->npm_install($temporary_dn);
    $self->system_in_dir($temporary_dn, $self->option('npm', 'npm'),
        'exec', '--', 'vitepress', 'build', $docs_dn, '--config', $config_fn,
        '--outDir', $output_dn);
    return $output_dn;

}


sub serve {

    my ($self)=@_;
    my ($temporary_dn, $docs_dn, $config_fn)=$self->prepare();
    $self->npm_install($temporary_dn);
    my $host=$self->option('host', $MARKDOWN_PUBLISH_HOST);
    my $port=$self->option('port', $MARKDOWN_PUBLISH_PORT);
    $host='127.0.0.1' unless defined($host);
    $port=5173 unless defined($port);
    return $self->system_in_dir($temporary_dn, $self->option('npm', 'npm'),
        'exec', '--', 'vitepress', 'dev', $docs_dn, '--config', $config_fn,
        '--host', $host, '--port', $port);

}
__END__

=begin markdown

# NAME

Markdown::Publish::VitePress - publish distribution documentation with VitePress

# SYNOPSIS

```perl
use Markdown::Publish::VitePress;
my $publish_or=Markdown::Publish::VitePress->new({sources => ['doc']});
$publish_or->build();
```

# DESCRIPTION

This engine assembles documents, writes generated navigation when no authored
configuration is supplied, and runs VitePress in a temporary npm project.
Set `config` to an authored VitePress configuration; its original location is
preserved for relative imports. `npm`, `version`, `host`, `port`, and `output`
customise operation. `prepare` returns the temporary root, documentation
directory, and configuration path; `build` returns the site directory; `serve`
runs the foreground server. For generated configuration, `base` sets
VitePress's deployment base path. An authored configuration remains
authoritative.

Set `config_extend` to an ECMAScript module whose default export is a function
accepting `(config, context)`. It may return the generated configuration after
adding VitePress settings; synchronous and asynchronous functions are accepted.
The context contains the generated publication name, base, output, pages, and
navigation. `config` and `config_extend` cannot be combined.

```javascript
export default (config) => ({
  ...config,
  themeConfig: {...config.themeConfig, search: {provider: 'local'}},
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

Markdown::Publish::VitePress - publish distribution documentation with VitePress


=head1 SYNOPSIS


 use Markdown::Publish::VitePress;
 my $publish_or=Markdown::Publish::VitePress->new({sources => ['doc']});
 $publish_or->build();

=head1 DESCRIPTION

This engine assembles documents, writes generated navigation when no authored
configuration is supplied, and runs VitePress in a temporary npm project.
Set C<config> to an authored VitePress configuration; its original location is
preserved for relative imports. C<npm>, C<version>, C<host>, C<port>, and C<output>
customise operation. C<prepare> returns the temporary root, documentation
directory, and configuration path; C<build> returns the site directory; C<serve>
runs the foreground server. For generated configuration, C<base> sets
VitePress's deployment base path. An authored configuration remains
authoritative.

Set C<config_extend> to an ECMAScript module whose default export is a function
accepting C<(config, context)>. It may return the generated configuration after
adding VitePress settings; synchronous and asynchronous functions are accepted.
The context contains the generated publication name, base, output, pages, and
navigation. C<config> and C<config_extend> cannot be combined.


 export default (config) => ({
   ...config,
   themeConfig: {...config.themeConfig, search: {provider: 'local'}},
 });

=head1 SEE ALSO

C<Markdown::Publish>


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.

=cut
