# Example suite shipped with Langertha-Holmgang, to learn the case DSL from:
# a world without a simulator, its one tool described by a handler, and
# three cases built by a generate block from a seed.
# Origin: written for this distribution; the hills, the beacons and the task
# are invented and no real benchmark case (ADR 0003).
# Author: Torsten Raudssus <torsten@raudssus.de>
# License: same terms as Perl itself (Perl_5), like the distribution.
#
# holmgang lint share/suites/demo-beacons
# holmgang export-yaml share/suites/demo-beacons --out /tmp/exported   # the same suite as format 2
# holmgang lint share/suites/demo-beacons --seed demo-beacons=7         # other hills, another suite
use Langertha::Holmgang;

my @HILLS = qw( ashfell brackenhow cragside dunmoor eskrigg fellgate );

suite 'demo-beacons' => sub {
  title       'Demo: a beacon chain, cases from a generator';
  description 'An invented chain of hill beacons; a seeded generate block picks which ones to light.';
  version     1;
  topic       'demo';
  license     'Perl_5';
  source      title   => 'Langertha-Holmgang example suites',
              authors => 'Torsten Raudssus <torsten@raudssus.de>',
              license => 'Perl_5',
              url     => 'https://github.com/Getty/langertha-holmgang';
  threshold   pass_rate => 1;
  system_prompt 'You keep the beacon chain of the hills. Light beacons through the tool, then reply briefly without a tool.';
  settings    max_turns => 6;

  tool light_beacon => (
    description => 'Light the beacon on one hill. A lit beacon stays lit.',
    parameters  => { type => 'object', required => ['hill'],
                     properties => { hill => { type => 'string', enum => [@HILLS] } } },
    handlers    => [ handler match  => { hill => '^(?<hill>[a-z]+)$' },
                             apply  => [ { set => 'beacons.{hill}', value => 'lit' } ],
                             output => 'the beacon is lit' ],
  );

  # the seed picks the hills; the same seed gives the same three cases
  generate seed => 1066, sub {
    my ( $rng ) = @_;
    for my $n ( 1 .. 3 ) {
      my ( $first, $second, $other ) = $rng->shuffle(@HILLS);
      case sprintf( 'light-%02d', $n ) => sub {
        title      'Light the beacons on '.$first.' and '.$second;
        difficulty 'leicht';
        world beacons => { map { ( $_ => 'dark' ) } @HILLS };
        ask 'Light the beacons on '.$first.' and on '.$second.'. Leave every other beacon dark.';
        rule $first.' is lit'  => at 'beacons.'.$first,  equals => 'lit';
        rule $second.' is lit' => at 'beacons.'.$second, equals => 'lit';
        rule 'no other beacon' => unchanged_except [ 'beacons.'.$first, 'beacons.'.$second ];
        solution call( light_beacon => { hill => $first } ), call( light_beacon => { hill => $second } );
        alternative 'the other way round' =>
          call( light_beacon => { hill => $second } ), call( light_beacon => { hill => $first } );
        wrong 'only the first' => call light_beacon => { hill => $first };
        wrong 'a third hill instead of the second' =>
          call( light_beacon => { hill => $first } ), call( light_beacon => { hill => $other } );
      };
    }
  };
};
