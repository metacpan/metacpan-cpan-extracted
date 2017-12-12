#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use Test::More 'no_plan';

######################################################################
# strict

eval q{
    use Doit;
    $strict_violation;
};
like $@, qr{\QGlobal symbol "\E\$\Qstrict_violation" requires explicit package name}, 'import strict works';

eval q{
    use Doit;
    no strict;
    $strict_violation;
};
is $@, '', 'user turning strict off';

eval q{
    use Doit;
    no Doit;
    $strict_violation;
};
is $@, '', 'unimport strict works';

######################################################################
# warnings

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    eval q{
        use Doit;
        my $warnings_violation;
        $warnings_violation == 0;
    };
    like "@warnings", qr{\QUse of uninitialized value\E( \$warnings_violation)?\Q in numeric eq}, 'import warnings works';
}

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    eval q{
        use Doit;
	no warnings;
        my $warnings_violation;
        $warnings_violation == 0;
    };
    is "@warnings", '', 'user turning warnings off';
}

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    eval q{
        use Doit;
	no Doit;
        my $warnings_violation;
        $warnings_violation == 0;
    };
    is "@warnings", '', 'unimport warnings works';
}

__END__
