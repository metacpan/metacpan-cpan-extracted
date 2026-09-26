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
package Markdown::Publish::Starlight;


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
    my $site_dn=File::Spec->catdir($temporary_dn, 'starlight');
    my $site_docs_dn=File::Spec->catdir($site_dn, 'src', 'content', 'docs');
    make_path($site_docs_dn);
    $self->copy_tree($docs_dn, $site_docs_dn);
    $self->normalize_node_markdown($site_docs_dn);
    my $astro_version=$self->option('astro_version', 'latest');
    my $starlight_version=$self->option('starlight_version', 'latest');
    my $package_hr={
        type         => 'module',
        scripts      => {build => 'astro build', start => 'astro dev'},
        dependencies => {
            astro                      => $astro_version,
            '@astrojs/starlight'       => $starlight_version,
            '@astrojs/markdown-remark' => 'latest',
            'github-slugger'          => 'latest'
        }
    };
    $self->write_file(File::Spec->catfile($site_dn, 'package.json'), encode_json($package_hr));
    $self->write_file(File::Spec->catfile($site_dn, 'local-links.mjs'), $self->local_links_plugin());
    my ($config_fn, $extend_fn)=$self->configuration_files();
    my $prepared_config_fn;
    if (defined($config_fn) && length($config_fn)) {
        die "Starlight configuration not found: $config_fn\n" unless -f $config_fn;
        my $authored_fn=abs_path($config_fn);
        my $config="import { defineConfig, mergeConfig } from 'astro/config';\n".
            "import { pathToFileURL } from 'node:url';\n".
            "import { unified } from '\@astrojs/markdown-remark';\n".
            "import localLinks from './local-links.mjs';\n\n".
            "const authored = (await import(pathToFileURL(".encode_json($authored_fn).
            ").href)).default;\n".
            "const markdown = authored.markdown || {};\n".
            "const processor = markdown.processor;\n".
            "if (processor && processor.name !== 'unified') throw new Error('Starlight link resolution requires unified Markdown processing');\n".
            "const options = processor ? processor.options : {};\n".
            "const configured = unified({ ...options, remarkPlugins: [...(options.remarkPlugins || []), ...(markdown.remarkPlugins || []), localLinks] });\n".
            "export default defineConfig(mergeConfig(authored, { markdown: { processor: configured } }));\n";
        $prepared_config_fn=File::Spec->catfile($site_dn, 'astro.config.mjs');
        $self->write_file($prepared_config_fn, $config);
    }
    else {
        my @items=map {
            #  Astro normalizes content collection slugs to lower case.
            my $slug=lc($_->{'id'});
            "      { label: ".encode_json($_->{'title'}).
                ", slug: ".encode_json($slug)." }"
        } @{$navigation_ar};
        my $imports="import { defineConfig } from 'astro/config';\n".
            "import { unified } from '\@astrojs/markdown-remark';\n".
            "import starlight from '\@astrojs/starlight';\n\n".
            "import localLinks from './local-links.mjs';\n";
        my $astro="{\n  base: ".encode_json($self->site_base('/')).",\n".
            "  markdown: { processor: unified({ remarkPlugins: [localLinks] }) }\n}";
        my $starlight="{\n    title: ".
            encode_json($self->option('name', 'Documentation')).
            ",\n    sidebar: [{ label: 'Docs', items: [\n".
            join(",\n", @items)."\n    ] }]\n  }";
        my $config;
        if (defined($extend_fn)) {
            die "Starlight configuration extension not found: $extend_fn\n"
                unless -f $extend_fn;
            my $context_hr=$self->configuration_context($pages_ar, $navigation_ar);
            my $authored_fn=abs_path($extend_fn);
            $config=$imports."import { pathToFileURL } from 'node:url';\n\n".
                "const generated = { astro: $astro, starlight: $starlight };\n".
                "const context = ".encode_json($context_hr).";\n".
                "const extend = (await import(pathToFileURL(".
                encode_json($authored_fn).").href)).default;\n".
                "if (typeof extend !== 'function') throw new Error('Starlight config_extend must export a default function');\n".
                "const configured = await extend(generated, context);\n".
                "if (!configured || typeof configured !== 'object' || !configured.astro || !configured.starlight) throw new Error('Starlight config_extend must return astro and starlight configuration objects');\n".
                "const integrations = configured.astro.integrations || [];\n".
                "if (!Array.isArray(integrations)) throw new Error('Starlight config_extend astro.integrations must be an array');\n".
                "const { integrations: unused, ...astro } = configured.astro;\n".
                "export default defineConfig({ ...astro, integrations: [starlight(configured.starlight), ...integrations] });\n";
        }
        else {
            $config=$imports."\nexport default defineConfig({ ...$astro, integrations: [starlight($starlight)] });\n";
        }
        $prepared_config_fn=File::Spec->catfile($site_dn, 'astro.config.mjs');
        $self->write_file($prepared_config_fn, $config);
    }
    $self->write_file(File::Spec->catfile($site_dn, 'src', 'content.config.ts'),
        "import { defineCollection } from 'astro:content';\n".
        "import { glob } from 'astro/loaders';\n".
        "import { docsSchema } from '\@astrojs/starlight/schema';\n\n".
        "export const collections = { docs: defineCollection({ loader: glob({ pattern: '**/*.{md,mdx}', base: './src/content/docs' }), schema: docsSchema() }) };\n");
    return ($temporary_dn, $site_dn, $prepared_config_fn);

}


