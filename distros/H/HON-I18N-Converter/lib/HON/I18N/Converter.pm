package HON::I18N::Converter;

use 5.006;
use strict;
use warnings;

use Encode;
use Spreadsheet::ParseExcel;
use JSON::XS;
use IO::All -utf8;
use Carp;

=head1 NAME

HON::I18N::Converter - perl I18N Converter

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

Convert Excel (2003) i18n file to another format

    use HON::I18N::Converter;

    my $converter = HON::I18N::Converter->new( excel => 'path/to/my/file.xls' );
    $converter->build_properties_file('INI', 'destination/folder/', $comment);
    ...

=head1 DESCRIPTION

perl I18N Converter

=cut

{
  use Object::InsideOut;

  my @workbook : Field : Acc( 'Name' => 'workbook' );

  #Tableau labels
  my @labels : Field : Type('Hash') : Acc( 'Name' => 'labels' );

  #Table de hachage init_args
  my %init_args : InitArgs = (
    'EXCEL' => {
      Regex     => qr/^excel$/i,
      Mandatory => 1,
      Type      => 'Scalar',
    },
  );

  sub init : Init {
    my ( $self, $args ) = @_;

    $self->labels( {} );

    my $parser = Spreadsheet::ParseExcel->new();
    $self->workbook( $parser->parse( $args->{EXCEL} ) );

    if ( !defined $self->workbook ) {
      die $parser->error(), ".\n";
    }
  }

  #Retourne le tableau contenant la liste des langues
  sub p_getLanguage {

    #La fonction shift prend un tableau en argument; elle supprime son premier element
    #(les autres sont alors decales) et renvoie cet element.
    my ($self) = shift;

    #Declaration tableau vide
    my @line = ();

    for my $worksheet ( $self->workbook->worksheets() ) {
      my ( $col_min, $col_max ) = $worksheet->col_range();

      #Recuperation des cellules de la premiere ligne (ligne correspondant a la langue)
      for my $col ( $col_min .. $col_max ) {

        #Valeur de la cellule
        my $cell = $worksheet->get_cell( 0, $col );

        #Va a la prochaine cellule sauf si la cellule est vide
        next unless $cell;

        #Push permet d'ajouter une liste de valeurs scalaires au tableau @line
        push @line, $cell->value();
      }
    }

    #Retourne le tableau contenant la liste des langues
    return @line;
  }

  sub p_buildHash {
    my ( $self, $languages ) = @_;

    #Parcours ligne par ligne
    #Colonne par colonne
    for my $worksheet ( $self->workbook->worksheets() ) {

      my ( $row_min, $row_max ) = $worksheet->row_range();
      my ( $col_min, $col_max ) = $worksheet->col_range();

      for my $row ( 1 .. $row_max ) {

        my $label;

        for my $col ( $col_min .. $col_max ) {
          my $cell = $worksheet->get_cell( $row, $col );
          next unless $cell;

          if ( $col == 0 ) {
            $label = $cell->value();
          }
          else {
            $self->labels->{ $languages->[$col] }->{$label} = $cell->value();
          }
        }
      }
    }
    return;
  }

  #Fonction valable pour le javascript
  sub p_write_JS_i18n {
    my ( $self, $folder, $header ) = @_;

    #En tete du fichier jQuery
    my $content = $header . "(function(\$){\n";

    #Pour encodage
    my $encoder = JSON::XS->new->ascii->pretty->allow_nonref;

    #Parcours d'une table de hachage
    foreach my $lang ( keys %{ $self->labels } ) {

      my $json = $encoder->encode( { strings => $self->labels->{$lang} } );

      #Intitule de chaque section
      $content .= "\$.i18n.$lang = $json;\n";
    }

    #Derniere ligne du document jQuery
    $content .= '})(jQuery);';

    $content > io( $folder . '/jQuery-i18n.js' );
    return;
  }

  #Fonction valable pour le.ini
  sub p_write_INI_i18n {
    my ( $self, $folder, $header ) = @_;

    foreach my $lang ( keys %{ $self->labels } ) {
      my $content = $header;
      foreach my $LAB ( keys %{ $self->labels->{$lang} } ) {
        $content .= ( $LAB . q{=} . $self->labels->{$lang}->{$LAB} . "\n" );
      }
      $content > io( $folder . q{/} . $lang . '.ini' );
    }
    return;
  }

=head1 SUBROUTINES/METHODS

=head2 $self->build_properties_file()

Convert Excel file to INI or Jquery i18n plugin

=cut

  sub build_properties_file {
    my ( $self, $format, $folder, $header ) = @_;
    my @languges = $self->p_getLanguage();
    $self->p_buildHash( \@languges );

    if ( $format eq 'JS' ) {
      return $self->p_write_JS_i18n( $folder, $header );
    }
    elsif ( $format eq 'INI' ) {
      return $self->p_write_INI_i18n( $folder, $header );
    }
    else {
      croak 'Unknown format';
    }
  }
}

=head1 AUTHOR

Samia Chahlal, C<< <samia.chahlal at yahoo.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-hon-i18n-converter at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HON-I18N-Converter>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HON::I18N::Converter


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HON-I18N-Converter>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HON-I18N-Converter>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HON-I18N-Converter>

=item * Search CPAN

L<http://search.cpan.org/dist/HON-I18N-Converter/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Samia Chahlal.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of HON::I18N::Converter
