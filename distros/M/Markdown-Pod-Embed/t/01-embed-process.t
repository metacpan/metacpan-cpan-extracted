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
    my $fn="${dir}/plain.pm";
    my $orig=<<'PLAIN';
package Sample::Plain;
1;
__END__

=head1 NAME

Sample::Plain - plain pod only

=cut
PLAIN
    spew($fn, $orig);
    my $markpod_or=Markdown::Pod::Embed->new({nobackup => 1});
    my $changed=$markpod_or->markpod_process($fn);
    is($changed, 0, 'plain POD without markdown reports no changes');
    $markpod_or->markpod_inplace_update($fn);
    is(slurp($fn), $orig, 'plain POD without markdown is preserved');
}

{
    my $dir=tempdir(CLEANUP => 1);
    my $fn="${dir}/embedded.pm";
    spew($fn, <<'EMBEDDED');
package Sample::Embedded;
1;
__END__

=begin markdown

# NAME

Sample::Embedded - embedded markdown

=end markdown
=cut
EMBEDDED
    my $markpod_or=Markdown::Pod::Embed->new({nobackup => 1});
    my $changed=$markpod_or->markpod_process($fn);
    ok($changed > 0, 'embedded markdown reports changes');
    $markpod_or->markpod_inplace_update($fn);
    my $updated=slurp($fn);
    like($updated, qr/^=begin markdown\b/m, 'embedded markdown block retained');
    like($updated, qr/^=head1 NAME\b/m, 'generated POD added for embedded markdown');
}

{
    my $dir=tempdir(CLEANUP => 1);
    my $fn="${dir}/sidecar.pm";
    spew($fn, <<'SIDECAR_PM');
package Sample::Sidecar;
1;
__END__

=head1 NAME

Sample::Sidecar - stale pod

=cut
SIDECAR_PM
    spew("${fn}.md", <<'SIDECAR_MD');
# NAME

Sample::Sidecar - sidecar markdown
SIDECAR_MD
    my $markpod_or=Markdown::Pod::Embed->new({nobackup => 1});
    my $changed=$markpod_or->markpod_process($fn);
    ok($changed > 0, 'sidecar markdown reports changes');
    $markpod_or->markpod_inplace_update($fn);
    my $updated=slurp($fn);
    like($updated, qr/^=begin markdown\b/m, 'sidecar markdown inserted into POD');
    like($updated, qr/Sample::Sidecar - sidecar markdown/, 'sidecar markdown content applied');
}

{
    my $dir=tempdir(CLEANUP => 1);
    my $fn="${dir}/no-pod.pm";
    spew($fn, <<'NO_POD_PM');
package Sample::NoPod;
1;
NO_POD_PM
    spew("${fn}.md", <<'NO_POD_MD');
# NAME

Sample::NoPod - sidecar markdown
NO_POD_MD
    my $markpod_or=Markdown::Pod::Embed->new({nobackup => 1});
    my $changed=$markpod_or->markpod_process($fn);
    is($changed, 1, 'sidecar markdown creates a new POD section');
    $markpod_or->markpod_inplace_update($fn);
    my $updated=slurp($fn);
    like($updated, qr/^__END__$/m, 'new POD section adds __END__ marker');
    like($updated, qr/__END__\n\n=begin markdown\n\n# NAME/, 'new POD section has normalized markdown spacing');
    like($updated, qr/^=begin markdown\b/m, 'sidecar markdown block embedded into file');
    like($updated, qr/^=head1 NAME\b/m, 'generated POD added for new section');
}

{
    my $dir=tempdir(CLEANUP => 1);
    my $fn="${dir}/sidecar-over-embedded.pm";
    spew($fn, <<'SIDE_EMBED_PM');
package Sample::SidecarOverEmbedded;
1;
__END__

=begin markdown

# NAME

Sample::SidecarOverEmbedded - embedded markdown

=end markdown
=cut
SIDE_EMBED_PM
    spew("${fn}.md", <<'SIDE_EMBED_MD');
# NAME

Sample::SidecarOverEmbedded - sidecar markdown
SIDE_EMBED_MD
    my $markpod_or=Markdown::Pod::Embed->new({nobackup => 1});
    my $changed=$markpod_or->markpod_process($fn);
    ok($changed > 0, 'sidecar overrides embedded markdown');
    $markpod_or->markpod_inplace_update($fn);
    my $updated=slurp($fn);
    like($updated, qr/Sample::SidecarOverEmbedded - sidecar markdown/, 'sidecar markdown content embedded');
    unlike($updated, qr/Sample::SidecarOverEmbedded - embedded markdown/, 'embedded markdown content replaced');
}

{
    my $dir=tempdir(CLEANUP => 1);
    my $fn="${dir}/multi.pm";
    my $orig=<<'MULTI';
package Sample::Multi;
1;
__END__

=head1 NAME

Sample::Multi - plain section

=cut

=begin markdown

# DESCRIPTION

Converted section

=end markdown
=cut
MULTI
    spew($fn, $orig);
    my $markpod_or=Markdown::Pod::Embed->new({nobackup => 1});
    my $changed=$markpod_or->markpod_process($fn);
    ok($changed > 0, 'mixed POD reports changes');
    $markpod_or->markpod_inplace_update($fn);
    my $updated=slurp($fn);
    like($updated, qr/Sample::Multi - plain section/, 'plain POD block preserved');
    like($updated, qr/^=head1 DESCRIPTION\b/m, 'markdown-backed POD block regenerated');
}

done_testing;
