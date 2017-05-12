package Lingua::EN::AffectiveNorms;

use warnings;
use strict;
use File::ShareDir ':ALL';
my $dist = __PACKAGE__;
$dist =~ s/::/-/g;

my $file = dist_file($dist, 'norms.db');


use base qw/DBIx::Class::Schema::Loader/;

__PACKAGE__->loader_options(
    debug         => 1,
);
__PACKAGE__->connection("dbi:SQLite:$file");

1;

__END__

=head1 NAME

Lingua::EN::AffectiveNorms - Perl based data store for the ANEW - standardised
list of Affective Norms for English Words.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module provides data store and retrieval to assess the emotional content
of text based on a standardised list of english words.  It has use in some text
mining procedures (e.g. see ACKNOWLEDGEMENTS section).

DBIx::Class schema (dynamic) to load list of english affective words from
http://csea.phhp.ufl.edu/media/anewmessage.html

 my $schema    = Lingua::EN::AffectiveWords->connect; # db lives in same dir as package by default
 my $all_rs    = $schema->resultset(AllSubjects);
 my $male_rs   = $schema->resultset(Male);
 my $female_rs = $schema->resultset(Female);

The list of words is a bit tricky to obtain (see link above), so this module comes with a blank database stored in the same dir as the .pm file, with the following schema:

 create table all_subjects (
 word varchar(32),
 word_stem varchar(32),
 word_no integer,
 valence_mean float,
 valence_sd float,
 arousal_mean float,
 arousal_sd float,
 dominance_mean float,
 dominance_sd float,
 word_freq float,
 primary key(word)
 );

 create table male (
 word varchar(32),
 word_stem varchar(32),
 word_no integer,
 valence_mean float,
 valence_sd float,
 arousal_mean float,
 arousal_sd float,
 dominance_mean float,
 dominance_sd float,
 word_freq float,
 primary key(word)
 );

 create table female (
 word varchar(32),
 word_stem varchar(32),
 word_no integer,
 valence_mean float,
 valence_sd float,
 arousal_mean float,
 arousal_sd float,
 dominance_mean float,
 dominance_sd float,
 word_freq float,
 primary key(word)
 );

The next thing is to put the male, female and all_subjects lists into separate
csv files, with the headibngs as for the column names in the database, then run
the following perl script on it (also available in the examples dir of the
distribution).

 #!/usr/bin env perl
 use warnings;
 use strict;
 use Text::CSV_XS;
 my $csv = Text::CSV_XS->new;

 use Lingua::Stem qw/stem/;

 my ($infile, $table) = @ARGV or die "infile and table name required";
 die "table should be AllSubjects, Male or Female" unless table ~ /^(AllSubjects|Male|Female)$/)
 my $schema = Lingua::EN::AffectiveNorms::Schema->connect;
 my $rs = $schema->resultset($table);

 open my $IN, "<", $infile;
 my @header;
 while (<$IN>) {
     $csv->parse($_);
     my @row = $csv->fields;
     if ($. == 1) {
         @header = @row;
     }
     else {
         my %data;
         @data{@header} = @row;
         $data{word_stem} = stem($data{word})->[0];
         $rs->create(\%data);
     }
 }

I'd distribute the databse with this module, except that the distribution
conditions of the word list preclude this.


=head1 AUTHOR

Kieren Diment, C<< <zarquon at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lingua-en-affectivenorms at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-EN-AffectiveNorms>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::EN::AffectiveNorms


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-EN-AffectiveNorms>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-EN-AffectiveNorms>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lingua-EN-AffectiveNorms>

=item * Search CPAN

L<http://search.cpan.org/dist/Lingua-EN-AffectiveNorms/>

=item * VC Repository

L<http://github.com/singingfish/Lingua-EN-AffectiveNorms/tree/master>

=back


=head1 ACKNOWLEDGEMENTS

Inspired by the paper Dodds, P., & Danforth, C. (2009). Measuring the Happiness
of Large-Scale Written Expression: Songs, Blogs, and Presidents. Journal of
Happiness Studies. doi: 10.1007/s10902-009-9150-9. avialable (open access)
from: L<http://www.springerlink.com/content/757723154j4w726k>


=head1 COPYRIGHT & LICENSE

Copyright 2009 Kieren Diment, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Lingua::EN::AffectiveNorms
