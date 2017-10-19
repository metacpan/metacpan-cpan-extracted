use strict;
use warnings;

package Footprintless::Extract;
$Footprintless::Extract::VERSION = '1.26';
# ABSTRACT: Extracts data from archives
# PODNAME: Footprintless::Extract
#
use Carp;
use Cwd;
use File::Path qw(make_path);
use File::Spec;
use Log::Any;

my $logger = Log::Any->get_logger();

sub new {
    return bless( {}, shift )->_init(@_);
}

sub extract {
    my ( $self, %options ) = @_;
    my $to = $options{to} || getcwd();

    my $current_dir = getcwd();
    eval {
        croak("$to is not a directory") if ( -e $to && !-d $to );
        make_path($to);
        chdir($to);

        if ( $self->{type} eq 'zip' ) {
            _unzip( $self->{archive}, $to );
        }
        if ( $self->{type} eq 'tar' ) {
            _untar( $self->{archive}, $to );
        }
    };
    my $error = $@;
    chdir($current_dir);
    die($error) if ($error);

    return 1;
}

sub _init {
    my ( $self, %options ) = @_;

    croak('archive required') unless ( $options{archive} );
    $self->{archive} = $options{archive};

    my $dot_extension = $options{type} ? ".$options{type}" : $self->{archive};
    if ( $dot_extension =~ /\.zip|\.war|\.jar|\.ear|\.twbx$/ ) {
        $self->{type} = 'zip';
    }
    elsif ( $dot_extension =~ /\.tar|\.tar\.gz|\.tgz$/ ) {
        $self->{type} = 'tar';
    }
    else {
        croak("unknown archive type");
    }

    return $self;
}

sub _untar {
    my ( $archive, $to ) = @_;
    $logger->tracef( 'untar [%s] to [%s]', $archive, $to );
    require Archive::Tar;
    Archive::Tar->new($archive)->extract();
}

sub _unzip {
    my ( $archive, $to ) = @_;
    $logger->tracef( 'unzip [%s] to [%s]', $archive, $to );
    require IO::Uncompress::Unzip;

    my $unzip = IO::Uncompress::Unzip->new($archive)
        || croak("unable to open $archive: $IO::Uncompress::Unzip::UnzipError");

    my $status;
    eval {
        for ( $status = 1; $status > 0; $status = $unzip->nextStream() ) {
            my $header = $unzip->getHeaderInfo();
            my ( undef, $path, $name ) = File::Spec->splitpath( $header->{Name} );
            my $dest_dir = File::Spec->catdir( $to, $path );

            unless ( -d $dest_dir ) {
                make_path($dest_dir) || croak("unable to create dir $dest_dir: $!");
            }

            unless ($name) {
                last if ( $status < 0 );
                next;
            }

            my $dest_file = File::Spec->catfile( $dest_dir, $name );
            my $buffer;
            my $file = IO::File->new( $dest_file, "w" )
                || croak("unable to create file $dest_file: $!");
            while ( ( $status = $unzip->read($buffer) ) > 0 ) {
                $file->write($buffer);
            }
            $file->close();
            my $stored_time = $header->{Time};
            utime( $stored_time, $stored_time, $dest_file )
                || croak("couldn't set utime on $dest_file: $!");
        }
        croak("error processing $archive: $!") if ( $status < 0 );
    };
    my $error = $@;
    $unzip->close();
    die($error) if ($error);
    return;
}

1;

__END__

=pod

=head1 NAME

Footprintless::Extract - Extracts data from archives

=head1 VERSION

version 1.26

=head1 DESCRIPTION

Provides a built in library for extracting data from archives.  It 
presents an interface compatible with C<Archive::Extract> for the 
functions used by C<Footprintless>.

=head1 CONSTRUCTORS

=head2 new(archive => $archive, %options)

Constructs a new instance.  Note that C<archive => $archive> is 
I<REQUIRED> in order to provide a interface compatible with 
C<Archive::Extract>.  The available options are:

=over 4

=item type

The type of archive.  The supported types are C<tar>, C<tgz>, and C<zip>.
If not provided, the file extension will be used to determine the type.

=back

=head1 METHODS

=head2 extract(%options)

Returns a I<truthy> value if C<$hostname> is an alias for localhost.

=over 4

=item to

The destination directory to extract into.  If not supplied, C<Cwd::getcwd>
will be used.

=back

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Footprintless|Footprintless>

=item *

L<Archive::Extract|Archive::Extract>

=item *

L<Cwd::getcwd|Cwd::getcwd>

=item *

L<Footprintless|Footprintless>

=back

=cut
