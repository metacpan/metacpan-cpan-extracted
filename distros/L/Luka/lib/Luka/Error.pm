# $Id: Error.pm,v 1.1.1.1 2006/02/20 00:35:57 toni Exp $
package Luka::Error;
use strict;
use warnings;
use vars qw($VERSION); 
use Error;
use Data::Dumper;
use Cwd;
use File::Spec;
use base qw(Error::Simple);
use Luka;
$VERSION = '1.00';
$Error::Debug = 1;

sub set_id             { $_[0]->{id}             = $_[1] }
sub set_path           { $_[0]->{path}           = $_[1] }
sub id                 { $_[0]->{id}                     }
sub path               { $_[0]->{path}                   }

sub report {
    my $self = shift;

    $self->set_path( cwd() );

    my ($vol,$dir,$file) = File::Spec->splitpath($0);

    $self->{id}     = "generic"; # this is a class for generic errors

    my $obj = Luka->new({ filename => $file, 
			  error    => $self });
    $obj->report_error();
    return;
}

1;

