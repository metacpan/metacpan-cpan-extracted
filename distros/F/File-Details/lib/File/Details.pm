package File::Details;

use strict;
use warnings;

use base qw/Class::Accessor/;

use Cwd 'abs_path';

my @stats = qw/dev ino mode nlink uid gid rdev size accessed
               modified changed blksize blocks/;

my @details = qw/abspath filename hashtype/;

my @hashtypes = qw/MD5/;

File::Details->mk_accessors(( @stats, @details ) );

sub new{
    my ( $class, $filename, $options ) = @_;

    my $self = {
        filename => $filename,
        abspath  => abs_path($filename),
    };

    for my $digest ( @hashtypes ) {
        no strict 'refs';
        $self->{ _hash_dispatch }{ $digest } = &$digest();
    }

    if ( -e $filename ){
        _read_attribs( $self );
        return bless $self, $class;
    }else{
        die "File $filename does not exists\n";
    }
}

sub _read_attribs {
    my ( $self ) = @_;

    @$self{ @stats } = stat( $self->{ filename } );
}

sub hash {
    my ( $self ) = @_;

    return $self->{ hash } if exists $self->{ hash };

    my $type = $self->{ hashtype } || "MD5";

    $self->{ _hash_dispatch }{ $type }( $self );
}

# plugin or something?
sub MD5 {
    eval "require Digest::MD5";

    if ( !$@ ) {
        Digest::MD5->import();
    }

    return sub {
        my ( $self ) = @_;
        open my $fh , "<", $self->{ filename };
        my $hash = Digest::MD5->new;
        $hash->addfile( $fh );
        close $fh;
        return $hash->hexdigest;
    }
}


1;

=head1 NAME

File::Details - File details in an object, stat, hash, etc..

=head1 SYNOPSIS

This module provides a class, File::Details that returns an
object with stats and optionally other information about some file.

Instead creating hashs or even other classes to represent this, we
simple can use File::Details. It also works like an stat that returns
an object.

    use File::Details;

    my $details = File::Details->new( "filename" );

    my $size = $detais->size();  # same output as stat("filename")[7]

    # Getting the MD5 sum ( needs Digest::MD5 installed )

    my $hash = $details->hash();

=head1 METHODS

=head2 new

Creates a new object, on the filename received as parameter. It generates the stat info.

=head2 dev ino mode etc...

The stat elements are the same, so:

$details->blocks();

returns the actual number of system-specific blocks allocated on disk.

=head2 hash

Returns the MD5sum from the contents of the file. It calculates when the hash method is called for the first time. Another calls will return the same value calculated on first time.

=head1 AUTHOR

RECSKY, C<< <recsky@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-details at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Details>. 

=head1 SUPPORT

Usually we are on irc on irc.perl.org

    #sao-paulo.pm
    #perl

=head1 LICENSE AND COPYRIGHT

Copyright 2015 RECSKY

This program is free software; you can redistribute it and/or modify
it under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0> 

=cut


__END__
dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks

dev ino mode nlink uid gid rdev size accessed modified changed blksize blocks

