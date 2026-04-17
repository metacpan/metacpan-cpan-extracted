package MIDI::Drummer::Tiny::Grooves;
$MIDI::Drummer::Tiny::Grooves::VERSION = '0.7013';
our $AUTHORITY = 'cpan:GENE';

use Moo;
use strictures 2;
# use Data::Dumper::Compact qw(ddc);
use File::ShareDir qw(dist_dir);
use Path::Tiny;
use MIDI::Drummer::Tiny ();
use namespace::clean;

#pod =head1 SYNOPSIS
#pod
#pod   use MIDI::Drummer::Tiny ();
#pod   use MIDI::Drummer::Tiny::Grooves ();
#pod   # TODO use MIDI::Drummer::Tiny::Grooves qw(:house :rock); # maybe
#pod
#pod   my $drummer = MIDI::Drummer::Tiny->new(
#pod     file => "grooves.mid",
#pod     kick => 36,
#pod   );
#pod
#pod   my $grooves = MIDI::Drummer::Tiny::Grooves->new(
#pod     drummer => $drummer
#pod   );
#pod
#pod   my $all = $grooves->all_grooves;
#pod
#pod   my $groove = $grooves->get_groove;  # random groove
#pod   $groove = $grooves->get_groove(42); # numbered groove
#pod   print "42. $groove->{cat}\n$groove->{name}";
#pod   $grooves->groove($groove->{groove}) for 1 .. 4; # add to score
#pod
#pod   my $set = $grooves->search({ cat => 'house' });
#pod   my $pattern = $set->{27}{groove}; # { kick => '...', }
#pod   $set = $grooves->search({ name => 'deep' }, $set); # refine search
#pod
#pod   for my $i (sort keys %$set) {
#pod     $groove = $set->{$i};
#pod     print "$i. $groove->{cat}\n$groove->{name}]\n";
#pod     $grooves->groove($groove->{groove}); # a bit redundant!
#pod   }
#pod
#pod   $grooves->drummer->write;
#pod   # then:
#pod   # > timidity grooves.mid
#pod
#pod =head1 DESCRIPTION
#pod
#pod Return the common grooves, as listed in the "Pocket Operations", that
#pod are L<linked below|/SEE ALSO>. There are a total of 269 known drum
#pod patterns.
#pod
#pod A groove is a numbered and named hash reference, with the following
#pod structure:
#pod
#pod   1 => {
#pod       cat  => "Basic Patterns",
#pod       name => "ONE AND SEVEN & FIVE AND THIRTEEN",
#pod       groove => {
#pod         kick  => { num => $self->kick,  pat => ['1000001000000000'] },
#pod         snare => { num => $self->snare, pat => ['0000100000001000'] },
#pod         ...
#pod       },
#pod   },
#pod
#pod =cut

#pod =head1 ACCESSORS
#pod
#pod =head2 drummer
#pod
#pod   $drummer = $grooves->drummer;
#pod   $grooves->drummer($drummer);
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
#pod   $duration = $grooves->duration;
#pod   $grooves->duration($duration);
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

#pod =head2 kick, rimshot, snare, clap, conga, cowbell, shaker, closed, open, cymbal, hi_tom, mid_tom, low_tom
#pod
#pod   $kick = $grooves->kick;
#pod   $grooves->kick(36);
#pod
#pod The drum patches that are used by the grooves.
#pod
#pod Each is initialized to a corresponding patch of the drummer
#pod L<MIDI::Drummer::Tiny> object that is given to, or created by the
#pod constructor.
#pod
#pod =cut

#pod =head2 return_patterns
#pod
#pod   $return_patterns = $grooves->return_patterns;
#pod
#pod Either return the raw patterns of 16 beats or C<synch>'ed B<drummer>
#pod object phrases from the B<groove()> method.
#pod
#pod Default: C<0>
#pod
#pod =cut

has return_patterns => (
  is      => 'rw',
  isa     => sub { die "Not a Boolean" unless $_[0] =~ /^[01]$/ },
  default => sub { 0 },
);

has _grooves => (
    is      => 'lazy',
    builder => '_build__grooves',
);
sub _build__grooves {
    my ($self) = @_;
    my %mapping = (
        BD => 'kick',
        SN => 'snare',
        RS => 'rimshot',
        CH => 'closed',
        OH => 'open',
        CY => 'cymbal',
        CB => 'cowbell',
        CL => 'clap',
        SH => 'shaker',
        HT => 'hi_tom',
        MT => 'mid_tom',
        LT => 'low_tom',
        HC => 'conga',
    );
    my $file = '/drum-pattern-bit-strings.txt';
    my $path = dist_dir('MIDI-Drummer-Tiny') . $file;
    $path = 'share' . $file unless -e $path;
    my @contents = path($path)->lines;
    my (%grooves, $cat, $name, %patterns);
    my $i = 0;
    for my $line (@contents) {
        chomp $line;
        chop $line if $line =~ /\r$/;
        if ($line =~ /^Instrument/) {
            next;
        }
        elsif ($line =~ /^([A-Z][A-Z]),([01]+)$/) {
            my $mapping = $mapping{$1} || next;
            my $val = { num => $self->$mapping, pat => [$2] };
            $patterns{$mapping} = $val;
        }
        elsif ($line =~ /^\* (.+)$/) {
            $cat = $1;
        }
        else {
            if (keys %patterns) {
                # print ddc \%patterns;
                $grooves{++$i} = {
                    cat    => $cat,
                    name   => $name,
                    groove => { %patterns },
                };
            }
            %patterns = ();
            $name = $line;
        }
    }
    # print ddc \%grooves;
    return \%grooves;
}

