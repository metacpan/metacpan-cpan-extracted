#!/usr/bin/perl

use strict;
use warnings;
use JavaScript::Beautifier qw/js_beautify/;
use Getopt::Long;
use Pod::Usage;
use IO::File;
use Carp qw/croak/;

my $file = pop @ARGV;
pod2usage(1) unless ($file);

my %params;
GetOptions(
	\%params,
	"help|?",
	"o",
	"output=s",
	"s|indent_size=i",
	"c|indent_character=s",
	"p|preserve_newlines",
) or pod2usage(2);

pod2usage(1) if $params{help};

my $file_io;
if ($file eq '-') {
    my $io = new IO::Handle;
    $file_io = $io->fdopen(fileno(STDIN),"r");
} else {
    $file_io = new IO::File($file, "<");
    defined $file_io or croak "can't open $file: $!";
}
local $/;
my $js_source_code = <$file_io>;
$file_io->close;

my $pretty_js = js_beautify( $js_source_code, {
    indent_size => $params{s} || 4,
    indent_character => $params{c} || ' ',
    preserve_newlines => $params{p} || 1
} );

if ( $params{output} or $params{o} ) {
    my $to_file = $params{output} || $file;
    open(my $fh, '>', $to_file) or die("could not open $to_file: $!");
    print $fh $pretty_js;
    close($fh);
} else {
    print $pretty_js;
}

1;
__END__

=head1 NAME

js_beautify.pl - command tool to beautify your javascript files

=head1 SYNOPSIS

    js_beautify.pl [options] FILE
    js_beautify.pl [options] -

=head1 OPTIONS

=over 4

=item B<-?>, B<--help>

=item B<-o>, B<--output>

By default, we will print beautified javascript to STDOUT

if B<-o>, it will override the C<FILE>

if B<-output=newfile.js>, it will write into C<newfile.js>

=item B<-s>, B<--indent_size>

=item B<-c>, B<--indent_character>

By default, we use 4 spaces.

but if you prefer 8 spaces, we can do B<-s=8>

=item B<-p>, B<--preserve_newlines>

1 by default

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut