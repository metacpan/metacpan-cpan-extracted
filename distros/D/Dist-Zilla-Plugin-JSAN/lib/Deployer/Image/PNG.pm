package Deployer::Image::PNG;
BEGIN {
  $Deployer::Image::PNG::VERSION = '0.06';
}

# ABSTRACT: Thing wrapper around PNG image for size optimization

use Moose;

use Path::Class;


has 'filename' => (
    is => 'rw',
     
    required => 1
);


has 'iterations' => (
    is => 'rw',
     
    default => sub { 1 }
);


has 'use_lossless' => (
    is => 'rw',
     
    default => sub { 1 }
);


has 'use_optipng' => (
    is => 'rw',
     
    default => sub { 1 }
);


has 'use_pngout' => (
    is => 'rw',
     
    default => sub { 1 }
);


has 'use_quantization' => (
    is => 'rw',
     
    default => sub { 1 }
);


has 'png_out_binary' => (
    is => 'rw'
);


sub get_size {
    my ($self) = @_;
    
    return file($self->filename)->stat->size;
}



sub optimize {
    my ($self) = @_;
    
    for (my $i = 0; $i < $self->iterations; $i++) {
        
        $self->quantize()               if $self->use_quantization;
        $self->optimize_lossless()      if $self->use_lossless;
    }
    
} 


sub optimize_lossless {
    my ($self) = @_;
    
    my $file        = $self->filename;
    my $pngout      = $self->png_out_binary;      
    
    qx!optipng -q -o3 $file!    if $self->use_optipng;   
    qx!$pngout -q -y $file!     if $self->use_pngout;
} 


sub quantize {
    my ($self) = @_;
    
    my $file        = $self->filename;
    
    my $file_nq8    = $file;
    $file_nq8       =~ s/\.png$/-nq8.png/;
    
    
    my $before      = file($file)->stat->size;
    
    qx!pngnq -s 1 -Q f $file 2> /dev/null!;
    
    my $after       = file($file_nq8)->stat->size;
    
    
    if ($after < $before) {
        `mv -f $file_nq8 $file`;
    } else {
        unlink($file_nq8);
    }
}

__PACKAGE__
__END__
=pod

=head1 NAME

Deployer::Image::PNG - Thing wrapper around PNG image for size optimization

=head1 VERSION

version 0.06

=head1 AUTHOR

Nickolay Platonov <nplatonov@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Nickolay Platonov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

