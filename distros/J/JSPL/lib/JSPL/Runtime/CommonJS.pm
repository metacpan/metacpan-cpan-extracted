package JSPL::Runtime::CommonJS;
use strict;
use warnings;
use File::Basename qw(dirname);
use IO::File;

our $VERSION = '0.10';

my %MODS = ();
sub _absolute {
    my $path = shift;
    if($path =~ m|^\./(.*)|) {
	$path = dirname($JSPL::This->{module}{id}) . "/$1";
    }
    $path;
}

my @Paths = ();

sub _require {
    my $path = shift;
    $path = _absolute($path);
    my $incs = $MODS{$JSPL::Context::CURRENT};
    return $incs->{$path} if($incs->{$path});
    for(@Paths) {
	my $file = "$_/$path.js";
	if(-r $file) {
	    my $ctx = JSPL::Context->current;
	    my $gbl = $ctx->get_global;
	    my $scope = $ctx->new_object;
	    $scope->{'exports'} = $ctx->new_object($scope);
	    $incs->{$path} = $scope->{'exports'};
	    $scope->{'module'} = $ctx->new_object($scope);
	    $scope->{'module'}{'id'} = $path;
	    $scope->{'require'} = $gbl->{'require'};
	    $ctx->jsc_eval($scope, undef, $file);
	    return $incs->{$path};
	}
    }
    die "Can't open $path\n";
}

our @System = (
    env => \%ENV,
    args => \@main::ARGS,
    platform => 'JSPL commonJS',
    stdout => IO::Handle->new_from_fd(fileno(STDOUT), 'w'),
    stdin => IO::Handle->new_from_fd(fileno(STDIN), 'r'),
    stderr => IO::Handle->new_from_fd(fileno(STDERR), 'w'),
);

$JSPL::Runtime::Plugins{commonJS} = {
    ctxcreate => sub {
	my $ctx = shift;
	$MODS{$ctx->id} = { 
	    program => $ctx->eval(q|var require, exports = {}; exports;|)
	};
	$ctx->bind_all(
	    'require' => \&_require, 
	    'require.paths' => \@Paths,
	    'require.main' => undef
	);
    },
    main => sub {
	my $ctx = shift;
	my $prgname = shift;
	push @Paths, dirname($prgname);
	my $sys = $ctx->new_object;
	while(my($k, $v) = splice(@System, 0,  2)) {
	    $sys->STORE($k, $v);
	}
	$sys->STORE('global', $ctx->get_global);
	$sys->STORE('command', $prgname);
	my $ctl = $ctx->get_controller;
	$ctl->_chktweaks('IO::Handle', $ctl->add('IO::Handle'));
	$MODS{$ctx->id}{'system'} = $sys;
    },
};

1;

__END__

=head1 NAME

JSPL::Runtime::CommonJS - A CommonJS-complaint Runtime

=head1 SYNOPSYS

    use JSPL;

    my $ctx->stock_context('commonJS');
    $ctx->eval(q| 
	var print = function() {
	    var stdout = require("system").stdout;
	    stdout.print.apply(stdout, arguments);
	}
    |);

=head1 DESCRIPTION

This JSPL Runtime plugin implements the emerging CommonJS standards APIs.

=head1 CONFORMACE

A this time, the following CommonJS specifications are implemented:

=over 4

=item *

Modules/1.1.1

=item *

System/1.0

=back

=cut
