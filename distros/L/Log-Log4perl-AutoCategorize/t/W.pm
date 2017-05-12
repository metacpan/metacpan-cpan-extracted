package W;

use Log::Log4perl::AutoCategorize (alias => 'Logger',
				   debug => 'vfmjrabc'
				   );

sub truck {
    Logger->warn("truckin:", @_);
    Logger->debug("truckin:", @_);
    #Y::myLogger->info("truckin:", @_);
}

1;

__END__

# this file turns on debugging output.  Its only used once by 10_multi_pack.t
