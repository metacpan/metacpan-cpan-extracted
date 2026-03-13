package MIDI::Drummer::Tiny::Grooves;
$MIDI::Drummer::Tiny::Grooves::VERSION = '0.7002';
our $AUTHORITY = 'cpan:GENE';

use Moo;
use strictures 2;
use MIDI::Drummer::Tiny ();
use namespace::clean;

#pod =head1 SYNOPSIS
#pod
#pod   use MIDI::Drummer::Tiny ();
#pod   use MIDI::Drummer::Tiny::Grooves ();
#pod   # TODO use MIDI::Drummer::Tiny::Grooves qw(:house :rock);
#pod
#pod   my $drummer = MIDI::Drummer::Tiny->new(
#pod     file => "grooves.mid",
#pod     kick => 36,
#pod   );
#pod
#pod   my $grooves = MIDI::Drummer::Tiny::Grooves->new(
#pod     drummer => $drummer,
#pod   );
#pod
#pod   my $all = $grooves->all_grooves;
#pod
#pod   my $groove = $grooves->get_groove;  # random groove
#pod   $groove = $grooves->get_groove(42); # numbered groove
#pod   say $groove->{cat};
#pod   say $groove->{name};
#pod   $groove->{groove}->() for 1 .. 4; # add to score
#pod
#pod   my $set = $grooves->search({}, { cat => 'house' });
#pod   $set = $grooves->search($set, { name => 'deep' });
#pod   my @nums = keys %$set;
#pod   for (1 .. 4) {
#pod     $groove = $set->{ $nums[ rand @nums ] };
#pod     say $groove->{cat};
#pod     say $groove->{name};
#pod     $groove->{groove}->();
#pod   }
#pod
#pod   $grooves->drummer->write;
#pod   # then:
#pod   # > timidity grooves.mid
#pod
#pod =head1 DESCRIPTION
#pod
#pod Return the common grooves, as listed in the "Pocket Operations", that
#pod are L<linked below|/SEE ALSO>.
#pod
#pod A groove is a numbered and named hash reference, with the following
#pod structure:
#pod
#pod   { 1 => {
#pod       cat    => "Basic Patterns",
#pod       name   => "ONE AND SEVEN & FIVE AND THIRTEEN",
#pod       groove => sub {
#pod         $self->drummer->sync_patterns(
#pod         $self->kick  => ['1000001000000000'],
#pod         $self->snare => ['0000100000001000'],
#pod         duration     => $self->duration,
#pod       ),
#pod     },
#pod   },
#pod   2 => { ... }, ... }
#pod
#pod =cut

#pod =head1 ACCESSORS
#pod
#pod =head2 drummer
#pod
#pod   $grooves->drummer($drummer);
#pod   $drummer = $grooves->drummer;
#pod
#pod The L<MIDI::Drummer::Tiny> object. If not given in the constructor, a
#pod new one is created when a method is called.
#pod
#pod =cut

has drummer => (
  is      => 'rw',
  isa     => sub { die "Invalid drummer object" unless ref($_[0]) eq 'MIDI::Drummer::Tiny' },
  default => sub { MIDI::Drummer::Tiny->new },
);

#pod =head2 duration
#pod
#pod   $grooves->duration($duration);
#pod   $duration = $grooves->duration;
#pod
#pod The "resolution" duration that is given to the
#pod L<MIDI::Drummer::Tiny/sync_patterns> method.
#pod
#pod This is initialized to the sixteenth duration of the drummer
#pod L<MIDI::Drummer::Tiny> object.
#pod
#pod =cut

has duration => (
    is => 'lazy',
);
sub _build_duration { shift->drummer->sixteenth }

#pod =head2 kick, rimshot, snare, clap, cowbell, shaker, closed, open, cymbal, hi_tom, mid_tom, low_tom
#pod
#pod   $grooves->kick(36);
#pod   $kick = $grooves->kick;
#pod
#pod The drum patches that are used by the grooves.
#pod
#pod Each is initialized to a corresponding patch of the drummer
#pod L<MIDI::Drummer::Tiny> object that is given to, or created by the
#pod constructor. (So changing these can be done in either the
#pod L<MIDI::Drummer::Tiny> object, or in the C<Groove> constructor.)
#pod
#pod =cut

