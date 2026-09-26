package Docbook::Convert::Pandoc;

#
#  This file is part of Docbook::Convert.
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

use strict qw(vars);
use warnings;
use vars qw($VERSION);

#  Core modules
use File::Basename qw(dirname);
use File::Find ();
use File::Spec;
use File::Temp qw(tempdir tempfile);
use Cwd qw(abs_path);

#  Non-core modules
use IPC::Run3 qw(run3);

#  Version information
$VERSION='1.012';

sub new {
    my ($class, $opt_hr)=@_;
    return bless({%{$opt_hr || {}}}, $class);
}

sub command {
    my ($self, @command)=@_;
    my ($output, $error);
    run3(\@command, \undef, \$output, \$error);
    die "command failed (@command): $error\n" if $?;
    return $output;
}

sub convert_file {
    my ($self, $fn)=@_;
    die "DocBook file not found: $fn\n" unless -f $fn;
    my $source_fn=abs_path($fn);
    my $temporary_dn=tempdir(CLEANUP => 1);
    my $expanded_fn=File::Spec->catfile($temporary_dn, 'expanded.xml');
    my $promoted_fn=File::Spec->catfile($temporary_dn, 'promoted.xml');
    my $asset_dn=File::Spec->catdir(dirname(abs_path(__FILE__)), 'Pandoc');
    $self->command($self->{'xmllint'} || 'xmllint', '--nonet', '--xinclude', '--noent',
        $source_fn, '--output', $expanded_fn);
    $self->command($self->{'xsltproc'} || 'xsltproc', '--nonet', '-o', $promoted_fn,
        File::Spec->catfile($asset_dn, 'promote-title-ids.xsl'), $expanded_fn);
    my $markdown=$self->command($self->{'pandoc'} || 'pandoc', '-f', 'docbook',
        '-t', 'markdown-smart-auto_identifiers-simple_tables+pipe_tables-all_symbols_escapable',
        '--wrap=none',
        '--lua-filter='.File::Spec->catfile($asset_dn, 'admonition.lua'),
        '--resource-path='.dirname($source_fn), $promoted_fn);
    $markdown=~s/\{\.manual-page-new-tab\s+role="manual-page-new-tab"\}/{target="_blank" rel="noopener"}/g;
    return $markdown;
}


sub discover_articles {

    my ($self, $root_dn)=@_;
    $root_dn='doc' unless defined($root_dn) && length($root_dn);
    return [] unless -d $root_dn;
    my @article_fn;
    File::Find::find({
        no_chdir => 1,
        wanted   => sub {
            my $fn=$File::Find::name;
            if (-d $fn && $fn=~m{(?:^|/)(?:build|site|mkdocs|example|examples|images)$}) {
                $File::Find::prune=1;
                return;
            }
            return unless -f $fn && !-l $fn && $fn=~/\.xml$/i;
            push @article_fn, $fn if $self->is_article($fn);
        }
    }, $root_dn);
    return [sort @article_fn];

}


sub convert_articles {

    my ($self, $root_dn)=@_;
    my @changed_fn;
    foreach my $source_fn (@{$self->discover_articles($root_dn)}) {
        (my $output_fn=$source_fn)=~s/\.xml$/.md/i;
        my $markdown=$self->convert_file($source_fn);
        my $existing=-f $output_fn ? $self->read_file($output_fn) : undef;
        next if defined($existing) && $existing eq $markdown;
        die "refusing to overwrite symlink $output_fn\n" if -l $output_fn;
        push @changed_fn, $output_fn;
        next if $self->{'dry_run'};
        $self->write_file($output_fn, $markdown);
    }
    return \@changed_fn;

}


sub is_article {

    my ($self, $fn)=@_;
    my $xml=$self->read_file($fn);
    $xml=~s/^\xEF\xBB\xBF//;
    $xml=~s/<\?.*?\?>//gs;
    $xml=~s/<!--.*?-->//gs;
    return 0 unless $xml=~/<([A-Za-z_][A-Za-z0-9_.-]*(?::[A-Za-z_][A-Za-z0-9_.-]*)?)(?=[\s\/>])/s;
    my $root=$1;
    $root=~s/^.*://;
    return $root eq 'article';

}


