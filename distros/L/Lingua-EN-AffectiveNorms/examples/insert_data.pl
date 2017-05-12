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