for my $patch (qw(
    kick
    rimshot
    snare
    clap
    cowbell
    shaker
    closed
    open
    cymbal
    hi_tom
    mid_tom
    low_tom
)) {
    has $patch => (
        is      => 'lazy',
        builder => '_build_' . $patch,
    );
}
sub _build_kick    { shift->drummer->kick }
sub _build_rimshot { shift->drummer->side_stick }
sub _build_snare   { shift->drummer->snare }
sub _build_clap    { shift->drummer->clap }
sub _build_cowbell { shift->drummer->cowbell }
sub _build_shaker  { shift->drummer->maracas }
sub _build_closed  { shift->drummer->closed_hh }
sub _build_open    { shift->drummer->open_hh }
sub _build_cymbal  { shift->drummer->crash1 }
sub _build_hi_tom  { shift->drummer->hi_mid_tom }
sub _build_mid_tom { shift->drummer->low_mid_tom }
sub _build_low_tom { shift->drummer->low_tom }

#pod =head1 METHODS
#pod
#pod =head2 new
#pod
#pod   $grooves = MIDI::Drummer::Tiny::Grooves->new;
#pod   $grooves = MIDI::Drummer::Tiny::Grooves->new(drummer => $drummer);
#pod
#pod Return a new C<MIDI::Drummer::Tiny::Grooves> object.
#pod
#pod =head2 get_groove
#pod
#pod   $groove = $grooves->get_groove($groove_number);
#pod   $groove = $grooves->get_groove; # random groove
#pod   $groove = $grooves->get_groove(0, $set); # random groove of set
#pod   $groove = $grooves->get_groove($groove_number, $set); # numbered groove of set
#pod
#pod Return a numbered or random groove from either the given B<set> or
#pod all known grooves.
#pod
#pod =cut

sub get_groove {
    my ($self, $groove_number, $set) = @_;
    unless (keys %$set) {
        $set = $self->all_grooves;
    }
    unless ($groove_number) {
        my @keys = keys %$set;
        $groove_number = $keys[ int rand @keys ];
    }
    return $set->{$groove_number};
}

#pod =head2 all_grooves
#pod
#pod   $all = $grooves->all_grooves;
#pod
#pod Return all the known grooves as a hash reference.
#pod
#pod =cut

sub all_grooves {
    my ($self) = @_;
    return $self->_grooves();
}

#pod =head2 search
#pod
#pod   $set = $grooves->search({ cat => $x, name => $y }); # search all grooves
#pod   $set = $grooves->search({ cat => $x, name => $y }, $set); # search a subset
#pod
#pod Return the found grooves with names matching the B<cat> or B<name>
#pod strings and given an optional set of grooves to search in.
#pod
#pod =cut

sub search {
    my ($self, $args, $set) = @_;
    unless ($set && keys %$set) {
        $set = $self->all_grooves;
    }
    my $found = {};
    if ($args->{cat}) {
        my $string = lc $args->{cat};
        for my $k (keys %$set) {
            if (lc($set->{$k}{cat}) =~ /$string/) {
                $found->{$k} = $set->{$k};
            }
        }
    }
    if ($args->{name}) {
        my $string = lc $args->{name};
        for my $k (keys %$set) {
            if (lc($set->{$k}{name}) =~ /$string/) {
                $found->{$k} = $set->{$k};
            }
        }
    }
    return $found;
}

