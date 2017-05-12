package Froody::Walker::XML;
use strict;
use warnings;
use base 'Froody::Walker::Driver';

use Froody::Logger;
my $logger = get_logger('froody.walker.xml');

use XML::LibXML;
  
=head1 NAME

Froody::Walker::XML - read and write XML

=head1 SYNOPSIS

=head1 DESCRIPTION

Turn xml into data in the form of Implementation class returns.

=cut

sub init_source {
  my ($self, $source) = @_;
  
  if ($source and !ref($source)) {
    $source = XML::LibXML->new->parse_string( $source )->documentElement;
  }
  
  return $source;
}

sub init_target {
  my ($self, $xpath, $parent) = @_;
  
  my $doc = $parent ? $parent->ownerDocument 
                    : XML::LibXML->createDocument("1.0", "UTF8");
                    
  return $doc->createDocumentFragment unless $xpath;
 
  my $name = (split '/', $xpath)[-1];
 
  return $doc->createElement($name);
}

sub validate_source {
  my ($self, $source, $path) = @_;
  my $spec = $self->spec_for_xpath($path);

  my %check = map { $_ => 1 } @{ $spec->{attr} };
  my @my_attr = map { $_->name } $source->attributes();
  for (@my_attr) {
    $logger->warn("bad attr '$_' in node '$path' (not in spec)") unless $check{$_};
  }

  %check = map { ($path ? "$path/$_" : $path) => 1 } @{ $spec->{elts} };
  my @my_elem = map { $_->nodeType == 1 ? $_->nodeName : () } $source->childNodes();
  for (@my_elem) {
    $logger->warn("bad element '$_' in node '$path' (not in spec)") unless $check{($path ? "$path/$_" : $path)};
  }

  if (!$spec->{text} and my $text = $self->read_text($source, $path)) {
    warn $source->toString(1);
    $logger->warn("bad text content '$text' for node '$path' (not in spec)");
  }

  return 1;
}

sub read_attribute {
  my ($self, $source, $path, $attr) = @_;
  return $source->getAttribute($attr);
}

sub read_text {
  my ($self, $source, $path) = @_;
  
  my $text = $source->findvalue('./text()');
  $text =~ s/^\s+//;
  $text =~ s/\s+$//;
  return $text;
}

sub child_sources {
  my ($self, $source, $xpath, $element) = @_;
  return $source->findnodes( "./$element" ) ;
}

sub _encode {
  my ($target,$value) = @_;
  return Encode::encode($target->ownerDocument->encoding, $value)
}

sub write_attribute {
  my ($self, $target, $path, $attr, $value) = @_;
  
  $target->setAttribute($attr, _encode($target, $value));
  return $target;
}

sub write_text {
  my ($self, $target, $xpath_key, $value) = @_;
  $target->appendText(_encode($target, $value));
  return $target;
}


sub add_child_to_target {
  my ($self, $target, $xpath, $element, $child) = @_;
  $target->addChild($child);
  return $target;
}


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

L<Froody>, L<Froody::Walker>

=cut

1;
