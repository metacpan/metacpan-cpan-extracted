package X;

use Log::Log4perl::AutoCategorize (alias => 'myLogger',
				   #debug => 'vfmjrabc'
				   );

sub truck {
    myLogger->warn("truckin:", @_);
    myLogger->debug("truckin:", @_);
}

1;

__END__

