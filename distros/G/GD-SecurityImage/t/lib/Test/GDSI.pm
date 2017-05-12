## no critic (NamingConventions::Capitalization, ValuesAndExpressions::ProhibitMagicNumbers)
package Test::GDSI;
use strict;
use warnings;

our $VERSION = '0.40';

use constant GD      => defined($GD::VERSION)            ? $GD::VERSION            : 0;
use constant MAGICK  => defined($Image::Magick::VERSION) ? $Image::Magick::VERSION : '0.0.0';
use constant PROBLEM => GD && GD < 2.07 ? 1 : 0;
use Carp qw(croak);

my(%options, %info_text);

sub the_info_text { return 'GD::SecurityImage' }

sub GD::SecurityImage::CIT { # __check_info_text
    my $self = shift;
    $self->info_text( %info_text ) if %info_text;
    return $self;
}

sub styles {
    return qw( default rect box circle ellipse ec );
}

sub options {
    my($class, @args) = @_;
    %options = @args if @args;
    if ( $options{info_text} ) {
        %info_text = %{ delete $options{info_text} };
    }
    return %options;
}

sub has_method {
    my $self = shift;
    my $name = shift || q{};
    if ( PROBLEM && ($name eq 'ellipse' or $name eq 'ec') ) {
        return 'circle';
    }
    return $name;
}

sub clear {
    %options   = ();
    %info_text = ();
    return;
}

sub set_options {
    my($class, @args) = @_;
    my %o = @args % 2 ? () : @args;
    foreach ( keys %o ) {
        next if $_ eq 'thickness' && PROBLEM;
        $options{$_} = $o{$_};
    }
    return $class;
}

sub random {
    return {
        ec      => 'EC0123',
        ellipse => 'ELLIPS',
        circle  => 'CIRCLE',
        box     => 'BOX012',
        rect    => 'RECT01',
        default => 'DFAULT',
    }
}

sub save {
    my($class, $image, $mime, $random, $style, $ID, $counter) = @_;
    my $name = sprintf '%s_%02d_%s.%s', $ID, $counter, $style, $mime;
    require IO::File;
    my $SI = IO::File->new;
    $SI->open( $name, '>' ) or croak "Error writing the image '$name' to disk: $!";
    binmode $SI;
    print {$SI} $image or croak "Unable to print to $name";
    close $SI or croak "Unable to close $name";
    print  "[OK] $name\n" or croak 'Unable to print to STDOUT';
    return 'SUCCESS';
}

package gd_normal;

sub ec {
    return GD::SecurityImage
            ->new(
                lines   => 5,
                bgcolor => [0,0,0],
                Test::GDSI->options,
            )
            ->random( Test::GDSI->random->{ec} )
            ->create( qw( normal ec ), [84, 207, 112], [0,0,0] )
            ->particle( 100 )
            ->CIT
}

sub ellipse {
    return GD::SecurityImage
            ->new(lines => 10, bgcolor => [208, 202, 206], Test::GDSI->options)
            ->random(Test::GDSI->random->{ellipse})
            ->create(normal => Test::GDSI->has_method('ellipse'), [31,219,180], [231,219,180])
            ->particle(100)->CIT
}

sub circle {
    return GD::SecurityImage
            ->new(lines => 5, bgcolor => [210, 215, 196], Test::GDSI->options)
            ->random(Test::GDSI->random->{circle})
            ->create(normal => 'circle', [63, 143, 167], [90, 195, 176])
            ->particle(250, 2)->CIT
}

sub box {
    return GD::SecurityImage
            ->new(lines => 5, Test::GDSI->options)
            ->random(Test::GDSI->random->{box})
            ->create(normal => 'box', [63, 143, 167], [226, 223, 169])
            ->particle(150, 4)->CIT
}

sub rect {
    return GD::SecurityImage
            ->new(lines => 10, Test::GDSI->options)
            ->random(Test::GDSI->random->{rect})
            ->create(normal => 'rect', [63, 143, 167], [226, 223, 169])
            ->particle(100)->CIT
}

sub default { ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    return GD::SecurityImage
            ->new(lines => 10, Test::GDSI->options, send_ctobg => 0)
            ->random(Test::GDSI->random->{default})
            ->create(normal => 'default', [68,150,125], [255,0,0])
            ->particle(500)->CIT
}

package gd_ttf;

sub ec {
    return GD::SecurityImage
            ->new(lines => 16, bgcolor => [0,0,0], Test::GDSI->set_options(thickness => 1)->options)
            ->random(Test::GDSI->random->{ec})
            ->create(ttf => 'ec', [84, 207, 112], [0,0,0])
            ->particle(1000)->CIT
}

sub ellipse {
    return GD::SecurityImage
            ->new(lines => 15, bgcolor => [208, 202, 206], Test::GDSI->set_options(thickness => 2)->options)
            ->random(Test::GDSI->random->{ellipse})
            ->create(ttf => Test::GDSI->has_method('ellipse'), [184,20,180], [184,20,180])
            ->particle(2000)->CIT
}

sub circle {
    return GD::SecurityImage
            ->new(lines => 50, bgcolor => [210, 215, 196],Test::GDSI->set_options(thickness => 1)->options)
            ->random(Test::GDSI->random->{circle})
            ->create(ttf => 'circle', [63, 143, 167], [210, 215, 196])
            ->particle(3500)->CIT
}

sub box {
    return GD::SecurityImage
            ->new(lines => 6, Test::GDSI->set_options(thickness => 1)->options, frame => 0)
            ->random(Test::GDSI->random->{box})
            ->create(ttf => 'box', [245,240,220], [115, 115, 115])
            ->particle(3000, 2)->CIT
}

sub rect {
    return GD::SecurityImage
            ->new(lines => 30, Test::GDSI->set_options(thickness => 1)->options)
            ->random(Test::GDSI->random->{rect})
            ->create(ttf => 'rect', [63, 143, 167], [226, 223, 169])
            ->particle(2000)->CIT
}

sub default { ## no critic (ProhibitBuiltinHomonyms)
    return GD::SecurityImage
            ->new(lines => 10, Test::GDSI->set_options(thickness => 2)->options)
            ->random(Test::GDSI->random->{default})
            ->create(ttf => 'default', [68,150,125], [255,0,0])
            ->particle(5000)->CIT
}

package gd_normal_scramble;              use base qw(gd_normal);
package gd_ttf_scramble;                 use base qw(gd_ttf);
package gd_ttf_scramble_fixed;           use base qw(gd_ttf);
package gd_normal_info_text;             use base qw(gd_normal);
package gd_ttf_info_text;                use base qw(gd_ttf);
package gd_normal_scramble_info_text;    use base qw(gd_normal);
package gd_ttf_scramble_info_text;       use base qw(gd_ttf);
package gd_ttf_scramble_fixed_info_text; use base qw(gd_ttf);

package magick;                          use base qw(gd_ttf);
package magick_scramble;                 use base qw(gd_ttf);
package magick_scramble_fixed;           use base qw(gd_ttf);
package magick_info_text;                use base qw(gd_ttf);
package magick_scramble_info_text;       use base qw(gd_ttf);
package magick_scramble_fixed_info_text; use base qw(gd_ttf);

1;

__END__
