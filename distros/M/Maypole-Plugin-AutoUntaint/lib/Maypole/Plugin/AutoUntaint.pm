package Maypole::Plugin::AutoUntaint;

use UNIVERSAL::require;

use warnings;
use strict;

use NEXT;

Class::DBI::Plugin::AutoUntaint->require;

=head1 NAME

Maypole::Plugin::AutoUntaint - CDBI::AutoUntaint for Maypole

=cut

our $VERSION = 0.07;

=head1 SYNOPSIS

    package BeerDB;
    use Maypole::Application qw( AutoUntaint );
    
    # instead of this
    #BeerDB::Brewery->untaint_columns( printable => [qw/name notes url/] );
    #BeerDB::Style->  untaint_columns( printable => [qw/name notes/] );
    #BeerDB::Pub->    untaint_columns( printable => {qw/name notes url/] );
    #BeerDB::Beer->   untaint_columns( printable => [qw/abv name price notes/],
    #                                  integer    => [qw/style brewery score/],
    #                                  date       => [ qw/date/],
    #                                  );   
    
    # say this
    BeerDB->auto_untaint;

=over 4

=item setup

Installs the C<Class::DBI::Plugin::AutoUntaint::auto_untaint()> method into the model
class.

=cut

sub setup 
{
    my $r = shift;
    
    # ensure Maypole::setup() is called, which will load the model class
    $r->NEXT::DISTINCT::setup( @_ );

    # insert CDBI::Plugin::AutoUntaint and CDBI::Plugin::Type into the model class
    my $model = $r->config->model ||
        die "Please configure a model in $r before calling auto_untaint()";
    
    no strict 'refs';
    *{"$model\::auto_untaint"} = \&Class::DBI::Plugin::AutoUntaint::auto_untaint;
    
    eval "package $model; use Class::DBI::Plugin::Type";
    
    die $@ if $@;
}

=item auto_untaint( %args )

Takes the same arguments as C<Class::DBI::AutoUntaint::auto_untaint()>, but 
C<untaint_columns> and C<skip_columns> must be further keyed by table:

=over 4

=item untaint_columns
    
    untaint_columns => { $table => { printable => [ qw( name title ) ],
                                     date => [ qw( birthday ) ],
                                     },
                         ...,
                         },
                         
=item skip_columns
   
    skip_columns => { $table => [ qw( secret_stuff internal_data )  ],
                      ...,
                      },
                      
Accepts two additional arguments. C<match_cols_by_table> is the same as the 
C<match_cols> argument, but only applies to specific tables: 

=item match_cols_by_table

    match_cols_by_table => { $table => { qr(^(first|last)_name$) => 'printable',
                                         qr(^.+_event$)          => 'date',
                                         qr(^count_.+$)          => 'integer',
                                         },
                             ...,
                             },
                             
Column regexes here take precedence over any in <match_cols> that are the same.

=item untaint_tables

Specifies the tables to untaint as an arrayref. Defaults to C<<$r->config->{display_tables}>>.

=back

=item debug

The debug level of the Maypole application is passed on to L<Class::DBI::Plugin::AutoUntaint|Class::DBI::Plugin::AutoUntaint>. If set to 1, this 
notes (via C<warn>) each table processed. 

If the debug level is set to 2, it will report the untaint type used for each column.

If debug mode is turned off, this module switches on L<Class::DBI::Plugin::AutoUntaint|Class::DBI::Plugin::AutoUntaint>'s 'strict' mode.

=cut

sub auto_untaint {
    my ( $r, %args ) = @_;
    
    my $untaint_tables = $args{untaint_tables} || $r->config->{display_tables};

    foreach my $table ( @$untaint_tables )
    {
        my %targs = map { $_ => $args{ $_ } } qw( untaint_types match_types );
        
        $targs{untaint_columns} = $args{untaint_columns}->{ $table };
        $targs{skip_columns}    = $args{skip_columns}->{ $table };
        
        $targs{match_columns} = $args{match_columns};
        
        if ( my $more_match_cols = $args{match_columns_by_table}->{ $table } )
        {
            $targs{match_columns}->{ $_ } = $more_match_cols->{ $_ } 
                for keys %$more_match_cols;
        }
                                    
        $targs{debug} = $r->debug;
        
        $targs{strict} = 1 unless $r->debug;
        
        my $class = $r->config->loader->find_class( $table );
        
        die "no class exists for table '$table'" unless $class;
    
        $class->auto_untaint( %targs );
    }
}

=back

=head1 TODO

Tests!

=head1 SEE ALSO

This module wraps L<Class::DBI::Plugin::AutoUntaint|Class::DBI::Plugin::AutoUntaint>, 
which describes the arguments in more detail.

L<Maypole::Plugin::Untaint>.

=head1 AUTHOR

David Baird, C<< <cpan@riverside-cms.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-maypole-plugin-autountaint@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Maypole-Plugin-AutoUntaint>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 David Baird, All Rights Reserved.

=cut

1; # End of Maypole::Plugin::AutoUntaint
