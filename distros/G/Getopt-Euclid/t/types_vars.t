BEGIN {
    @ARGV = (
        '--alpha'   , 'aaa',
        '--beta'    , '0.8',
        '--gamma'   , '123',
        '--delta'   , 'asdf',
        '--epsilon' , 'abcdef',
        '--mu'      , '256',
        '--price'   , '$10',
        '--distance', 'km',
    );
}

use Getopt::Euclid qw(:defer);

use Test::More 'no_plan';

no warnings('once');

our $TEST = 'aaa';

our @THRESH;
$THRESH[0] = 0;
$THRESH[1] = 1;

our $VAL = 123;

our %RE;
$RE{letters} = '[a-z]+';

$::STRING = 'abcdefghij';

$Package::EXIT_STATUS = 0;

Getopt::Euclid->process_args(\@ARGV);


is $ARGV{'--alpha'},    'aaa'   ;
is $ARGV{'--beta'} ,     0.8    ;
is $ARGV{'--gamma'},     123    ;
is $ARGV{'--delta'},    'asdf'  ;
is $ARGV{'--epsilon'},  'abcdef';
is $ARGV{'--mu'},        256    ;
is $ARGV{'--price'},    '$10'   ;
is $ARGV{'--distance'}, 'km'    ;

__END__

=head1 OPTIONS

=over

=item --alpha <alpha>

=for Euclid
   alpha.type: string, alpha eq $TEST


=item --beta <beta>

=for Euclid
   beta.type: number, beta > $THRESH[0] && beta < $THRESH[1]


=item --gamma <gamma>

=for Euclid
   gamma.type: number, gamma == $VAL


=item --delta <delta>

=for Euclid
   delta.type: string, delta =~ /$RE{letters}/


=item --epsilon <epsilon>

=for Euclid
   epsilon.type: string, length(epsilon) < length($::STRING)


=item  --mu <mu>

=for Euclid
   mu.type: number, mu != $Package::EXIT_STATUS

=item --price <price>

=for Euclid
     price.type: string, price eq '$10'

=item --distance <distance>

=for Euclid
   distance.type: /km$/

=back