sub _grooves {
    my ($self) = @_;

    my %grooves = (

        1 => {
            cat  => "Basic Patterns",
            name => "ONE AND SEVEN & FIVE AND THIRTEEN",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick  => ['1000001000000000'],
                    $self->snare => ['0000100000001000'],
                    duration     => $self->duration,
                ),
            },
        },

        2 => {
            cat  => "Basic Patterns",
            name => "BOOTS N' CATS",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000000010000000'],
                    $self->snare  => ['0000100000001000'],
                    $self->closed => ['1010101010101010'],
                    duration      => $self->duration,
                ),
            },
        },

        3 => {
            cat  => "Basic Patterns",
            name => "TINY HOUSE",
            groove => sub {
                $self->drummer->sync_patterns( # 123456789ABCDEF0
                    $self->kick => ['1000100010001000'],
                    $self->open => ['0010001000100010'],
                    duration    => $self->duration,
                ),
            },
        },

        4 => {
            cat  => "Basic Patterns",
            name => "GOOD TO GO",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick  => ['1001001000100000'],
                    $self->snare => ['0000100000001000'],
                    duration     => $self->duration,
                ),
            },
        },

        5 => {
            cat  => "Basic Patterns",
            name => "HIP HOP",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1010001100000010'],
                    $self->snare  => ['0000100000001000'],
                    $self->closed => ['1010101010101010'],
                    duration      => $self->duration,
                ),
            },
        },

        6 => {
            cat  => "Standard Breaks",
            name => "STANDARD BREAK 1",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000000000100000'],
                    $self->snare  => ['0000100000001000'],
                    $self->closed => ['1010101011101010'],
                    duration      => $self->duration,
                ),
            },
        },

        7 => {
            cat  => "Standard Breaks",
            name => "STANDARD BREAK 2",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000000000100000'],
                    $self->snare  => ['0000100000001000'],
                    $self->closed => ['1010101110100010'],
                    duration      => $self->duration,
                ),
            },
        },

        8 => {
            cat  => "Standard Breaks",
            name => "ROLLING BREAK",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000000100100000'],
                    $self->snare  => ['0000100000001000'],
                    $self->closed => ['1010101010101010'],
                    duration      => $self->duration,
                ),
            },
        },

        9 => {
            cat  => "Standard Breaks",
            name => "THE UNKNOWN DRUMMER",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1001001000100000'],
                    $self->snare  => ['0100100100001000'],
                    $self->closed => ['0110110100000100'],
                    $self->open   => ['0000000010000010'],
                    duration      => $self->duration,
                ),
            },
        },

        10 => {
            cat  => "Rock",
            name => "ROCK 1",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000000110100000'],
                    $self->snare  => ['0000100000001000'],
                    $self->closed => ['1010101010101010'],
                    $self->cymbal => ['1000000000000000'],
                    duration      => $self->duration,
                ),
            },
        },

        11 => {
            cat  => "Rock",
            name => "ROCK 2",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000000110100000'],
                    $self->snare  => ['0000100000001000'],
                    $self->closed => ['1010101010101010'],
                    duration      => $self->duration,
                ),
            },
        },

        12 => {
            cat  => "Rock",
            name => "ROCK 3",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000000110100000'],
                    $self->snare  => ['0000100000001000'],
                    $self->closed => ['1010101010101000'],
                    $self->open   => ['0000000000000010'],
                    duration      => $self->duration,
                ),
            },
        },

        13 => {
            cat  => "Rock",
            name => "ROCK 4",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000000110100000'],
                    $self->snare  => ['0000100000001011'],
                    $self->closed => ['1010101010101000'],
                    $self->open   => ['0000000000000010'],
                    duration      => $self->duration,
                ),
            },
        },

        14 => {
            cat  => "Electro",
            name => "ELECTRO 1 - A",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick  => ['1000001000000000'],
                    $self->snare => ['0000100000001000'],
                    duration     => $self->duration,
                ),
            },
        },

        15 => {
            cat  => "Electro",
            name => "ELECTRO 1 - B",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick  => ['1000001000100010'],
                    $self->snare => ['0000100000001000'],
                    duration     => $self->duration,
                ),
            },
        },

        # nb: ELECTRO 2 - A == ELECTRO 1 - A

        16 => {
            cat  => "Electro",
            name => "ELECTRO 2 - B",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick  => ['1000000000100100'],
                    $self->snare => ['0000100000001000'],
                    duration     => $self->duration,
                ),
            },
        },

        17 => {
            cat  => "Electro",
            name => "ELECTRO 3 - A",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick  => ['1000001000010000'],
                    $self->snare => ['0000100000001000'],
                    duration     => $self->duration,
                ),
            },
        },

        18 => {
            cat  => "Electro",
            name => "ELECTRO 3 - B",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick  => ['1000001000010100'],
                    $self->snare => ['0000100000001000'],
                    duration     => $self->duration,
                ),
            },
        },

        19 => {
            cat  => "Electro",
            name => "ELECTRO 4",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick  => ['1000001000100100'],
                    $self->snare => ['0000100000001000'],
                    duration     => $self->duration,
                ),
            },
        },

        20 => {
            cat  => "Electro",
            name => "SIBERIAN NIGHTS",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000001000000000'],
                    $self->snare  => ['0000100000001000'],
                    $self->closed => ['1011101110111011'],
                    duration      => $self->duration,
                ),
            },
        },

        21 => {
            cat  => "Electro",
            name => "NEW WAVE",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000001011000000'],
                    $self->snare  => ['0000100000001000'],
                    $self->closed => ['1101111111111111'],
                    $self->open   => ['0010000000000000'],
                    $self->shaker => ['0000100000001000'],
                    duration      => $self->duration,
                ),
            },
        },

        22 => {
            cat  => "House",
            name => "HOUSE",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000100010001000'],
                    $self->snare  => ['0000100000001000'],
                    $self->open   => ['0010001000100010'],
                    $self->cymbal => ['1000000000000000'],
                    duration      => $self->duration,
                ),
            },
        },

        23 => {
            cat  => "House",
            name => "HOUSE 2",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000001011000000'],
                    $self->snare  => ['0000100000001000'],
                    $self->closed => ['1101101111011011'],
                    $self->open   => ['0010010000100100'],
                    duration      => $self->duration,
                ),
            },
        },

        24 => {
            cat  => "House",
            name => "BRIT HOUSE",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000001011000000'],
                    $self->snare  => ['0000100000001000'],
                    $self->closed => ['1101110111011101'],
                    $self->open   => ['0010001000100010'],
                    $self->cymbal => ['0010001000100010'],
                    duration      => $self->duration,
                ),
            },
        },

        25 => {
            cat  => "House",
            name => "FRENCH HOUSE",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000001011000000'],
                    $self->snare  => ['0000100000001000'],
                    $self->closed => ['1010101010101010'],
                    $self->open   => ['0101010101010101'],
                    $self->shaker => ['1110101111101011'],
                    duration      => $self->duration,
                ),
            },
        },

        26 => {
            cat  => "House",
            name => "DIRTY HOUSE",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1010100010101001'],
                    $self->snare  => ['0000100000001000'],
                    $self->closed => ['0000000000100001'],
                    $self->open   => ['0010000000000010'],
                    $self->clap   => ['0010100010101000'],
                    duration      => $self->duration,
                ),
            },
        },

        27 => {
            cat  => "House",
            name => "DEEP HOUSE",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000100010001000'],
                    $self->clap   => ['0000100000001000'],
                    $self->closed => ['0100000101000000'],
                    $self->open   => ['0010001000100010'],
                    duration      => $self->duration,
                ),
            },
        },

        28 => {
            cat  => "House",
            name => "DEEPER HOUSE",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick    => ['1000100010001000'],
                    $self->clap    => ['0100000001000000'],
                    $self->open    => ['0010001000110010'],
                    $self->shaker  => ['0001000010000000'],
                    $self->mid_tom => ['0010000100100000'],
                    duration       => $self->duration,
                ),
            },
        },

        29 => {
            cat  => "House",
            name => "SLOW DEEP HOUSE",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000100010001000'],
                    $self->clap   => ['0000100000001000'],
                    $self->closed => ['1000100010001000'],
                    $self->open   => ['0011001101100010'],
                    $self->shaker => ['1111111111111111'],
                    duration      => $self->duration,
                ),
            },
        },

        30 => {
            cat  => "House",
            name => "FOOTWORK - A",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick    => ['1001001010010010'],
                    $self->clap    => ['0000000000001000'],
                    $self->closed  => ['0010000000100000'],
                    $self->rimshot => ['1111111111111111'],
                    duration       => $self->duration,
                ),
            },
        },

        31 => {
            cat  => "House",
            name => "FOOTWORK - B",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick    => ['1001001010010010'],
                    $self->clap    => ['0000000000001000'],
                    $self->closed  => ['0010001100100010'],
                    $self->rimshot => ['1111111111111111'],
                    duration       => $self->duration,
                ),
            },
        },

        32 => {
            cat  => "Miami Bass",
            name => "MIAMI BASS - A",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000001000100100'],
                    $self->snare  => ['0000100000001000'],
                    $self->closed => ['1011101110111011'],
                    duration      => $self->duration,
                ),
            },
        },

        33 => {
            cat  => "Miami Bass",
            name => "MIAMI BASS - B",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000001000000000'],
                    $self->snare  => ['0000100000001000'],
                    $self->closed => ['1011101110111011'],
                    duration      => $self->duration,
                ),
            },
        },

        34 => {
            cat  => "Miami Bass",
            name => "SALLY",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick    => ['1000001000100010'],
                    $self->snare   => ['0000100000001000'],
                    $self->closed  => ['1010101010101010'],
                    $self->low_tom => ['1000001000100010'],
                    duration       => $self->duration,
                ),
            },
        },

        35 => {
            cat  => "Miami Bass",
            name => "ROCK THE PLANET",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1001001000000000'],
                    $self->snare  => ['0000100000001000'],
                    $self->closed => ['1011101110111111'],
                    duration      => $self->duration,
                ),
            },
        },

        36 => {
            cat  => "Hip Hop",
            name => "HIP HOP 1 - A",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick  => ['1000001100010010'],
                    $self->snare => ['0000100000001000'],
                    duration     => $self->duration,
                ),
            },
        },

        37 => {
            cat  => "Hip Hop",
            name => "HIP HOP 1 - B",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick  => ['1000000100010000'],
                    $self->snare => ['0000100000001000'],
                    duration     => $self->duration,
                ),
            },
        },

        38 => {
            cat  => "Hip Hop",
            name => "HIP HOP 2 - A",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick  => ['1000000111010101'],
                    $self->snare => ['0000100000001000'],
                    duration     => $self->duration,
                ),
            },
        },

        39 => {
            cat  => "Hip Hop",
            name => "HIP HOP 2 - B",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick  => ['1000000110010000'],
                    $self->snare => ['0000100000001000'],
                    duration     => $self->duration,
                ),
            },
        },

        40 => {
            cat  => "Hip Hop",
            name => "HIP HOP 3 - A",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick  => ['1010000010100000'],
                    $self->snare => ['0000100000001000'],
                    duration     => $self->duration,
                ),
            },
        },

        41 => {
            cat  => "Hip Hop",
            name => "HIP HOP 3 - B",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick  => ['1010000011010000'],
                    $self->snare => ['0000100000001000'],
                    duration     => $self->duration,
                ),
            },
        },

        42 => {
            cat  => "Hip Hop",
            name => "HIP HOP 4 - A",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick  => ['1001000101100001'],
                    $self->snare => ['0000100000001000'],
                    duration     => $self->duration,
                ),
            },
        },

        43 => {
            cat  => "Hip Hop",
            name => "HIP HOP 4 - B",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick  => ['1010000111100000'],
                    $self->snare => ['0000100000001000'],
                    duration     => $self->duration,
                ),
            },
        },

        44 => {
            cat  => "Hip Hop",
            name => "HIP HOP 5",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick  => ['1010000110100001'],
                    $self->snare => ['0000100000001000'],
                    duration     => $self->duration,
                ),
            },
        },

        45 => {
            cat  => "Hip Hop",
            name => "HIP HOP 6",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1010000000110001'],
                    $self->snare  => ['0000100000001000'],
                    $self->closed => ['1010101010101010'],
                    duration      => $self->duration,
                ),
            },
        },

        46 => {
            cat  => "Hip Hop",
            name => "HIP HOP 7",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000000100100101'],
                    $self->snare  => ['0000100000001000'],
                    $self->closed => ['1010101010101010'],
                    duration      => $self->duration,
                ),
            },
        },

        47 => {
            cat  => "Hip Hop",
            name => "HIP HOP 8",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1001000010110000'],
                    $self->snare  => ['0000100000001000'],
                    $self->closed => ['1101101111011011'],
                    $self->open   => ['0000010000000100'],
                    duration      => $self->duration,
                ),
            },
        },

        48 => {
            cat  => "Hip Hop",
            name => "TRAP - A",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000001000001000'],
                    $self->snare  => ['0000000010000000'],
                    $self->closed => ['1010101010101010'],
                    duration      => $self->duration,
                ),
            },
        },

        49 => {
            cat  => "Hip Hop",
            name => "TRAP - B",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['0010100000000000'],
                    $self->snare  => ['0000000010000000'],
                    $self->closed => ['1110101010101110'],
                    duration      => $self->duration,
                ),
            },
        },

        50 => {
            cat  => "Hip Hop",
            name => "PLANET ROCK - A",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick    => ['1000001000000000'],
                    $self->snare   => ['0000100000001000'],
                    $self->clap    => ['0000100000001000'],
                    $self->closed  => ['1011101110111111'],
                    $self->cowbell => ['1010101101011010'],
                    duration       => $self->duration,
                ),
            },
        },

        51 => {
            cat  => "Hip Hop",
            name => "PLANET ROCK - B",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick    => ['1000001000100100'],
                    $self->snare   => ['0000100000001000'],
                    $self->clap    => ['0000100000001000'],
                    $self->closed  => ['1011101110111111'],
                    $self->cowbell => ['1010101101011010'],
                    duration       => $self->duration,
                ),
            },
        },

        52 => {
            cat  => "Hip Hop",
            name => "INNA CLUB",
            groove => sub {
                $self->drummer->sync_patterns( # 123456789ABCDEF0
                    $self->kick  => ['0010000100100001'],
                    $self->snare => ['0000100000001000'],
                    $self->clap  => ['0000100000001000'],
                    $self->open  => ['1010101010101010'],
                    duration     => $self->duration,
                ),
            },
        },

        53 => {
            cat  => "Hip Hop",
            name => "ICE",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000001000100010'],
                    $self->snare  => ['0000100000001000'],
                    $self->shaker => ['1010101010101010'],
                    duration      => $self->duration,
                ),
            },
        },

        54 => {
            cat  => "Hip Hop",
            name => "BACK TO CALI - A",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000001000000000'],
                    $self->snare  => ['0000100000001000'],
                    $self->clap   => ['0000101010001010'],
                    $self->closed => ['1010101010101010'],
                    duration      => $self->duration,
                ),
            },
        },

        55 => {
            cat  => "Hip Hop",
            name => "BACK TO CALI - B",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000001000100100'],
                    $self->snare  => ['0000100000001000'],
                    $self->clap   => ['1000101010001000'],
                    $self->closed => ['1010101010100010'],
                    $self->open   => ['0000000000001000'],
                    duration      => $self->duration,
                ),
            },
        },

        56 => {
            cat  => "Hip Hop",
            name => "SNOOP STYLES",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick    => ['1001001000010000'],
                    $self->snare   => ['0000100000001000'],
                    $self->clap    => ['0000100000001000'],
                    $self->rimshot => ['0010010010010000'],
                    $self->open    => ['1001001000010000'],
                    duration       => $self->duration,
                ),
            },
        },

        57 => {
            cat  => "Hip Hop",
            name => "THE GROOVE - A",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1001000100010010'],
                    $self->snare  => ['0000100000001000'],
                    $self->shaker => ['0000100000001000'],
                    $self->closed => ['1010101010101010'],
                    $self->open   => ['0000000100000000'],
                    duration      => $self->duration,
                ),
            },
        },

        58 => {
            cat  => "Hip Hop",
            name => "THE GROOVE - B",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick    => ['1001000100010010'],
                    $self->snare   => ['0000100000001000'],
                    $self->shaker  => ['0000100000001000'],
                    $self->closed  => ['1010101010000100'],
                    $self->open    => ['0000000100111010'],
                    $self->hi_tom  => ['0000000001100000'],
                    $self->mid_tom => ['0000000000010100'],
                    $self->low_tom => ['0000000000000011'],
                    duration       => $self->duration,
                ),
            },
        },

        59 => {
            cat  => "Hip Hop",
            name => "BOOM BAP",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick    => ['1010010001000100'],
                    $self->snare   => ['0010001000100010'],
                    $self->clap    => ['0010001000100010'],
                    $self->closed  => ['1111111111111101'],
                    $self->cowbell => ['0000000010000000'],
                    duration       => $self->duration,
                ),
            },
        },

        60 => {
            cat  => "Hip Hop",
            name => "MOST WANTED - A",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000001011000001'],
                    $self->snare  => ['0000100000001000'],
                    $self->clap   => ['0000100000001000'],
                    $self->closed => ['0010101010101010'],
                    $self->cymbal => ['1000000000000000'],
                    duration      => $self->duration,
                ),
            },
        },

        61 => {
            cat  => "Hip Hop",
            name => "MOST WANTED - B",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['0010001011000000'],
                    $self->snare  => ['0000100000001000'],
                    $self->clap   => ['0000100000001000'],
                    $self->closed => ['0010101010101010'],
                    $self->open   => ['0010000000000000'],
                    duration      => $self->duration,
                ),
            },
        },

        62 => {
            cat  => "Funk and Soul",
            name => "AMEN BREAK - A",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1010000000110000'],
                    $self->snare  => ['0000000101001001'],
                    $self->closed => ['1010101010101010'],
                    duration      => $self->duration,
                ),
            },
        },

        63 => {
            cat  => "Funk and Soul",
            name => "AMEN BREAK - B",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick    => ['1010000000110000'],
                    $self->snare   => ['0000100101001001'],
                    $self->rimshot => ['0000100000000000'],
                    $self->closed  => ['1010101010101010'],
                    duration       => $self->duration,
                ),
            },
        },

        64 => {
            cat  => "Funk and Soul",
            name => "AMEN BREAK - C",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick    => ['1010000000100000'],
                    $self->snare   => ['0000100101001001'],
                    $self->rimshot => ['0000000000000010'],
                    $self->closed  => ['1010101010101010'],
                    duration       => $self->duration,
                ),
            },
        },

        65 => {
            cat  => "Funk and Soul",
            name => "AMEN BREAK - D",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1010000000100000'],
                    $self->snare  => ['0100100101000010'],
                    $self->closed => ['1010101010001010'],
                    $self->cymbal => ['0000000000100000'],
                    duration      => $self->duration,
                ),
            },
        },

        66 => {
            cat  => "Funk and Soul",
            name => "THE FUNKY DRUMMER",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1010001000100100'],
                    $self->snare  => ['0000100101011001'],
                    $self->closed => ['1111111011111011'],
                    $self->open   => ['0000000100000100'],
                    duration      => $self->duration,
                ),
            },
        },

        67 => {
            cat  => "Funk and Soul",
            name => "IMPEACH THE PRESIDENT",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000000110000010'],
                    $self->snare  => ['0000100000001000'],
                    $self->closed => ['1010101110001010'],
                    $self->open   => ['0000000000100000'],
                    duration      => $self->duration,
                ),
            },
        },

        68 => {
            cat  => "Funk and Soul",
            name => "WHEN THE LEVEE BREAKS",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1100000100110000'],
                    $self->snare  => ['0000100000001000'],
                    $self->closed => ['1010101010101010'],
                    duration      => $self->duration,
                ),
            },
        },

        69 => {
            cat  => "Funk and Soul",
            name => "IT'S A NEW DAY",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1010000000110001'],
                    $self->snare  => ['0000100000001000'],
                    $self->closed => ['1010101010101010'],
                    duration      => $self->duration,
                ),
            },
        },

        70 => {
            cat  => "Funk and Soul",
            name => "THE BIG BEAT",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1001001010000000'],
                    $self->snare  => ['0000100000001000'],
                    $self->closed => ['0000100000001000'],
                    duration      => $self->duration,
                ),
            },
        },

        71 => {
            cat  => "Funk and Soul",
            name => "ASHLEY'S ROACHCLIP",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick    => ['1010001011000000'],
                    $self->snare   => ['0000100000001000'],
                    $self->closed  => ['1010101010001010'],
                    $self->open    => ['0000000000100000'],
                    $self->cowbell => ['1010101010101010'],
                    duration       => $self->duration,
                ),
            },
        },

        72 => {
            cat  => "Funk and Soul",
            name => "PAPA WAS TOO",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000000110100001'],
                    $self->snare  => ['0000100000001000'],
                    $self->closed => ['0000100010101011'],
                    $self->cymbal => ['0000100000000000'],
                    duration      => $self->duration,
                ),
            },
        },

        73 => {
            cat  => "Funk and Soul",
            name => "SUPERSTITION",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000100010001000'],
                    $self->snare  => ['0000100000001000'],
                    $self->closed => ['1010101111101011'],
                    duration      => $self->duration,
                ),
            },
        },

        74 => {
            cat  => "Funk and Soul",
            name => "CISSY STRUT - A",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1001010001011010'],
                    $self->snare  => ['0000100101100000'],
                    $self->cymbal => ['0000000000001010'],
                    duration      => $self->duration,
                ),
            },
        },

        75 => {
            cat  => "Funk and Soul",
            name => "CISSY STRUT - B",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick  => ['1001000101011010'],
                    $self->snare => ['0010011011000000'],
                    duration     => $self->duration,
                ),
            },
        },

        76 => {
            cat  => "Funk and Soul",
            name => "CISSY STRUT - C",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000100101011010'],
                    $self->snare  => ['0010111001000000'],
                    $self->cymbal => ['0000000000001010'],
                    duration      => $self->duration,
                ),
            },
        },

        77 => {
            cat  => "Funk and Soul",
            name => "CISSY STRUT - D",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1000100101011010'],
                    $self->snare  => ['1010010011000000'],
                    $self->cymbal => ['0000000000001010'],
                    duration      => $self->duration,
                ),
            },
        },

        78 => {
            cat  => "Funk and Soul",
            name => "HOOK AND SLING - A",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1010000001000110'],
                    $self->snare  => ['0000101100101000'],
                    $self->closed => ['1011010011010010'],
                    duration      => $self->duration,
                ),
            },
        },

        79 => {
            cat  => "Funk and Soul",
            name => "HOOK AND SLING - B",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['0000000000000010'],
                    $self->snare  => ['1000110100110011'],
                    $self->closed => ['1101001011001010'],
                    duration      => $self->duration,
                ),
            },
        },

        80 => {
            cat  => "Funk and Soul",
            name => "HOOK AND SLING - C",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1100000000001101'],
                    $self->snare  => ['0010101100110010'],
                    $self->closed => ['1010110101001100'],
                    duration      => $self->duration,
                ),
            },
        },

        81 => {
            cat  => "Funk and Soul",
            name => "HOOK AND SLING - D",
            groove => sub {
                $self->drummer->sync_patterns(
                    $self->kick   => ['1010010000010110'],
                    $self->snare  => ['0000100100100001'],
                    $self->closed => ['1010110100000000'],
                    duration      => $self->duration,
                ),
            },
        },

        # TODO MORE!
        0 => {
            cat  => "",
            name => "",
            groove => sub {
                $self->drummer->sync_patterns(
                                      # 123456789ABCDEF0
                    $self->kick    => ['0000000000000000'],
                    $self->snare   => ['0000000000000000'],
                    $self->rimshot => ['0000000000000000'],
                    $self->clap    => ['0000000000000000'],
                    $self->shaker  => ['0000000000000000'],
                    $self->closed  => ['0000000000000000'],
                    $self->open    => ['0000000000000000'],
                    $self->cowbell => ['0000000000000000'],
                    $self->cymbal  => ['0000000000000000'],
                    $self->hi_tom  => ['0000000000000000'],
                    $self->mid_tom => ['0000000000000000'],
                    $self->low_tom => ['0000000000000000'],
                    duration       => $self->duration,
                ),
            },
        },

    );
    return \%grooves;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Drummer::Tiny::Grooves

