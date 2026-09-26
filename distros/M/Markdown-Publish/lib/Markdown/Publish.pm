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
package Markdown::Publish;


#  Compiler pragma and package variables
#
use strict qw(vars);
use vars qw($VERSION $AUTHORITY);
use warnings;


#  Core and external packages
#
use Cwd qw(abs_path getcwd);
use File::Basename qw(basename);
use File::Copy qw(copy);
use File::Find ();
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Run3 qw(run3);
use JSON::PP qw(decode_json encode_json);
use Markdown::Publish::Constant;


#  Version information
#
$AUTHORITY='cpan:ASPEER';
$VERSION='1.003';


#  Supported publication actions
#
my %ACTION=map {$_ => 1} qw(build serve gh gh-push cloudflare);


#  Short names for the publisher classes supplied by this distribution
#
my %module_alias=(
    mkdocs     => 'Markdown::Publish::MkDocs',
    vitepress  => 'Markdown::Publish::VitePress',
    docusaurus => 'Markdown::Publish::Docusaurus',
    starlight  => 'Markdown::Publish::Starlight'
);


#  Done
#
1;


#======================================================================================================================

sub new {

    my ($class, $opt_hr)=@_;
    $opt_hr={} unless defined($opt_hr);
    die "publication configuration must be a hash reference\n"
        unless ref($opt_hr) eq 'HASH';
    if ($class eq __PACKAGE__) {
        if (exists($opt_hr->{'config_file'})) {
            die "config_file cannot be combined with inline publication settings\n"
                unless keys(%{$opt_hr})==1;
            return $class->load_config($opt_hr->{'config_file'});
        }
        my $publisher=defined($ENV{'MARKDOWN_PUBLISH_MODULE'}) ?
            $ENV{'MARKDOWN_PUBLISH_MODULE'} :
            (exists($opt_hr->{'module'}) ? $opt_hr->{'module'} : $MARKDOWN_PUBLISH_MODULE);
        die "publication module is not defined\n"
            unless defined($publisher) && length($publisher);
        $publisher=$module_alias{lc($publisher)} || $publisher;
        (my $publisher_fn=$publisher)=~s{::}{/}g;
        my $loaded=eval {
            require "$publisher_fn.pm";
            1;
        };
        die "unable to load publication module $publisher: $@"
            unless $loaded;
        die "$publisher is not a Markdown::Publish subclass\n"
            unless $publisher->isa(__PACKAGE__);
        return $publisher->new($opt_hr);
    }
    my $self=bless({%{$opt_hr}}, $class);
    return $self;

}


sub load_config {


    #  Read a standalone JSON configuration and accept either the complete
    #  metadata extension or its publish section.
    #
    my ($class, $config_fn)=@_;
    open(my $config_fh, '<', $config_fn) ||
        die "unable to read publication configuration $config_fn: $!\n";
    local $/=undef;
    my $json=<$config_fh>;
    close($config_fh) ||
        die "unable to close publication configuration $config_fn: $!\n";
    my $config_hr=decode_json($json);
    die "publication configuration in $config_fn must be an object\n"
        unless ref($config_hr) eq 'HASH';

    if (ref($config_hr->{'x_documentation'}) eq 'HASH') {
        $config_hr=$config_hr->{'x_documentation'};
    }
    if (ref($config_hr->{'publish'}) eq 'HASH') {
        $config_hr=$config_hr->{'publish'};
    }
    return $class->new($config_hr);

}


sub option {

    my ($self, $name, $default)=@_;
    return $self->{$name} if exists($self->{$name});
    return $default;

}


sub configuration_files {

    my ($self)=@_;
    my $config_fn=$self->option('config', undef);
    my $extend_fn=$self->option('config_extend', undef);
    my $has_config=defined($config_fn) && length($config_fn);
    my $has_extend=defined($extend_fn) && length($extend_fn);
    die "config and config_extend cannot be combined\n"
        if $has_config && $has_extend;
    return ($has_config ? $config_fn : undef,
        $has_extend ? $extend_fn : undef);

}


sub configuration_context {

    my ($self, $pages_ar, $navigation_ar)=@_;
    $pages_ar=[] unless defined($pages_ar);
    $navigation_ar=[] unless defined($navigation_ar);
    return {
        name       => $self->option('name', 'Documentation'),
        base       => $self->site_base('/'),
        output     => $self->option('output', $MARKDOWN_PUBLISH_OUTPUT_DN),
        pages      => [@{$pages_ar}],
        navigation => [map {{%{$_}}} @{$navigation_ar}]
    };

}


