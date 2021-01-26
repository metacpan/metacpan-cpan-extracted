#! /usr/bin/env perl
@ARGV == 4
	or die "Usage: ./benchmark.pl EXPORTER_MODULE EXPORT_MOD_COUNT EXPORT_IDENT_COUNT CONSUMER_COUNT\n";
my ($exporter_module, $export_mod_count, $exports, $consumers)= @ARGV;
$|= 1;
my $use_module= '';
for my $m (1..$export_mod_count) {
	my $module= join('', map 'sub fn'.$m.'_'.$_.'{ '.$_."}\n", 0..$exports); 
	my $fn_list= join ' ', map 'fn'.$m.'_'.$_, 0..$exports;

	if ($exporter_module eq 'Exporter::Extensible-cwd') {
		unshift @INC, 'lib' unless $INC[0] eq 'lib';
		$module .= 'use Exporter::Extensible -exporter_setup => 1;';
		$module .= 'export(qw( '.$fn_list.' ));';
	}
	elsif ($exporter_module eq 'Exporter::Extensible') {
		$module .= 'use Exporter::Extensible -exporter_setup => 1;';
		$module .= 'export(qw( '.$fn_list.' ));';
	}
	elsif ($exporter_module eq 'Exporter') {
		$module .= 'use parent "Exporter";';
		$module .= '@EXPORT_OK= qw( '.$fn_list.');';
		$module .= '%EXPORT_TAGS= ( all => \@EXPORT_OK );';
	}
	elsif ($exporter_module eq 'Sub::Exporter') {
		$module .= 'use Sub::Exporter -setup => { exports => [qw( '.$fn_list.' )] };';
	}
	elsif ($exporter_module eq 'Exporter::Tiny') {
		$module .= 'use base "Exporter::Tiny";';
		$module .= '@EXPORT_OK= qw( '.$fn_list.');';
		$module .= '%EXPORT_TAGS= ( all => \@EXPORT_OK );';
	}
	else {
		die "Unhandled exporter '$exporter_module'\n";
	}
	eval "package MyModule$m;\n$module;1"
		or die $@;
	$use_module .= "use MyModule$m ':all';";
	$INC{"MyModule$m.pm"}= 1;
}

for (0..$consumers) {
	eval "package Consumer$_; $use_module;1"
		or die $@;
}
