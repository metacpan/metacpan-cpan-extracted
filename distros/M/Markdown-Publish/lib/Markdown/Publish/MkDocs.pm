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
package Markdown::Publish::MkDocs;


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

    my ($self, $preview)=@_;
    my ($config_fn, $extend_fn)=$self->configuration_files();
    die "config_extend cannot be used with direct MkDocs configuration\n"
        if defined($extend_fn) && $self->option('config_mode', '') eq 'direct';
    $config_fn='mkdocs.yml'
        if !defined($config_fn) && !defined($extend_fn) && -f 'mkdocs.yml';
    if (defined($config_fn) && length($config_fn) &&
        ($self->option('config_mode', '') eq 'direct' || $config_fn eq 'mkdocs.yml')) {
        die "MkDocs configuration not found: $config_fn\n" unless -f $config_fn;
        return abs_path($config_fn);
    }
    $config_fn=$extend_fn if defined($extend_fn);
    $config_fn='doc/mkdocs/mkdocs.yml'
        if !defined($config_fn) && -f 'doc/mkdocs/mkdocs.yml';

    my ($temporary_dn, $docs_dn, $pages_ar)=$self->prepare_docs();
    $self->promote_home($docs_dn, $pages_ar);
    my $generated_fn=File::Spec->catfile($temporary_dn, 'mkdocs.yml');
    my $output_dn=File::Spec->rel2abs($self->option('output', $MARKDOWN_PUBLISH_OUTPUT_DN));
    my $config='';
    if (defined($config_fn) && length($config_fn)) {
        die "MkDocs configuration not found: $config_fn\n" unless -f $config_fn;
        $config.='INHERIT: '.encode_json(abs_path($config_fn))."\n";
    }
    else {
        $config.='site_name: '.encode_json($self->option('name', 'Documentation'))."\n";
        $config.="theme:\n  name: material\n";
        $config.="markdown_extensions:\n  - admonition\n  - attr_list\n  - def_list\n  - footnotes\n  - tables\n  - pymdownx.superfences\n";
    }
    $config.='docs_dir: '.encode_json(abs_path($docs_dn))."\n";
    $config.='site_dir: '.encode_json($output_dn)."\n";
    $config.="plugins:\n  - search\n" if $preview;
    $config.="nav:\n";
    $config.='  - '.encode_json($_)."\n" foreach @{$pages_ar};
    $self->write_file($generated_fn, $config);
    return $generated_fn;

}


sub build {

    my ($self)=@_;
    my $output_dn=File::Spec->rel2abs($self->option('output', $MARKDOWN_PUBLISH_OUTPUT_DN));
    my $config_fn=$self->prepare(0);
    my @command=($self->option('command', 'mkdocs'), 'build');
    push(@command, '--strict') if $self->option('strict', 1);
    push(@command, '-f', $config_fn, '--site-dir', $output_dn);
    $self->command(@command);
    return $output_dn;

}


sub serve {

    my ($self)=@_;
    my $config_fn=$self->prepare(1);
    my @command=($self->option('command', 'mkdocs'), 'serve', '-f', $config_fn);
    my $address=$self->option('address', undef);
    unless (exists($self->{'address'})) {
        my $host=$self->option('host', $MARKDOWN_PUBLISH_HOST);
        my $port=$self->option('port', $MARKDOWN_PUBLISH_PORT);
        if (defined($host) || defined($port)) {
            $host='127.0.0.1' unless defined($host);
            $port=8000 unless defined($port);
            $address="$host:$port";
        }
    }
    push(@command, '-a', $address) if defined($address) && length($address);
    return $self->system_command(@command);

}
__END__

=begin markdown

# NAME

Markdown::Publish::MkDocs - publish distribution documentation with MkDocs

# SYNOPSIS

```perl
use Markdown::Publish::MkDocs;
my $publish_or=Markdown::Publish::MkDocs->new({sources => ['doc']});
$publish_or->build();
```

# DESCRIPTION

This engine prepares a MkDocs configuration and runs MkDocs. Set `config` to
an authored YAML file. A root `mkdocs.yml` is used directly; other files are
inherited by a temporary configuration that supplies the assembled documents
and navigation. Set `config_mode => 'direct'` when an authored file already
owns that layout. `command`, `strict`, `address`, and `output` customise the
build and local server. `prepare($preview)` returns the configuration path;
`build` returns the site directory; `serve` runs the foreground server.

`config_extend` explicitly selects a supplemental YAML file for inheritance.
It cannot be combined with `config` or direct mode. The publisher retains
control of the assembled `docs_dir`, `site_dir`, and generated navigation.

When no home page is authored, the first top-level assembled page is also used
for `index.md`. Its original URL remains available for existing links.

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

Markdown::Publish::MkDocs - publish distribution documentation with MkDocs


=head1 SYNOPSIS


 use Markdown::Publish::MkDocs;
 my $publish_or=Markdown::Publish::MkDocs->new({sources => ['doc']});
 $publish_or->build();

=head1 DESCRIPTION

This engine prepares a MkDocs configuration and runs MkDocs. Set C<config> to
an authored YAML file. A root C<mkdocs.yml> is used directly; other files are
inherited by a temporary configuration that supplies the assembled documents
and navigation. Set C<<< config_mode => 'direct' >>> when an authored file already
owns that layout. C<command>, C<strict>, C<address>, and C<output> customise the
build and local server. C<prepare($preview)> returns the configuration path;
C<build> returns the site directory; C<serve> runs the foreground server.

C<config_extend> explicitly selects a supplemental YAML file for inheritance.
It cannot be combined with C<config> or direct mode. The publisher retains
control of the assembled C<docs_dir>, C<site_dir>, and generated navigation.

When no home page is authored, the first top-level assembled page is also used
for C<index.md>. Its original URL remains available for existing links.


=head1 SEE ALSO

C<Markdown::Publish>


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.

=cut