=head1 VERSION

version 0.7002

=head1 SYNOPSIS

  use MIDI::Drummer::Tiny ();
  use MIDI::Drummer::Tiny::Grooves ();
  # TODO use MIDI::Drummer::Tiny::Grooves qw(:house :rock);

  my $drummer = MIDI::Drummer::Tiny->new(
    file => "grooves.mid",
    kick => 36,
  );

  my $grooves = MIDI::Drummer::Tiny::Grooves->new(
    drummer => $drummer,
  );

  my $all = $grooves->all_grooves;

  my $groove = $grooves->get_groove;  # random groove
  $groove = $grooves->get_groove(42); # numbered groove
  say $groove->{cat};
  say $groove->{name};
  $groove->{groove}->() for 1 .. 4; # add to score

  my $set = $grooves->search({}, { cat => 'house' });
  $set = $grooves->search($set, { name => 'deep' });
  my @nums = keys %$set;
  for (1 .. 4) {
    $groove = $set->{ $nums[ rand @nums ] };
    say $groove->{cat};
    say $groove->{name};
    $groove->{groove}->();
  }

  $grooves->drummer->write;
  # then:
  # > timidity grooves.mid

=head1 DESCRIPTION

Return the common grooves, as listed in the "Pocket Operations", that
are L<linked below|/SEE ALSO>.

