#!/usr/bin/perl -w

use strict;
use warnings;
use Games::Bingo;

my $version = "0.02";

my $bingo = Games::Bingo->new(90);

my @taken;
init_taken(\@taken);

main();

sub main {
	my $number;
	
	while (1) {

		system("clear");
		print "########################################\n";
		print "           bingo.pl $version\n";
		print "########################################\n";

		show_taken(\@taken);
		
		print "\nNumber = $number\n\n" if $number;

		last unless scalar @{$bingo->{'_numbers'}};

		print "Hit <Return> for next number\n";
		my $v = <STDIN>;

		$number = $bingo->play();
		$bingo->take(\@taken, $number);
	}
}

sub init_taken {
	my $taken = shift;

	for (my $j = 0; $j < 10; $j++) {
		for (my $k = 0; $k < 10; $k++) {
			if (($j == 0 and $k == 0) or ($j == 9 and $k > 0)) {
				$taken->[$j][$k] = "    ";
			} else {
				$taken->[$j][$k] = "[  ]";
			}
		}
	}
}

sub show_taken {
	my $taken = shift;

	for (my $m = 0; $m < 10; $m++) {
		for (my $n = 0; $n < 10; $n++) {
			if ($taken->[$m][$n] =~ m/\d+/) {
				print '['.$taken->[$m][$n].']';
			} else {
				print $taken->[$m][$n]; 
			}
		}
		print "\n";
	}
}

__END__

=head1 NAME

bingo.pl

=cut

=head1 SYNOPSIS

% bingo.pl

=cut

=head1 DESCRIPTION

This is a console bingo game application. With bingo_print.pl from
Games::Bingo::Print you can generate cards and then you are actually
ready to play.

=cut

=head1 SEE ALSO

=over 4

=item Games::Bingo

=item Games::Bingo::Print

=back

=cut

=head1 TODO

The TODO file contains a complete list for the whole Games::Bingo
project.

=cut

=head1 AUTHOR

jonasbn E<gt>jonasbn@cpan.orgE<lt>

=cut

=head1 COPYRIGHT

Games::Bingo and related modules are free software and is released under
the Artistic License. See
E<lt>http://www.perl.com/language/misc/Artistic.htmlE<gt> for details.

Games::Bingo is (C) 2003 Jonas B. Nielsen (jonasbn)
E<gt>jonasbn@cpan.orgE<lt>

=cut
