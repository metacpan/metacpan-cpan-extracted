package Ipv4_networks;
use 5.006001;
use strict;
use warnings;
require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ('all' => [ qw(new class_a class_b class_c)]);
our @EXPORT_OK = (@{$EXPORT_TAGS{'all'}});
our @EXPORT = qw();
our $VERSION = '0.1';
#####################################################
my @network = qw - 128 192 224 240 248 252 254 255 -;
my ($class, $this, @class_a, @class_b, @class_c);
#####################################################
sub new {
	$class = shift or die $!;
	$this = {};
	bless $this, $class;
	return $this;
}
#####################################################
#Public
sub class_a{
		$this = shift or die $!;
		$this->{ip} = shift or die $!;
        foreach (@network){
                secondo($_);
        }
        foreach (@network){
			for (my$i=0; $i<256;$i++){
				secondo_terzo($i,$_);
			}
		}
		foreach (@network){
			for (my$i=0; $i<256;$i++){
				for (my$i2=0; $i2<256;$i2++){
					secondo_terzo_quarto($i,$i2,$_);
				}
			}
		}
		#no push and return, or memory problems.
}
#Public
sub class_b{
		$this = shift;
		$this->{ip} = shift or die $!;
        foreach (@network){
                terzo($_);
        }
        foreach (@network){
			for (my$i = 0; $i <256; $i++){
				terzo_quarto($i,$_);
			}
		}
		return @class_b;
}
#Public
sub class_c{
		$this = shift;
		$this->{ip} = shift or die $!;
        foreach (@network){
                quarto($_);
        }
		return @class_c;
}
##################################################################################################
#Private
sub secondo{
	    my$n = shift;
		my@split = split /\./, $this->{ip};
        my$terminale = trasforma($n, 'secondo');
        my$magic = 256;
        my$blocchida  = $magic-$n;
        my$numeroblocchi = $magic/$blocchida;
        my$salto = 0;
        my$a = "$split[0]."; my$b = "$salto.0.0/$terminale";
        push @class_a, $a.$b;
        print $a.$b."\n";
        for (my$x = 1; $x<$numeroblocchi; $x++){
                my$c = "$split[0]."; my$d = $salto+=$blocchida; my$e = ".0.0/$terminale";
                print $c.$d.$e."\n";
        }
}
#Private
sub secondo_terzo{
		my$first = shift;
		my$n = shift;
		my@split = split /\./, $this->{ip};
        my$terminale = trasforma($n, 'terzo');
        my$magic = 256;
        my$blocchida  = $magic-$n;
        my$numeroblocchi = $magic/$blocchida;
        my$salto = 0;
        $a = "$split[0].$first.$salto.0/$terminale";
        print $a."\n";
        for (my$x = 1; $x<$numeroblocchi; $x++){
			my$b = "$split[0]."; my$c = "$first."; my$d = $salto+=$blocchida; my$e = ".0/$terminale";
			print $b.$c.$d.$e."\n";
        }
	
}
#Private
sub secondo_terzo_quarto{
	my$first = shift;
	my$second = shift;
	my$n = shift;
	my@split = split /\./, $this->{ip};
    my$terminale = trasforma($n, 'quarto');
    my$magic = 256;
    my$blocchida  = $magic-$n;
    my$numeroblocchi = $magic/$blocchida;
    my$salto = 0;
    my$a = "$split[0].$first.$second.$salto/$terminale";
    print  $a."\n";
    for (my$x = 1; $x<$numeroblocchi; $x++){
		my$b = "$split[0]."; my$c = "$first.$second."; my$d = $salto+=$blocchida; my$e = "/$terminale";
		print $b.$c.$d.$e."\n";
    }
}
#Private
sub terzo{
	my$n = shift;
	my@split = split /\./, $this->{ip};
    my$terminale = trasforma($n, 'terzo');
    my$magic = 256;
    my$blocchida  = $magic-$n;
    my$numeroblocchi = $magic/$blocchida;
    my$salto = 0;
    my$a = "$split[0].$split[1]."; my$b = "$salto.0/$terminale";
    push @class_b, $a.$b;
    for (my$x = 1; $x<$numeroblocchi; $x++){
         my$c = "$split[0].$split[1]."; my$d = $salto+=$blocchida; my$e = ".0/$terminale";
         push @class_b, $c.$d.$e;
    }
}
#Private
sub terzo_quarto{
	my$first = shift;
	my$n = shift;
	my@split = split /\./, $this->{ip};
    my$terminale = trasforma($n, 'quarto');
    my$magic = 256;
    my$blocchida  = $magic-$n;
    my$numeroblocchi = $magic/$blocchida;
    my$salto = 0;
    my$a = "$split[0].$split[1].$first.$salto/$terminale"; 
    push @class_b, $a;
    for (my$x = 1; $x<$numeroblocchi; $x++){
         my$b = "$split[0].$split[1]."; my$c = "$first."; my$d = $salto+=$blocchida; my$e = "/$terminale";
         push @class_b, $b.$c.$d.$e;
    }
}
#Private
sub quarto {
        my$n = shift;
		my@split = split /\./, $this->{ip};
        my$terminale = trasforma($n, 'quarto');
        my$magic = 256;
        my$blocchida  = $magic-$n;
        my$numeroblocchi = $magic/$blocchida;
        my$salto = 0;
        my$a = "$split[0].$split[1]."; $b = "$split[2].0/$terminale";
        push @class_c, $a.$b;
        for (my$x = 1; $x<$numeroblocchi; $x++){
                my$c = "$split[0].$split[1].$split[2]."; my$d = $salto+=$blocchida; my$e = "/$terminale";
                push @class_c, $c.$d.$e;
        }
}
#Private
sub trasforma{
        my$n = shift;
        my$metodo = shift;
        my $terminale;
        $terminale = 9 if $n == 128 and $metodo eq 'secondo';
        $terminale = 10 if $n == 192 and $metodo eq 'secondo';
        $terminale = 11 if $n == 224 and $metodo eq 'secondo';
        $terminale = 12 if $n == 240 and $metodo eq 'secondo';
        $terminale = 13 if $n == 248 and $metodo eq 'secondo';
        $terminale = 14 if $n == 252 and $metodo eq 'secondo';
        $terminale = 15 if $n == 254 and $metodo eq 'secondo';
        $terminale = 16 if $n == 255 and $metodo eq 'secondo';
        $terminale = 17 if $n == 128 and $metodo eq 'terzo';
        $terminale = 18 if $n == 192 and $metodo eq 'terzo';
        $terminale = 19 if $n == 224 and $metodo eq 'terzo';
        $terminale = 20 if $n == 240 and $metodo eq 'terzo';
        $terminale = 21 if $n == 248 and $metodo eq 'terzo';
        $terminale = 22 if $n == 252 and $metodo eq 'terzo';
        $terminale = 23 if $n == 254 and $metodo eq 'terzo';
        $terminale = 24 if $n == 255 and $metodo eq 'terzo';
        $terminale = 25 if $n == 128 and $metodo eq 'quarto';
        $terminale = 26 if $n == 192 and $metodo eq 'quarto';
        $terminale = 27 if $n == 224 and $metodo eq 'quarto';
        $terminale = 28 if $n == 240 and $metodo eq 'quarto';
        $terminale = 29 if $n == 248 and $metodo eq 'quarto';
        $terminale = 30 if $n == 252 and $metodo eq 'quarto';
        $terminale = 31 if $n == 254 and $metodo eq 'quarto';
        $terminale = 32 if $n == 255 and $metodo eq 'quarto';
        return $terminale;
}
return 1;

__END__


=head1 NAME

Ipv4_networks - ipv4 networks calculator

=head1 SYNOPSIS

use strict;

use warnings;

use Ipv4_networks;

my$obj = Ipv4_networks->new();

$obj->class_a("X"); #print directly, too big.

my@bit_16 = $obj->class_b("X.X");

my@bit_24 = $obj->class_c("X.X.X");

#################################################

print $_."\n" foreach @bit_16;

print $_."\n" foreach @bit_24;

=head1 DESCRIPTION


ipv4 networks calculator


=head2 EXPORT

None by default.

=head1 SEE ALSO

=head1 AUTHOR

Cladi, E<lt>cladi@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Cladi Di Domenico

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