A groove is a numbered and named hash reference, with the following
structure:

  { 1 => {
      cat    => "Basic Patterns",
      name   => "ONE AND SEVEN & FIVE AND THIRTEEN",
      groove => sub {
        $self->drummer->sync_patterns(
        $self->kick  => ['1000001000000000'],
        $self->snare => ['0000100000001000'],
        duration     => $self->duration,
      ),
    },
  },
  2 => { ... }, ... }

=head1 ACCESSORS

=head2 drummer

  $grooves->drummer($drummer);
  $drummer = $grooves->drummer;

The L<MIDI::Drummer::Tiny> object. If not given in the constructor, a
new one is created when a method is called.

=head2 duration

  $grooves->duration($duration);
  $duration = $grooves->duration;

The "resolution" duration that is given to the
L<MIDI::Drummer::Tiny/sync_patterns> method.

This is initialized to the sixteenth duration of the drummer
L<MIDI::Drummer::Tiny> object.

=head2 kick, rimshot, snare, clap, cowbell, shaker, closed, open, cymbal, hi_tom, mid_tom, low_tom

  $grooves->kick(36);
  $kick = $grooves->kick;

The drum patches that are used by the grooves.

Each is initialized to a corresponding patch of the drummer
L<MIDI::Drummer::Tiny> object that is given to, or created by the
constructor. (So changing these can be done in either the
L<MIDI::Drummer::Tiny> object, or in the C<Groove> constructor.)

=head1 METHODS

=head2 new

  $grooves = MIDI::Drummer::Tiny::Grooves->new;
  $grooves = MIDI::Drummer::Tiny::Grooves->new(drummer => $drummer);

Return a new C<MIDI::Drummer::Tiny::Grooves> object.

=head2 get_groove

  $groove = $grooves->get_groove($groove_number);
  $groove = $grooves->get_groove; # random groove
  $groove = $grooves->get_groove(0, $set); # random groove of set
  $groove = $grooves->get_groove($groove_number, $set); # numbered groove of set

Return a numbered or random groove from either the given B<set> or
all known grooves.

=head2 all_grooves

  $all = $grooves->all_grooves;

Return all the known grooves as a hash reference.

=head2 search

  $set = $grooves->search({ cat => $x, name => $y }); # search all grooves
  $set = $grooves->search({ cat => $x, name => $y }, $set); # search a subset

Return the found grooves with names matching the B<cat> or B<name>
strings and given an optional set of grooves to search in.

=head1 SEE ALSO

The "Pocket Operations" at L<https://shittyrecording.studio/>

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2026 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