for my $patch (qw(
    kick
    rimshot
    snare
    clap
    conga
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
sub _build_conga   { shift->drummer->open_hi_conga }
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
#pod   $grooves = MIDI::Drummer::Tiny::Grooves->new(%arguments);
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

#pod =head2 groove
#pod
#pod   $self->groove(\%patterns);
#pod
#pod Add the patterns to the score. If the B<return_patterns> attribute is
#pod on, the patterns are just returned.
#pod
#pod =cut

sub groove {
    my ($self, $patterns) = @_;
    if ($self->return_patterns) {
        return map { $_ => [ split '', $patterns->{$_}{pat}[0] ] } keys %$patterns;
    }
    else {
        $self->drummer->sync_patterns(
            (map { $patterns->{$_}{num} => $patterns->{$_}{pat} } keys %$patterns),
            duration => $self->duration,
        );
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Drummer::Tiny::Grooves

=head1 VERSION

version 0.7013

=head1 SYNOPSIS

  use MIDI::Drummer::Tiny ();
  use MIDI::Drummer::Tiny::Grooves ();
  # TODO use MIDI::Drummer::Tiny::Grooves qw(:house :rock); # maybe

  my $drummer = MIDI::Drummer::Tiny->new(
    file => "grooves.mid",
    kick => 36,
  );

  my $grooves = MIDI::Drummer::Tiny::Grooves->new(
    drummer => $drummer
  );

  my $all = $grooves->all_grooves;

  my $groove = $grooves->get_groove;  # random groove
  $groove = $grooves->get_groove(42); # numbered groove
  print "42. $groove->{cat}\n$groove->{name}";
  $grooves->groove($groove->{groove}) for 1 .. 4; # add to score

  my $set = $grooves->search({ cat => 'house' });
  my $pattern = $set->{27}{groove}; # { kick => '...', }
  $set = $grooves->search({ name => 'deep' }, $set); # refine search

  for my $i (sort keys %$set) {
    $groove = $set->{$i};
    print "$i. $groove->{cat}\n$groove->{name}]\n";
    $grooves->groove($groove->{groove}); # a bit redundant!
  }

  $grooves->drummer->write;
  # then:
  # > timidity grooves.mid

=head1 DESCRIPTION

Return the common grooves, as listed in the "Pocket Operations", that
are L<linked below|/SEE ALSO>. There are a total of 269 known drum
patterns.

A groove is a numbered and named hash reference, with the following
structure:

  1 => {
      cat  => "Basic Patterns",
      name => "ONE AND SEVEN & FIVE AND THIRTEEN",
      groove => {
        kick  => { num => $self->kick,  pat => ['1000001000000000'] },
        snare => { num => $self->snare, pat => ['0000100000001000'] },
        ...
      },
  },

=head1 ACCESSORS

=head2 drummer

  $drummer = $grooves->drummer;
  $grooves->drummer($drummer);

The L<MIDI::Drummer::Tiny> object. If not given in the constructor, a
new one is created when a method is called.

=head2 duration

  $duration = $grooves->duration;
  $grooves->duration($duration);

The "resolution" duration that is given to the
L<MIDI::Drummer::Tiny/sync_patterns> method.

This is initialized to the sixteenth duration of the drummer
L<MIDI::Drummer::Tiny> object.

=head2 kick, rimshot, snare, clap, conga, cowbell, shaker, closed, open, cymbal, hi_tom, mid_tom, low_tom

  $kick = $grooves->kick;
  $grooves->kick(36);

The drum patches that are used by the grooves.

Each is initialized to a corresponding patch of the drummer
L<MIDI::Drummer::Tiny> object that is given to, or created by the
constructor.

=head2 return_patterns

  $return_patterns = $grooves->return_patterns;

Either return the raw patterns of 16 beats or C<synch>'ed B<drummer>
object phrases from the B<groove()> method.

Default: C<0>

=head1 METHODS

=head2 new

  $grooves = MIDI::Drummer::Tiny::Grooves->new;
  $grooves = MIDI::Drummer::Tiny::Grooves->new(%arguments);

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

=head2 groove

  $self->groove(\%patterns);

Add the patterns to the score. If the B<return_patterns> attribute is
on, the patterns are just returned.

=head1 SEE ALSO

The "Pocket Operations" at L<https://shittyrecording.studio/> (which contains a few typos and duplicates.)

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2026 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
