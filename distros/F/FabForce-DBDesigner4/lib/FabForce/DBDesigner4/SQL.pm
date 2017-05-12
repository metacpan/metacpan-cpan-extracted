package FabForce::DBDesigner4::SQL;

use 5.006001;
use strict;
use warnings;
use Carp;
use IO::File;

use FabForce::DBDesigner4::Table qw(:const);
use FabForce::DBDesigner4::SQL::Mysql;
use FabForce::DBDesigner4::SQL::Sqlite;
use FabForce::DBDesigner4::SQL::Utils qw( get_foreign_keys );

our $VERSION     = 0.8;
our $ERROR       = 0;

sub new{
    my ($class) = @_;
    my $self = bless {},$class;
    return $self;
}# new

sub writeSQL{
    my ($self,$structure,$file,$args) = @_;
    
    return unless ref($structure) eq 'ARRAY';
    
    my $fh = (defined $file) ? IO::File->new(">$file") : \*STDOUT;
    
    unless( ref($fh) =~ /IO::File/ ){
      $fh = \*STDOUT;
    }

    print $fh $self->getSQL($structure,$args);
  
    $fh->close if ref($fh) ne 'GLOB';
}# writeSQL

sub getSQL{
    my ($self,$structure,$args) = @_;
    return unless ref($structure) eq 'ARRAY';
    
    my @statements;
    
    my %types = (
        mysql  => 'FabForce::DBDesigner4::SQL::Mysql',
        sqlite => 'FabForce::DBDesigner4::SQL::Sqlite',
    );
    
    for my $table(@$structure){
        
        if( $args->{type} and exists $types{ $args->{type} } ) {
            my $name   = $types{ $args->{type} };
            my $drop   = $name->drop_table( $table, $args->{sql_options} );
            my $create = $name->create_table( $table, $args->{sql_options} );
            
            push @statements, $drop if $args->{drop_tables};
            push @statements, $create;
            next;
        }
        
        my @columns   = $table->columns();
        my $tablename = $table->name();
        
        my @relations = grep{ $_->[1] =~ /^$tablename\./ }$table->relations();
           @relations = get_foreign_keys( @relations );
        
        my $foreign_keys = "";
           $foreign_keys = join( ",\n  ", @relations ) . ",\n  " 
            if scalar(@relations) > 0;
        
        my $cols_string =  join( ",\n  ", @columns );
           $cols_string =~ s!\s+\z!!;
        
        my $stmt = "CREATE TABLE `$tablename` (\n  $cols_string,\n  ";
        $stmt   .= "PRIMARY KEY(".join(",",$table->key())."),\n  " if(scalar($table->key()) > 0);
        $stmt   .= $foreign_keys; #
        $stmt    =~ s!,\n\s\s\z!\n!;
        $stmt   .= ");\n\n";
        
        
        if( $args->{drop_tables} ) {
            push @statements, "DROP TABLE `$tablename`;\n\n";
        }
    
        push @statements,$stmt;
    }
    
    return @statements;
}

1;



=pod

=head1 NAME

FabForce::DBDesigner4::SQL

=head1 VERSION

version 0.31

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 NAME

FabForce::DBDesigner4::XML - parse XML file

=head1 METHODS

=head2 new

=head2 getSQL

=head2 writeSQL

=head1 AUTHOR

Renee Baecker, E<lt>module@renee-baecker.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 - 2009 by Renee Baecker

This program is free software; you can redistribute it and/or
modify it under the terms of the Artistic License version 2.0.

=head1 AUTHOR

Renee Baecker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0

=cut


__END__
