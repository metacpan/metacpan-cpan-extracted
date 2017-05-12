package IO::Buffered::Size; 
use strict;
use warnings;
use Carp;

use base ("IO::Buffered");

# FIXME: Write documentation

our $VERSION = '1.00';

=head1 NAME

IO::Buffered::Size - Size buffering based on pack templates

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 METHODS

=over

=cut

use base "Exporter";

our @EXPORT_OK = qw();

=item new()

=cut

sub new {
    my ($class, $args, %opts) = @_;
    
    croak "Args should be an array reference" if ref $args ne 'ARRAY';

    my ($template, $offset) = (@{$args}, 0); # Offset defaults to 0

    # Check if $template is a string, has no * and only returns one number
    croak "Template should be a string"  if !(defined $template and 
        ref $template eq '' and $template !~ /^\d+$/);
    croak "Template should not contain *" if $template =~ /\*/;
    croak "Template should only return one number: $template" 
        if ref unpack($template, "x" x 30) ne '';
    
    # Check if $offset is a number
    croak "Offset should be a number" if !(defined $offset 
        and $offset =~ /^-?\d+$/);
   
    # Check that $regexp is a Regexp or a non empty string
    croak "Option MaxSize should be a positiv integer" if $opts{MaxSize} and !( 
        $opts{MaxSize} =~ /^\d+$/ and $opts{MaxSize} > 0);

    my %self = (
        buffer   => '',
        offset   => $offset,
        minsize  => length(pack($template, 0)), # Get minimun size
        template => $template,
        maxsize  => $opts{MaxSize},
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
    my ($self) = (@_);
    my $template = $self->{template};
    my $offset   = $self->{offset};
    my $minsize  = $self->{minsize};
    my @records; 

    while(length $self->{buffer} > $minsize) {
        my $length = (unpack($template, $self->{buffer}))[0]+$offset;
        my $datastart = length(pack($template, $length));
    
        if(length $self->{buffer} >= $length + $datastart) {
            push(@records, substr($self->{buffer}, $datastart, $length));
            substr($self->{buffer}, 0, $length+$datastart) = '';
        } else {
            last;
        }
    }
    return @records;
}

=item returns_last()

=cut

sub returns_last {
    return 1;
}

=item read_last()

=cut

sub read_last {
    my ($self) = @_;
    my @records = $self->read();
    
    my $template = $self->{template};
    my $offset   = $self->{offset};
    
    if($self->{buffer} ne '') {
        my $length = (unpack($template, $self->{buffer}))[0]+$offset;
        my $datastart = length(pack($template, $length));
    
        push(@records, substr($self->{buffer}, $datastart));
        $self->{buffer} = '';
    }

    return @records; 
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

