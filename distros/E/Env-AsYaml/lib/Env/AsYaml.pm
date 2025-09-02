package Env::AsYaml;
# Last modified: Thu Aug 28 2025 12:40:56 PM -04:00 [EDT]
# First created: Sat Aug 09 2025 05:38:14 PM -04:00 [EDT]

use v5.18;
use strict;
use utf8;
use warnings;

=head1 NAME/ABSTRACT

Env::AsYaml is intended to be a tool for examination of the environment in 
which the user is running programs, starting processes or for otherwise
troubleshooting the system. 

=head1 VERSION

Version 0.30

=cut

our $VERSION = '0.30';

=head1 SYNOPSIS

This module checks the environment it's running in and prints it to STDOUT as
YAML. Env vars that are lists (such as C<$PATH>) are formatted in YAML as lists.

    use Env::AsYaml;   # imports 'showPathLists' and 'showScalars'

=cut

use vars qw( @Wanted @Bare );
  # ---------------------- ### ---------------------- #
  BEGIN {
     @Wanted = map { push @Bare=> $_; q%@% .$_ } grep {
                $_ eq "PERL5LIB"
             || $_ eq "PATH"
             || /^XDG_[A-Z]+_DIRS\z/
             || ( /^[_A-Z0-9]+PATH\z/ && !/^XDG_.+_PATH\z/ )
             || /PSModulePath/i   # does not work on cygwin, why?
                  } sort keys %ENV;

      eval "use Env qw/@Wanted/ ;";
  }
  # ---------------------- ### ---------------------- #

use Env::Paths::2yaml;
use Env::Scalars::scalars2yaml;
use YAML::Any;
use Getopt::Std;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(showPathLists showScalars);
use Data::Dump::Color;
$Data::Dump::Color::INDEX = 0;
$Data::Dump::Color::COLOR = 'true';

=head1 EXPORTS

These subroutines are available to import ("@EXPORT_OK").
    showPathLists showScalars

=head1 SUBROUTINES/METHODS

=head2 showPathLists

Use Env::Paths::2yaml to transmute all env path lists into YAML serialization.

=head2 

=cut

sub showPathLists {
    use Env::Paths::2yaml qw( ToYaml );
    my $dd = defined $_[0] ? 'true' : '';
# It's nasty to hard-code it this way but this stuff in my env is just
# in the way:
@Bare = grep { $_ ne 'ORIGINAL_PATH'
            && $_ ne 'AMDRMSDKPATH'
            && $_ ne 'HOMEPATH' } @Bare;

    my( $accumulator , @all_docs );
    for my $kstr ( @Bare ) {
        no strict 'refs'; # a symbolic reference below:
        my $seq = ToYaml( $kstr, @{$kstr} );
        my $yaml_segment = join q[]=> @$seq;
        $accumulator .= qq[\n---\n] . $yaml_segment;
    }
    print $accumulator;

# Load YAML here, to dump the data in color if desired.
    @all_docs = Load( $accumulator );

    if ($dd) { #   Dump as perl data, in vivid technicolor.
        print qq[\n];
        dd( @all_docs );
    }
}

=head2 showScalars

Print simple scalar strings present in the environment.

=cut

use Env::Scalars::scalars2yaml qw( s2yaml );
sub showScalars {
    my $simples = s2yaml();
    my $dd = defined $_[0] ? 'true' : '';
    say qq[\n---];
    say for @$simples;
    if ($dd) {
        dd( $simples );
    }
}

__END__

=head1 AUTHOR

Sören Andersen, C<< <somian08 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-env-asyaml at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Env-AsYaml>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 TESTED-ON

So far, only on Cygwin, Linux and Windows.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Env::AsYaml


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Env-AsYaml>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Env-AsYaml>

=item * Search CPAN

L<https://metacpan.org/release/Env-AsYaml>

=back


=head1 ACKNOWLEDGEMENTS

The fine monks and nuns of Perlmonks (perlmonks.org).

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Sören Andersen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Env::AsYaml
