package Lingua::EN::GeniaTagger;

use strict;
use Class::Spiffy;
use Exporter::Lite;
use IPC::Open2;
use Data::Dumper;

our $VERSION = '0.01';

our @EXPORT = qw(
		 start_genia
		 tag
		 chunk
		 stringify_chunks
		 );

our $PATH;
$PATH = '/home/xern/tmp/geniatagger-2.0.1';
our ($I_GENIA, $O_GENIA);

sub start_genia {
    chdir( $_[0] || $PATH || die "Please specify the path of GENIA") or die $!;
    my $pid = open2($I_GENIA, $O_GENIA, './geniatagger');
}

END {
    close $I_GENIA;
    close $O_GENIA;
}

sub tag {
    my $text = shift or die "Please input text";
    print {$O_GENIA} $text."\n";
    local $_;
    my $result;
    while($_ = <$I_GENIA>){
	last if /\A\n\z/;
	$result .= $_;
    }
    return $result;
}

sub chunk {
    my $sentence = shift;
    my $idx = -1;
    my @chunk = ();
    foreach my $line (split /\n+/, $sentence){
	my ($word, $base, $pos, $chunk) = split /\t/, $line;
	my $entry = [ $word, $base, $pos, $chunk ];
#	print "[ $word, $base, $pos, $chunk ]\n";

	if($chunk =~ /^B-(.+)/){
	    push @{$chunk[++$idx]}, $1, $entry;
	}
	elsif($chunk =~ /^I/){
	    push @{$chunk[$idx]}, $entry;
	}
	elsif($chunk =~ /^O/){
	    if($entry->[2] =~ /\w/){
		push @{$chunk[++$idx]}, $entry->[2], $entry;
	    }
	    else {
		push @{$chunk[++$idx]}, 'PUNCT', $entry;
	    }
	}
    }
    return \@chunk;
}

sub stringify_chunks {
    my $chunk = ref($_[0]) ? shift : chunk($_[0]);
    my $ret;
    foreach my $c (@$chunk){
	my $tag = shift @$c;
	my @token = @$c;
	$ret .= "[$tag ".join (q/ /, map{"$_->[0]/$_->[2]"} @token)." $tag] ";
    }
    $ret;
}





1;

__END__

=pod

=head1 NAME

Lingua::EN::GeniaTagger - There's no fear with this elegant site scraper

=head1 SYSNOPSIS

  use Lingua::EN::GeniaTagger;

  start_genia('/path/to/geniatagger');

  $sentence = 'IL-2 gene expression and NF-kappa B activation through CD28 requires reactive oxygen production by 5-lipoxygenase.');

  my $result = tag($sentence);

  print chunk($sentence);

  print stringify_chunks($sentence);


=head1 DESCRIPT

This module is a perl interface for accessing geniatagger. It
automatically exports four functions. First, you need to specify the
path to geniatagger. Then, you can use tag() to put part-of-speech
tags to text, use chunk(), which returns an array of arrays, to do
shallow parsing, and you can also call stringify_chunks() to stringify
the result derived from chunk().


=head1 SEE ALSO

=head1 AUTHOR & COPYRIGHT

Copyright (C) 2006 by Yung-chung Lin (a.k.a. xern) <xern@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself


=cut