sub local_links_plugin {

    #  Astro routes Markdown through slugged page IDs; resolve authored file
    #  links while their source paths are still available to remark.
    #
    return <<'JAVASCRIPT';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { slug } from 'github-slugger';

const root = path.resolve('src/content/docs');

function route(filename) {
  const parts = path.relative(root, filename).replace(/\\/g, '/').replace(/\.mdx?$/i, '').split('/');
  const id = parts.map((part) => slug(part)).join('/');
  if (id === 'index') return '/';
  if (parts[parts.length - 1].toLowerCase() === 'index') return '/' + parts.slice(0, -1).map((part) => slug(part)).join('/') + '/';
  return '/' + id + '/';
}

export default function localLinks() {
  return (tree, file) => {
    function visit(node) {
      if ((node.type === 'link' || node.type === 'definition') && typeof node.url === 'string') {
        const match = /^([^?#]+\.mdx?)(\?[^#]*)?(#.*)?$/i.exec(node.url);
        if (match && !match[1].startsWith('/') && !match[1].includes('://')) {
          const target = path.resolve(path.dirname(file.path), decodeURI(match[1]));
          if (target.startsWith(root + path.sep) && existsSync(target)) {
            const from = route(file.path);
            const to = route(target);
            node.url = (path.posix.relative(from, to) || '.') + '/' + (match[2] || '') + (match[3] || '');
          }
        }
      }
      for (const child of node.children || []) visit(child);
    }
    visit(tree);
  };
}
JAVASCRIPT

}


sub normalize_backend_markdown {

    my ($self, $fn, $markdown)=@_;
    $markdown=$self->title_frontmatter($fn, $markdown);
    return $self->starlight_title_heading($markdown);

}


sub heading_anchor_required {

    return 1;

}


sub admonition_type {

    my ($self, $kind)=@_;
    my %map=(note => 'note', tip => 'tip', warning => 'caution',
        important => 'caution', caution => 'caution');
    return $map{$kind} || $kind;

}


sub starlight_title_heading {

    my ($self, $markdown)=@_;
    my @output;
    my ($fence, $length, $frontmatter, $removed)=('', 0, 0, 0);
    my $index=0;
    foreach my $line (split(/(?<=\n)/, $markdown)) {
        if (!$index && $line=~/^---[ \t]*\r?\n?$/) {
            $frontmatter=1;
            push(@output, $line);
            $index++;
            next;
        }
        if ($frontmatter) {
            $frontmatter=0 if $line=~/^---[ \t]*\r?\n?$/;
            push(@output, $line);
            $index++;
            next;
        }
        if (!$fence && $line=~/^ {0,3}(`{3,}|~{3,})/) {
            $fence=substr($1, 0, 1);
            $length=length($1);
        }
        elsif ($fence && $line=~/^ {0,3}\Q$fence\E{$length,}\s*$/) {
            $fence='';
        }
        elsif (!$fence && !$removed && $line=~/^#\s+(.+?)[ \t]*(\r?\n)?$/) {
            my ($title, $newline)=($1, $2 || '');
            my ($id)=$title=~/\s+\{#([\w.-]+)(?:\s+[^}]*)?\}\s*$/;
            unless (defined($id)) {
                $id=lc($title);
                $id=~s/[^a-z0-9]+/-/g;
                $id=~s/^-|-$//g;
            }
            push(@output, "<a id=\"$id\"></a>$newline") if length($id);
            $removed=1;
            $index++;
            next;
        }
        push(@output, $line);
        $index++;
    }
    return join('', @output);

}


sub build {

    my ($self)=@_;
    my $output_dn=File::Spec->rel2abs($self->option('output', $MARKDOWN_PUBLISH_OUTPUT_DN));
    my (undef, $site_dn, $config_fn)=$self->prepare();
    my $config_arg=File::Spec->abs2rel($config_fn, $site_dn);
    $config_arg=$config_fn if $config_arg=~m{^\.\.[/\\]};
    $self->npm_install($site_dn);
    $self->system_in_dir($site_dn, $self->option('npm', 'npm'),
        'run', 'build', '--', '--config', $config_arg, '--outDir', $output_dn);
    return $output_dn;

}


sub serve {

    my ($self)=@_;
    my (undef, $site_dn, $config_fn)=$self->prepare();
    my $config_arg=File::Spec->abs2rel($config_fn, $site_dn);
    $config_arg=$config_fn if $config_arg=~m{^\.\.[/\\]};
    $self->npm_install($site_dn);
    local $ENV{'ASTRO_DEV_BACKGROUND'}=0;
    my $host=$self->option('host', $MARKDOWN_PUBLISH_HOST);
    my $port=$self->option('port', $MARKDOWN_PUBLISH_PORT);
    $host='127.0.0.1' unless defined($host);
    $port=4321 unless defined($port);
    return $self->system_in_dir($site_dn, $self->option('npm', 'npm'),
        'run', 'start', '--', '--config', $config_arg,
        '--host', $host, '--port', $port);

}
__END__

=begin markdown

# NAME

Markdown::Publish::Starlight - publish distribution documentation with Astro Starlight

# SYNOPSIS

```perl
use Markdown::Publish::Starlight;
my $publish_or=Markdown::Publish::Starlight->new({sources => ['doc']});
$publish_or->build();
```

# DESCRIPTION

This engine assembles documents and an ordered sidebar in a temporary Astro
Starlight project. Set `config` to an authored Astro configuration, or let the
engine create one. `npm`, `astro_version`, `starlight_version`, `host`, `port`,
and `output` customise operation. `prepare` returns the temporary root,
project directory, and configuration path; `build` returns the site directory;
`serve` runs the foreground server. For generated configuration, `base` sets
Astro's deployment base path. An authored configuration remains authoritative.
Local Markdown links such as `lib/Example/Module.pm.md` are resolved to the
corresponding Starlight page in the temporary project. An authored Astro
configuration is wrapped to retain this behavior; its Markdown processor must
be unified if it sets one explicitly.

Set `config_extend` to an ECMAScript module whose default export receives
`({astro, starlight}, context)`. It must return both objects. `astro` contains
the generated Astro settings and required Markdown processor; `starlight`
contains the generated title and sidebar options passed to the Starlight
integration. Extra `astro.integrations` are retained after the Starlight
integration. Synchronous and asynchronous functions are accepted. `config`
and `config_extend` cannot be combined.

```javascript
export default ({astro, starlight}) => ({
  astro,
  starlight: {
    ...starlight,
    social: [{icon: 'github', label: 'GitHub', href: 'https://github.com/example/project'}],
  },
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

Markdown::Publish::Starlight - publish distribution documentation with Astro Starlight


=head1 SYNOPSIS


 use Markdown::Publish::Starlight;
 my $publish_or=Markdown::Publish::Starlight->new({sources => ['doc']});
 $publish_or->build();

=head1 DESCRIPTION

This engine assembles documents and an ordered sidebar in a temporary Astro
Starlight project. Set C<config> to an authored Astro configuration, or let the
engine create one. C<npm>, C<astro_version>, C<starlight_version>, C<host>, C<port>,
and C<output> customise operation. C<prepare> returns the temporary root,
project directory, and configuration path; C<build> returns the site directory;
C<serve> runs the foreground server. For generated configuration, C<base> sets
Astro's deployment base path. An authored configuration remains authoritative.
Local Markdown links such as C<lib/Example/Module.pm.md> are resolved to the
corresponding Starlight page in the temporary project. An authored Astro
configuration is wrapped to retain this behavior; its Markdown processor must
be unified if it sets one explicitly.

Set C<config_extend> to an ECMAScript module whose default export receives
C<({astro, starlight}, context)>. It must return both objects. C<astro> contains
the generated Astro settings and required Markdown processor; C<starlight>
contains the generated title and sidebar options passed to the Starlight
integration. Extra C<astro.integrations> are retained after the Starlight
integration. Synchronous and asynchronous functions are accepted. C<config>
and C<config_extend> cannot be combined.


 export default ({astro, starlight}) => ({
   astro,
   starlight: {
     ...starlight,
     social: [{icon: 'github', label: 'GitHub', href: 'https://github.com/example/project'}],
   },
 });

=head1 SEE ALSO

C<Markdown::Publish>


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.

=cut
