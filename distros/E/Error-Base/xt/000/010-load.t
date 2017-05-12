use Test::More tests => 1;

BEGIN {
    $SIG{__DIE__}   = sub {
        warn @_;
        BAIL_OUT( q[Couldn't use module; can't continue.] );    
        
    };
}   

BEGIN {
use Error::Base;                # Simple structured errors with full backtrace
use Error::Base::Cookbook;      # Examples of Error::Base usage
    
}

pass( 'Load modules.' );
diag( "Testing Error::Base $Error::Base::VERSION" );
