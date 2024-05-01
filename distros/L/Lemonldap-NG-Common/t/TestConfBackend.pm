package t::TestConfBackend;

use strict;
use Lemonldap::NG::Common::Conf::Constants;
use Test::More;
our %stats;
our %defaultConf = (
    cfgNum    => 1,
    cfgDate   => time,
    cfgAuthor => 'LLNG Team',
);
our @conf        = ( \%defaultConf );
our $fail_prereq = 0;

our $VERSION = '2.19.0';

sub prereq {
    my $self = shift;

    if ($fail_prereq) {
        $Lemonldap::NG::Common::Conf::msg .= "Module was set to fail\n";
        return 0;
    }
    return 1;
}

sub available {
    $stats{'available'} += 1;
    my @res = map { $_->{cfgNum} } @conf;
    return @res;
}

sub lastCfg {
    $stats{'lastCfg'} += 1;
    my $res = @conf[-1]->{cfgNum};
    return $res;
}

sub isLocked {
    $stats{'isLocked'} += 1;
    return 1;
}

sub unlock {
    $stats{'unlock'} += 1;
    return 1;
}

sub store {
    $stats{'store'} += 1;
    $Lemonldap::NG::Common::Conf::msg = 'Read-only backend!';
    return DATABASE_LOCKED;
}

sub load {
    my ( $self, $num ) = @_;
    $stats{'load'} += 1;
    my @res = grep { $_->{cfgNum} == $num } @conf;
    return { %{ $res[0] } };
}

sub delete {
    $stats{'delete'} += 1;
    $Lemonldap::NG::Common::Conf::msg = 'Read-only backend!';
    return 0;
}

# Reset state, used by tests
sub testReset {
    @conf        = ( \%defaultConf );
    %stats       = ();
    $fail_prereq = 0;
}

sub fail_prereq {
    $fail_prereq = 1;
}

1;
