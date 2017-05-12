package TestDeprecate;


use strict;
use warnings;

use Devel::Deprecate 'deprecate';
use DateTime;
use Carp ();

use base 'Exporter';

our ($CLUCK, $CARP, $CONFESS, $CROAK);
our @EXPORT = qw(
    $CLUCK
    $CARP
    $CONFESS
    $CROAK
    check
    Dump
    is_deprecated
);

{
    no warnings 'redefine';

    # don't want these actually happening!
    *Carp::cluck   = sub { $CLUCK   = shift };
    *Carp::carp    = sub { $CARP    = shift };
    *Carp::confess = sub { $CONFESS = shift; die };
    *Carp::croak   = sub { $CROAK   = shift; die };

    *DateTime::today = sub {
        return DateTime->new(
            year  => 1976,
            month => 1,
            day   => 9,
        );
    };
}

# so the tests pass even if not run through the harness
$ENV{HARNESS_ACTIVE} = 1;
sub check (&) {
    ($CLUCK, $CARP, $CONFESS, $CROAK) = ('', '', '', '');
    eval { shift->() };
}

sub is_deprecated {
    return grep { $_ } $CLUCK, $CARP, $CONFESS, $CROAK;
}

sub Dump {
    require Data::Dumper;
    my $dump = Data::Dumper->Dump( 
        [$CLUCK, $CARP, $CONFESS, $CROAK],
        [qw[*CLUCK *CARP *CONFESS  *CROAK]],
    );
    warn $dump if not defined wantarray;
    return $dump;
}
1;
