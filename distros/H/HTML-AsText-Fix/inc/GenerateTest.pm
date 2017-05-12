package inc::GenerateTest;
use lib qw(lib);
use strict;
use warnings 'all';

use Cwd;
use HTML::AsText::Fix;
use Regexp::Common qw(comment);

use Moose;
with 'Dist::Zilla::Role::AfterBuild';

use constant HTML => getcwd . '/t/test.html';
use constant TEXT => getcwd . '/t/test.txt';

sub after_build {
    my ($self) = @_;

    $self->log('Generating test HTML...');

    my $pod = new Pod::Simple::HTML;
    my $html = '';
    $pod->index(1);
    $pod->output_string(\$html);
    $pod->parse_file(getcwd . '/README.pod');

    $html =~ s/$RE{comment}{HTML}\s*//gos;

    open(my $fh, '>:encoding(latin1)', HTML);
    print $fh $html;
    close $fh;

    $self->log('Generating test plaintext...');

    my $tree = HTML::Tree->new_from_file(HTML);
    my $guard = HTML::AsText::Fix::object(
        $tree,
        lf_char     => "\x{0a}",
        zwsp_char   => "\x{0a}",
    );

    open($fh, '>:encoding(UTF-8)', TEXT);
    print $fh $tree->as_text;
    close $fh;

    $self->log('OK!');
}

1;
