# $Id: ExceptionBase.pm,v 1.1.1.1 2006/02/20 00:35:57 toni Exp $
package Luka::ExceptionBase;
use strict;
use warnings;
use vars qw($VERSION); 
use Exception::Class;
use base qw(Exception::Class::Base);
use Error qw(:try);
push @Exception::Class::Base::ISA, 'Error'
    unless Exception::Class::Base->isa('Error');
use Cwd;
use Data::Dumper;
use File::Spec;
use Luka;

$VERSION = '1.1';

sub report {
    my $self = shift;

    $self->{path} = Cwd::cwd();

    my ($vol,$dir,$file) = File::Spec->splitpath($0);

    my $obj = Luka->new({ filename => $file, 
			  error    => $self });

    $obj->report_error();

    return;
}

1;

