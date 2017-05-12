# $Id: XPath.pm,v 1.3 2003/11/10 08:30:33 grantm Exp $

package File::Find::Rule::XPath;

use strict;
use Carp;
use File::Find::Rule;
use File::Spec;
use Cwd ();

use vars qw($VERSION @ISA @EXPORT);

$VERSION = '0.03';
@ISA     = qw(File::Find::Rule);
@EXPORT  = @File::Find::Rule::EXPORT;


sub File::Find::Rule::xpath {
  my $self  = shift()->_force_object;
  my $xpath = @_ ? shift : '/';


  # Use XML::LibXML if it's installed otherwise try XML::XPath
  
  my $use_libxml = 0;
  if(eval { require XML::LibXML }) {
    $use_libxml = 1;
  }
  elsif(!eval { require XML::XPath }) {
    croak 'Can\'t locate XML::LibXML or XML::XPath in @INC';
  }

  my $cwd = Cwd::cwd();

  if($use_libxml) {

    $self->exec(
      sub { 
        my($shortname, $path, $fullname) = @_;

        eval {
          unless(File::Spec->file_name_is_absolute($fullname)) {
            $fullname = File::Spec->rel2abs($fullname, $cwd);
          }

          my $xp = XML::LibXML->new();

          $xp->parse_file($fullname)->find($xpath)->get_nodelist();
        };
      }
    );

  }
  else {

    $self->exec(
      sub { 
        my($shortname, $path, $fullname) = @_;

        eval {
          unless(File::Spec->file_name_is_absolute($fullname)) {
            $fullname = File::Spec->rel2abs($fullname, $cwd);
          }

          my $xp = XML::XPath->new(filename => $fullname);

          $xp->exists($xpath);
        };
      }
    );

  }

}


1;
__END__

=head1 NAME

File::Find::Rule::XPath - rule to match on XPath expressions

=head1 SYNOPSIS

  use File::Find::Rule::XPath;
  
  my @files = File::Find::Rule->file
              ->name('*.dkb')
              ->xpath( '//section/title[contains(., "Crustacean")]' )
              ->in($root);

=head1 DESCRIPTION

This module extends L<File::Find::Rule> to provide the ability to locate
XML files which match a given XPath expression.

=head1 METHODS

=head2 xpath( $xpath_expression )

Matches XML files which contain one or more nodes matching the given XPath
expression.  Files which are not 'well formed' XML are silently skipped.

If no XPath expression is supplied, the value '/' is used.  This will match
all files which are well formed XML.

=head1 AUTHOR

Grant McLean E<lt>grantm@cpan.orgE<gt>

=head1 SEE ALSO

To use this module, you must have L<File::Find::Rule> and one of the
following XPath implementations: L<XML::LibXML> or L<XML::XPath>

=head1 COPYRIGHT 

Copyright 2002 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut
