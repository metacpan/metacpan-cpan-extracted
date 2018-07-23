use strict;
use warnings;
package Graphics::Raylib::Key;

# ABSTRACT: Keyboard Key class
our $VERSION = '0.022'; # VERSION

use Graphics::Raylib::XS qw(:all);
use Carp;
use Scalar::Util qw/blessed/;
require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = (keys => [ grep /^KEY_/, @Graphics::Raylib::XS::EXPORT_OK ]);
Exporter::export_ok_tags('keys');
{
    my %seen;
    push @{$EXPORT_TAGS{all}}, grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} foreach keys %EXPORT_TAGS;
}

sub new {
    my $class = shift;
    my %self = @_;

    return from_keycode($class, $self{keycode}) if exists $self{keycode};
    return from_vinotation($class, $self{map}) if exists $self{map};
    return;
}

my %SPECIAL_KEYCODE_OF = (
    space  => KEY_SPACE,
    esc    => KEY_ESCAPE,
    enter  => KEY_ENTER,
    return => KEY_ENTER,
    cr     => KEY_ENTER,
    bs     => KEY_BACKSPACE,
    right  => KEY_RIGHT,
    left   => KEY_LEFT,
    down   => KEY_DOWN,
    up     => KEY_UP,
    f1     => KEY_F1,
    f2     => KEY_F2,
    f3     => KEY_F3,
    f4     => KEY_F4,
    f5     => KEY_F5,
    f6     => KEY_F6,
    f7     => KEY_F7,
    f8     => KEY_F8,
    f9     => KEY_F9,
    f10    => KEY_F10,
    f11    => KEY_F11,
    f12    => KEY_F12,
    sleft  => KEY_LEFT_SHIFT,
    cleft  => KEY_LEFT_CONTROL,
    aleft  => KEY_LEFT_ALT,
    mleft  => KEY_LEFT_ALT,
    sright => KEY_RIGHT_SHIFT,
    cright => KEY_RIGHT_CONTROL,
    aright => KEY_RIGHT_ALT,
    mright => KEY_RIGHT_ALT,
    s      => [ KEY_LEFT_SHIFT, KEY_RIGHT_SHIFT ],
    shift  => [ KEY_LEFT_SHIFT, KEY_RIGHT_SHIFT ],
    c      => [ KEY_LEFT_CONTROL, KEY_RIGHT_CONTROL ],
    ctrl   => [ KEY_LEFT_CONTROL, KEY_RIGHT_CONTROL ],
    a      => [ KEY_LEFT_ALT, KEY_RIGHT_ALT ],
    alt    => [ KEY_LEFT_ALT, KEY_RIGHT_ALT ],
    m      => [ KEY_LEFT_ALT, KEY_RIGHT_ALT ],
    meta   => [ KEY_LEFT_ALT, KEY_RIGHT_ALT ],
);
my %SPECIAL_VINOTATION_OF = reverse %SPECIAL_KEYCODE_OF;

sub from_vinotation {
    my $class = shift;
    my $self = {
        map => lc(shift),
    };
    $self->{special} = ($self->{map} =~ /<([a-z0-9\-]+)>/);

    if ($self->{special}) {
        $self->{keycode} = $SPECIAL_KEYCODE_OF{$1}
                        // ($1 =~ /^([[:xdigit:]]{4,8})$/ ? hex $1 : undef)
                        // croak 'Unknown keycode';
    } else {
        $self->{keycode} = ord $self->{map};
    }

    bless $self, $class;
    return $self;
}

sub from_keycode {
    my $class = shift;
    my $self = {
        keycode => shift,
        special => 0
    };
    return if $self->{keycode} == -1;

    if (defined ($self->{map} = $SPECIAL_VINOTATION_OF{$self->{keycode}})) {
        $self->{special} = 1;
        $self->{map} = "<$self->{map}>";
    } elsif (chr($self->{keycode}) =~ /^[[:print:]]$/) {
        $self->{map} = chr $self->{keycode}
    } else {
        $self->{special} = 1;
        my $width = $self->{keycode}>0xFFFF ? 8 : 4;
        $self->{map} = sprintf "<%0${width}x>", $self->{keycode};
    }

    bless $self, $class;
    return $self;
}

sub is_special { $_[0]->{special} }

use Data::Dumper;
sub keycode { $_[0]->{keycode} }
sub keycode_eq {
    my ($self, $keycode) = @_;

    $keycode = [$keycode] unless ref($keycode) eq 'ARRAY';
    return scalar grep { $_ == $self->keycode } @$keycode;
}

use overload 'eq' => \&streq, '==' => \&numeq, '""' => \&tostr, '0+' => \&tonum;

sub numeq {
    my ($self, $other) = @_;
    if ((blessed $other) // '' eq 'Graphics::Raylib::Key') {
        $other = $other->keycode;
    }

    return $self->keycode_eq($other);
}
sub streq {
    my ($self, $other, $swapped) = @_;

    unless ((blessed $other) // '' eq 'Graphics::Raylib::Key') {
        $other = Graphics::Raylib::Key->from_vinotation($other);
    }

    return numeq($self, $other, $swapped);
}
sub tostr {
    my $self = shift;
    return $self->{map};
}
sub tonum {
    my $self = shift;
    return $self->keycode;
}
