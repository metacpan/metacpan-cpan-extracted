# -*- perl -*-

require 5.004;
use strict;


require Mail::IspMailGate::Config;
require MIME::Parser;
require File::Basename;


package Mail::IspMailGate::Parser;

$Mail::IspMailGate::Parser::VERSION = '0.01';
@Mail::IspMailGate::Parser::ISA = qw(MIME::Parser);

sub new ($$) {
    my $class = shift;  my %attr = @_;
    $attr{'output_dir'} ||= $Mail::IspMailGate::Config::config->{'tmp_dir'};
    $attr{'output_prefix'} ||= 'part';
    $attr{'output_to_core'} ||= 'NONE';
    $class->SUPER::new(%attr);
}

sub output_path ($$) {
    my($self, $head) = @_;
    my($path) = $self->SUPER::output_path($head);
    my($i) = 0;
    my($opath) = $path;
    while (-f $path) {
	$path = File::Basename::dirname($opath) . "/$i" .
	    File::Basename::basename($opath);
	++$i;
    }
    $path;
}


1;
