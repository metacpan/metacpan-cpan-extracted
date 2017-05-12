package DocLife;

use strict;
use warnings;
our $VERSION = '0.03';

use parent qw( Plack::Component );
use Cwd 'abs_path';
use Digest::MD5;
use File::Find;
use File::Spec;
use URI::Escape;
use Path::Class;
use Plack::Request;
use Plack::Util::Accessor qw(
    base_url
    root
    suffix
);

sub prepare_app {
    my ($self, $env) = @_;
    $self->base_url('/') unless defined $self->base_url;
    $self->root(dir(abs_path($self->root || './')));
}

sub call {
    my ($self, $env) = @_;

    my $req = Plack::Request->new($env);
    my $res = $req->new_response(200);
    $res->content_type('text/html; charset=UTF-8');

    if ($req->path eq '/') {
        $self->toppage($req, $res);
    }
    elsif ($req->path=~m|\Q/../| or $req->path=~m|\Q//|) {
        $self->forbidden($req, $res);
    }
    else {
        $self->page($req, $res);
    }
    $res->finalize;
}

sub format {
    my ($self, $req, $res, $file) = @_;
    $res->content_type('text/plain; charset=UTF-8');
    $res->body($file->slurp);
}

sub page {
    my ($self, $req, $res) = @_;

    my $file = file($self->root, $req->path);
    $file = file($self->root, $req->path . $self->suffix) if !-f $file and defined $self->suffix;
    if (-f $file) {
        $self->format($req, $res, $file);
    }
    else {
        $self->not_found($req, $res);
    }
}

sub toppage {
    my ($self, $req, $res) = @_;

    my $body = $self->html_header;
    my $suffix = $self->suffix;
    my $root = $self->root;
    my @files;
    find( sub {
        return unless -f $_;
        return if length $suffix and $_!~m|\Q$suffix\E$|;
        push @files, $File::Find::name;
    }, $root );
    $body.= "<ul>\n";
    for my $file ( sort @files ) {
        $file=~s|^\Q$root\E/?||;
        my $url = $self->base_url . uri_escape($file);
        if (length $suffix) {
            $file=~s|\Q$suffix\E$||;
        }
        $body.= qq{<li><a href="$url">$file</a></li>\n};
    }
    $body.= "</ul>\n";
    $body.= $self->html_footer;
    $res->body($body);
}

sub forbidden {
    my ($self, $req, $res) = @_;
    $res->status(403);
    $res->body('Forbidden.');
}

sub not_found {
    my ($self, $req, $res) = @_;
    $res->status(404);
    $res->body('Not Found.');
}

sub html_header {
<<"EOF"
<!DOCTYPE html>
<html>
<head>
<title>Index</title>
</head>
<body>
EOF
}

sub html_footer {
<<"EOF"
</body>
</html>
EOF
}

=head1 NAME

DocLife - Document Viewer written in Perl, to run under Plack.

=head1 SYNOPSIS

    # app.psgi
    use DocLife::Pod;
    DocLife::Pod->new( root => "./lib" );

    # one-liner
    plackup -MDocLife::Pod -e 'DocLife::Pod->new( root => "./lib" )->to_app'

=head1 How To Mount

need base_url option.

    # app.psgi
    use Plack::Builder;
    use DocLife::Pod;
    use DocLife::Markdown;

    my $pod_app = DocLife::Pod->new(
        root => '../lib',
        base_url => '/pod/'
    );

    my $doc_app = DocLife::Markdown->new(
        root => './doc',
        suffix => '.md',
        base_url => '/doc/'
    );

    builder {
        mount '/pod' => $pod_app;
        mount '/doc' => $doc_app;
    };

=head1 CONFIGURATION

=over 4

=item root

Document root directory. Defaults to the current directory.

=back

=over 4

=item base_url

Specifies a base URL for all URLs on a index page. Defaults to the `/`.

=back

=over 4

=item suffix

Show only files that match the suffix. No url suffix.

=back

=head1 SEE ALSO

L<Plack>

=head1 COPYRIGHT

Copyright 2013 Shinichiro Aska

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