sub site_base {

    my ($self, $default)=@_;
    my $base=exists($self->{'base'}) ? $self->{'base'} : $default;
    return undef unless defined($base);
    die "publication base must start and end with / and contain no empty or dot segments\n"
        if ref($base) || !length($base) || $base!~m{\A/} || $base!~m{/\z} ||
            $base=~m{//} || $base=~m{(?:\A|/)\.\.?/} || $base=~m{[\s?#]};
    return $base;

}


sub github_repository_name {

    my ($self)=@_;
    my $remote;
    eval {$remote=$self->command('git', 'config', '--get', 'remote.origin.url')};
    if (defined($remote) && length($remote)) {
        $remote=~s/[\r\n]+\z//;
        $remote=~s{[/\\]+\z}{};
        $remote=~s{\.git\z}{}i;
        if ($remote=~m{([^/\\:]+)\z}) {
            my $repository=$1;
            return $repository if $repository=~/\A[A-Za-z0-9._-]+\z/;
        }
    }
    my $root_dn=$self->command('git', 'rev-parse', '--show-toplevel');
    $root_dn=~s/[\r\n]+\z//;
    my $repository=basename($root_dn);
    die "unable to determine GitHub repository name\n"
        unless defined($repository) && $repository=~/\A[A-Za-z0-9._-]+\z/;
    return $repository;

}


sub github_base {

    my ($self)=@_;
    my $repository=$self->github_repository_name();
    return '/' if $repository=~/\.github\.io\z/i;
    return "/$repository/";

}


sub github_site_base {

    my ($self)=@_;
    return $self->site_base('/') if exists($self->{'base'});
    return $self->github_base();

}


sub validate_action {

    my ($self, $action)=@_;
    die "unknown publication action: $action\n"
        unless defined($action) && $ACTION{$action};
    return 1;

}


sub run {

    my ($self, $action)=@_;
    $self->validate_action($action);
    return $self->build() if $action eq 'build';
    return $self->serve() if $action eq 'serve';
    return $self->publish_gh() if $action eq 'gh';
    return $self->publish_gh_push() if $action eq 'gh-push';
    return $self->publish_cloudflare();

}


sub command {

    my ($self, @command)=@_;
    my ($output, $error);
    run3(\@command, \undef, \$output, \$error);
    die "command failed (@command): $error\n" if $?;
    return $output;

}


sub system_command {

    my ($self, @command)=@_;
    system(@command);
    die "command failed (@command)\n" if $?;
    return 1;

}


sub system_in_dir {

    my ($self, $dir, @command)=@_;
    my $cwd=getcwd();
    chdir($dir) || die "unable to chdir $dir: $!\n";
    my $ok=eval {$self->system_command(@command); 1};
    my $error=$@;
    chdir($cwd) || die "unable to chdir $cwd: $!\n";
    die $error unless $ok;
    return 1;

}


sub write_file {

    my ($self, $fn, $text)=@_;
    my (undef, $parent_dn)=File::Spec->splitpath($fn);
    make_path($parent_dn) if length($parent_dn) && !-d $parent_dn;
    open(my $output_fh, '>', $fn) || die "unable to write $fn: $!\n";
    print {$output_fh} $text;
    close($output_fh) || die "unable to close $fn: $!\n";
    return 1;

}


sub copy_tree {

    my ($self, $source_dn, $target_dn)=@_;
    return unless -d $source_dn;
    File::Find::find({
        no_chdir => 1,
        wanted   => sub {
            my $fn=$File::Find::name;
            return if -l $fn;
            my $relative=File::Spec->abs2rel($fn, $source_dn);
            my $output_fn=File::Spec->catfile($target_dn, $relative);
            if (-d $fn) {
                make_path($output_fn);
            }
            elsif (-f $fn) {
                copy($fn, $output_fn) || die "unable to copy $fn: $!\n";
            }
        }
    }, $source_dn);
    return 1;

}


sub source_directories {


    #  An explicit source list is exact. Without one, doc is the publication
    #  boundary whenever it exists; module sidecars are only a fallback.
    #
    my ($self)=@_;
    if (exists($self->{'sources'})) {
        die "publication sources must be an array reference\n"
            unless ref($self->{'sources'}) eq 'ARRAY';
        return [@{$self->{'sources'}}];
    }
    return ['doc'] if -d 'doc';
    my @source_dn=grep {-d $_} qw(lib bin);
    warn "doc directory not found; publishing module and executable sidecars\n"
        if @source_dn;
    return \@source_dn;

}


sub target_filename {

    my ($self, $source_dn, $fn)=@_;
    my $relative=File::Spec->abs2rel($fn, $source_dn);
    if ($source_dn eq 'lib') {
        $relative=~s/\.pm\.md$/.md/;
        $relative=~s{[/\\]}{_}g;
        return File::Spec->catfile('modules', $relative);
    }
    if ($source_dn eq 'bin') {
        return File::Spec->catfile('utilities', $relative);
    }
    return $relative;

}


sub copy_markdown_tree {

    my ($self, $source_dn, $docs_dn)=@_;
    return unless -d $source_dn;
    File::Find::find({
        no_chdir   => 1,
        preprocess => sub {sort @_},
        wanted     => sub {
            my $fn=$File::Find::name;
            return if -l $fn;
            return unless -f $fn && $fn=~/\.md$/;
            my $target_fn=File::Spec->catfile($source_dn,
                File::Spec->abs2rel($fn, $source_dn));
            my $output_fn=File::Spec->catfile($docs_dn, $target_fn);
            die "publication page already exists: $target_fn\n" if -e $output_fn;
            my (undef, $parent_dn)=File::Spec->splitpath($output_fn);
            make_path($parent_dn);
            copy($fn, $output_fn) || die "unable to copy $fn: $!\n";
        }
    }, $source_dn);
    return 1;

}


sub promote_home {

    #  Keep the first page's original path available for authored links.
    #  Only a top-level page can be copied to index without rebasing its links.
    #
    my ($self, $docs_dn, $pages_ar)=@_;
    return unless @{$pages_ar};
    my $has_index=grep {$_ eq 'index.md'} @{$pages_ar};
    return if $has_index || $pages_ar->[0]=~m{[/\\]};
    my $first_fn=File::Spec->catfile($docs_dn, $pages_ar->[0]);
    my $index_fn=File::Spec->catfile($docs_dn, 'index.md');
    copy($first_fn, $index_fn) || die "unable to copy $first_fn: $!\n";
    $pages_ar->[0]='index.md';
    return 1;

}


sub prepare_docs {


    #  Assemble the configured source roots and mirror lib/bin Markdown when
    #  doc is selected. Nested documents remain linkable but outside generated
    #  navigation.
    #
    my ($self)=@_;
    my $temporary_dn=abs_path(tempdir(CLEANUP => 1));
    my $docs_dn=File::Spec->catdir($temporary_dn, 'docs');
    make_path($docs_dn);
    my @pages;
    my $source_dn_ar=$self->source_directories();

    foreach my $source_dn (@{$source_dn_ar}) {
        die "publication source directory not found: $source_dn\n"
            unless -d $source_dn;
        File::Find::find({
            no_chdir   => 1,
            preprocess => sub {sort @_},
            wanted     => sub {
                my $fn=$File::Find::name;
                if (-d $fn && $fn=~m{[/\\](?:build|example|examples|mkdocs|node_modules|site|t)$}) {
                    $File::Find::prune=1;
                    return;
                }
                return unless -f $fn && !-l $fn && $fn=~/\.md$/;
                my $target_fn=$self->target_filename($source_dn, $fn);
                my $output_fn=File::Spec->catfile($docs_dn, $target_fn);
                my (undef, $parent_dn)=File::Spec->splitpath($output_fn);
                make_path($parent_dn);
                my $navigation_page=$source_dn eq 'lib' || $source_dn eq 'bin' ||
                    $target_fn!~m{[/\\]};

                if ($source_dn eq 'doc' && $navigation_page) {
                    open(my $input_fh, '<', $fn) || die "unable to read $fn: $!\n";
                    local $/=undef;
                    my $markdown=<$input_fh>;
                    close($input_fh) || die "unable to close $fn: $!\n";
                    my $split_hr=$self->split($target_fn, $markdown);
                    if (keys(%{$split_hr}) > 1) {
                        foreach my $page (@{$self->{'page_order'}}) {
                            my $page_fn=File::Spec->catfile($docs_dn, $page);
                            $self->write_file($page_fn, $split_hr->{$page});
                            push(@pages, $page);
                        }
                        return;
                    }
                }
                copy($fn, $output_fn) || die "unable to copy $fn: $!\n";
                push(@pages, $target_fn) if $navigation_page;
            }
        }, $source_dn);
    }

    die "no Markdown documents discovered in publication sources\n" unless @pages;
    if (grep {$_ eq 'doc'} @{$source_dn_ar}) {
        $self->copy_markdown_tree('lib', $docs_dn);
        $self->copy_markdown_tree('bin', $docs_dn);
    }
    #  Keep a home page without placing its generated link list in navigation.
    #
    unless (-f File::Spec->catfile($docs_dn, 'index.md')) {
        my $index="# Documentation\n\n";
        $index.="- [$_]($_)\n" foreach @pages;
        $self->write_file(File::Spec->catfile($docs_dn, 'index.md'), $index);
    }

    foreach my $source_dn (@{$source_dn_ar}) {
        $self->copy_tree(File::Spec->catdir($source_dn, 'images'),
            File::Spec->catdir($docs_dn, 'images'));
        $self->copy_tree(File::Spec->catdir($source_dn, 'assets'),
            File::Spec->catdir($docs_dn, 'assets'));
    }
    return ($temporary_dn, $docs_dn, \@pages);

}


sub split {

    my ($self, $fn, $markdown)=@_;
    (my $stem=$fn)=~s/\.md$//;
    my (%pages, %anchor, %chapter_anchor, @order);
    my ($page, $fence, $length, $preamble)=('', '', 0, '');
    foreach my $line (split(/(?<=\n)/, $markdown)) {
        if (!$fence && $line=~/^ {0,3}(`{3,}|~{3,})/) {
            $fence=substr($1, 0, 1);
            $length=length($1);
        }
        elsif ($fence && $line=~/^ {0,3}\Q$fence\E{$length,}\s*$/) {
            $fence='';
        }
        elsif (!$fence && $line=~/^#\s+(.+?)\s*$/) {
            my $title=$1;
            my ($id)=$title=~/\{#([^}]+)\}/;
            unless ($id) {
                $id=lc($title);
                $id=~s/[^a-z0-9]+/-/g;
                $id=~s/^-|-$//g;
            }
            die "empty or unsafe chapter ID in $fn\n"
                unless $id && $id=~/^[\w.-]+$/;
            $page="$stem--$id.md";
            die "duplicate chapter ID $id in $fn\n" if exists($pages{$page});
            $pages{$page}=$preamble;
            $preamble='';
            $chapter_anchor{$id}=1;
            push(@order, $page);
        }
        $anchor{$1}=$page if !$fence && $line=~/\{#([^}]+)\}/ && $page;
        if ($page) {
            $pages{$page}.=$line;
        }
        else {
            $preamble.=$line;
        }
    }

    foreach my $current_page (@order) {
        my $text='';
        my ($current_fence, $current_length)=('', 0);
        foreach my $line (split(/(?<=\n)/, $pages{$current_page})) {
            if (!$current_fence && $line=~/^ {0,3}(`{3,}|~{3,})/) {
                $current_fence=substr($1, 0, 1);
                $current_length=length($1);
            }
            elsif ($current_fence && $line=~/^ {0,3}\Q$current_fence\E{$current_length,}\s*$/) {
                $current_fence='';
            }
            elsif (!$current_fence) {
                foreach my $id (keys(%anchor)) {
                    my (undef, undef, $target)=File::Spec->splitpath($anchor{$id});
                    my $link=$target.($chapter_anchor{$id} ? '' : "#$id");
                    $line=~s{\]\(\#\Q$id\E\)}{]($link)}g;
                }
            }
            $text.=$line;
        }
        $pages{$current_page}=$text;
    }
    $self->{'page_order'}=\@order;
    return \%pages;

}


sub normalize_node_admonitions {

    my ($self, $markdown)=@_;
    my @output;
    my @line=split(/(?<=\n)/, $markdown);
    for (my $index=0; $index<@line; $index++) {
        if ($line[$index]=~/^!!!\s+(\w+).*?\n?$/) {
            my $kind=$self->admonition_type($1);
            push(@output, ":::$kind\n");
            while ($index + 1 < @line && $line[$index + 1]=~/^(?:    |\s*$)/) {
                $index++;
                my $admonition_line=$line[$index];
                $admonition_line=~s/^    //;
                push(@output, $admonition_line);
            }
            push(@output, ":::\n");
            next;
        }
        push(@output, $line[$index]);
    }
    return join('', @output);

}


sub admonition_type {

    my ($self, $kind)=@_;
    return $kind;

}


sub normalize_node_definition_lists {

    my ($self, $markdown)=@_;
    my @line=split(/(?<=\n)/, $markdown);
    my @output;
    my ($fence, $length)=('', 0);
    for (my $index=0; $index<@line; $index++) {
        if (!$fence && $line[$index]=~/^ {0,3}(`{3,}|~{3,})/) {
            $fence=substr($1, 0, 1);
            $length=length($1);
        }
        elsif ($fence && $line[$index]=~/^ {0,3}\Q$fence\E{$length,}\s*$/) {
            $fence='';
        }

        #  Pandoc definition lists are not portable to the Node renderers.
        #  Their two-space continuation indent is also the content indent for
        #  the equivalent CommonMark list item, so the remaining block can be
        #  retained verbatim.
        #
        if (!$fence && $index + 2 < @line && $line[$index]!~/^\s*$/ &&
            $line[$index + 1]=~/^\s*$/ && $line[$index + 2]=~/^:\s+(.*)$/) {
            my $term=$line[$index];
            my $description=$1;
            my $newline=$line[$index + 2]=~/\n\z/ ? "\n" : '';
            $term=~s/\r?\n\z//;
            $description=~s/\r?\n\z//;
            push(@output, "- **$term**\n\n  $description$newline");
            $index+=2;
            next;
        }
        push(@output, $line[$index]);
    }
    return join('', @output);

}


sub normalize_node_attributes {

    my ($self, $markdown)=@_;
    my @output;
    my ($fence, $length)=('', 0);
    foreach my $line (split(/(?<=\n)/, $markdown)) {
        if ($fence) {
            if ($line=~/^ {0,3}\Q$fence\E{$length,}\s*$/) {
                $fence='';
            }
            push(@output, $line);
            next;
        }

        #  Retain an authored code-block ID as an adjacent HTML anchor and
        #  pass its first class as the conventional fenced-code language.
        #
        if ($line=~/^( {0,3})(`{3,}|~{3,})[ \t]*\{([^}\r\n]+)\}[ \t]*(\r?\n)?$/) {
            my ($indent, $delimiter, $attributes, $newline)=($1, $2, $3, $4 || '');
            my ($id)=$attributes=~/(?:^|\s)#([\w.-]+)/;
            my ($language)=$attributes=~/(?:^|\s)\.([\w+-]+)/;
            push(@output, "$indent<a id=\"$id\"></a>$newline") if defined($id);
            push(@output, $indent.$delimiter.(defined($language) ? $language : '').$newline);
            $fence=substr($delimiter, 0, 1);
            $length=length($delimiter);
            next;
        }
        if ($line=~/^ {0,3}(`{3,}|~{3,})/) {
            $fence=substr($1, 0, 1);
            $length=length($1);
            push(@output, $line);
            next;
        }

        #  Docusaurus and Starlight do not accept Pandoc heading attributes.
        #  A raw anchor preserves the stable identifiers used by split links.
        #
        if ($self->heading_anchor_required() &&
            $line=~/^( {0,3})(#{1,6}[^\r\n]*?)\s+\{#([\w.-]+)(?:\s+[^}]*)?\}[ \t]*(\r?\n)?$/) {
            push(@output, "$1<a id=\"$3\"></a>".($4 || '').$1.$2.($4 || ''));
            next;
        }

        #  Attribute blocks on inline links and images otherwise become
        #  visible text in one or more of the Node renderers.
        #
        $line=~s{((?:!)?\[[^\]]*\]\([^\)\r\n]+\))\{[^\}\r\n]+\}}{$1}g;
        push(@output, $line);
    }
    return join('', @output);

}


sub heading_anchor_required {

    return 0;

}




sub markdown_title {

    my ($self, $fn, $markdown)=@_;
    my $title;

    #  Prefer authored frontmatter, accepting the simple quoted and unquoted
    #  title forms used by the supported documentation engines.
    #
    if ($markdown=~/\A---[ \t]*\r?\n(.*?)^---[ \t]*\r?\n/ms) {
        my $frontmatter=$1;
        ($title)=$frontmatter=~/^title:[ \t]*(.*?)[ \t]*\r?$/m;
        if (defined($title) && $title=~/\A"/) {
            my $decoded=eval {decode_json($title)};
            $title=$decoded if defined($decoded) && !ref($decoded);
        }
        elsif (defined($title) && $title=~/\A'(.*)'\z/s) {
            $title=$1;
            $title=~s/''/'/g;
        }
    }

    #  Otherwise use the first level-one heading outside a fenced example.
    #
    unless (defined($title) && length($title)) {
        my ($fence, $length)=('', 0);
        foreach my $line (split(/(?<=\n)/, $markdown)) {
            if (!$fence && $line=~/^ {0,3}(`{3,}|~{3,})/) {
                $fence=substr($1, 0, 1);
                $length=length($1);
            }
            elsif ($fence && $line=~/^ {0,3}\Q$fence\E{$length,}\s*$/) {
                $fence='';
            }
            elsif (!$fence && $line=~/^#\s+(.+?)\s*$/) {
                $title=$1;
                $title=~s/\s+\{#[^}]+\}\s*$//;
                $title=~s/[ \t]+#+[ \t]*$//;
                last;
            }
        }
    }

    #  A filename-derived label is a last resort for headingless documents.
    #
    unless (defined($title) && length($title)) {
        (undef, undef, $title)=File::Spec->splitpath($fn);
        $title=~s/\.md$//;
        $title=~s/[-_]+/ /g;
        $title=join(' ', map {ucfirst($_)} split(/\s+/, $title));
    }
    $title=~s/\s+\{#[^}]+\}\s*$//;
    return $title;

}


sub title_frontmatter {

    my ($self, $fn, $markdown)=@_;
    my $title=$self->markdown_title($fn, $markdown);
    if ($markdown=~/\A---[ \t]*\r?\n(.*?)^---[ \t]*\r?\n/ms) {
        my $frontmatter=$1;
        return $markdown if $frontmatter=~/^title:[ \t]*/m;
        my $title_line='title: '.encode_json($title)."\n";
        $markdown=~s/\A(---[ \t]*\r?\n)/$1$title_line/;
        return $markdown;
    }
    return "---\ntitle: ".encode_json($title)."\n---\n\n$markdown";

}


sub navigation {

    my ($self, $docs_dn, $pages_ar)=@_;
    my @navigation;
    foreach my $page (@{$pages_ar}) {
        my $fn=File::Spec->catfile($docs_dn, $page);
        open(my $input_fh, '<', $fn) || die "unable to read $fn: $!\n";
        local $/=undef;
        my $markdown=<$input_fh>;
        close($input_fh) || die "unable to close $fn: $!\n";
        (my $id=$page)=~s/\.md$//;
        $id=~s{\\}{/}g;
        push(@navigation, {
            file  => $page,
            id    => $id,
            title => $self->markdown_title($page, $markdown)
        });
    }
    return \@navigation;

}


sub normalize_node_markdown {

    my ($self, $source_dn)=@_;
    File::Find::find({
        no_chdir => 1,
        wanted   => sub {
            my $fn=$File::Find::name;
            return unless -f $fn && $fn=~/\.md$/;
            open(my $input_fh, '<', $fn) || die "unable to read $fn: $!\n";
            local $/=undef;
            my $markdown=<$input_fh>;
            close($input_fh) || die "unable to close $fn: $!\n";
            $markdown=$self->normalize_node_definition_lists($markdown);
            $markdown=$self->normalize_backend_markdown($fn, $markdown);
            $markdown=$self->normalize_node_attributes($markdown);
            $markdown=$self->normalize_node_admonitions($markdown);
            $self->write_file($fn, $markdown);
        }
    }, $source_dn);
    return 1;

}


sub normalize_backend_markdown {

    my ($self, $fn, $markdown)=@_;
    return $markdown;

}


sub npm_install {

    my ($self, $site_dn)=@_;
    my $npm=$self->option('npm', 'npm');
    my $engine=ref($self);
    $engine=~s/^.*:://;
    print STDERR "Installing $engine npm dependencies...\n";
    my @quiet=defined($MARKDOWN_PUBLISH_NPM_VERBOSE) &&
        $MARKDOWN_PUBLISH_NPM_VERBOSE eq '1' ? () : ('--silent');
    $self->system_in_dir($site_dn, $npm, 'install', @quiet);
    print STDERR "$engine npm dependencies installed.\n";
    return 1;

}


sub build {

    die "publication backend must implement build()\n";

}


sub serve {

    die "publication backend must implement serve()\n";

}


sub publish_gh {


    #  Build first, then replace only the disposable publication worktree.
    #  Leave the resulting branch local so pushing remains an explicit Git
    #  operation controlled by the repository's configured upstream.
    #
    my ($self)=@_;
    my $branch=$self->option('branch', $MARKDOWN_PUBLISH_BRANCH);
    my $base=$self->github_site_base();
    local $self->{'base'}=$base;
    my $site_dn=$self->build();
    $self->command('git', 'check-ref-format', '--branch', $branch);
    my $temporary_dn=abs_path(tempdir(CLEANUP => 1));
    my $work_dn=File::Spec->catdir($temporary_dn, 'pages');
    my $exists=eval {
        $self->command('git', 'rev-parse', '--verify', "refs/heads/$branch");
        1;
    };
    $self->command('git', 'worktree', 'add', ($exists ? () : '--detach'), $work_dn,
        $exists ? $branch : 'HEAD');
    my $ok=eval {
        $self->command('git', '-C', $work_dn, 'checkout', '--orphan', $branch)
            unless $exists;
        $self->command('git', '-C', $work_dn, 'rm', '-r', '-f', '--ignore-unmatch', '.');
        $self->copy_tree($site_dn, $work_dn);
        $self->write_file(File::Spec->catfile($work_dn, '.nojekyll'), '');
        $self->command('git', '-C', $work_dn, 'add', '.');
        my $changed=$exists ?
            length($self->command('git', '-C', $work_dn, 'diff', '--cached', '--name-only')) : 1;
        $self->command('git', '-C', $work_dn, 'commit', '-m', 'Update documentation')
            if $changed;
        1;
    };
    my $error=$@;
    $self->command('git', 'worktree', 'remove', '--force', $work_dn);
    die $error unless $ok;
    return $branch;

}


sub publish_gh_push {


    #  Keep local branch creation in publish_gh(), then make the remote side
    #  effect explicit by pushing only the resulting branch to origin.
    #
    my ($self)=@_;
    my $branch=$self->publish_gh();
    $self->command('git', 'push', 'origin', $branch);
    return $branch;

}


sub publish_cloudflare {


    #  The site generator owns the build; Wrangler deploys only the resulting
    #  static assets using an explicitly selected Worker configuration.
    #
    my ($self)=@_;
    my $cloudflare_hr=$self->{'cloudflare'};
    die "cloudflare publication configuration must be a hash reference\n"
        unless ref($cloudflare_hr) eq 'HASH';
    my $config_fn=$cloudflare_hr->{'config'} ||
        die "cloudflare publication requires a Wrangler configuration file\n";
    die "Wrangler configuration not found: $config_fn\n" unless -f $config_fn;
    $config_fn=abs_path($config_fn);
    my $wrangler=$cloudflare_hr->{'wrangler'} || 'wrangler';

    my $site_dn=$self->build();
    die "built site directory not found: $site_dn\n" unless -d $site_dn;
    $site_dn=abs_path($site_dn);
    my @command=($wrangler, 'deploy', '--config', $config_fn,
        '--assets', $site_dn);
    push(@command, '--env', $cloudflare_hr->{'environment'})
        if defined($cloudflare_hr->{'environment'}) && length($cloudflare_hr->{'environment'});
    $self->system_command(@command);
    return $site_dn;

}


__END__

=begin markdown

# NAME

Markdown::Publish - common documentation publication operations

# SYNOPSIS

```perl
use Markdown::Publish;

my $publish_or=Markdown::Publish->new({
    module  => 'Markdown::Publish::MkDocs',
    sources => ['doc'],
    config  => 'doc/mkdocs/mkdocs.yml',
});

$publish_or->run('build');
$publish_or->run('serve');
$publish_or->run('gh');
$publish_or->run('gh-push');
$publish_or->run('cloudflare');
```

# DESCRIPTION

This module selects one publishing engine and provides the shared operations
for assembling Markdown, splitting chapters, normalising links and assets,
and publishing a built site through a temporary Git worktree. The engine
classes implement their own `prepare`, `build`, and `serve` methods. No
Makefile is needed; `ASPEER::MakeMaker::Markdown::Publish` supplies optional
MakeMaker targets.

An existing `doc/` directory is the default publication boundary. When it is
assembled, Markdown beneath `lib/` and `bin/` is mirrored under those paths in
the temporary site documents. A guide can link to `lib/Example/Module.pm.md`.
Mirrored pages are available through links but are not added to generated
navigation. When `doc/` is absent, sidecars become the default source pages.
Set `sources` explicitly to include other directories. Source files are never rewritten;
assembly and engine-specific Markdown adjustments happen in temporary trees.
Nested Markdown under `doc/` remains available for links but does not appear
in generated navigation. When no `index.md` was authored, the first top-level
page becomes the home page in each engine; its original URL remains available.

# CONFIGURATION

The default engine is `Markdown::Publish::MkDocs`. Select another class
with `module`. `MARKDOWN_PUBLISH_MODULE` overrides `module`, including
when it comes from a JSON file or MakeMaker metadata. The `mkdocs`, `vitepress`,
`docusaurus`, and `starlight` shortcuts select the bundled publishers. A fully
qualified name may select another installed subclass. Engine settings are
flat, rather than nested beneath engine names:

```perl
{
    module  => 'Markdown::Publish::Docusaurus',
    sources => ['doc'],
    name    => 'Example documentation',
    config  => 'doc/docusaurus/docusaurus.config.js',
    output  => 'site',
    branch  => 'gh-pages',
    cloudflare => {config => 'wrangler.jsonc'},
}
```

The `config` path and other engine-specific options are described by the
selected engine module. `load_config($filename)` accepts a JSON object
containing the settings directly, under `publish`, or under
`x_documentation.publish`. `new({config_file => $filename})` is equivalent.
Do not combine `config_file` with inline settings.

`base` sets the deployment path for generated VitePress, Docusaurus, and
Starlight configuration. It must begin and end with `/`; for example,
`base => '/example/'`. An authored engine configuration remains authoritative
for its own base path.

Set `config_extend` instead of `config` to customise a generated configuration.
The two settings cannot be combined. MkDocs inherits the supplied YAML file.
VitePress and Starlight load an ECMAScript module whose default export is a
function; Docusaurus loads a CommonJS module exporting a synchronous function.
Each function receives the generated configuration followed by a context object
containing `name`, `base`, `output`, `pages`, and `navigation`, and must return
the configuration to use.

VitePress and Docusaurus receive their native configuration object. Starlight
receives `{astro, starlight}` so its Astro settings and the options passed to
the Starlight integration can be extended separately. Generated values remain
in effect unless the function explicitly replaces them.

For a static documentation Worker, a minimal authored `wrangler.jsonc` is:

```jsonc
{
    "name": "example-docs",
    "compatibility_date": "2026-09-22",
    "assets": {
        "directory": "./site",
        "not_found_handling": "404-page"
    },
    "observability": {
        "enabled": true,
        "traces": {"enabled": true}
    }
}
```

Use the current compatibility date for a new Worker and choose the intended
Worker name. The deploy action replaces `assets.directory` with the selected
engine's actual build output; the authored file remains unchanged.

# METHODS

## new

Loads and constructs the selected engine class. A direct engine-class
constructor may be used when the class is already known.

## load_config

Reads a JSON configuration and constructs its selected engine.

## run

Dispatches `build`, `serve`, `gh`, `gh-push`, or `cloudflare`. `gh` builds the
site and updates the local publication branch. It does not contact a remote;
push the branch through the repository's normal Git workflow. `gh-push`
performs the same build and local branch update, then pushes that branch to
`origin`. These are explicit publishing actions, not part of `build` or
`serve`. `cloudflare`
builds and deploys the static files to a Cloudflare Worker without committing
or pushing Git.

## source_directories

Returns the configured source roots or the default roots described above.

## prepare_docs

Assembles source Markdown and assets in a temporary directory. Returns the
temporary root, assembled document directory, and ordered pages.

## split

Splits a guide at top-level headings outside code fences and repairs links to
anchors moved into another generated page.

## publish_gh

Builds and commits to a temporary worktree for the configured local branch. It
does not change the current checkout or contact a remote. When `base` is not
configured, this action derives it from the `origin` repository name. A normal
project repository uses `/<repository>/`, while a repository named
`<owner>.github.io` uses `/`. If `origin` is unavailable, the Git top-level
directory name is used. This inferred value applies only to the GitHub Pages
build; ordinary builds, local preview, and Cloudflare publication keep their
normal base path.

## publish_gh_push

Runs `publish_gh`, then pushes the resulting publication branch to `origin`.
It does not force the update or push any other branch.

## publish_cloudflare

Builds through the selected engine, then deploys that output as Workers Static
Assets using Wrangler. Set `cloudflare.config` to an existing, dedicated
Wrangler configuration file for the intended Worker. `cloudflare.wrangler`
selects the executable (`wrangler` by default); `cloudflare.environment`
optionally selects an authored Wrangler environment. The site directory is
passed with `--assets`, overriding the config file's asset directory. Missing
configuration or build output is fatal before deployment. Authentication
comes from Wrangler's existing login or environment, not publication metadata.

The Wrangler config owns the Worker name, compatibility date, routing, and
other deployment settings. Use a static-assets-only config without a `main`
script for this documentation workflow. Publishing to an existing Worker can
update its settings; review its config before invoking this remote action.

# SEE ALSO

`Markdown::Publish::MkDocs`,
`Markdown::Publish::VitePress`,
`Markdown::Publish::Docusaurus`,
`Markdown::Publish::Starlight`,
`ASPEER::MakeMaker::Markdown::Publish`

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

Markdown::Publish - common documentation publication operations


=head1 SYNOPSIS


 use Markdown::Publish;

 my $publish_or=Markdown::Publish->new({
     module  => 'Markdown::Publish::MkDocs',
     sources => ['doc'],
     config  => 'doc/mkdocs/mkdocs.yml',
 });

 $publish_or->run('build');
 $publish_or->run('serve');
 $publish_or->run('gh');
 $publish_or->run('gh-push');
 $publish_or->run('cloudflare');

=head1 DESCRIPTION

This module selects one publishing engine and provides the shared operations
for assembling Markdown, splitting chapters, normalising links and assets,
and publishing a built site through a temporary Git worktree. The engine
classes implement their own C<prepare>, C<build>, and C<serve> methods. No
Makefile is needed; C<ASPEER::MakeMaker::Markdown::Publish> supplies optional
MakeMaker targets.

An existing C<doc/> directory is the default publication boundary. When it is
assembled, Markdown beneath C<lib/> and C<bin/> is mirrored under those paths in
the temporary site documents. A guide can link to C<lib/Example/Module.pm.md>.
Mirrored pages are available through links but are not added to generated
navigation. When C<doc/> is absent, sidecars become the default source pages.
Set C<sources> explicitly to include other directories. Source files are never rewritten;
assembly and engine-specific Markdown adjustments happen in temporary trees.
Nested Markdown under C<doc/> remains available for links but does not appear
in generated navigation. When no C<index.md> was authored, the first top-level
page becomes the home page in each engine; its original URL remains available.


=head1 CONFIGURATION

The default engine is C<Markdown::Publish::MkDocs>. Select another class
with C<module>. C<MARKDOWN_PUBLISH_MODULE> overrides C<module>, including
when it comes from a JSON file or MakeMaker metadata. The C<mkdocs>, C<vitepress>,
C<docusaurus>, and C<starlight> shortcuts select the bundled publishers. A fully
qualified name may select another installed subclass. Engine settings are
flat, rather than nested beneath engine names:


 {
     module  => 'Markdown::Publish::Docusaurus',
     sources => ['doc'],
     name    => 'Example documentation',
     config  => 'doc/docusaurus/docusaurus.config.js',
     output  => 'site',
     branch  => 'gh-pages',
     cloudflare => {config => 'wrangler.jsonc'},
 }
The C<config> path and other engine-specific options are described by the
selected engine module. C<load_config($filename)> accepts a JSON object
containing the settings directly, under C<publish>, or under
C<x_documentation.publish>. C<<< new({config_file => $filename}) >>> is equivalent.
Do not combine C<config_file> with inline settings.

C<base> sets the deployment path for generated VitePress, Docusaurus, and
Starlight configuration. It must begin and end with C</>; for example,
C<<< base => '/example/' >>>. An authored engine configuration remains authoritative
for its own base path.

Set C<config_extend> instead of C<config> to customise a generated configuration.
The two settings cannot be combined. MkDocs inherits the supplied YAML file.
VitePress and Starlight load an ECMAScript module whose default export is a
function; Docusaurus loads a CommonJS module exporting a synchronous function.
Each function receives the generated configuration followed by a context object
containing C<name>, C<base>, C<output>, C<pages>, and C<navigation>, and must return
the configuration to use.

VitePress and Docusaurus receive their native configuration object. Starlight
receives C<{astro, starlight}> so its Astro settings and the options passed to
the Starlight integration can be extended separately. Generated values remain
in effect unless the function explicitly replaces them.

For a static documentation Worker, a minimal authored C<wrangler.jsonc> is:


 {
     "name": "example-docs",
     "compatibility_date": "2026-09-22",
     "assets": {
         "directory": "./site",
         "not_found_handling": "404-page"
     },
     "observability": {
         "enabled": true,
         "traces": {"enabled": true}
     }
 }
Use the current compatibility date for a new Worker and choose the intended
Worker name. The deploy action replaces C<assets.directory> with the selected
engine's actual build output; the authored file remains unchanged.


=head1 METHODS


=head2 new

Loads and constructs the selected engine class. A direct engine-class
constructor may be used when the class is already known.


=head2 load_config

Reads a JSON configuration and constructs its selected engine.


=head2 run

Dispatches C<build>, C<serve>, C<gh>, C<gh-push>, or C<cloudflare>. C<gh> builds the
site and updates the local publication branch. It does not contact a remote;
push the branch through the repository's normal Git workflow. C<gh-push>
performs the same build and local branch update, then pushes that branch to
C<origin>. These are explicit publishing actions, not part of C<build> or
C<serve>. C<cloudflare>
builds and deploys the static files to a Cloudflare Worker without committing
or pushing Git.


=head2 source_directories

Returns the configured source roots or the default roots described above.


=head2 prepare_docs

Assembles source Markdown and assets in a temporary directory. Returns the
temporary root, assembled document directory, and ordered pages.


=head2 split

Splits a guide at top-level headings outside code fences and repairs links to
anchors moved into another generated page.


=head2 publish_gh

Builds and commits to a temporary worktree for the configured local branch. It
does not change the current checkout or contact a remote. When C<base> is not
configured, this action derives it from the C<origin> repository name. A normal
project repository uses C<<< /<repository>/ >>>, while a repository named
C<<< <owner>.github.io >>> uses C</>. If C<origin> is unavailable, the Git top-level
directory name is used. This inferred value applies only to the GitHub Pages
build; ordinary builds, local preview, and Cloudflare publication keep their
normal base path.


=head2 publish_gh_push

Runs C<publish_gh>, then pushes the resulting publication branch to C<origin>.
It does not force the update or push any other branch.


=head2 publish_cloudflare

Builds through the selected engine, then deploys that output as Workers Static
Assets using Wrangler. Set C<cloudflare.config> to an existing, dedicated
Wrangler configuration file for the intended Worker. C<cloudflare.wrangler>
selects the executable (C<wrangler> by default); C<cloudflare.environment>
optionally selects an authored Wrangler environment. The site directory is
passed with C<--assets>, overriding the config file's asset directory. Missing
configuration or build output is fatal before deployment. Authentication
comes from Wrangler's existing login or environment, not publication metadata.

The Wrangler config owns the Worker name, compatibility date, routing, and
other deployment settings. Use a static-assets-only config without a C<main>
script for this documentation workflow. Publishing to an existing Worker can
update its settings; review its config before invoking this remote action.


=head1 SEE ALSO

C<Markdown::Publish::MkDocs>,
C<Markdown::Publish::VitePress>,
C<Markdown::Publish::Docusaurus>,
C<Markdown::Publish::Starlight>,
C<ASPEER::MakeMaker::Markdown::Publish>


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE AND COPYRIGHT

This file is part of Markdown::Publish. Copyright (c) 2026 Andrew
Speer. This is free software; you can redistribute it and/or modify it under
the same terms as Perl 5.

=cut
