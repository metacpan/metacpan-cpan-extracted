# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Helpers::DBSerialize;
use strict;
use warnings;

# Serialize/deserialize complex data structures in a way compatible to a
# postgres TEXT field (achieved through Storable and Base64 encoding)

use base qw(Exporter);
our @EXPORT = qw(dbfreeze dbthaw dbderef); ## no critic (Modules::ProhibitAutomaticExportation)
our $VERSION = 0.995;

use YAML::Syck;
use Carp;

sub dbfreeze {
    my ($data) = @_;

    if(!defined($data)) {
        croak('$data is undefined in dbfreeze');
    } elsif(ref($data) eq "REF") {
        return Dump($data);
    } else {
        return Dump(\$data);
    }
      
}

sub dbthaw {
    my ($data) = @_;
    
    return Load($data);
}

sub dbderef {
    my ($val) = @_;
    
    return if(!defined($val));
    
    while(ref($val) eq "SCALAR" || ref($val) eq "REF") {
        $val = $$val;
        last if(!defined($val));
    }
    
    return $val;
}

1;
__END__

=head1 NAME

Maplat::Helpers::DBSerialize - serialize data structures for saving them into a database text field

=head1 SYNOPSIS

  use Maplat::Helpers::DBSerialize;
  
  my $textstring = dbfreeze($reftodata);
  my $reftodata = dbthaw($textstring);

=head1 DESCRIPTION

This module provides functions to encode data structures in a way so they can be saved to
non-binary text strings in databases (like the "text" data type in PostgreSQL).

Internally, it uses Storable and MIME::Base64 to do its job.

=head2 dbfreeze

Takes one argument, the reference to the data structure to be encoded. Returns a text string.

=head2 dbthaw

Takes one argument, a text string encoded by dbfreeze(). Returns a reference to a data structure.

=head2 dbderef

Takes one argument, a scalar that (possibly) needs derefencing. This is a helper function that should(tm) do
the right things in most of the cases and return the correctly derefenced scalar. YMMV

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
