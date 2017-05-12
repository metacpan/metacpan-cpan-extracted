package Games::Worms::Beeler;
use strict;
use vars qw($Debug $VERSION @ISA);
use Games::Worms::Base 0.6;
@ISA = ('Games::Worms::Base');
$Debug = 0;
$VERSION = "0.60";

my %let2num = qw(A 1 B 2 C 3 D 4);

=head1 NAME

Games::Worms::Beeler -- class for Conway/Patterson/Beeler worms

=head1 SYNOPSIS

  perl -MGames::Worms -e worms -- -tTk Games::Worms::Beeler/1a2d3cbaa4b

=head1 DESCRIPTION

This class implements Conway/Patterson/Beeler worms -- "Beeler worms"
for short.

See the I<Scientific American> reference in L<Games::Worms>.

Note that my notation for rule-strings is directly taken from that
article.

=cut

#--------------------------------------------------------------------------
# init rules.

sub init {
  my $worm = $_[0];

  $worm->{'memory'} = {}; # for memoization

  $worm->{'rules'} ||=  # default to a random rule
    join('',
         '1', (qw(A B))[rand 2],
         '2', (qw(A B C D))[rand 4],
         '3', (qw(A B C))[rand 3], (qw(A B C))[rand 3],
              (qw(A B C))[rand 3], (qw(A B C))[rand 3],
         '4', (qw(A B))[rand 2],
        );

  die "Rule string $worm->{'rules'} is malformed"
   unless uc($worm->{'rules'}) =~
    /^1([AB])
      2([ABCD])
      3([ABC])([ABC])([ABC])([ABC])
      4([AB])
     $
    /xs;
  @{$worm}{
    qw(beeler_1
       beeler_2
       beeler_3a beeler_3b beeler_3c beeler_3d
       beeler_4
      )
  } = map($let2num{$_}, $1, $2, $3, $4, $5, $6, $7);

  $worm->{'name'} .= '/' . $worm->{'rules'};
  
  $worm->SUPER::init;
  return;
}

#--------------------------------------------------------------------------
# a necessary data table

my %group3rules = (      # A B C
 '00111' => ['beeler_3a', [0,1,2]],
 '01011' => ['beeler_3a', [2,0,1]],

 '10011' => ['beeler_3b', [0,1,2]],
 '01110' => ['beeler_3b', [1,0,2]],

 '11001' => ['beeler_3c', [0,1,2]],
 '10101' => ['beeler_3c', [1,0,2]],

 '11100' => ['beeler_3d', [0,1,2]],
 '11010' => ['beeler_3d', [0,1,2]],

 # the two 'unnatural' cases:
 '01101' => ['beeler_3d', [0,1,2]],
 '10110' => ['beeler_3d', [0,1,2]],


);

#--------------------------------------------------------------------------

sub which_way { # figure out which direction to go in
  my($worm, $hash_r, $list_r, $context) = @_;

  my $situation = substr($context,1);

  return($worm->{'memory'}{$situation})  # memoization
    if exists $worm->{'memory'}{$situation};

  my $rules = $worm->{'rules'};
  die "No rules for worm $worm?\n" unless $rules;

  my $free_count = grep($_, @$list_r);
  my @avail = grep($list_r->[$_], (1,2,3,4,5));
  print "% $free_count nodes free: $situation (@avail) | " if $Debug;

  my($rule, $dir);

  if($free_count >= 5) {      $rule = 'beeler_1';
    splice(@avail,0,3); # leaving just the last 2
  } elsif($free_count == 2) { $rule = 'beeler_4';
  } elsif($free_count == 4) { $rule = 'beeler_2';
  } elsif($free_count == 3) { # Rule 3...
    my $sit_entry = $group3rules{$situation}
     || die "Tilt! Unknown situation $situation\n";
    $rule = $sit_entry->[0];
    $dir = $avail[
                  $sit_entry->[1]->[ $worm->{$rule} - 1 ]
                 ];
  }

  die "No deciding rule?" unless $rule;

  $dir = $avail[ $worm->{$rule} - 1] unless defined($dir);
  print " out of ", join('', @avail),
    ", going R$dir via rule $rule (=", $worm->{$rule}, ")\n"
   if $Debug;

  return( $worm->{'memory'}{$situation} = $dir );
}

#--------------------------------------------------------------------------
1;

__END__

perl worms.pl Games::Worms::Beeler/1A2B3ACAC4B
fig 127: 1A2B3ACAC4B
fig 128: 1B2B3AAAB4A
fig 129: 1a2c3acba4a
fig 130: 1a2d3caaa4b

fig 133: 1a2d3cbaa4b


worm 1:     400 : Games::Worms::Beeler(0)/1a2d3caaa4b
worm 2:     399 : Games::Worms::Beeler(1)/1B2B3AAAB4A
worm 3:     518 : Games::Worms::Beeler(2)/1a2d3cbaa4b

