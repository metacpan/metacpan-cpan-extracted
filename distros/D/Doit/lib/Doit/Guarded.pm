package Doit::Guarded;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(ensure using);

sub ensure (&;@) {
    my $code = shift;
    (ensure => $code, @_);
}

sub using (&) {
    my $code = shift;
    (using => $code, @_);
}

sub new { bless {}, shift }
sub functions { qw(guarded_step) }

sub guarded_step {
    my($doit, $name, %opts) = @_;
    my $ensure = delete $opts{ensure} || Doit::Log::error("ensure is missing");
    my $using  = delete $opts{using}  || Doit::Log::error("using is missing");
    Doit::Log::error("Unhandled options: " . join(" ", %opts)) if %opts;

    if (!$ensure->($doit)) {
	if ($doit->is_dry_run) {
	    Doit::Log::info("$name (dry-run)");
	} else {
	    Doit::Log::info($name);
	    $using->($doit);
	    if (!$ensure->($doit)) {
		Doit::Log::error("'ensure' block for '$name' still fails after running the 'using' block");
	    }
	}
    }
}

1;

__END__
