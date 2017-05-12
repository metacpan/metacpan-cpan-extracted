package HTML::Dojo;

use 5.006;
use strict;
use warnings;
use Carp qw/ croak /;

our $VERSION = '0.0403.0';

our $COMMON_DATA;
our $EDITIONS_DATA;
our $SRC_DATA;

=head1 NAME

HTML::Dojo - Provides the Dojo JavaScript / AJAX distribution 0.4.3 files.

=head1 SYNOPSIS

    use HTML::Dojo;
    
    my $dojo = HTML::Dojo->new;
    
    my @editions = $dojo->editions();
    
    my @files = $dojo->list( \%options );
    
    my $data = $dojo->file( $filename, \%options );

=head1 DESCRIPTION

HTML::Dojo provides files from the Dojo JavaScript / AJAX distribution.

These files include the C<dojo.js> file, the entire C<src> directory, 
the C<iframe_history.html> file, various C<*.swf> files, the C<LICENSE>, 
C<README> and C<build.txt> files.

=head1 METHODS

=head2 new

    $dojo->new( %options );

This returns a HTML::Dojo object.

Optional arguments are:

=over

=item C<edition>

=back

=cut

sub new {
    my ($class, %args) = @_;
    
    if (exists $args{edition}) {
        croak "invalid edition"
            unless grep { $_ eq $args{edition} } $class->editions;
    }
    
    return bless \%args, $class;
}

# support a :no_files import flag, so that build_packages.pl can 
# use us without locking the sub-module .pm files

sub import {
    my $class   = shift;
    my $require = 1;
    
    for (@_) {
        if ($_ eq ':no_files') {
            $require = 0;
        }
        else {
            croak "unknown import option: $_";
        }
    }
    
    if ($require == 1) {
        require HTML::Dojo::common;
        require HTML::Dojo::editions;
        require HTML::Dojo::src;
    }
}

=head2 editions

    $dojo->editions();

This method returns a list of all available editions. Each edition 
represents a distribution file made available by the Dojo Foundation, 
and as such is subject to change with each release.

The current editions available are:

=over

=item ajax

=item charting

=item dojoWebsite

=item editor

=item event_and_io

=item kitchen_sink

=item lfx

=item moxie

=item storage

=item widget

=item xdomain-ajax

=over

=cut

sub editions {
    return qw/
        ajax
        charting
        editor
        event_and_io
        kitchen_sink
        src
        storage
        widget
        xdomain-ajax
    /;
}

=head2 list

    $dojo->list( \%options );

Returns an array-ref of all files available.

Optional arguments are:

=over

=item C<edition>

=item C<directories>, include directory names, default C<0>

=item C<files>, include ordinary-file names, default C<1>

=back

=cut

sub list {
    my ($self, $opt) = @_;
    
    my $edition = $opt->{edition} || $self->{edition} || 'ajax';
    $opt->{directories} = 0 if ! exists $opt->{directories};
    $opt->{files}       = 1 if ! exists $opt->{files};
    
    croak "too many arguments, options must be a hash-ref" if @_ > 2;
    
    croak "invalid edition"
        unless grep { $_ eq $edition } $self->editions;
    
    my @files;
    
    push @files, $self->_editions_files( $edition )
        if $opt->{files};
    
    push @files, $self->_common_files()
        if $opt->{files};
    
    push @files, $self->_list_src( $edition, $opt );
    
    return \@files;
}

sub _list_src {
    my ($self, $edition, $opt) = @_;
    my @files;
    
    if (! defined $SRC_DATA) {
        local $/;
        $SRC_DATA = eval { package HTML::Dojo::src; <DATA> };
    }
    # use look-ahead so the __CPAN_ line isn't removed
    my @data = split /^(?=__CPAN_[^\n]+\r?\n)/m, $SRC_DATA;
    
    for (@data) {
        next unless length;
        
        croak "unknown format: '$_'" unless /__CPAN_(DIR|FILE)__ ([^\r\n]+)/;

        if ($1 eq 'DIR' && $opt->{directories}) {
            push @files, $2;
        }
        
        if ($1 eq 'FILE' && $opt->{files}) {
            push @files, $2;
        }
    }
    return @files;
}

