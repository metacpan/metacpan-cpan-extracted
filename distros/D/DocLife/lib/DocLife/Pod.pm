package DocLife::Pod;

use strict;
use warnings;
use parent 'DocLife';
use Pod::Simple::XHTML;

sub format {
    my ($self, $req, $res, $file) = @_;
    
    my $body = $file->slurp;
    if ($req->param('source')) {
        $res->content_type('text/plain');
        $res->body($body);
        return;
    }
    
    my $home = $self->base_url;
    my ($title) = $body=~m|^package (.*);|;
    $title ||= $file->basename;
    my $src = qq{<p class="home"><a href="$home">Home</a></p><a href="?source=1">Source</a>};
    my $pod = Pod::Simple::XHTML->new;
    $pod->html_header($self->html_header($title) . $src);
    $pod->index(1);
    $pod->output_string(\my $html);
    $pod->parse_string_document($body);
    $res->body($html);
}

sub html_header {
my ($self, $title) = @_;
$title = 'Index' unless defined $title;
<<"EOF"
<!DOCTYPE html>
<html>
<head>
<title>$title</title>
<style>
body {
    font-family: arial,sans-serif;
    margin: 0;
    padding: 1ex;
}
a:link, a:visited {
    color: #069;
}
li {
    line-height: 1.2em;
    list-style-type: none;
}
h1 {
    color: #006699;
    font-size: large;
}
h2 {
    color: #006699;
    font-size: medium;
}
h3 {
    color: #006699;
    font-size: medium;
    font-style: italic;
}
h4 {
    color: #006699;
    font-size: medium;
    font-weight: normal;
}
pre {
    background: #eeeeee;
    border: 1px solid #888888;
    color: black;
    padding: 1em;
    white-space: pre;
}
.home {
    margin: 0;
    padding: 0;
    text-align: center;
}
</style>
</head>
<body>
EOF
}

=head1 NAME

DocLife::Pod - Pod Viewer.

=head1 SYNOPSIS

    # app.psgi
    use DocLife::Pod;
    DocLife::Pod->new( root => "./lib" );

    # one-liner
    plackup -MDocLife::Pod -e 'DocLife::Pod->new( root => "./lib" )->to_app'

=head1 SEE ALSO

L<DocLife>, L<Pod::Simple::XHTML>

=cut

1;
