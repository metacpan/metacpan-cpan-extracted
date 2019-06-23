use strict;
use warnings;

=pod

    use lib 'lib';

    use Endoscope;
    my $scope = Endoscope->new();
    $scope->add(__FILE__, __LINE__ + 3, q|$foo|);
    $scope->apply();
    my $foo = 'foo';
    my $bar = 'baz';

    sub blorg {
        print "SDFSD\n";
    }


    my $i = 0;
    while ($i < 100) {
        my $bar = [{a => ["$foo" . " aaaaaagh $i", \&blorg]}];
        $i++;
        sleep 3;
    }

=cut
