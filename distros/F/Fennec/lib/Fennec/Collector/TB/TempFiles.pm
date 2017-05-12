package Fennec::Collector::TB::TempFiles;
use strict;
use warnings;

use base 'Fennec::Collector::TB';

use File::Temp;

use Fennec::Util qw/ accessors verbose_message /;

accessors qw/tempdir handles tempobj _pid/;

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);

    my $temp = File::Temp::tempdir( CLEANUP => 0 );
    verbose_message("# Using temp dir: '$temp' for process results\n");

    $self->_pid($$);
    $self->handles( {} );
    $self->tempobj($temp);
    $self->tempdir("$temp");

    return $self;
}

sub report {
    my $self   = shift;
    my %params = @_;

    if ( $$ == $self->_pid ) {
        for my $item ( @{$params{data}} ) {
            for my $part ( split /\r?\n/, $item ) {
                $self->render( $params{name}, $part );
            }
        }
        return;
    }

    my $handle;
    if ( $self->handles->{$$} ) {
        $handle = $self->handles->{$$};
    }
    else {
        my $path = $self->tempdir . "/$$";
        open( $handle, '>', $path ) || die "$!";
        $self->handles->{$$} = $handle;
    }

    for my $item ( @{$params{data}} ) {
        for my $part ( split /\r?\n/, $item ) {
            print $handle "$params{name}|$params{source}|$part\n";
        }
    }
}

sub collect {
    my $self = shift;
    return unless $self->_pid == $$;

    my $handle;
    if ( $self->handles->{tempdir} ) {
        $handle = $self->handles->{tempdir};
        rewinddir $handle;
    }
    else {
        opendir( $handle, $self->tempdir ) || die "$!";
        $self->handles->{tempdir} = $handle;
    }

    while ( my $file = readdir $handle ) {
        my $path = $self->tempdir . "/$file";
        next unless -f $path;
        next unless $path =~ m/\.ready$/;
        open( my $fh, '<', $path ) || die $!;

        while ( my $line = <$fh> ) {
            chomp($line);
            next unless $line;
            my ( $handle, $source, $part ) = ( $line =~ m/^(\w+)\|([^\|]+)\|(.*)$/g );
            warn "Bad Input: '$line'\n" unless $handle && $source;

            $self->render( $handle, $part );
        }

        close($fh);

        rename( $path => "$path.done" ) || die "Could not rename file: $!";
    }
}

sub finish {
    my $self = shift;
    return unless $self->_pid == $$;

    $self->ready() if $self->handles->{$$};

    $self->collect;
    $self->SUPER::finish();

    my $handle = $self->handles->{tempdir};
    rewinddir $handle;

    die "($$) Not all files were collected?!"
        if grep { m/^\d+(\.ready)?$/ } readdir $handle;

    if ( !$ENV{FENNEC_DEBUG} ) {
        rewinddir $handle;
        while ( my $file = readdir $handle ) {
            next unless $file =~ m/\.done$/;
            unlink( $self->tempdir . '/' . $file ) || warn "error deleting $file: $!";
        }
        close($handle);
        rmdir( $self->tempdir ) || warn "Could not cleanup temp dir: $!";
    }
}

sub ready {
    my $self = shift;
    warn "No Temp Dir! $$" unless $self->tempdir;
    my $path = $self->tempdir . "/$$";
    return unless -e $path;
    close( $self->handles->{$$} ) || warn "Could not close file $path - $!";
    rename( $path => "$path.ready" ) || warn "Could not rename file $path - $!";
}

sub end_pid { }

sub DESTROY {
    my $self = shift;
    $self->ready;
}

1;

__END__

=head1 NAME

Fennec::Collector::TB::TempFiles - Test::Builder collector that uses temporary
files to convey results.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2013 Chad Granum

Fennec is free software; Standard perl license (GPL and Artistic).

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
