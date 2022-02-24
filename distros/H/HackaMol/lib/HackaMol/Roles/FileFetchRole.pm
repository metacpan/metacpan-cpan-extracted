package HackaMol::Roles::FileFetchRole;
$HackaMol::Roles::FileFetchRole::VERSION = '0.053';
#ABSTRACT: Role for using LWP::Simple to fetch files from www 
use Moose::Role;
use Carp;
use Path::Tiny;
use HTTP::Tiny;
#use LWP::Simple;
use Data::Dumper;

has 'pdbserver',   is => 'rw', isa => 'Str', lazy => 1, default => 'https://files.rcsb.org/download/';
has 'overwrite',   is => 'rw', isa => 'Bool', lazy => 1, default => 0;

sub _fix_pdbid{
  my $pdbid = shift;
  $pdbid =~ s/\.pdb//; #just in case
  $pdbid .= '.pdb';
  return $pdbid;
}

sub get_pdbid{
  #return pdb contents downloaded from pdb.org
  my $self = shift;
  my $pdbid = _fix_pdbid(shift);  
  my ($ok, $why) = HTTP::Tiny->can_ssl;
  if ($ok){
    my $pdb = HTTP::Tiny->new->get($self->pdbserver.$pdbid);
    return ( $pdb->{content} );
  }
  else {
    warn "$why";
    return 0;
  }
}

sub getstore_pdbid{
  #return array of lines from pdb downloaded from pdb.org
  my $self = shift;
  my $pdbid =  _fix_pdbid(shift); 
  my $fpdbid = shift ;
  $fpdbid = $pdbid unless defined($fpdbid);
  $fpdbid = path($fpdbid);

  if ($fpdbid->exists and not $self->overwrite){
    carp "$fpdbid exists, set self->overwrite(1) to overwrite";
    return $fpdbid->stringify;
  }
  my $pdb = $self->get_pdbid( $pdbid );
  
  if ($pdb){
    $fpdbid->spew($pdb);
    return ( $fpdbid->stringify );
  }
  else{
    warn "could not connect, $fpdbid not written\n";
    return 0;
  }
}

no Moose::Role;
1;

__END__

=pod

=head1 NAME

HackaMol::Roles::FileFetchRole - Role for using LWP::Simple to fetch files from www 

=head1 VERSION

version 0.053

=head1 SYNOPSIS

   use HackaMol;

   my $pdb = $HackaMol->new->get_pdbid("2cba");
   print $pdb;

=head1 DESCRIPTION

FileFetchRole provides attributes and methods for pulling files from the internet.
Currently, the Role has one method and one attribute for interacting with the Protein Database.

=head1 METHODS

=head2 get_pdbid 

fetches a pdb from pdb.org and returns the file in a string.

=head2 getstore_pdbid 

arguments: pdbid and filename for writing (optional). 
Fetches a pdb from pdb.org and stores it in your working directory unless {it exists and overwrite(0)}. If a filename is not
passed to the method, it will write to $pdbid.pdb. use get_pdbid to return contents

=head1 ATTRIBUTES

=head2 overwrite    

isa lazy ro Bool that defaults to 0 (false).  If overwrite(1), then fetched files will be able to overwrite
those of same name in working directory.

=head2 pdbserver  

isa lazy rw Str that defaults to http://pdb.org/pdb/files/

=head1 SEE ALSO

=over 4

=item *

L<http://www.pdb.org>

=item *

L<LWP::Simple>

=back

=head1 AUTHOR

Demian Riccardi <demianriccardi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Demian Riccardi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
