use strict;
use warnings;

use Test::More;

# this test seems spurious, but it already found warnings ....

BEGIN {
    if ( $INC{'Sub/Util.pm'} ) {
        plan skip_all => "Can't test if Sub::Util is preloaded";
        exit 0;
    }
    if ( $INC{'Sub/Name.pm'} ) {
        plan skip_all => "Can't test if Sub::Name is preloaded";
        exit 0;
    }
    local @INC = @INC;
    unshift @INC, sub {
        die "Hidden" if $_[1] eq 'Sub/Util.pm';
        die "Hidden" if $_[1] eq 'Sub/Name.pm';
        return;
    };
    require Log::Contextual::WarnLogger::Fancy;
    delete $INC{'Sub/Util.pm'};
    delete $INC{'Sub/Name.pm'};
}
my $sub_ident;

BEGIN {
    if ( $INC{'Sub/Util.pm'} or eval { require Sub::Util; 1 } ) {
        $sub_ident = \&Sub::Util::subname;
        note "Using Sub::Util for naming";
    }
    if ( not defined $sub_ident ) {
        if ( $INC{'Sub/Identify.pm'} or eval { require Sub::Identify; 1 } ) {
            $sub_ident = \&Sub::Identify::sub_name;
            note "Using Sub::Identify for naming";
        }
        else {
            plan skip_all =>
              "Need either Sub::Util or Sub::Identify for this test";
            exit 0;
        }
    }
}

my $id = $sub_ident->( \&Log::Contextual::WarnLogger::Fancy::is_info );
note $id;
like( $id, qr/__ANON__/, "Sub is named anonymously" );

done_testing;
