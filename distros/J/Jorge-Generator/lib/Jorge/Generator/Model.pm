package Jorge::Generator::Model;

use warnings;
use strict;

=head1 NAME

Jorge::Generator::Model - Jorge based Models generator. Runs with jorge-generate

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.03';

use Data::Dumper;
use Getopt::Long;
use Pod::Usage;
use Carp qw( croak cluck);

=head1 FUNCTIONS

=head2 run

=cut

my @types = qw(
  bit
  char
  datetime
  enum
  int
  text
  timestamp
  varchar
  pk
);

our $char_lenght    = 255;
our $varchar_lenght = 255;
our $int_lenght = 11;


my %sql_types = (
    bit         => 'TINYINT(1) NOT NULL',
    char        => "CHAR($char_lenght) NOT NULL",
    date        => 'DATETIME NOT NULL',
    enum        => 'ENUM("") NOT NULL',
    int       => "INT($int_lenght) NOT NULL",
    pk          => "INT($int_lenght)  NOT NULL AUTO_INCREMENT",
    text        => 'TEXT NOT NULL',
    timestamp   => 'TIMESTAMP  NOT NULL default CURRENT_TIMESTAMP',
    varchar     => "VARCHAR($char_lenght) NOT NULL",
);

sub run {
    pod2usage() unless @ARGV;

    my %config;
    GetOptions(
        'model=s'  => \$config{_model},
        'plural=s' => \$config{_plural},
        'fields=s' => \$config{_fields},
        help       => sub { pod2usage(); },
    ) or pod2usage();

    pod2usage() unless ( $config{_model} && $config{_fields} );

    $config{_model}  = ucfirst( $config{_model} );
    $config{_plural} = ucfirst( $config{_plural} ||  $config{_model} . 's');

    #now, parse the fields we received.
    my @fields = split( /,/, $config{_fields} );
    foreach my $f (@fields) {
        my ( $field, $value ) = split( ':', $f );
        croak "missing param or value" unless $field && $value;
        
        my $its_a_class = $value =~ m/[A-Z](.*)/;
        croak "invalid data type \'$value\' on $field"
          if !( grep { $_ eq $value } @types or $its_a_class );

        $value = ucfirst $value;
        $field = ucfirst $field;

        if ($its_a_class){
            push( @{ $config{_classes} }, $value );
        }
        
        $config{$field} = $value;
        push( @{ $config{_order} }, $field );
    }
    write_file($config{_model}, singular(%config));
    write_file($config{_plural}, plural(%config));

}


sub singular {
    my %config      = @_;
        my @use         = @{$config{_classes}} if defined $config{_classes};
    my @fields_raw  = @{$config{_order}};
    my $use_line    = join( "", map { "use $_;\n" } @use );
    my @fields      = grep { $config{$_} =~ m/[a-z]+/ } @fields_raw;
    
    my $fields_list = join( "\n        ", map { $_ } @fields );
    #note the spacing. must match the number of spaces in the $tmpl var in
    # order to properly allign the fields
    my @pks = grep { $config{$_} eq 'Pk' } @fields;
    my $pks_line        = join("\n        ", map { "$_ => { pk => 1, read_only => 1 }," } @pks);
    my @datetimes       = grep { $config{$_} eq 'Timestamp' ||  $config{$_} eq 'Datetime' } @fields;
    my $datetime_line   = join("\n        ", map { "$_ => { datetime => 1 }," } @datetimes);
    my $classes_line    = join("\n        ", map { "$_ => { class => new $_() }," } @use);
    
    #sql code
    my $sql_pks = join(",",@pks);
    my $sql_fields = join("\n    ", map { "`$_` ". ( $sql_types{lc($config{$_})} || 'INT('.$int_lenght.') NOT NULL ') ." ," } @fields);
    
    
    my $tmpl = <<END;
package $config{_model};
use base 'Jorge::DBEntity';
use Jorge::Plugin::Md5;

#Insert any dependencies here.
#Example:
$use_line

use strict;

sub _fields {
    
    my \$table_name = '$config{_model}';
    
    my \@fields = qw(
        $fields_list
    );

    my \%fields = (
        $pks_line
        $datetime_line
        $classes_line
    );

    return [ \\\@fields, \\\%fields, \$table_name ];
}

1;
__END__
CREATE TABLE IF NOT EXISTS `$config{_model}` (
    $sql_fields
    PRIMARY KEY  (`$sql_pks`)
) ENGINE=MyISAM DEFAULT CHARSET=cp850 AUTO_INCREMENT=1 ;

END

    return $tmpl;
}



sub plural{
    my %config = @_;
    my $tmpl = <<END;
package $config{_plural};
use base 'Jorge::Collection';

use $config{_model};

use strict;

sub create_object {
	return new $config{_model};
}

1;
END
    return $tmpl;
}


sub write_file {
    my ($file, $tmpl) = @_;
    my $path = $file . '.pm';
    open( TEMPLATE, ">", $path ) || die "Can't create file $path $!";
    print TEMPLATE $tmpl;
    close(TEMPLATE);
    return 1;
}

=head1 AUTHOR

Julián Porta, C<< <julian.porta at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-jorge-generator at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Jorge-Generator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Jorge::Generator::Model


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Jorge-Generator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Jorge-Generator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Jorge-Generator>

=item * Search CPAN

L<http://search.cpan.org/dist/Jorge-Generator/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Julián Porta, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of Jorge::Generator::Model

