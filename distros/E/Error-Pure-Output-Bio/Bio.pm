package Error::Pure::Output::Bio;

use base qw(Exporter);
use strict;
use warnings;

use Readonly;

# Constants.
Readonly::Array our @EXPORT => qw(err_bio);
Readonly::Scalar my $SPACE => q{ };

our $VERSION = 0.01;

# Bio error print.
sub err_bio {
	my @errors = @_;

	my @ret;
	foreach my $error_hr (@errors) {
		my $e = shift @{$error_hr->{'msg'}};
		chomp $e;

		# Title.
		# XXX Add class.
		my $title = '------------- EXCEPTION -------------';
		push @ret, $title;

		# Error.
		push @ret, 'MSG: '.$e;

		# Value.
		while (@{$error_hr->{'msg'}}) {
			my $f = shift @{$error_hr->{'msg'}};
			my $t = shift @{$error_hr->{'msg'}};

			if (! defined $f) {
				last;
			}
			my $ret = 'VALUE: '.$f;
			if ($t) {
				$ret .= ': '.$t;
			}
			push @ret, $ret;
		}

		# Stack trace.
		foreach my $i (0 .. $#{$error_hr->{'stack'}}) {
			my $st = $error_hr->{'stack'}->[$i];
			my $ret = 'STACK: '.$st->{'class'};
			$ret .= $SPACE.$st->{'prog'};
			$ret .= ':'.$st->{'line'};
			push @ret, $ret;
		}

		# Footer.
		my $footer = ('-' x length($title));
		push @ret, $footer;
	}

	return wantarray ? @ret : (join "\n", @ret)."\n";
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Error::Pure::Output::Bio - Output bioperl subroutines for Error::Pure.

=head1 SYNOPSIS

 use Error::Pure::Output::Bio qw(err_bio);

 my $err = err_bio(@errors);
 my @err = err_bio(@errors);

=head1 SUBROUTINES

=head2 C<err_bio>

 my $err = err_bio(@errors);
 my @err = err_bio(@errors);

Bioperl print of backtrace.

Returns string in scalar context.
Returns array of lines in array context.

=head1 EXAMPLE

=for comment filename=err_bio.pl

 use strict;
 use warnings;

 use Error::Pure::Output::Bio qw(err_bio);

 # Fictional error structure.
 my $err_hr = {
         'msg' => [
                 'FOO',
                 'KEY',
                 'VALUE',
         ],
         'stack' => [
                 {
                         'args' => '(2)',
                         'class' => 'main',
                         'line' => 1,
                         'prog' => 'script.pl',
                         'sub' => 'err',
                 }, {
                         'args' => '',
                         'class' => 'main',
                         'line' => 20,
                         'prog' => 'script.pl',
                         'sub' => 'eval {...}',
                 }
         ],
 };

 # Print out.
 print scalar err_bio($err_hr);

 # Output:
 # ------------- EXCEPTION -------------
 # MSG: FOO
 # VALUE: KEY: VALUE
 # STACK: main script.pl:1
 # STACK: main script.pl:20
 # -------------------------------------

=head1 DEPENDENCIES

L<Exporter>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Task::Error::Pure>

Install the Error::Pure modules.

=item L<Error::Pure::Output::Text>

Output subroutines for Error::Pure.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Error-Pure-Output-Bio>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2013-2026

BSD 2-Clause License

=head1 VERSION

0.01

=cut
