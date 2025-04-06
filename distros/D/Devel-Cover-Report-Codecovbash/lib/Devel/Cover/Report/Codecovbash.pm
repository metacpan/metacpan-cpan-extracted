package Devel::Cover::Report::Codecovbash;

# Nearly all of the code in this package is copied from Pine Mizuna's
# Devel::Cover::Report::Codecov distro. This package simply omits the part of
# the code that sent the coverage to codecov directly. Instead, we write it to
# a file so that we can use codecov's bash script to do the upload instead.

use strict;
use warnings;
use namespace::autoclean;

use File::Spec;
use JSON::MaybeXS qw( encode_json );

our $VERSION = 'v0.41.0'; # VERSION

sub report {
    shift;
    my $db      = shift;
    my $options = shift;

    my $json = _get_codecov_json( $options->{file}, $db );
    my $file = File::Spec->catfile( $options->{outputdir}, 'codecov.json' );
    open my $fh, '>', $file
        or die "Cannot write to $file: $!";
    print {$fh} $json
        or die "Cannot write to $file: $!";
    close $fh
        or die "Cannot write to $file: $!";
}

sub _get_codecov_json {
    my ( $files, $db ) = @_;

    my %coverages = map { _get_file_coverage( $_, $db ) } @$files;
    return encode_json( { coverage => \%coverages, messages => {} } );
}

sub _get_file_coverage {
    my ( $filepath, $db ) = @_;

    my $realpath   = _get_file_realpath($filepath);
    my $lines      = _get_file_lines($realpath);
    my $file       = $db->cover->file($filepath);
    my $statements = $file->statement;
    my $branches   = $file->branch;
    my @coverage   = (undef);

    for my $i ( 1 .. $lines ) {
        unless (defined $statements) {
            push @coverage, undef;
            next;
        }
        my $statement = $statements->location($i);
        my $branch    = defined $branches ? $branches->location($i) : undef;
        push @coverage, _get_line_coverage( $statement, $branch );
    }

    return $realpath => \@coverage;
}

sub _get_file_realpath {
    my $file = shift;

    if ( -d 'blib' ) {
        my $realpath = $file;
        $realpath =~ s/blib\/lib/lib/;

        return $realpath if -f $realpath;
    }

    return $file;
}

sub _get_file_lines {
    my ($file) = @_;

    my $lines = 0;

    open my $fp, '<', $file
        or die "Cannot read $file: $!";
    $lines++ while <$fp>;
    close $fp
        or die "Cannot read $file: $!";

    return $lines;
}

sub _get_line_coverage {
    my ( $statement, $branch ) = @_;

    # If all branches covered or uncoverable, report as all covered
    return $branch->[0]->total . '/' . $branch->[0]->total
        if $branch && !$branch->[0]->error;
    return $branch->[0]->covered . '/' . $branch->[0]->total if $branch;
    return $statement unless $statement;
    return undef if $statement->[0]->uncoverable;
    return $statement->[0]->covered;
}

1;

# ABSTRACT: Generate a JSON file to be uploaded with the codecov bash script.

__END__

=head1 DESCRIPTION

This is a coverage reporter for Codecov. It generates a JSON file that can be
uploaded with the bash script provided by codecov. See
L<https://docs.codecov.io/docs/about-the-codecov-bash-uploader> for details.

The generated file will be named F<codecov.json> and will be in the
F<cover_db> directory by default.

Nearly all of the code in this distribution was simply copied from Pine
Mizune's
L<Devel-Cover-Report-Codecov|https://metacpan.org/release/Devel-Cover-Report-Codecov>
distribution.

=head1 UPLOADING RESULTS

Use the codecov bash script:

    cover -report codecovbash
    bash <(curl -s https://codecov.io/bash) -t token -f cover_db/codecov.json

=head1 SOURCE

The source code repository for Devel-Cover-Report-Codecovbash can be found at
L<https://github.com/perlpunk/Devel-Cover-Report-Codecovbash>.

=head1 AUTHOR

Tina Müller <tinita@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Dave Rolsky Tina Müller

=over 4

=item *

Dave Rolsky <autarch@urth.org>

=item *

Tina Müller <cpan2@tinita.de>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 - 2021 by Pine Mizune.

This is free software, licensed under:

  The MIT (X11) License

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
