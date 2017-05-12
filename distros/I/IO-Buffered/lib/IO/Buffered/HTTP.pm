package IO::Buffered::HTTP; 
use strict;
use warnings;
use Carp;

use base ("IO::Buffered");

# FIXME: Write documentation

our $VERSION = '1.00';

=head1 NAME

IO::Buffered::HTTP - HTTP buffering

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
    my ($class, %opts) = @_;
    
    croak "Option MaxSize should be a positiv integer" if $opts{MaxSize} and !( 
        $opts{MaxSize} =~ /^\d+$/ and $opts{MaxSize} > 0);
    
    my %self = (
        maxsize => $opts{MaxSize},
        headeronly => (exists $opts{HeaderOnly} ? $opts{HeaderOnly} : 0),
        buffer => '',
        length => 0,
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
    my ($self, $readlength) = (@_);
    my @records;
 
    # FIXME: Something is boaken

    $self->{length} = ($readlength or -1) if $self->{length} < 0;
    #print "hello: $self->{length}, $readlength\n";

    while($self->{length} >= 0) {
        if(my $length = $self->{length}) {
            if(length $self->{buffer} >= $length) {
                push(@records, substr($self->{buffer}, 0, $length));
                substr($self->{buffer}, 0, $length) = '';
                $self->{length} = 0;
                #$readlength = undef;
                next if length($self->{buffer}) > 0;
            }

        } else {
            my $idx = index($self->{buffer}, "\r\n\r\n");
            # Found what could be a header
            if($idx >= 0) {
                my $header = substr($self->{buffer}, 0, $idx + 4);;
                
                if($self->{headeronly}) {
                    push(@records, $header);
                    substr($self->{buffer}, 0, $idx + 4) = '';
                    $self->{length} = -1;
                
                } elsif($header =~ /Content-Length:\s+(\d+)/six) {
                    my $length = $1 + $idx + 4;
                    if(length $self->{buffer} >= $length) {
                        push(@records, substr($self->{buffer}, 0, $length));
                        substr($self->{buffer}, 0, $length) = '';
                        next if length($self->{buffer}) > 0;
                    } else {
                        $self->{length} = $length;
                    }

                } else {
                    push(@records, $header);
                    substr($self->{buffer}, 0, $idx + 4) = '';
                    next if length($self->{buffer}) > 0;
                }
            }
        }
        
        last;
    };

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

