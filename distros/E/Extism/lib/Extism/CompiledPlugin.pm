package Extism::CompiledPlugin v0.3.1;

use 5.016;
use strict;
use warnings;
use Carp qw(croak);
use Extism::XS qw(
    compiled_plugin_new
    compiled_plugin_free
);
use Exporter 'import';
use Data::Dumper qw(Dumper);
use Devel::Peek qw(Dump);

our @EXPORT_OK = qw(BuildPluginNewParams);

sub BuildPluginNewParams {
    my ($wasm, $opt) = @_;
    my $functions = $opt->{functions} // [];
    my @rawfunctions = map {$$_} @{$functions};
    my %p = (
        wasm => $wasm,
        _functions_array => pack('Q*', @rawfunctions)
    );
    $p{functions} = unpack('Q', pack('P', $p{_functions_array}));
    $p{n_functions} = scalar(@rawfunctions);
    $p{wasi} = $opt->{wasi} // 0;
    $p{fuel_limit} = $opt->{fuel_limit};
    $p{errptr} = "\x00" x 8;
    $p{errmsg} = unpack('Q', pack('P', $p{errptr}));
    \%p
}

sub new {
    my ($name, $wasm, $options) = @_;
    my %opt = %{$options // {}};
    if (defined $opt{fuel_limit}) {
        croak "No way to set fuel for CompiledPlugins yet";
    }
    my $p = BuildPluginNewParams($wasm, \%opt);
    my $compiled = compiled_plugin_new($p->{wasm}, length($p->{wasm}), $p->{functions}, $p->{n_functions}, $p->{wasi}, $p->{errmsg});
    my %savedoptions;
    if ($opt{allow_http_response_headers}) {
        $savedoptions{allow_http_response_headers} = $opt{allow_http_response_headers};
    }
    my %obj = ( compiled => $compiled, options => \%savedoptions);
    bless \%obj, $name
}

sub DESTROY {
    my ($self) = @_;
    $self->{compiled} or return;
    compiled_plugin_free($self->{compiled});
}

1;