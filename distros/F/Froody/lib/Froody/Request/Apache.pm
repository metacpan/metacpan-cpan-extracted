=head1 NAME

Froody::Request::Apache

=head1 DESCRIPTION

A Froody request object that slurps its data from a Apache request.

=over 4

=cut

package Froody::Request::Apache;
use warnings;
use strict;
eval q[
  use Apache;
  use Apache::Request;
  1;
];

use Froody::Error;
use Froody::Upload;
use base qw( Froody::Request );

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);

  my $vars = $self->get_params;
  my $method = delete $vars->{method};
  $self->method($method);

  my $type = delete $vars->{'_type'} || delete $vars->{'_froody_type'};
  $self->type($type);
  
  $self->params($vars);
  
  return $self;
}

=item get_params

gets a hash of incoming params from apache, returns a hashref

=cut

sub get_params {
  my $self = shift;

  my $r = Apache->request;
  my $ar = Apache::Request->instance( Apache->request );

  my %vars = map {
    my @results = $ar->param($_);
    @results = map { Encode::decode("utf-8", $_, 1) } @results;
    ( $_ => scalar(@results) > 1 ? [ @results ] : $results[0] );
  } $ar->param();

  foreach my $upload ( $ar->upload ) {
    my $name = $upload->name;
    $vars{$name} = -f $upload->tempname ? Froody::Upload
      ->new->fh($upload->fh)
           ->filename($upload->tempname)
           ->client_filename($upload->filename)
           ->mime_type($upload->info->{'Content-Type'})
    : undef;
  }

  return \%vars;
}

=back

=head1 BUGS

None known.

Please report any bugs you find via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Froody>

=head1 AUTHOR

Copyright Fotango 2005.  All rights reserved.

Please see the main L<Froody> documentation for details of who has worked
on this project.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Froody>, L<Froody::Request>

=cut

1;

