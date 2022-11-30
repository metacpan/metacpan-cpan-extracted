package # hide from PAUSE
 FPSetup;

use Import::Into;
use Function::Parameters ();
sub import {
	my ($class) = @_;
	my $target = caller;
	Function::Parameters->import::into( $target,
		{
			fun         => { defaults => 'function_lax'    },
			classmethod => { defaults => 'classmethod_lax' },
			method      => { defaults => 'method_lax'      },
			around      => { defaults => 'around'          },
		}
	);
	return;
}

1;
