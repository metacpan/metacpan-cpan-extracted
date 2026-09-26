#
#  This file is part of Markdown::Pod::Embed.
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
package Markdown::Pod::Embed;


#  Pragma
#
use strict;
use warnings;
use vars qw($VERSION $AUTHORITY);


#  Base Packages
#
use Markdown::Pod::Embed::Util;
use Markdown::Pod::Embed::Constant;


#  Other external modules
#
use File::Copy;
use PPI;
use Markdown::Pod;
use File::Temp qw(tempfile);
use File::Basename qw(dirname);
use File::Find ();
use File::Spec;


#  Version information
#
$AUTHORITY='cpan:ASPEER';
$VERSION='1.013';


#  Done
#
1;


#===================================================================================================
#
# Object creation and import methods
#


sub new {

    #  Bless self ref and retun
    #
    my ($class, $opt_hr)=@_;


    #  Get default options and overrides
    #
    my %opt=(
        %{$OPTION_HR},
        $opt_hr ? %{$opt_hr} : ()
    );


    #  Done
    #
    return bless({opt=>\%opt}, $class);

}


#===================================================================================================
#
#  Markdown processing and source updates
#
sub markpod_process {


    #  Find and replace POD in a file
    #
    my ($self, $fn)=@_;
    delete @{$self}{qw(pod_changed markdown pod ppi_doc_or)};
    debug("processing file: $fn");


    #  Create new PPI documents from supplied file
    #
    my $ppi_doc_or=PPI::Document->new($fn) ||
        return err ("nable to create new PPI instance on file $fn");


    my $sidecar_md=$self->markpod_markdown_file_read($fn);
    my $end_or=$ppi_doc_or->find_first('PPI::Statement::End');


    #  Find Pod section and massage. If no POD exists, create one from sidecar markdown
    #
    my $pod_or_ar=$ppi_doc_or->find('PPI::Token::Pod');
    unless ($pod_or_ar) {
        unless (defined $sidecar_md) {
            return undef;
        }
        my $original=$ppi_doc_or->serialize();
        die "cannot append documentation after a data section in $fn\n"
            if $original=~/^__DATA__\b/m || ($end_or && $end_or->content()!~/\A__END__\s*\z/);
        $self->markpod_end_normalize($end_or) if $end_or;
        my $pod_md=$sidecar_md;
        my $pod=
            $self->markpod_pod_merge($pod_md, $fn) ||
                return err();
        $pod.="\n=cut\n";
        unless ($end_or) {
            $ppi_doc_or->add_element(PPI::Token::Separator->new("__END__\n\n"));
        }
        $ppi_doc_or->add_element(PPI::Document->new(\$pod));
        @{$self}{qw(

            pod_changed
            markdown
            ppi_doc_or

        )}=(

            1,
            $pod_md,
            $ppi_doc_or
        );
        return 1;
    }
    my $end_changed=0;
    if ($end_or && (defined $sidecar_md || grep { $_->content()=~/^=begin markdown(?=\s*)/im } @{$pod_or_ar})) {
        $end_changed=$self->markpod_end_normalize($end_or);
    }
    my $sidecar_target_idx=0;
    if (defined $sidecar_md) {
        foreach my $idx (0 .. $#{$pod_or_ar}) {
            if ($pod_or_ar->[$idx]->content()=~/^=begin markdown(?=\s*)/im) {
                $sidecar_target_idx=$idx;
                last;
            }
        }
    }
    my ($md, $pod_changed, @pod, @raw_pod)=(undef, $end_changed);
    foreach my $idx (0 .. $#{$pod_or_ar}) {
        my $pod_or=$pod_or_ar->[$idx];
        my $pod_content=$pod_or->content();
        my $pod_md=$self->markpod_markdown_extract($pod_content);
        if (defined $sidecar_md && $idx == $sidecar_target_idx) {
            $pod_md=$sidecar_md;
            undef $sidecar_md;
        }
        unless (defined $pod_md) {
            debug("pod: no markdown source, preserving existing POD");
            push @pod, $pod_content;
            push @raw_pod, $pod_content;
            next;
        }
        $md.=$pod_md;
        my $pod=
            $self->markpod_pod_merge($pod_md, $fn) ||
                return err();
        push @raw_pod, $self->{'pod'};
        $pod.="\n=cut\n";
        if ($pod_changed += ($pod ne $pod_content)) {
            debug("pod: updating");
            $pod_or->set_content($pod);
        }
        else {
            debug("pod: no change, not updating");
        }
        push @pod, $pod;
    }


    #  Join POD
    #
    my $pod=join($/, @raw_pod);


    #  Store results
    #
    @{$self}{qw(

        pod_changed
        markdown
        ppi_doc_or

    )}=(

        $pod_changed,
        $md || '',
        $ppi_doc_or
    );


    #  Return number of pod lines that would have changed
    #
    return $pod_changed;

}


