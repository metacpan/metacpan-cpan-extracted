package Froody::Pod;
use warnings;
use strict;

use Froody::Dispatch;
use Data::Dumper;

=head1 NAME

Froody::Pod

=head1 SYNOPSIS

  use Froody::Pod;
  Froody::Pod->run( 'My::Froody::API' );

=head1 DESCRIPTION

Create a POD file for L<Froody> services.

=head2 Methods

=over

=item run( api )

Passed the name of a subclass of L<Froody::API>, this documents the API
to STDOUT as a POD file.

=cut

sub run {
  my ($class, @args) = @_;

  my ($client,$args)  = Froody::Dispatch->cli_config(@args);
  my @methods = $client->get_methods();
  
  print "=head1 NAME\n\n";
  my $filters = $args->{filters} || 'all available methods';
  print "\n\n";
  
  print "=head1 DESCRIPTION\n\n";
  print "Froody API documentation\n\n";
  
  print "=head2 Methods\n\n";
  
  print "=over\n\n";
  
  for my $method(sort {$a->full_name() cmp $b->full_name()} @methods) {
    _print_method($method);
  }
  print "=back\n\n";
}


sub _print_method {
  my $method = shift;
  
  print "=item B<" . $method->full_name() . ">\n\n";
  print "  " .$method->description . "\n\n";
  
  _print_arguments($method);
  _print_errors($method);
  _print_response($method);
}

sub _print_arguments {
  my $method = shift;
  print "=over 2\n\n";
  print "=head3 Arguments\n\n";
  if (my %arguments = %{$method->arguments()}) {
    for my $name (keys(%arguments)) {
      my $argument = $arguments{$name};
      print "=item $name\n\n";
      print "Type:        " . join(",",@{$argument->{type}}) . "\n\n";
      print "Description: $argument->{doc}\n\n";
      print "Required:    ";
      print $argument->{optional} ? "optional\n\n" : "required\n\n";
    }
  } else {
    print "None\n\n";
  }
  print "=back\n\n";
}

sub _print_errors {
  my $method = shift;
  print "=over 2\n\n";
  print "=head3 Errors\n\n";
  if (my %errors = %{$method->errors()}) {
    for my $code (keys(%errors)) {
      my $error = $errors{$code};
      print "=item $code\n\n";
      print "$error->{description}\n\n";
    }
  } else {
    print "None\n\n";
  }
  print "=back\n\n";
}

sub _print_response {
  my $method = shift;
  print "=over 2\n\n";
  print "=head3 Response\n\n";
  if (my $response = $method->example_response()) {
    my $xml = $response->render(1);
    $xml =~ s|\n|\n  |g;
    print "  $xml  \n\n";
#    print Dumper($response->xml());
  } else {
    print "Empty response\n\n";
  }
  print "=back\n\n";
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

L<Froody>

=cut

1;

