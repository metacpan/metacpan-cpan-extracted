#!/usr/bin/perl -W
package Finance::Quant::TA;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Finance::Quant::TA ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


	sub logs {
		my $s = shift;
		return [ map {log} @{$s}[0..$#{$s}] ];
	}
	
	sub diff {
		my ($series, $lag) = @_;
		my @diff = map {undef} 1..$lag;
		push @diff, $series->[$_] - $series->[$_-$lag] for ( $lag..$#{$series} );
		return \@diff;
	}
	
	sub ma {
		my ($series, $lag) = @_;
		my @ma = map {undef} 1..$lag;
		for(@{$series}){unless($_){push @ma,undef}else{last}}
		my $sum = 0;
		for my $i ($#ma..$#{$series}) {
			$sum += $series->[$i-$_] for (0..($lag-1));
			push @ma, $sum/($lag);
			$sum = 0;
		}
		return \@ma;
	}
	
	sub stdev {
		my ($series, $lag) = @_;
		my @stdev = map {undef} 1..$lag;
		for(@{$series}){unless($_){push @stdev,undef}else{last}}
		my ($sum, $sum2) = (0, 0);
		for my $i ($#stdev..$#{$series}) {
			for (0..($lag-1)) {
				$sum2 += ($series->[$i-$_])**2;
				$sum += $series->[$i-$_] ;
			}
			push @stdev, ($sum2/$lag - ($sum/$lag)**2)**0.5;
			($sum, $sum2) = (0, 0);
		}
		return \@stdev;
	}

	sub nstdev_ma{
		my ($sd, $ma, $n) = @_;
		my $ans=[[],[]]; 
		for (0..$#{$sd}) {
			my $yn = defined $sd->[$_] && defined $ma->[$_];
			$ans->[0][$_] = $yn ? $ma->[$_] + $n*($sd->[$_]) : undef;
			$ans->[1][$_] = $yn ? $ma->[$_] - $n*($sd->[$_]) : undef;			
		}
		return $ans;
	}






1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Finance::Quant::TA - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Finance::Quant::TA;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Finance::Quant::TA, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

sante zero, E<lt>santex@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by sante zero

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