sub markpod_end_normalize {

    my ($self, $end_or)=@_;
    my $content=$end_or->content();
    my @children=$end_or->children();
    return 0 unless @children;

    my $pod_idx;
    foreach my $idx (0 .. $#children) {
        if ($children[$idx]->isa('PPI::Token::Pod')) {
            $pod_idx=$idx;
            last;
        }
    }

    my $last_gap_idx=defined $pod_idx ? $pod_idx - 1 : $#children;
    foreach my $idx (1 .. $last_gap_idx) {
        return 0 if $children[$idx]->content()=~/\S/;
    }
    foreach my $idx (0 .. $#children) {
        if ($idx == 0) {
            $children[$idx]->set_content("__END__");
        }
        elsif ($idx == 1 && $idx <= $last_gap_idx) {
            $children[$idx]->set_content("\n\n");
        }
        elsif ($idx <= $last_gap_idx) {
            $children[$idx]->set_content('');
        }
    }
    if (!defined $pod_idx && @children == 1) {
        $end_or->add_element(PPI::Token::Whitespace->new("\n\n"));
    }
    return $content ne $end_or->content();

}


sub markpod_markdown_file_read {

    my ($self, $fn)=@_;
    my $md_fn="${fn}.md";
    return undef unless -f $md_fn;
    my $md=slurp($md_fn);
    chomp($md);
    $md=$self->markpod_markdown_normalize($md);
    unless (length $md) {
        debug("markdown sidecar file is empty, falling back to embedded markdown: $md_fn");
        return undef;
    }
    debug("using markdown sidecar file: $md_fn");
    return $md;

}



sub markpod_inplace_update {


    #  Update file in place
    #
    my ($self, $fn)=@_;
    my $ppi_doc_or=$self->ppi_doc_or()
        || return err();
    return 1 if $self->{'opt'}{'dry_run'};
    die "refusing to replace symlink $fn\n" if -l $fn;


    #  Make a backup copy if needed
    #
    debug("updating file ${fn}");
    unless ($self->{'opt'}{'nobackup'}) {
        File::Copy::copy($fn, "${fn}.bak") || die "unable to back up $fn: $!\n";
    }


    #  Save
    #
    my ($output_fh, $temporary_fn)=tempfile('.markpod-XXXXXX', DIR => dirname($fn), UNLINK => 1);
    binmode($output_fh);
    print {$output_fh} $ppi_doc_or->serialize() or die "unable to write $fn: $!\n";
    close($output_fh) || die "unable to close $fn: $!\n";
    chmod((stat($fn))[2] & 07777, $temporary_fn) || die "unable to preserve mode of $fn: $!\n";
    rename($temporary_fn, $fn) || die "unable to replace $fn: $!\n";
    return 1;


}


sub markpod_process_and_update {


    #  Process a file and save any resulting changes
    #
    my ($self, $fn)=@_;
    my $pod_changed=$self->markpod_process($fn);
    return undef unless defined $pod_changed;
    if ($pod_changed) {
        $self->markpod_inplace_update($fn) ||
            return err();
    }
    return $pod_changed;

}


sub markpod_markdown_source {


    #  Resolve markdown source for a file using sidecar-first precedence
    #
    my ($self, $fn)=@_;
    my $sidecar_md=$self->markpod_markdown_file_read($fn);
    return $sidecar_md if defined $sidecar_md;


    #  Fall back to embedded markdown in POD blocks
    #
    my $ppi_doc_or=PPI::Document->new($fn) ||
        return err ("unable to create new PPI instance on file $fn");
    my $pod_or_ar=$ppi_doc_or->find('PPI::Token::Pod') || return undef;
    my $md='';
    foreach my $pod_or (@{$pod_or_ar}) {
        my $pod_md=$self->markpod_markdown_extract($pod_or->content()) || next;
        $md.=$pod_md;
    }
    return length $md ? $md : undef;

}


sub markpod_markdown_extract {

    my ($self, $pod)=@_;
    my $md;
    if ($pod=~/^=begin markdown(?=\s*)(.*?)\n(.*?)\n*^=end markdown\s*$/gims || $pod=~/^=begin markdown(?=\s*)(.*?)\n(.*)\n*$/gims) {
        if (my $fn=$1) {
            $fn=~s/^\s*//;
            debug("suggested output filename: $fn");
            $self->{'opt'}{'outfile'} ||= $fn;
        }
        $md=$2;
    }
    else {
        return undef;
    }
    chomp($md);
    $md=$self->markpod_markdown_normalize($md);
    debug('extracted markdown: %d bytes', length($md));
    return $md;

}


