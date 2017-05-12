package Z;

use Log::Log4perl::AutoCategorize (alias => 'Logger',
				   # debug => 'vfmjrabc'
				   );

sub truck {
    Logger->warn("truckin:", @_);
    Logger->debug("truckin:", @_);
    #Y::myLogger->info("truckin:", @_);
}

1;

__END__

