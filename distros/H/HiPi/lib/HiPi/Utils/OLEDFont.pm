#########################################################################################
# Package        HiPi::Utils::OLEDFont
# Description  : OLED Font Creation
# Copyright    : Copyright (c) 2018 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Utils::OLEDFont;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Class );
use Image::Imlib2;
use JSON qw( encode_json decode_json );
use File::Slurp;
use Try::Tiny;
use Cwd;

__PACKAGE__->create_accessors( qw(
    json_file
    input_folder
    output_folder
    module_base
    base_suffix
    font_name
    face_name
    space_width
) );

sub new {
    my($class, %params ) = @_;
    
    $params{module_base} //= 'HiPi::Graphics::BitmapFont';
    
    my $self = $class->SUPER::new( %params );
    return $self;
}

sub write_font {
    my $self = shift;
    return '' unless $self->_init_oledfont;
    my $dataref = $self->_read_json;
    return '' unless $dataref;
    my $content = $self->_get_content( $dataref );
    return '' unless $content;
    try {
        my $outfile = $self->output_folder . '/' . $self->font_name . '.pm';
        open(my $fh, '>:encoding(UTF-8)',$outfile) or die $!;
        print $fh $content;
        close($fh);
    } catch {
        warn $_;
    };
}

sub _get_content {
    my($self, $fontdata) = @_;
    
    my $output = try {
        my $pngfile = $fontdata->{config}->{textureFile};
        my $image = Image::Imlib2->load($self->input_folder . '/' . $pngfile );
    
        my @codelines = ();
        my $facename = $fontdata->{config}->{face};
        warn qq(Outputting $pngfile ) . $fontdata->{config}->{charHeight};
        $facename =~ s/^\s+|\s+$//g;
        $facename =~ s/'/ /g;
        # We must not name Bitstream Vera fonts as BitstreamVera
        $facename =~ s/\s*bitstream\s*vera\s*//i;
        # rename Sans Mono fonts to Mono;
        $facename = 'Mono' if $facename eq 'Sans Mono';
        
        
        
        push @codelines, qq(my \$gap_width = $fontdata->{config}->{charSpacing};);
        
        my $fontname = $facename;
        $fontname =~ s/\s+//g;
        
        $fontname .= $self->base_suffix if $self->base_suffix;
        
        my $fontheight = $fontdata->{config}->{charHeight};
        my $linespacing = $fontdata->{config}->{lineSpacing};
        
        # get the kerning
        my $kerning = {};
        for my $kern ( @{ $fontdata->{kerning} } ) {
            my $first = $kern->{first};
            my $second = $kern->{second};
            $kerning->{$first}->{$second} = $kern->{amount};
        }
        
        my @symbollines =  q(my $symbols = {);
        my @kernlines = q(my $kerning = {);
                
        # get min yoffset
        my $minyoff = 1000;
        for ( my $i = 0; $i < @{ $fontdata->{symbols} }; $i ++) {
            my $symbol = $fontdata->{symbols}->[$i];
            next if $symbol->{id} == 32;
            my $yoffset = $symbol->{yoffset};
            if( $yoffset < $minyoff ) {
                $minyoff = $yoffset;
            }
        }
        my $addyoffset = 0;
        
        if( $minyoff < 0 ) {
            $addyoffset = abs( $minyoff );
            $minyoff = 0;
            $fontheight += $addyoffset;
        }
        
        # warn (qq(min y offset = $minyoff ));
        
        my $space_width;
        
        for ( my $i = 0; $i < @{ $fontdata->{symbols} }; $i ++) {
            
            #"height": 7,
            #"id": 33,
            #"width": 1,
            #"x": 2,
            #"xadvance": 3,
            #"xoffset": 1,
            #"y": 1,
            #"yoffset": 1
            
            my $symbol = $fontdata->{symbols}->[$i];
            my $ord = $symbol->{id};
            my $height = $symbol->{height};
            my $width = $symbol->{width};
            my $x = $symbol->{x};
            my $y = $symbol->{y};
            my $xadvance = $symbol->{xadvance};
            my $xoffset = $symbol->{xoffset};
            my $yoffset = $symbol->{yoffset} + $addyoffset;
            
            if( $ord == 32 ) {
                $space_width = $xadvance;
                next;
            }
            
            my $char = chr($ord);
            
            push @symbollines, qq(    '$ord' => {    # '$char');
            push @symbollines, qq(        'width'    => $width, );
            push @symbollines, qq(        'xoffset'  => $xoffset, );
            push @symbollines, qq(        'xadvance' => $xadvance, );
            push @symbollines, qq(        'bitmap'   => [ );
                        
            # kerning
            {
                my $kernline = qq(    '$ord' => { );
                if( my $kern = $kerning->{$ord} ) {
                    for my $second ( sort { $a <=> $b } keys %$kern ) {
                        my $amount = $kern->{$second};
                        $kernline .= qq('$second' => $amount, );
                    }
                }
                $kernline .= qq(},  # $char);
                push @kernlines, $kernline;
            }
            
            my $bytesperline = int( $width / 8);
            my $bitshift = 0;
            if( $bitshift = $width % 8 ) {
                $bytesperline ++;
                $bitshift = 8 - $bitshift;
            }
            
            # create the bits
            
            for ( my $iy = $minyoff; $iy < $fontheight; $iy ++ ) {
                my $line = '           ';
                my $linex = ' ##  ';
                my @linebytes = (0) x $bytesperline;
                if( $iy < $yoffset || $iy >= ( $yoffset + $height ) ) {
                    for( @linebytes ) {
                        $line .= sprintf(' 0x%02X,', $_);
                    }
                    push @symbollines, $line . $linex;
                    next;
                }
                
                my $wordval = 0;
                
                for (my $ix = 0; $ix < $width; $ix ++) {
                    
                    my($r, $g, $b, $a)= $image->query_pixel( $ix + $x, ($iy - $yoffset) + $y  );
                    if( $a != 0 ) {
                        my $shiftval = $bitshift + ($width - 1) - $ix;
                        $linex .= '0';
                        $wordval |= ( 1 << $shiftval );
                    } else {
                        $linex .= ' ';
                    }
                }
                
                my $shiftbyte = $bytesperline;
                while( $shiftbyte ) {
                    my $shiftval = 8 * ( $shiftbyte - 1 );
                    my $byte = 0xFF & ($wordval >> $shiftval );
                    $line .= sprintf(' 0x%02X,', $byte);
                    $shiftbyte --;
                }
                
                push @symbollines, $line . $linex;
                
            }
            push @symbollines, qq(        ], ); # end bitmaps
            push @symbollines, qq(    }, ); # end symbol
            
        }
        
        push @symbollines, '};';
        
        push @kernlines, '};';
        
        $fontheight -= $minyoff;
        push @codelines, qq(my \$char_height = $fontheight;);
        
        $linespacing += $minyoff;
        push @codelines, qq(my \$line_spacing = $minyoff;);
        $facename .= ' ' . $fontheight;
        
        if( $self->face_name ) {
            $facename = $self->face_name;
        } else {
            $self->face_name( $facename );
        }
        
        if( $self->font_name ) {
            $fontname = $self->font_name;
        } else {
            $fontname .= $fontheight;
            $self->font_name( $fontname );
        }
        
        push @codelines, qq(my \$name = '$facename';);
        
        unless($space_width) {
            if( defined( $self->space_width ) ) {
                $space_width = $self->space_width;
            } else {
                $space_width = int($fontheight / 3);
            }
        }
        
        push @codelines, qq(my \$space_width = $space_width;);
        
        push @codelines, ' ', @symbollines, ' ', @kernlines;
        
        my $codeblock = join(qq(\n), @codelines) . qq(\n);
        
        my $modbase = $self->module_base;
        
        my $content = get_template();
        $content =~ s/REPLACE_PACKAGE_KEYWORK/package/g;
        $content =~ s/REPLACEMODULEBASE/$modbase/g;
        $content =~ s/REPLACENAME/$fontname/g;
        $content =~ s/REPLACEFONTCONTENT/$codeblock/;
        
        return $content;
    } catch {
        warn $_;
        return '';
    };

    return $output;
}

sub _init_oledfont {
    my $self = shift;
    
    my $rval = try {
        my $ifolder = Cwd::abs_path( $self->input_folder );
        unless( -d $ifolder ) {
            warn 'could not locate input folder ' . $self->input_folder;
            return  0;
        }
        $self->input_folder( $ifolder );
        my $ofolder = Cwd::abs_path( $self->output_folder );
        unless( -d $ofolder ) {
            warn 'could not locate output folder' . $self->output_folder;
            return  0;
        }
        $self->output_folder( $ofolder );
        unless( -f $self->input_folder . '/' . $self->json_file ) {
            warn 'could not locate json file ' . $self->json_file;
            return  0;
        }
        return 1;
    } catch {
        warn $_;
        return 0;
    };
    
    return $rval;
}

sub _read_json {
    my $self = shift;
    my $data = try {
        my $json = File::Slurp::read_file( $self->input_folder . '/' . $self->json_file ) or die $!;
        my $ref = decode_json( $json );
        return $ref;
    } catch {
        my $error = $_;
        warn sprintf('Failed to load JSON file %s : %s', $self->json_file, $error );
        return undef;
    };
    return $data;
}


sub get_template {
    my $template = q(#########################################################################################
# Package        REPLACEMODULEBASE::REPLACENAME
# Description  : Monochrome OLED Font
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

REPLACE_PACKAGE_KEYWORK REPLACEMODULEBASE::REPLACENAME;

#########################################################################################

use utf8;
use strict;
use warnings;
use parent qw( HiPi::Graphics::BitmapFont);

our $VERSION ='0.81';

REPLACEFONTCONTENT

sub new {
    my($class) = @_;
    
    my $self = $class->SUPER::new(
        name        => $name,
        char_height => $char_height,
        space_width => $space_width,
        gap_width   => $gap_width,
        symbols     => $symbols,
        kerning     => $kerning,
        line_spacing => $line_spacing,
        class       => 'hipi_2',
    );
    
    return $self;
}

1;

__END__
);

    return $template;  
}


1;

__END__