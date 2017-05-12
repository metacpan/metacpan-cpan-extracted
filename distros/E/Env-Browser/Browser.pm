package Env::Browser;

# Pragmas.
use base qw(Exporter);
use strict;
use warnings;

# Modules.
use Readonly;

# Constants.
Readonly::Array our @EXPORT_OK => qw(run);
Readonly::Scalar our $SPACE => q{ };

# Version.
our $VERSION = 0.05;

# Run browser.
sub run {
	my $uri = shift;

	# Environment $BROWSER variable.
	my $browser_string = $ENV{'BROWSER'};
	if (! $browser_string) {
		return;
	}

	# Split variables.
	my @browser = split m/:/ms, $browser_string;

	# Run.
	while (my $browser = shift @browser) {
		if ($browser =~ m/%s/ms) {
			$browser = sprintf $browser, $uri;
		} else {
			$browser .= $SPACE.$uri;
		}
		if ((system $browser) == 0) {
			last;
		}
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Env::Browser - Process environment variable $BROWSER and run web browser.

=head1 SYNOPSIS

 use Env::Browser qw(run);
 run($uri);

=head1 SUBROUTINES

=over 8

=item B<run($uri)>

 Run browser defined by $BROWSER variable.

=back

=head1 ENVIRONMENT

 $BROWSER variable is defined by L<The BROWSER project|http://www.catb.org/~esr/BROWSER/index.html>.

=head1 EXAMPLE1

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Env::Browser qw(run);

 # Set $BROWSER variable.
 $ENV{'BROWSER'} = 'echo';

 # Run.
 run('http://example.com');

 # Output:
 # http://example.com

=head1 EXAMPLE2

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Env::Browser qw(run);

 # Set $BROWSER variable.
 $ENV{'BROWSER'} = 'echo %s';

 # Run.
 run('http://example.com');

 # Output:
 # http://example.com

=head1 EXAMPLE3

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Env::Browser qw(run);

 # Set $BROWSER variable.
 $ENV{'BROWSER'} = 'foo:echo %s:bar';

 # Run.
 run('http://example.com');

 # Output:
 # http://example.com

=head1 DEPENDENCIES

L<Readonly>.

=head1 SEE ALSO

=over

=item L<urlview>

URL extractor/launcher

=back

=head1 REPOSITORY

L<https://github.com/tupinek/Env-Browser>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2013-2015 Michal Špaček
 BSD 2-Clause License

=head1 VERSION

0.05

=cut