=head2 file

    $dojo->file( $filename, \%options )

Returns the contents of the named file.

Optional arguments are:

=over

=item C<edition>, default C<ajax>.

=back

=cut

sub file {
    my ($self, $filename, $opt) = @_;
    
    my $edition = $opt->{edition} || $self->{edition} || 'ajax';
    
    croak "too many arguments, options must be a hash-ref" if @_ > 3;
    
    croak "invalid edition"
        unless grep { $_ eq $edition } $self->editions;
    
    if (grep { $filename eq $_ } $self->_common_files) {
        return $self->_file_common( $filename );
    }
    elsif (grep { $filename eq $_ } $self->_editions_files) {
        return $self->_file_edition( $filename, $edition );
    }
    else {
        return $self->_file_src( $filename );
    }
}

sub _file_common {
    my ($self, $filename) = @_;
    
    if (! defined $COMMON_DATA) {
        local $/;
        no warnings 'once';
        $COMMON_DATA = eval { package HTML::Dojo::common; <DATA> };
    }
    # use look-ahead so the __CPAN_ line isn't removed
    my @data = split /^(?=__CPAN_[^\n]+\r?\n)/m, $COMMON_DATA;
    
    for (@data) {
        next unless length;
        
        croak "unknown format: '$_'" 
            unless s/__CPAN_COMMON__ ([^\r\n]+)\r?\n//;
        
        next unless $1 eq $filename;
        
        chomp;
        return $_;
    }
    
    croak "didn't find data for file '$filename''";
}

sub _file_edition {
    my ($self, $filename, $edition) = @_;
    
    if (! defined $EDITIONS_DATA) {
        local $/;
        no warnings 'once';
        $EDITIONS_DATA = eval { package HTML::Dojo::editions; <DATA> };
    }
    # use look-ahead so the __CPAN_ line isn't removed
    my @data = split /^(?=__CPAN_[^\n]+\r?\n)/m, $EDITIONS_DATA;
    
    for (@data) {
        next unless length;
        
        croak "unknown format" 
            unless s/__CPAN_EDITION__ (\w+) ([^\r\n]+)\r?\n//;
        
        next unless $1 eq $edition;
        next unless $2 eq $filename;
        
        chomp;
        return $_;
    }
    
    croak "didn't find data for file '$filename', edition '$edition'";
}

sub _file_src {
    my ($self, $filename) = @_;
    
    if (! defined $SRC_DATA) {
        local $/;
        $SRC_DATA = eval { package HTML::Dojo::src; <DATA> };
    }
    # use look-ahead so the __CPAN_ line isn't removed
    my @data = split /^(?=__CPAN_[^\n]+\r?\n)/m, $SRC_DATA;
    
    for (@data) {
        next unless length;
        
        croak "unknown format" unless s/__CPAN_(DIR|FILE)__ ([^\r\n]+)\r?\n//;
        
        next unless $1 eq 'FILE' && $2 eq $filename;
        
        chomp;
        return $_;
    }
    
    croak "didn't find data for file '$filename'";
}

# internals used by build_packages.pl

sub _editions_files {
    return qw/
        dojo.js
        build.txt
    /;
}

sub _common_files {
    return qw/
        iframe_history.html
        flash6_gateway.swf
        storage_dialog.swf
        Storage_version6.swf
        Storage_version8.swf
        README
        LICENSE
    /;
}

=head1 SEE ALSO

L<http://dojotoolkit.org>, L<HTML::Prototype>

=head1 SUPPORT

Catalyst mailing list:

    http://lists.rawmode.org/mailman/listinfo/catalyst

=head1 AUTHOR

Carl Franks, E<lt>cfranks@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

    Copyright (C) 2006 by Carl Franks

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

	Copyright (c) 2004-2005, The Dojo Foundation

	All Rights Reserved

The Dojo distribution files may be redistributed under either the 
modified BSD license or the Academic Free License version 2.1.


=cut

1;