sub markpod_markdown_normalize {

    my ($self, $md)=@_;
    $md=~s/\A(?:[ \t]*\r?\n)+//;
    $md=~s/^[ \t]+$//mg;
    return $md;

}


sub markpod_pod_merge {

    my ($self, $md, $fn)=@_;
    my ($conversion_md, $replacement_ar)=$self->markpod_markdown_prepare($md);
    my $md2pod_or=Markdown::Pod->new() ||
        return err ('unable to create new Markdown::Pod object');
    my $pod=$md2pod_or->markdown_to_pod(
        dialect  => $self->{'opt'}{'dialect'},
        markdown => $conversion_md
    );
    $pod=$self->markpod_pod_module_links($pod, $fn);
    foreach my $replacement_hr (@{$replacement_ar}) {
        my $placeholder=$replacement_hr->{'placeholder'};
        my $format=$replacement_hr->{'format'};
        my $text=$replacement_hr->{'text'};
        my $formatted=$self->markpod_pod_format($format, $text);
        $pod=~s/\Q${format}<${placeholder}>\E/$formatted/g;
    }
    my $encoding=$md=~/[^\x00-\x7f]/ ? "=encoding utf8\n\n" : '';
    $pod=~s/^[ \t]+$//mg;
    #  Make a note of raw POD for getter function
    $self->{'pod'}="${encoding}${pod}";
    debug('created pod: %d bytes', length($pod));
    $pod=$encoding.join(
        "\n",
        '=begin markdown',
        '',
        $md,
        '',
        '=end markdown',
        '',
        $pod
    );
    #  This is markdown merged with created POD
    return $pod;

}


sub markpod_pod_module_links {

    my ($self, $pod, $source_fn)=@_;
    return $pod unless defined($source_fn) && length($source_fn);


    #  Resolve links to companion module sidecars for the POD rendering. The
    #  retained Markdown continues to use its repository-relative filename.
    #
    $pod=~s{L<([^<>|\r\n]+)\|([^<>|\r\n]+\.pm\.md)>}{
        my ($label, $target)=($1, $2);
        my $package=$self->markpod_module_link_package($source_fn, $target);
        defined($package) ? "L<${label}|${package}>" : $&;
    }ge;
    return $pod;

}


sub markpod_module_link_package {

    my ($self, $source_fn, $target)=@_;
    return undef if File::Spec->file_name_is_absolute($target);

    my $sidecar_fn=File::Spec->rel2abs($target, dirname($source_fn));
    return undef unless -f $sidecar_fn;

    my $module_fn=$sidecar_fn;
    $module_fn=~s/\.md\z// || return undef;
    return undef unless -f $module_fn;

    my $ppi_doc_or=PPI::Document->new($module_fn) || return undef;
    my $package_or=$ppi_doc_or->find_first('PPI::Statement::Package') ||
        return undef;
    my $package=$package_or->namespace();
    return defined($package) && $package=~/\A[A-Za-z_]\w*(?:::\w+)*\z/
        ? $package
        : undef;

}


