package MToken::Server::Alpha;
use utf8;

=encoding utf-8

=head1 NAME

MToken::Server::Alpha - The first (alpha) mojolicious controller

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use MToken::Server::Alpha;

=head1 DESCRIPTION

The first (alpha) mojolicious controller

=over 8

=item B<delete_tarball>

Performs removing tarballs

=item B<download_tarball>

Performs downloading tarballs

=item B<env>

Show environments values

=item B<info>

Show general information

=item B<list>

Get list of files or list of tarball on storage

=item B<root>

The root controller

=item B<upload_tarball>

Performs uploading tarballs

=back

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Mojolicious>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2021 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION /;
$VERSION = "1.00";

use Mojo::Base 'Mojolicious::Controller';

use Mojo::File qw/path/;
use Mojo::Asset::File;

use File::Find;

use CTK::Util qw/sharedir sharedstatedir trim dformat dtf ls/;
use CTK::ConfGenUtil;

use MToken::Const;
use MToken::Util qw/filesize md5sum/;

use constant {
        CONTENT_TYPE_JSON   => "application/json",
        CONTENT_TYPE_TXT    => "text/plain; charset=utf-8",
        ROW_NUM             => 500,
    };

sub root {
    my $self = shift;
    return $self->reply->static('index.html');
}
sub env {
    my $self = shift;
    $self->res->headers->content_type(CONTENT_TYPE_TXT);
    return $self->render(text => $self->dumper(\%ENV));
}
sub info {
    my $self = shift; # Mojolicious::Routes
    my $ctk = $self->app->ctk();

    # Logging
    #$self->app->log->debug("Catched! Debug log mark");
    $self->app->log->info("Catched! Info log mark") if $ctk->verbosemode();

    $self->res->headers->content_type(CONTENT_TYPE_JSON);
    return $self->render(json => {
            generated => dtf(DATETIME_GMT_FORMAT, time(), 1),
            message => "Ok",
            $ctk->debugmode() || $ctk->verbosemode() ? (
                mode => $ctk->debugmode()
                    ? "debug mode"
                    : $ctk->verbosemode()
                        ? "verbose mode"
                        : "Oops!",
                datadir => $ctk->datadir,
                homedir => $self->app->home(),
                documentroot => $self->app->documentroot,
                tempdir => $ctk->tempdir,
                logdir => $ctk->logdir,
                logfile => $ctk->logfile,
                paths => $self->app->static->paths(),
            ) : (),
            tokens => [grep {($_ =~ TOKEN_PATTERN) && -d path($ctk->datadir, $_)->to_string} ls($ctk->datadir)],
        });
}
sub list {
    my $self = shift;
    my $ctk = $self->app->ctk();
    my $token = $self->param("token");
    my $path = path($ctk->datadir, $token);
    my $dir = $path->to_string;

    # Check token
    return $self->render(json => {
            message => "Token not found",
        }, status => 404) unless -d $dir;

    $self->res->headers->content_type(CONTENT_TYPE_JSON);
    return $self->render(json => {
            generated => dtf(DATETIME_GMT_FORMAT, time(), 1),
            message => "Ok",
            token => $token,
            files => [_get_file_list($dir)],
        });
}
sub download_tarball {
    my $self = shift;
    my $ctk = $self->app->ctk();
    my $token = $self->param("token");
    my $tarball = $self->param("tarball");
    my $path = path($ctk->datadir, $token, $tarball);
    my $file = $path->to_string;

    # Check tarball
    return $self->render(json => {
            message => "Tarball not found",
        }, status => 404) unless -f $file;

    return $self->reply->static(path($token, $tarball)->to_string);
}
sub upload_tarball {
    my $self = shift;
    my $ctk = $self->app->ctk();
    my $token = $self->param("token");
    my $tarball = $self->param("tarball");
    my $path_dir = path($ctk->datadir, $token)->make_path;
    my $path = path($ctk->datadir, $token, $tarball);
    my $file = $path->to_string;

    # Upload file @tarball@
    my $fileuploaded = $self->req->upload('tarball');
    if ($fileuploaded) {
        my $size = $fileuploaded->size;
        my $name = $fileuploaded->filename;
        $fileuploaded->move_to($file);

        # Check file
        unless (-e $file) {
            return $self->render(json => {
                message => "Can't upload file \"$file\"",
            }, status => 500);
        }

        # Check name
        unless ($name eq $tarball) {
            $path->remove;
            return $self->render(json => {
                message => "File name mismatch: expected=\"$tarball\"; got=\"$name\"",
            }, status => 400);
        }

        # Check size
        if ($self->param("size") && $self->param("size") != $size) {
            $path->remove;
            return $self->render(json => {
                message => "File size mismatch",
            }, status => 400);
        }

        # Check md5sum
        if ($self->param("md5") && $self->param("md5") ne md5sum($file)) {
            $path->remove;
            return $self->render(json => {
                message => "File md5 checksum mismatch",
            }, status => 400);
        }
    }

    $self->res->headers->content_type(CONTENT_TYPE_JSON);
    return $self->render(json => {
            message => "Ok",
            token => $token,
            tarball => $tarball,
            size => $self->param("size"),
            md5 => $self->param("md5"),
            #raw => $self->req->body // '',
            #files => [@files],
            #headers => MToken::Util::explain($self->req->headers),
        });
}
sub delete_tarball {
    my $self = shift;
    my $ctk = $self->app->ctk();
    my $token = $self->param("token");
    my $tarball = $self->param("tarball");
    my $path = path($ctk->datadir, $token, $tarball);
    my $file = $path->to_string;

    # Check tarball
    return $self->render(json => {
            message => "Tarball not found",
        }, status => 404) unless -f $file;

    # Delete file
    $path->remove;

    $self->res->headers->content_type(CONTENT_TYPE_JSON);
    return $self->render(json => {
            message => "Ok",
            token => $token,
            tarball => $tarball,
        });
}

sub _get_file_list {
    my $dir = shift || '.';
    my @files;
    find({
      no_chdir => 1,
      wanted => sub {
        my $file = $_;
        my $path = path($file);
        my $filename = $path->basename;
        return unless ((-f $file) && $filename =~ TARBALL_PATTERN);
        push @files, {
                #file        => $file,
                filename    => $filename,
                size        => $path->stat->size,
                #md5         => md5sum($file),
                mtime       => $path->stat->mtime,
            };
    }}, $dir);
    return @files;
}

1;

__END__
