package Debug::CodeBlock;
use 5.006; use strict; use warnings; our $VERSION = '0.02';
use base 'Import::Export';

our %EX = ( DEBUG => [qw/all/] );

sub DEBUG (&) {
	my $code = shift;
	my ($package) = caller;
	if (($package->can('DEBUG_ENABLED') && $package->DEBUG_ENABLED) or $ENV{DEBUG_PERL}) {
		$code->();
	}
}

=head1 NAME

Debug::CodeBlock - Add DEBUG codeblocks to your code.

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Use %ENV and set DEBUG_PERL=1

	package House;
	
	sub rooms {
		my $rooms = model('House')->get_rooms();
		DEBUG {
			print "The house has ${rooms} rooms.";
		}
		return $rooms;
	}
	

... or you can define a DEBUG_ENABLED function in your package

	package House;
	
	our $DEBUG = 1;

	sub DEBUG_ENABLED { $DEBUG }
	
	sub rooms {
		my $rooms = model('House')->get_rooms();
		DEBUG {
			print "The house has ${rooms} rooms.";
		}
		return $rooms;
	}


=head1 EXPORT

=head2 DEBUG 

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-debug-codeblock at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Debug-CodeBlock>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Debug::CodeBlock

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Debug-CodeBlock>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Debug-CodeBlock>

=item * Search CPAN

L<https://metacpan.org/release/Debug-CodeBlock>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Debug::CodeBlock
