use strict;
use Test::More tests => 7;

END { unlink 't/log.out' if -e 't/log.out' }

{
    package Log::Dispatch::Configurator::Hardwired;
    use base qw(Log::Dispatch::Configurator);

    sub new { bless {}, shift }

    sub get_attrs_global {
	my $self = shift;
	return {
	    format => undef,
	    dispatchers => [ qw(file screen) ],
	};
    }

    sub get_attrs {
	my($self, $name) = @_;
	if ($name eq 'file') {
	    return {
		class     => 'Log::Dispatch::File',
		min_level => 'debug',
		filename  => 't/log.out',
		mode      => 'append',
		format    => '[%d] [%p] %m at %F line %L%n',
	    };
	} elsif ($name eq 'screen') {
	    return {
		class     => 'Log::Dispatch::Screen',
		min_level => 'info',
		stderr    => 1,
		format    => '%m',
	    };
	}
    }

    # every time it needs reload
    sub needs_reload { 1 }
}

use Log::Dispatch::Config;

my $config = Log::Dispatch::Configurator::Hardwired->new;
isa_ok $config, 'Log::Dispatch::Configurator';
isa_ok $config, 'Log::Dispatch::Configurator::Hardwired';

Log::Dispatch::Config->configure_and_watch($config);

my $disp = Log::Dispatch::Config->instance;
isa_ok $disp->{outputs}->{file}, 'Log::Dispatch::File';

my $disp2 = Log::Dispatch::Config->instance;
isa_ok $disp->{outputs}->{file}, 'Log::Dispatch::File';

isnt "$disp", "$disp2", "$disp - $disp2";

my $disp3 = Log::Dispatch::Config->instance;
isnt "$disp", "$disp3", "$disp - $disp3";
isnt "$disp2", "$disp3", "$disp2 - $disp3";