sub markpod_markdown_prepare {

    my ($self, $md)=@_;
    my @replacement;
    my $counter=0;

    #  A leading page title is useful in Markdown but would create an empty
    #  POD section immediately before the conventional NAME section.
    #
    $md=~s/\A[ \t]*\#[ \t]+[^\r\n]+?[ \t]*\#?[ \t]*\r?\n(?:[ \t]*\r?\n)+(?=[ \t]*\#[ \t]+NAME(?:[ \t]*\#)?[ \t]*(?:\r?\n|\z))//i;

    #  Protect constructs that Markdent's GitHub dialect emits as ambiguous
    #  POD. The placeholders contain no Markdown punctuation and are restored
    #  with delimiters appropriate for their original content.
    #
    $md=~s{(?<!`)`(https?://[^`\r\n]+)`(?!`)}{
        my $placeholder;
        do {
            $placeholder=sprintf('MARKPODTOKEN%06dX', ++$counter);
        } while (index($md, $placeholder)>=0);
        push(@replacement, {
            format      => 'C',
            placeholder => $placeholder,
            text        => $1
        });
        "`${placeholder}`";
    }ge;
    $md=~s{(?<!\S)\*\*([^*\r\n]*?>[^*\r\n]*)\*\*}{
        my $placeholder;
        do {
            $placeholder=sprintf('MARKPODTOKEN%06dX', ++$counter);
        } while (index($md, $placeholder)>=0);
        push(@replacement, {
            format      => 'B',
            placeholder => $placeholder,
            text        => $1
        });
        "**${placeholder}**";
    }ge;

    return ($md, \@replacement);

}


sub markpod_pod_format {

    my ($self, $format, $text)=@_;
    return "${format}<${text}>" unless $text=~/[<>]/;

    my $longest=0;
    while ($text=~/(<+|>+)/g) {
        my $length=length($1);
        $longest=$length if $length>$longest;
    }
    my $delimiter='<' x ($longest + 1);
    my $end_delimiter='>' x ($longest + 1);
    return "${format}${delimiter} ${text} ${end_delimiter}";

}


sub markpod_markdown_text {


    #  Convert Markdown to text
    #
    my ($self, $md, $fn)=@_;


    #  Need IPC::Run3
    #
    eval {
        require IPC::Run3;
        1;
    } || return err('unable to load IPC::Run3 module');


    #  Need pandoc for this bit
    #
    $PANDOC_EXE ||
        return err('pandoc is required for markdown to text conversion');

    #  Run the Pandoc conversion to markup
    #
    my $text;
    {   my $command_ar=
            $PANDOC_CMD_MD2TEXT_CR->($PANDOC_EXE, '-');

        #die Dumper($command_ar, \$md, ($fn || \$text), \undef);
        IPC::Run3::run3($command_ar, \$md, ($fn || \$text), \undef) ||
            return err('unable to run3 %s', Dumper($command_ar));
        if ((my $err=$?) >> 8) {
            return err("error $err on run3 of: %s", Dumper($command_ar));
        }
    }

    #  Done
    #
    return $text || '';

}


sub outfile {


    #  Save output to a file or send to STDOUT
    #
    my ($self, $output, $fn)=@_;


    #  Send to STDOUT or selected output file
    #
    return blurp($fn, $output) if $fn;
    print STDOUT $output;
    return 1;


}



#  Getters
#
sub markdown { $_[0]->{'markdown'} }
sub pod { $_[0]->{'pod'} }
sub ppi_doc_or { $_[0]->{'ppi_doc_or'} }

sub source { return shift()->markpod_markdown_source(@_) }
sub process { return shift()->markpod_process(@_) }
sub update { return shift()->markpod_process_and_update(@_) }

sub discover {
    my ($class, @input)=@_;
    my %found;
    foreach my $input (@input) {
        if (-f $input) {
            $found{$input}=1;
            next;
        }
        die "input does not exist: $input\n" unless -d $input;
        File::Find::find({no_chdir => 1, wanted => sub {
            my $fn=$File::Find::name;
            if (-d $fn && $fn=~m{(?:^|/)(?:\.git|\.venv|node_modules|blib|build|site|t)$}) {
                $File::Find::prune=1;
                return;
            }
            return unless -f $fn && !-l $fn;
            if ($fn=~/\.(?:pm|pl)$/) { $found{$fn}=1 }
            elsif ($fn=~/\.md$/) {
                (my $target_fn=$fn)=~s/\.md$//;
                $found{$target_fn}=1 if -f $target_fn && -x $target_fn && !-l $target_fn;
            }
        }}, $input);
    }
    return [sort keys %found];
}


1;
__END__

=begin markdown

# NAME

Markdown::Pod::Embed - maintain Perl documentation from Markdown

# SYNOPSIS

```perl
use Markdown::Pod::Embed;
my $processor_or=Markdown::Pod::Embed->new({nobackup => 1});
$processor_or->update('lib/Example.pm');
```

# DESCRIPTION

A nonempty `Example.pm.md` sidecar is the preferred documentation source. When
it is absent or empty, Markdown inside `=begin markdown` blocks is used instead.
Plain POD without a Markdown source is preserved. Generated documentation keeps
both the embedded Markdown and its POD rendering, so embedded-only authoring
continues to work.

Relative Markdown links to existing companion `*.pm.md` sidecars remain file
links in the retained Markdown. In the generated POD, their destinations become
the package declared by the companion `.pm` file, so module links work in both
renderings. Other relative links, unresolved targets, fragments, and external
URLs are preserved as written.

A leading Markdown page title immediately before `# NAME` is retained in the
Markdown but omitted from the POD rendering. UTF-8 documentation receives an
encoding declaration, and inline code and emphasis use safe POD delimiters when
their contents would otherwise conflict with POD syntax.

This library has no MakeMaker integration. Use ASPEER::MakeMaker::Markdown::Pod for
repository targets and maintenance.

# PUBLIC METHODS

`new(\%options)` constructs a processor. Options are `dialect` (default `GitHub`),
`nobackup` (suppress `.bak` copies), and `dry_run` (calculate without writing).

`source($filename)` returns the selected Markdown, or undef when none exists.

`process($filename)` prepares the transformed source in memory. It returns undef
for an undocumented file, zero when unchanged, or a positive value when changed.

`update($filename)` prepares and writes changed source. It has the same return
values as `process`; dry-run reports the intended result without writing.

`markdown()` and `pod()` return the most recently processed documentation.
`ppi_doc_or()` returns the prepared PPI document; `serialize()` on that object
returns the complete transformed source.

`discover(@files_or_directories)` is a class method returning a sorted array
reference of source paths. It finds `.pm`, `.pl`, and executable sidecar targets.
Normal recursive scans exclude `t`, `node_modules`, `.git`, `.venv`, `blib`,
`build`, and `site`. Explicit files may be supplied from those directories.

The existing `markpod_process`, `markpod_process_and_update`, and
`markpod_markdown_source` names remain aliases of the corresponding operations.
`markpod_inplace_update($filename)` saves the result of `process`.
`markpod_markdown_text($markdown)` renders plain text using Pandoc.

# ERRORS AND FILE SAFETY

Failures throw an exception. Updates preserve permissions and replace the file
only after writing the complete result. Symlinks are not replaced. Insertion
after a data section without existing POD is refused; move documentation ahead
of the data or supply an appropriate existing documentation block first.

# LICENSE

This software is copyright (c) 2026 by Andrew Speer. It may be distributed under
the same terms as Perl itself.

=end markdown


=head1 NAME

Markdown::Pod::Embed - maintain Perl documentation from Markdown


=head1 SYNOPSIS


 use Markdown::Pod::Embed;
 my $processor_or=Markdown::Pod::Embed->new({nobackup => 1});
 $processor_or->update('lib/Example.pm');

=head1 DESCRIPTION

A nonempty C<Example.pm.md> sidecar is the preferred documentation source. When
it is absent or empty, Markdown inside C<=begin markdown> blocks is used instead.
Plain POD without a Markdown source is preserved. Generated documentation keeps
both the embedded Markdown and its POD rendering, so embedded-only authoring
continues to work.

Relative Markdown links to existing companion C<*.pm.md> sidecars remain file
links in the retained Markdown. In the generated POD, their destinations become
the package declared by the companion C<.pm> file, so module links work in both
renderings. Other relative links, unresolved targets, fragments, and external
URLs are preserved as written.

A leading Markdown page title immediately before C<# NAME> is retained in the
Markdown but omitted from the POD rendering. UTF-8 documentation receives an
encoding declaration, and inline code and emphasis use safe POD delimiters when
their contents would otherwise conflict with POD syntax.

This library has no MakeMaker integration. Use ASPEER::MakeMaker::Markdown::Pod for
repository targets and maintenance.


=head1 PUBLIC METHODS

C<new(\%options)> constructs a processor. Options are C<dialect> (default C<GitHub>),
C<nobackup> (suppress C<.bak> copies), and C<dry_run> (calculate without writing).

C<source($filename)> returns the selected Markdown, or undef when none exists.

C<process($filename)> prepares the transformed source in memory. It returns undef
for an undocumented file, zero when unchanged, or a positive value when changed.

C<update($filename)> prepares and writes changed source. It has the same return
values as C<process>; dry-run reports the intended result without writing.

C<markdown()> and C<pod()> return the most recently processed documentation.
C<ppi_doc_or()> returns the prepared PPI document; C<serialize()> on that object
returns the complete transformed source.

C<discover(@files_or_directories)> is a class method returning a sorted array
reference of source paths. It finds C<.pm>, C<.pl>, and executable sidecar targets.
Normal recursive scans exclude C<t>, C<node_modules>, C<.git>, C<.venv>, C<blib>,
C<build>, and C<site>. Explicit files may be supplied from those directories.

The existing C<markpod_process>, C<markpod_process_and_update>, and
C<markpod_markdown_source> names remain aliases of the corresponding operations.
C<markpod_inplace_update($filename)> saves the result of C<process>.
C<markpod_markdown_text($markdown)> renders plain text using Pandoc.


=head1 ERRORS AND FILE SAFETY

Failures throw an exception. Updates preserve permissions and replace the file
only after writing the complete result. Symlinks are not replaced. Insertion
after a data section without existing POD is refused; move documentation ahead
of the data or supply an appropriate existing documentation block first.


=head1 LICENSE

This software is copyright (c) 2026 by Andrew Speer. It may be distributed under
the same terms as Perl itself.

=cut
