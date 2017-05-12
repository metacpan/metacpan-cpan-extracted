package FabForce::DBDesigner4::SQL::Utils;

use strict;
use warnings;

use base 'Exporter';

our @EXPORT_OK = qw( get_foreign_keys );

our $VERSION     = '0.01';

sub get_foreign_keys{
    my @rels = @_;
    
    my %relations;
    my @foreignKeys;
    
    for my $rel(@rels){
        next unless $rel;
        my $start           = (split(/\./,$rel->[1]))[1];
        my ($table,$target) =  split(/\./,$rel->[2]);
        push(@{$relations{$table}},[$start,$target]);
    }

    for my $key(keys(%relations)){
        my $string  = 'FOREIGN KEY ('.join(',',map{$_->[0]}@{$relations{$key}}).')';
           $string .= " REFERENCES $key(".join(',',map{$_->[1]}@{$relations{$key}}).')';
        push(@foreignKeys,$string)
    }

    return @foreignKeys;
}# getForeignKeys

1;



=pod

=head1 NAME

FabForce::DBDesigner4::SQL::Utils

=head1 VERSION

version 0.31

=head1 SYNOPSIS

  use FabForce::DBDesigner4::SQL::Utils qw(get_foreing_keys);

=head1 DESCRIPTION

As each database system has its own syntax, it is important to provide functions
for each system.

=head1 NAME

FabForce::DBDesigner4::SQL::Utils - some utility functions for SQL generation

=head1 METHODS

=head2 get_foreign_keys

=head1 AUTHOR

Renee Baecker, E<lt>module@renee-baecker.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 - 2009 by Renee Baecker

This program is free software; you can redistribute it and/or
modify it under the terms of the Artistic License version 2.0.

=cut

=head1 AUTHOR

Renee Baecker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0

=cut


__END__

