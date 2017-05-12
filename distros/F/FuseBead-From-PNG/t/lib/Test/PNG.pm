package Test::PNG;

use File::Temp qw(tempfile);
use Image::PNG::Libpng qw(:all);
use Image::PNG::Const qw(:all);
use Data::Debug;

sub new {
    my $class = shift;
    my $args  = ref $_[0] eq 'HASH' ? shift : {};

    my $self = bless $args, $class;

    ($self->{'fh'}, $self->{'filename'}) = tempfile( 'testpngXXXXXX', SUFFIX => '.png', TMPDIR => 1);
    binmode $self->{'fh'};

    $self->{'width'}      ||= 1024;
    $self->{'height'}     ||= 768;
    $self->{'unit_size'}  ||= 8;
    $self->{'color'}      ||= [];

    die 'Both width and height need to be divisible by unit size'
        unless ($self->{'width'} % $self->{'unit_size'} == 0) && ($self->{'height'} % $self->{'unit_size'} == 0);

    $self->generate_rnd_png;

    return $self;
}

sub fh { shift->{'fh'} }

sub filename { shift->{'filename'} }

sub width { shift->{'width'} }

sub height { shift->{'height'} }

sub unit_size { shift->{'unit_size'} }

sub generate_rnd_png {
    my $self = shift;

    my $rndclr = sub { srand time + (shift || 0); int (rand () * 0x100); };

    my $png = create_write_struct();

    $png->init_io($self->{'fh'});

    $png->set_IHDR ({height => $self->{'height'}, width => $self->{'width'}, bit_depth => 8,
                     color_type => PNG_COLOR_TYPE_RGB});

    my @rows;
    for(my $h = 0; $h < $self->{'height'} / $self->{'unit_size'}; $h++) {
        my @row;
        for(my $w = 0; $w < $self->{'width'} / $self->{'unit_size'}; $w++) {
            my @color = (ref $self->{'color'} eq 'ARRAY' && scalar @{$self->{'color'}} == 3)
                ? @{$self->{'color'}}
                : ($rndclr->($h + $w * 3000), $rndclr->($h + $w * 10), $rndclr->($h + $w * 200));
            push @row, @color for 1 .. $self->{'unit_size'};
        }
        my $len = $self->{'width'} * 3;
        push @rows, pack("C[$len]", @row) for 1 .. $self->{'unit_size'};
    }

    $png->set_rows(\@rows);

    $png->write_png();

    close $self->{'fh'};
}

sub DESTROY {
    my $self = shift;

    # Debug - comment this when you want to see the temp image after the test if over
    unlink $self->{'filename'} unless $self->{'preserve'};
}

1;
