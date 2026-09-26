#!perl

use strict;
use warnings;
use lib 'lib';

use File::Temp qw(tempdir);
use Test::More;

use Markdown::Pod::Embed;

sub spew {
    my ($fn, $content)=@_;
    open my $fh, '>', $fn or die "open $fn: $!";
    print {$fh} $content;
    close $fh or die "close $fn: $!";
}

{
    my $dir=tempdir(CLEANUP => 1);
    my $fn="${dir}/sidecar-wins.pm";
    spew($fn, <<'PM');
package Sample::SidecarWins;
1;
__END__

=begin markdown

# NAME

Sample::SidecarWins - embedded markdown

=end markdown
=cut
PM
    spew("${fn}.md", <<'MD');
# NAME

Sample::SidecarWins - sidecar markdown
MD

    my $md=Markdown::Pod::Embed->new->markpod_markdown_source($fn);
    like($md, qr/sidecar markdown/, 'sidecar markdown wins over embedded markdown');
    unlike($md, qr/embedded markdown/, 'embedded markdown is ignored when sidecar exists');
}

{
    my $dir=tempdir(CLEANUP => 1);
    my $fn="${dir}/embedded-only.pm";
    spew($fn, <<'PM');
package Sample::EmbeddedOnly;
1;
__END__

=begin markdown

# NAME

Sample::EmbeddedOnly - embedded markdown

=end markdown
=cut
PM

    my $md=Markdown::Pod::Embed->new->markpod_markdown_source($fn);
    like($md, qr/embedded markdown/, 'embedded markdown is used when no sidecar exists');
}

{
    my $dir=tempdir(CLEANUP => 1);
    my $fn="${dir}/plain.pm";
    spew($fn, <<'PM');
package Sample::Plain;
1;
__END__

=head1 NAME

Sample::Plain - plain POD

=cut
PM

    my $md=Markdown::Pod::Embed->new->markpod_markdown_source($fn);
    is($md, undef, 'no markdown source returns undef');
}

done_testing;
