package Dist::Zilla::Plugin::JSAN::OptimizePNG;
BEGIN {
  $Dist::Zilla::Plugin::JSAN::OptimizePNG::VERSION = '0.06';
}

# ABSTRACT: a plugin for Dist::Zilla which optimize the PNG images

use Moose;
use Moose::Autobox;

with 'Dist::Zilla::Role::AfterBuild';

use Deployer::Image::PNG;

use Path::Class;
use File::Find::Rule;


#================================================================================================================================================================================================================================================
sub mvp_multivalue_args { qw( dirs ) }
sub mvp_aliases { return { dir => 'dirs' } }


has dirs => (
    is   => 'ro',
    isa  => 'ArrayRef',
    default => sub { [ 'static/images' ] },
);


has only_for_release => (
    is      => 'rw',
    default => 1
);


has 'use_lossless' => (
    is => 'rw',
     
    default => 1
);


has 'use_quantization' => (
    is => 'rw',
     
    default => 1
);



has 'use_optipng' => (
    is => 'rw',
     
    default => 1
);


has 'use_pngout' => (
    is => 'rw',
     
    default => 0
);


has 'png_out_binary' => (
    is => 'rw'
);






#================================================================================================================================================================================================================================================
sub after_build {
    my ($self, $param) = @_;
    
    return if ($self->only_for_release && !$ENV{ DZIL_RELEASING });
    
    my $build_root = dir($param->{ build_root });

    my @png_files;
    
    foreach my $dir ($self->dirs->flatten) {
        push @png_files, File::Find::Rule->or(
            File::Find::Rule->file->name('*.png')
        )->in($build_root->subdir($dir));
    }
    
    my @log;
    
    my $overall_before  = 0;
    my $overall_after   = 0;
    
    foreach my $file (@png_files) {
        my $image = Deployer::Image::PNG->new({
            filename                => $file,
            
            use_lossless            => $self->use_lossless,
            use_quantization        => $self->use_quantization,
            
            use_pngout              => $self->use_pngout,
            use_optipng             => $self->use_optipng,
            png_out_binary          => $self->png_out_binary
        });
        
        my $before  = $image->get_size;
        $overall_before += $before;
        
        $image->optimize();
        
        my $after   = $image->get_size;
        $overall_after += $after;
        
        $file =~ /(.{0,30})$/;
        
        $self->log(sprintf("File %30.30s: before =%7d, after =%7d, optimization = %.3f%%", $1, $before, $after, 100 * ($after - $before) / $before));
    }
    
    $self->log('Overall:');
    $self->log(sprintf("     %30s  before =%7d, after =%7d, optimization = %.3f%%", '', $overall_before, $overall_after, 100 * ($overall_after - $overall_before) / $overall_before));
}



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);


1;



__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::JSAN::OptimizePNG - a plugin for Dist::Zilla which optimize the PNG images

=head1 VERSION

version 0.06

=head1 SYNOPSIS

In your F<dist.ini>:

    [JSAN::OptimizePNG]
    
    dir             = lib/Dist/Name/static/images/icons     ; runs in "After Build" phase, so need to consider 
    dir             = lib/Dist/Name/static/images/buttons   ; the effect of StaticDir plugin
    
    use_lossless            = 1    ;    default, use lossless optimizations
    use_quantization        = 1    ;    default, use quantization (with losses)
    
    use_optipng             = 1    ;    default, use the `optipng` command for optimization 
                                   ;    (available from `optipng` package)
                               
    use_pngout              = 0    ;    default is to not use the `png_out` command 
                                   ;    (its provides much better compression than `optipng`
                                   ;    but is available only from http://www.advsys.net/ken/utils.htm
                                   
    png_out_binary          = script/bin/pngout-static  ; path to the `pngout` binary, if enabled                                    

=head1 DESCRIPTION

=head1 AUTHOR

Nickolay Platonov <nplatonov@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Nickolay Platonov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

