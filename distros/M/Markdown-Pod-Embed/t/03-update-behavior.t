#!perl

use strict;
use warnings;
use lib 'lib';

use File::Temp qw(tempdir);
use Test::More;

use Markdown::Pod::Embed;

sub slurp {
    my ($fn)=@_;
    open my $fh, '<', $fn or die "open $fn: $!";
    local $/=undef;
    return scalar <$fh>;
}

sub spew {
    my ($fn, $content)=@_;
    open my $fh, '>', $fn or die "open $fn: $!";
    print {$fh} $content;
    close $fh or die "close $fn: $!";
}

{
    my $dir=tempdir(CLEANUP => 1);
    my $fn="${dir}/backup.pm";
    my $orig=<<'PM';
package Sample::Backup;
1;
__END__

=begin markdown

# NAME

Sample::Backup - original markdown

=end markdown
=cut
PM
    spew($fn, $orig);

    my $changed=Markdown::Pod::Embed->new->markpod_process_and_update($fn);
    ok($changed > 0, 'default update changes markdown-backed POD');
    ok(-f "${fn}.bak", 'default update creates backup file');
    is(slurp("${fn}.bak"), $orig, 'backup file preserves original content');
}

{
    my $dir=tempdir(CLEANUP => 1);
    my $fn="${dir}/multi-markdown.pm";
    spew($fn, <<'PM');
package Sample::MultiMarkdown;
1;
__END__

=begin markdown

# NAME

Sample::MultiMarkdown - first markdown block

=end markdown
=cut

=begin markdown

# DESCRIPTION

Second markdown block

=end markdown
=cut
PM

    my $markpod_or=Markdown::Pod::Embed->new({nobackup => 1});
    my $changed=$markpod_or->markpod_process($fn);
    ok($changed > 0, 'multiple markdown-backed POD sections report changes');
    like($markpod_or->markdown, qr/first markdown block.*Second markdown block/s, 'markdown getter contains both sources in order');

    $markpod_or->markpod_inplace_update($fn);
    my $updated=slurp($fn);
    like($updated, qr/^=head1 NAME\b/m, 'first generated heading is present');
    like($updated, qr/^=head1 DESCRIPTION\b/m, 'second generated heading is present');
}

{
    my $dir=tempdir(CLEANUP => 1);
    my $fn="${dir}/end-no-newline.pm";
    spew($fn, "package Sample::EndNoNewline;\n1;\n__END__");
    spew("${fn}.md", <<'MD');
# NAME

Sample::EndNoNewline - sidecar markdown
MD

    my $markpod_or=Markdown::Pod::Embed->new({nobackup => 1});
    my $changed=$markpod_or->markpod_process($fn);
    is($changed, 1, 'sidecar creates POD after existing __END__ without trailing newline');
    $markpod_or->markpod_inplace_update($fn);
    like(slurp($fn), qr/__END__\n\n=begin markdown\n\n# NAME/, 'existing __END__ without trailing newline gets normalized spacing');
}

{
    my $dir=tempdir(CLEANUP => 1);
    my $fn="${dir}/end-extra-blank.pm";
    spew($fn, <<'PM');
package Sample::EndExtraBlank;
1;
__END__



=begin markdown

# NAME

Sample::EndExtraBlank - embedded markdown

=end markdown
=cut
PM

    my $markpod_or=Markdown::Pod::Embed->new({nobackup => 1});
    my $changed=$markpod_or->markpod_process($fn);
    ok($changed > 0, 'existing markdown block with extra leading blanks reports changes');
    $markpod_or->markpod_inplace_update($fn);
    like(slurp($fn), qr/__END__\n\n=begin markdown\n\n# NAME/, 'extra blank lines after __END__ are collapsed');
}

{
    my $dir=tempdir(CLEANUP => 1);
    my $fn="${dir}/end-extra-blank-only.pm";
    spew($fn, <<'PM');
package Sample::EndExtraBlankOnly;
1;
__END__



=begin markdown

# NAME

Sample::EndExtraBlankOnly - embedded markdown

=end markdown


=head1 NAME

Sample::EndExtraBlankOnly - embedded markdown

=cut
PM

    my $changed=Markdown::Pod::Embed->new({nobackup => 1})->markpod_process_and_update($fn);
    ok($changed > 0, 'whitespace-only cleanup after __END__ reports a change');
    like(slurp($fn), qr/__END__\n\n=begin markdown\n\n# NAME/, 'whitespace-only cleanup after __END__ is saved');
}

{
    my $dir=tempdir(CLEANUP => 1);
    my $fn="${dir}/end-extra-blank-sidecar.pm";
    spew($fn, <<'PM');
package Sample::EndExtraBlankSidecar;
1;
__END__



=begin markdown

# NAME

Sample::EndExtraBlankSidecar - embedded markdown

=end markdown
=cut
PM
    spew("${fn}.md", <<'MD');
# NAME

Sample::EndExtraBlankSidecar - sidecar markdown
MD

    my $changed=Markdown::Pod::Embed->new({nobackup => 1})->markpod_process_and_update($fn);
    ok($changed > 0, 'sidecar update with extra blanks after __END__ reports a change');
    my $updated=slurp($fn);
    like($updated, qr/__END__\n\n=begin markdown\n\n# NAME/, 'sidecar update collapses blank lines after __END__');
    like($updated, qr/sidecar markdown/, 'sidecar content is embedded');
    unlike($updated, qr/embedded markdown/, 'old embedded markdown is replaced');
}

done_testing;
