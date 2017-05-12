package ExportTo;

use Carp();
use strict;

sub import{
  my $pkg = (caller)[0];
  {
    no strict 'refs';
    *{$pkg . '::export_to'} = \&export_to
      if not defined &{$pkg . '::export_to'};
  }
  goto \&export_to;
}

sub export_to {
  shift if $_[0] eq __PACKAGE__;
  my %hash = @_;
  my $pkg = (caller)[0];
  while(my($class, $subs) = each %hash){
    if(ref $subs eq 'HASH'){
      # {subname => \&coderef/subname}
      while (my($sub, $cr_or_name) = each %{$subs}) {
        my($cr, $subname) = ref $cr_or_name eq 'CODE' ? ($cr_or_name, undef) : (undef, $cr_or_name);
        my $esub = $class . '::' . $sub;
        $sub  =~ s/\+//og;
        ($esub =~ s/\+//og or ($subname and $subname =~s/\+//og)) ? undef &{$esub} : defined(&{$esub}) && next;
        # if($cr or $cr = \&{$pkg . '::' . $subname}) {
        if($cr or $cr = $pkg->can($subname)) {
          no strict 'refs';
          *{$esub} = $cr
        } else {
          Carp::croak($pkg, ' cannot do ' , $subname);
        }
      }
    }else{
      foreach my $sub (@$subs){
        my $esub;
        unless($sub =~ /::/o){
          $esub = $class . '::' . $sub;
        } else {
          $sub =~ s{^(.+)::}{}o and $pkg = $1;
          $esub = $class . '::' . $sub;
        }
        $sub  =~ s/\+//og;
        $esub =~ s/\+//og ? undef &{$esub} : defined(&{$esub}) && next;
        # if(my $cr = \&{$pkg . '::' . $subname}) {
        if(my $cr = $pkg->can($sub)) {
          no strict 'refs';
          *{$esub} = $cr
        } else {
          Carp::croak($pkg, ' cannot do ' , $sub);
        }
      }
    }
  }
}

=head1 NAME

ExportTo - export any function/method to any namespace

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

 package From;
 
 sub function_1{
   # ...
 }
 
 sub function_2{
   # ...
 }
 
 sub function_3{
   # ...
 }
 
 use ExportTo (NameSpace1 => [qw/function_1 function_2/], NameSpace2 => [qw/function_3/]);

 # Now, function_1 and function_2 are exported to 'NameSpace1' namespace.
 # function_3 is exported to 'NameSpace2' namespace.
 
 # If 'NameSpace1'/'NameSpace2' namespace has same name function/method,
 # such a function/method is not exported and ExportTo croaks.
 # but if you want to override, you can do it as following.
 
 use ExportTo (NameSpace1 => [qw/+function_1 function_2/]);
 
 # if adding + to function/method name,
 # This override function/method which namespace already has with exported function/method.
 
 use ExportTo ('+NameSpace' => [qw/function_1 function_2/]);
 
 # if you add + to namespace name, all functions are exported even if namespace already has function/method.

 use ExportTo ('+NameSpace' => {function_ => sub{print 1}, function_2 => 'function_2'});
 
 # if using hashref instead of arrayref, its key is regarded as subroutine name and
 # value is regarded as its coderef/subroutine name. and this subroutine name will be exported.


=head1 DESCRIPTION

This module allow you to export/override subroutine/method to one namespace.
It can be used for mix-in, for extension of modules not using inheritance.

=head1 FUNCTION/METHOD

=over 4

=item export_to

 # example 1 & 2
 export_to(PACKAGE_NAME => [qw/FUNCTION_NAME/]);
 ExportTo->export_to(PACKAGE_NAME => [qw/FUNCTION_NAME/]);
 
 # example 3
 ExportTo->export_to(PACKAGE_NAME => {SUBROUTINE_NAME => sub{ .... }, SUBROUTINE_NAME2 => 'FUNCTION_NAME'});

These are as same as following.

 # example 1 & 2
 use ExportTo(PACKAGE_NAME => [qw/FUNCTION_NAME/]);
 
 # example 3
 use ExportTo(PACKAGE_NAME => {SUBROUTINE_NAME => sub{ .... }, SUBROUTINE_NAME2 => 'FUNCTION_NAME'});

But, 'use' is needed to declare after declaration of function/method.
using 'export_to', you can write anywhere.

=back

=head1 Export from another package to another package (with renaming).

This is used in L<Util::Any>.
For example, CGI::Util's C<escape> function to other package.

 package main;
 use CGI ();
 
 # export CGI::Util::escape to OtherA
 use ExportTo (OtherA => ['CGI::Util::escape']);
 
 # export CGI::Util::escape to OtherB as cgi_escape
 use ExportTo (OtherB => {cgi_escape => \&CGI::Util::escape});
 
 print OtherA::escape("/"); # %2F
 print OtherB::cgi_escape("/"); # %2F

=head1 Import from another package's subroutine to current package (with renaming)

It is as same as above.

 use CGI ();
 
 # export CGI::Util::escape to current package
 use ExportTo (__PACKAGE__, ['CGI::Util::escape']);
 
 # export CGI::Util::escape to current package as cgi_escape
 use ExportTo (__PACKAGE__, {cgi_escape => \&CGI::Util::escape});
 
 print main::escape("/"); # %2F
 print main::cgi_escape("/"); # %2F

But for this purpose, L<Sub::Import> has better interface.

=head1 AUTHOR

Ktat, C<< <ktat at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-exportto at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ExportTo>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ExportTo

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ExportTo>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ExportTo>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ExportTo>

=item * Search CPAN

L<http://search.cpan.org/dist/ExportTo>

=back

=head1 SEE ALSO

L<Sub::Import>. If you import other module's function to current package,
it is better than ExportTo.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2009 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of ExportTo
