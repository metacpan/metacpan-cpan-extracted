package Language::LispPerl::CoreBindings;
$Language::LispPerl::CoreBindings::VERSION = '0.007';
use strict;
use warnings;

=head1 NAME

Language::LispPerl::CoreBindings - Perl functions binded from core.clp or file.clp

=head1 SYNOPSIS

=head2 In lisp:

  (require "core.clp")
  ( println (. env "USER") )

=cut

# Preloaded methods go here.

# file
sub print {
    print @_;
}

sub openfile {
    my $file = shift;
    my $cb   = shift;
    my $fh;
    open $fh, $file;
    &{$cb}($fh);
    close $fh;
}

sub puts {
    my $fh  = shift;
    my $str = shift;
    print $fh $str;
}

sub readline {
    my $fh = shift;
    return <$fh>;
}

sub readlines {
    my $file = shift;
    my $fh;
    open $fh, "<$file";
    my @lines = <$fh>;
    close $fh;
    return join( "\n", @lines );
}

sub file_exists {
    my $file = shift;
    return \( -e $file );
}

# lib search path
sub use_lib {
    my $path = shift;
    unshift @INC, $path;
}

sub gen_name {
    return "gen-" . rand;
}

# regexp
sub match {
    my $regexp = shift;
    my $str    = shift;
    my @m      = ( $str =~ qr($regexp) );
    return \@m;
}

sub get_env {
    my $name = shift;
    return $ENV{$name};
}

1;