sub read_file {

    my ($self, $fn)=@_;
    open(my $input_fh, '<', $fn) || die "unable to open $fn: $!\n";
    binmode($input_fh);
    local $/=undef;
    my $text=<$input_fh>;
    close($input_fh) || die "unable to close $fn: $!\n";
    return $text;

}


sub write_file {

    my ($self, $fn, $text)=@_;
    my ($output_fh, $temporary_fn)=tempfile('.docbook-XXXXXX', DIR => dirname($fn), UNLINK => 1);
    binmode($output_fh);
    print {$output_fh} $text || die "unable to write $fn: $!\n";
    close($output_fh) || die "unable to close $fn: $!\n";
    my $mode=-f $fn ? (stat($fn))[2] & 07777 : 0644;
    chmod($mode, $temporary_fn) || die "unable to set mode on $fn: $!\n";
    rename($temporary_fn, $fn) || die "unable to replace $fn: $!\n";
    return 1;

}

1;
__END__

=begin markdown

# NAME

Docbook::Convert::Pandoc - convert DocBook guides to Markdown

# SYNOPSIS

```perl
use Docbook::Convert::Pandoc;
my $converter_or=Docbook::Convert::Pandoc->new();
my $markdown=$converter_or->convert_file('doc/guide.xml');
$converter_or->convert_articles('doc');
```

# PUBLIC METHODS

`new(\%options)` creates a converter. Optional pandoc, xmllint and xsltproc
values select executable paths.

`convert_file($filename)` returns Markdown bytes. It expands local XIncludes
and entities, promotes title IDs to sections, and runs Pandoc with the supplied
admonition filter. It requires a real filename so relative includes resolve
against the source document. Intermediate XML lives in temporary files. Literal
angle brackets in prose are emitted as HTML entities so the Markdown renders
consistently with Pandoc and Python-Markdown based tools such as MkDocs.

`discover_articles($directory)` recursively returns DocBook article XML files.
Generated, site, MkDocs, example and image directories are excluded. Discovery
does not depend on a Perl distribution's `MANIFEST`.

`convert_articles($directory)` converts every discovered `article.xml` to its
sibling `article.md` name and returns the paths changed. Existing output is
replaced only when its content differs. Set `dry_run` when constructing the
converter to report changes without writing them. Symlink outputs are refused.

Commands use argument arrays and failures throw exceptions containing diagnostics.
The source document is never modified. Images remain references, so copy their
associated assets when assembling a site. Network document retrieval is disabled
for the XML preprocessing commands.

The package supplies its Lua and XSL filters under the adjacent Pandoc directory.

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of Docbook::Convert.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>


=end markdown


=head1 NAME

Docbook::Convert::Pandoc - convert DocBook guides to Markdown


=head1 SYNOPSIS


 use Docbook::Convert::Pandoc;
 my $converter_or=Docbook::Convert::Pandoc->new();
 my $markdown=$converter_or->convert_file('doc/guide.xml');
 $converter_or->convert_articles('doc');

=head1 PUBLIC METHODS

C<new(\%options)> creates a converter. Optional pandoc, xmllint and xsltproc
values select executable paths.

C<convert_file($filename)> returns Markdown bytes. It expands local XIncludes
and entities, promotes title IDs to sections, and runs Pandoc with the supplied
admonition filter. It requires a real filename so relative includes resolve
against the source document. Intermediate XML lives in temporary files. Literal
angle brackets in prose are emitted as HTML entities so the Markdown renders
consistently with Pandoc and Python-Markdown based tools such as MkDocs.

C<discover_articles($directory)> recursively returns DocBook article XML files.
Generated, site, MkDocs, example and image directories are excluded. Discovery
does not depend on a Perl distribution's C<MANIFEST>.

C<convert_articles($directory)> converts every discovered C<article.xml> to its
sibling C<article.md> name and returns the paths changed. Existing output is
replaced only when its content differs. Set C<dry_run> when constructing the
converter to report changes without writing them. Symlink outputs are refused.

Commands use argument arrays and failures throw exceptions containing diagnostics.
The source document is never modified. Images remain references, so copy their
associated assets when assembling a site. Network document retrieval is disabled
for the XML preprocessing commands.

The package supplies its Lua and XSL filters under the adjacent Pandoc directory.


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.

=cut
