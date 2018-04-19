package Koha::Contrib::Tamil::Authority::FromBiblioTask;
# ABSTRACT: Task extracting authorities from biblio records
$Koha::Contrib::Tamil::Authority::FromBiblioTask::VERSION = '0.055';
use Moose;

use Koha::Contrib::Tamil::Koha;
use Koha::Contrib::Tamil::RecordReader;
use MARC::Record;
use File::Temp qw( tempfile );
use YAML::Syck;
use List::Util qw( first );
use Locale::TextDomain 'Koha-Contrib-Tamil';


extends 'Koha::Contrib::Tamil::Authority::Task';

has tmp_file_fh => ( is => 'rw' ); 

has tmp_file => ( is => 'rw', isa => 'Str' );

has reader => ( is => 'rw', isa => 'Koha::Contrib::Tamil::RecordReader' );

has output => ( is => 'rw', isa => 'Str' );



sub run {
    my $self = shift;

    my ( $tmp_file_fh, $tmp_file ) = tempfile( $self->output . '.XXXX' );
    binmode( $tmp_file_fh, ":utf8" );
    $self->tmp_file_fh( $tmp_file_fh );
    $self->tmp_file( $tmp_file );

    my $reader = Koha::Contrib::Tamil::RecordReader->new(
        koha => Koha::Contrib::Tamil::Koha->new() ) ;
    $self->reader( $reader );

    my $output = $self->output;
    print __x("Create authorities from biblio records\n" .
              "  source:         Koha DB\n" .
              "  target:         {output}\n" .
              "  temporary file: {tmp_file}\n",
              output => $output, tmp_file => $tmp_file);

    $self->SUPER::run();
}


sub process {
    my $self = shift;
    my $record = $self->reader->read();
    if ( $record ) {
        $self->SUPER::process();
        # print $record->as_formatted(), "\n";
        foreach my $authority ( @{ $self->conf_authorities } ) { # loop on all authority types
            #print "authority: ", $authority->{authcode}, "\n";
            my @bibliotags = @{$authority->{bibliotags}};
            foreach my $tag ( @bibliotags ) { 
                # loop on all biblio tags related to the current authority
                foreach my $field ( $record->field( $tag ) ) {
                    # All field repetitions
                    my $concat = '';
                    foreach my $subfield ( $field->subfields() ) {
                        my ($letter, $value) = @$subfield;
                        next if $letter !~ /[a-zA-Z0-9]/;
                        #chop $value;
                        $value =~ s/^\s+//;
                        $value =~ s/\s+$//;
                    	$value =~ /([\w ,.'-_]+)/;
                    	$value = $1;
                        $value =~ s/^\s+//;
                        $value =~ s/\s+$//;
                        $value =~ s/(;|,|;|!|\?)$//;
                        $value =~ s/\s+$//;
                        $value = ucfirst $value;
                        if ( $authority->{authletters} =~ /$letter/ ) {
                            $concat .= "\t" if $concat;
                            $concat .= "$letter|$value";   
                        }
                    }
                    my $fh = $self->tmp_file_fh;
                    print $fh $authority->{authcode}, "\t$concat\n" 
                        if $concat;
                }
            }
        }
         
        return 1;
    }

    print __x("  bibios count:   {count}",
              count => $self->count), "\n";

    my $tmp_file = $self->tmp_file;
    my $output   = $self->output;

    print __x(
              "Sort and de-duplicate\n" .
              "  source:         {tmp_file}\n" .
              "  target:         {output}\n",
              tmp_file => $tmp_file,
              output => $output );
    system( "sort -f $tmp_file | uniq -i >$output" );

    return 0;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::Tamil::Authority::FromBiblioTask - Task extracting authorities from biblio records

=head1 VERSION

version 0.055

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Fréderic Démians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
