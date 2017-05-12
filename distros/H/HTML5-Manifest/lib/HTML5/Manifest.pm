package HTML5::Manifest;
use strict;
use warnings;
our $VERSION = '0.04';

use Digest::MD5;
use File::Spec;
use IO::Dir;

sub new {
    my($class, %args) = @_;
    bless {
        %args
    }, $class;
}

sub _recurse {
    my($self, $path, $cb) = @_;

    my $dir = IO::Dir->new($path) or die "Can't open directory $path: $!";
    my @list;
    while (defined(my $entry = $dir->read)) {
        next if $entry eq File::Spec->updir || $entry eq File::Spec->curdir;
        push @list, $entry;
    }
    for my $entry (sort @list) {
        my $new_path = File::Spec->catfile($path, $entry);
        my $is_dir = -d $new_path;
        $entry = "$entry/" if $is_dir;
        my $is_pass = $cb->($new_path, $entry, $is_dir);
        next unless $is_pass;
        if ($is_dir) {
            $self->_recurse($new_path, $cb);
        }
    }
}

sub generate {
    my $self = shift;

    my $manifest = "CACHE MANIFEST\n\n";
    if ($self->{network} && ref $self->{network} eq 'ARRAY') {
        $manifest .= "NETWORK:\n";
        for my $path (@{ $self->{network} }) {
            $manifest .= "$path\n";
        }
        $manifest .= "\n";
    }

    my $md5;
    $md5 = Digest::MD5->new if $self->{use_digest};

    my $htdocs = $self->{htdocs};
    $htdocs =~ s!\\!/!g if $^O eq 'MSWin32';
    $manifest .= "CACHE:\n";
    $self->_recurse($htdocs, sub {
        my($fullpath, $filename, $is_dir) = @_;
        my $manifest_path = $fullpath;
        $manifest_path =~ s!\\!/!g if $^O eq 'MSWin32';
        $manifest_path =~ s/^$htdocs//;

        for my $qr (@{ $self->{skip} || [] }) {
            return 0 if $filename =~ $qr;
        }
        return 1 if $is_dir;

        $manifest .= $manifest_path;
        if ($self->{use_digest}) {
            open my $fh, '<', $fullpath or die "Can't open file $fullpath: $!";
            $md5->addfile($fh);
        }
        $manifest .= "\n";
        return 1;
    });
    $manifest .= "\n# digest: " . $md5->b64digest . "\n" if $self->{use_digest};

    return $manifest;
}

1;
__END__

=head1 NAME

HTML5::Manifest - HTML5 application cache manifest file generator

=head1 SYNOPSIS

    use HTML5::Manifest;
    
    my $manifest = HTML5::Manifest->new(
        use_digest => 1,
        htdocs     => './htdocs/',
        skip       => [
            qr{^temporary/},
            qr{\.svn/},
            qr{\.swp$},
            qr{\.txt$},
            qr{\.html$},
            qr{\.cgi$},
        ],
        network => [
            '/api',
            '/foo/bar.cgi',
        ],
    );
    
    # show html5.manifest content
    say $manifest->generate;

=head1 DESCRIPTION

HTML5::Manifest is generate manifest contents of application cache in HTML5 Web application API.

=head1 METHOD

=head2 new(%args)

create HTML5::Manifest instance.

I<%args> are:

=over

=item C<< htdocs => $htdocs_path >>

root directory of a file included to manifest is specified.

=item C<< skip => \@skip_pattern_list >>

The file pattern excepted from C<$args{htdocs}> is described. It is the same work as C<MANIFEST.SKIP>.

=item C<< network => \@network_list >>

NETWORK: URL specified as section is specified in manifest file.

=item C<< use_digest => $boolean >>

md5 checksum is created from all the contents of the file included in cache, and it writes in manifest file.
This is useful to updating detection of manifest file.

=back

=head2 generate()

generate to html5 application cache manifest file.

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo {at} shibuya {dot} plE<gt>

=head1 SEE ALSO

L<http://www.w3.org/TR/html5/offline.html>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
