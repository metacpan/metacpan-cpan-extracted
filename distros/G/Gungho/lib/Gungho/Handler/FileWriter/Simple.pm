# $Id: /mirror/gungho/lib/Gungho/Handler/FileWriter/Simple.pm 1749 2007-06-10T08:52:31.230704Z lestrrat  $
#
# Copyrigt (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Handler::FileWriter::Simple;
use strict;
use warnings;
use base qw(Gungho::Handler);
use File::Spec;
use Path::Class();
use URI::Escape qw(uri_escape);

__PACKAGE__->mk_accessors($_) for qw(dir);

sub setup
{
    my ($self, $c) = @_;

    $self->dir(
        Path::Class::Dir->new( $self->config->{dir} || File::Spec->tmpdir)
    );
    $self->next::method($c);
}

sub path_to
{
    my ($self, $req, $res) = @_;

    # Just writes to a file name that has been "properly" (for better
    # or for worse...) URl-encoded

    return $self->dir->file( uri_escape( $req->uri ) );
}

sub handle_response
{
    my ($self, $c, $req, $res) = @_;

    my $file = $self->path_to($req, $res);
    my $fh   = $file->openw() or die;

    $c->log->debug("Writing " . $req->uri . " to $file");

    $fh->print($res->content);
    $fh->close;
}

1;

__END__

=head1 NAME

Gungho::Handler::FileWriter::Simple - Write Out Fetched Contents To File

=head1 DESCRIPTION

This is a simple, dumb module mostly for demonstration purposes. It just
writes out fetched contents to a single location in your file system.

In real life, you probably want to hash them to different locations, and
put better names to the files.

=head1 METHODS

=head2 setup

=head2 path_to

=head2 handle_response

=cut
