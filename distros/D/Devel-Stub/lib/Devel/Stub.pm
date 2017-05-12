package Devel::Stub;
use strict;
use warnings;
use Module::Load;
use Sub::Name qw/subname/;
use version;
our $VERSION = qv('0.02');

sub stub {
    my %params = @_;
    my @tags;
    if ($params{TAG}){
      @tags = ref($params{TAG}) ? @{$params{TAG}} : ($params{TAG});
      delete $params{TAG};
      return unless $ENV{STUB_TAG};
      return unless grep { $_ eq $ENV{STUB_TAG}} @tags;
    }
    my ($name,$code) = %params;
    no strict 'refs';
    no warnings 'redefine';
    my ($pkg,$file,$line) = caller;
    my $original = \&{"${pkg}::${name}"};
    *{"${pkg}::__original_${name}"} = $original;
    *{"${pkg}::${name}"} = subname $name,$code;
}

sub import{
    my $class = shift;
    my %params = @_ ;
    
    if ( $params{on}  ){
        my ($pkg,$file) = caller;
        no strict 'refs';
        *{"${pkg}::stub"} = \&stub;
        *{"${pkg}::_original"} = sub {
          no strict 'refs' ;
          my (undef,undef,undef,$subr) = caller(1);
          my $name = ( split /::/,$subr )[-1];
          &{"${pkg}::__original_${name}"}(@_);
        };
        my $pkgpath = $pkg;
        $pkgpath =~ s/::/\//g;
        $pkgpath .= ".pm";
        $file =~ s/[\w\/]+(\/$pkgpath)$/$params{on}$1/;
        load $file;
    } 
}


1;

__END__

=head1 NAME

Devel::Stub - stub some methods for development purpose

=head1 DESCRIPTION

For example, when you develop a webapp,you'd like to  develop views and/or
controllers using stubbed model modules which can return expected data.
This module helps it.

=over 2

=item * With this module,you can stub some methods on exisiting moudle 

=item * This module adds a lib path on initializing the app (when invoked with specific environment variable) so that you can organize stub file on the path outside of main lib path

=item * Changes you have to do on main app are just one line and it doesn't affect if you kick the app in usual way. You have to do nothing on existing modules.

=back


=head1 SYNOPSIS

The step is; 
1) declare Devel::Stub::lib on main applicaton file. 2) Overide methods with module which has same pacakge of original one.


=head2 Devel::Stub::lib

Change lib path for stubbing.

 use lib qw/mylib/;
 use Devel::Stub::lib active_if => $ENV{STUB};
 use Foo::Bar;

In this case,if $ENV{STUB} are given, this script will add 'stub' to @INC.

=head2 Devel::Stub

Stub some methods on existing module.

stub/Foo/Bar.pm

  package Foo::Bar;
  use Devel::Stub on => 'mylib';
  # this moudle override methods on mylib/Foo/Bar.pm

  stub foo => sub {
      "stubbed!"
  };



=head1 EXAMPLE

Suppose these files;

  ./app.pl
  ./mylib/Abcd/Efg.pm
  ./mylib/Foo/Bar.pm
  ./stub/Foo/Bar.pm

=over

=item app.pl

 use lib 'mylib';
 use Devel::Stub::lib active_if => $ENV{STUB}
 use Foo::Bar;

 my $b = Foo::Bar->new
 print $b->woo;
 print $b->moo; 

=item mylib/Foo/Bar.pm

 package Foo::Bar

 sub new{
     bless {},shift;
 }
 sub woo{
     "woo!";
 }
 sub moo {
     "moo!"
 }
 1;

=item stub/Foo/Bar.pm

 package Foo::Bar;
 use Devel::Stub on => "mylib";

 stub woo => sub {
    "stubbed!";
 };
 # override just 'woo' method. Others are intact.
 1;


=back

normal use

 $ perl app.pl  #=> woo!moo!

stub use
 
 $ STUB=1 perl app.pl #=>stubbed!moo!


=head1 PARAMETERS


=head2 Devel::Stub::lib


EXAMPLE:

 use Devel::Stub::lib 
    active_if => ($ENV{APP_ENV} eq 'development'), path => 'mystub', quiet => 1;


=over 4

=item active_if (optional - default: $ENV{STUB} )

specify condition for including stub path. 

=item path (optional - default: 'stub' )

specify path for stub modules. That will insert on top of @INC

=item quite (optional - default: false )

if true is given,no warning message will be shown when entering stub mode.

=back

=head2 Devel::Stub

EXAMPLE:

  use Devel::Stub on => "mylib"

=over 4

=item on (required)

specify where original modules are located. That mean if you want to stub method in 'foo_lib/Foga/Woo.pm',
you should put 'foo_lib'.

=back

=head1 WRITING STUBS

you can define stubs with C<stub> method.

  package Foo::Woo;
  use Devel::Stub on => 'mylib'

  stub hoo => sub {
     +{ stubbed => "data"};
  };


=head2 INVOKE ORIGINAL METHOD

you can invoke original method with C<_orginal()>.

 stub foo => sub {
   my ($self,$param) = @_;
   if($param ne 'xxx') {
       return _original(@_);  # invoke original one for some situation.
   }  
   ["stubbed","data","is","here"];
 };


=head2 TAG option

Opionaly,if you specify C<TAG> parameter with stub method.
That won't be activated unless you exec app with STUB_TAG environment.
 
  stub foo => sub {
    "stubbed!";
  },TAG => ["devel","local"];

  stub 
    TAG => ["staging"],
    moo => sub  {
      "stubbed!";
    };

with stub file above,

  STUB=1 STUB_TAG=local perl app.pl  # 'foo' is stubbed
  STUB=1 STUB_TAG=staging perl app.pl # 'moo' is stubbed.
  STUB=1 perl app.pl # neither is stubbed.


=head1 AUTHOR

Masaki Sawamura <sawamur@cpan.org>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Masaki Sawamura. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
