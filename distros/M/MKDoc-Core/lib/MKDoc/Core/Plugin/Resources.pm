=head1 NAME

MKDoc::Core::Plugin::Resources - Serves Resource Files.


=head1 SUMMARY

L<MKDoc::Core> has a mechanism to provide resource files (such as style sheet, images, etc)
which supports some inheritance mechanism.

When a request is made to /.resources/foo.png, it will try to serve:

=over 4

=item $ENV{SITE_DIR}/resources/foo.png

=item $ENV{MKDOC_DIR}/resources/foo.png

=item @INC/MKDoc/resources/foo.png

=back

Furthermore, if at any point it finds /resources/foo.png.deleted, it will
decline the request, which usually results in a 404 page.

=cut
package MKDoc::Core::Plugin::Resources;
use MKDoc::Core::ResourceFinder;
use base qw /MKDoc::Core::Plugin/;
use strict;
use warnings;
use HTTP::Date;


sub activate
{
    my $self = shift;
    my $req  = $self->request();
    my $path = $req->path_info();
    $path =~ s/^\/\.resources\/// or return;

    my $file = MKDoc::Core::ResourceFinder::rel2abs ($path) || return;
    $self->{'.file'} = $file;

    open FP, "<$file" or do {
        warn "Cannot read $file. Reason: $!";
        return;
    };
    $self->{'.data'} = join '', <FP>;
    close FP;

    return $self->SUPER::activate (@_);
}


sub render
{
    my $self = shift;
    return $self->{'.data'};
}


sub HTTP_Last_Modified
{
    my $self = shift;
    my $file = $self->{'.file'};
    my ( $dev, $ino, $mode, $nlink, $uid,
         $gid, $rdev, $size, $atime, $mtime,
         $ctime,$blksize,$blocks ) = stat ($file);

    return HTTP::Date::time2str ($mtime);
}


sub HTTP_Content_Type
{
    my $self = shift;
    my $file = $self->{'.file'};

    # if there is no mime types resource file, try
    # and return a generic default.
    my $mime = MKDoc::Core::ResourceFinder::rel2abs ('/misc/mime.types') || return 'application/octet-stream';
   
    # if we can't open the file, moan in the error log
    # and return a generic default. 
    open FP, "<$mime" || do {
        warn "Cannot read-open $mime";
        return 'application/octet-stream';
    };

    # build a file extension => mime type hash
    my %hash = ();
    while (my $line = <FP>)
    {
       chomp ($line);
       $line =~ s/^\s+//;
       $line =~ /^\#/ and next;

       my @split = split /\s+/, $line;
       @split <= 1 and next;
       
       my $mime = shift (@split);
       for (@split) { $hash{$_} = $mime }
    }
    close FP;

    # match the current file against file extensions, but
    # longest file extension first (i.e. .tar.gz != .gz). If a
    # match is found, return the matching mime type.
    foreach my $key (sort { length ($b) <=> length ($a) } keys %hash)
    {
        $file =~ /\.$key$/ and return $hash{$key};
    }

    # no match is found, return generic default.
    return 'application/octet-stream';
}
1;


__END__
