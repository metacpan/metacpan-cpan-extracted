package IO::Buffered::Regexp; 
use strict;
use warnings;
use Carp;

use base ("IO::Buffered");

our $VERSION = '1.00';

# FIXME: Write documentation

=head1 NAME

IO::Buffered::Regexp - Regular expression buffering

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 METHODS

=over

=cut

use base "Exporter";

our @EXPORT_OK = qw();

=item new($regexp, MaxSize => 0..Inf, Double => 0|1, ReturnsLast => 0|1)

The C<IO::Buffered::Regexp> buffer type takes a regular expression as input and 
splits records based on that. Only the match defined in the () is returned and 
not the complete match. 

The options C<MaxSize> and C<Double> are optional. 

C<MaxSize> provides a limit on how big a buffer can grow, when the limit is hit 
an exception is thrown. 

C<Double> defines the how the regexp is used to extract new items and remove 
old data from the buffer. By default a while loop is used that grabs and 
removes one item at a time from the buffer. If C<Double> is defined another 
method is used:

    my @records = ($self->{buffer} =~ /$regexp/g);
    $self->{buffer} =~ s/$regexp//g;

This might be faster in some cases and slower in others.

C<ReturnsLast> sets what the C<returns_last()> returns, this is used by the
"Split" buffer type to return the correct value as it is just a wrapper.

=cut

sub new {
    my ($class, $regexp, %opts) = @_;
    
    # Check that $regexp is a Regexp or a non empty string
    croak "Regexp should be a string or regexp" if !(defined $regexp and 
            (ref $regexp eq 'Regexp' or (ref $regexp eq '' and $regexp ne '')));

    # Check that $regexp is a Regexp or a non empty string
    croak "Option MaxSize should be a positiv integer" if $opts{MaxSize} and !( 
        $opts{MaxSize} =~ /^\d+$/ and $opts{MaxSize} > 0);
    
    my %self = (
        buffer => '',
        regexp => qr/$regexp/,
        maxsize => $opts{MaxSize},
        double => ($opts{Double} or 0),
        returns_last => (exists $opts{ReturnsLast} ? $opts{ReturnsLast} : 1),
    );
    
    return bless \%self, (ref $class || $class);
}

=item flush($str, ...)

=cut

sub flush {
    my $self = shift;
    $self->{buffer} = join ('', @_);
}

=item buffer()

=cut

sub buffer {
    my $self = shift;
    return $self->{buffer}; 
}

=item write($str, ...)

=cut

sub write {
    my $self = shift;
    my $str = join ('', @_);
    
    if(my $maxsize = $self->{maxsize}) {
        my $length = length($str) + length($self->{buffer});
        if($length > $maxsize) {
            croak "Buffer overrun";
        }
    }

    $self->{buffer} .= $str;
}

=item read()

=cut

sub read {
    my ($self) = @_;

    if($self->{double}) {
        my $regexp = $self->{regexp};
        my @records = ($self->{buffer} =~ /$regexp/g);
        $self->{buffer} =~ s/$regexp//g;
        return @records;
         
    } else {
        my $regexp = $self->{regexp}; 
        my @records; 
        while ($self->{buffer} =~ s/$regexp//) {
            if($1 ne '') {
                push(@records, $1);
            } else {
                last;
            }
        }
        return @records;
    }
}

=item returns_last()

=cut

sub returns_last {
    my $self = shift;
    return $self->{returns_last};
}

=item read_last()

=cut

sub read_last {
    my ($self) = @_;
    my @results = $self->read();
    push(@results, $self->{buffer}) if $self->{buffer} ne '';
    $self->{buffer} = '';
    return @results; 
}

=back

=head1 AUTHOR

Troels Liebe Bentsen <tlb@rapanden.dk> 

=head1 COPYRIGHT

Copyright(C) 2008 Troels Liebe Bentsen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

