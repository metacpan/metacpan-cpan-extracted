package Lemonldap::NG::Common::Logger::Std;

use strict;

our $VERSION = '2.0.15';

sub new {
    no warnings 'redefine';
    my $level = $_[1]->{logLevel} || 'info';
    my $show  = 1;

    foreach (qw(error warn notice info debug)) {
        if ($show) {
            eval
qq'sub $_ {print STDERR "[".localtime."] [LLNG:\$\$] [$_] \$_[1]\n"}';
        }
        else {
            eval qq'sub $_ {1}';
        }
        $show = 0 if ( $level eq $_ );
    }
    die "Unknown logLevel $level" if $show;

    return bless {}, shift;
}

1;
