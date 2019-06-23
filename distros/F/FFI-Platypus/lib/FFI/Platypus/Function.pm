package FFI::Platypus::Function;

use strict;
use warnings;
use FFI::Platypus;

# ABSTRACT: An FFI function object
our $VERSION = '0.88'; # VERSION


use overload '&{}' => sub {
  my $ffi = shift;
  sub { $ffi->call(@_) };
};

use overload 'bool' => sub {
  my $ffi = shift;
  return $ffi;
};

package FFI::Platypus::Function::Function;

use base qw( FFI::Platypus::Function );

sub attach
{
  my($self, $perl_name, $proto) = @_;

  my $frame = -1;
  my($caller, $filename, $line);

  do {
    ($caller, $filename, $line) = caller(++$frame);
  } while( $caller =~ /^FFI::Platypus(|::Function|::Function::Wrapper|::Declare)$/ );

  $perl_name = join '::', $caller, $perl_name
    unless $perl_name =~ /::/;

  $self->_attach($perl_name, "$filename:$line", $proto);
  $self;
}

package FFI::Platypus::Function::Wrapper;

use base qw( FFI::Platypus::Function );

sub new
{
  my($class, $function, $wrapper) = @_;
  bless [ $function, $wrapper ], $class;
}

sub call
{
  my($function, $wrapper) = @{ shift() };
  $wrapper->($function, @_);
}

my $counter = 0;

sub attach
{
  my($self, $perl_name, $proto) = @_;
  my($function, $wrapper) = @{ $self };

  unless($perl_name =~ /::/)
  {
    my $caller;
    my $frame = -1;
    do { $caller = caller(++$frame) } while( $caller =~ /^FFI::Platypus(|::Declare)$/ );
    $perl_name = join '::', $caller, $perl_name
  }

  my $attach_name = "FFI::Platypus::Inner::xsub@{[ $counter++ ]}";
  $function->attach($attach_name);
  my $xsub = \&{$attach_name};

  {
    no strict 'refs';
    *{$perl_name} = sub { $wrapper->($xsub, @_) };
  }

  $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::Platypus::Function - An FFI function object

=head1 VERSION

version 0.88

=head1 SYNOPSIS

 use FFI::Platypus;
 
 # call directly
 my $ffi = FFI::Platypus->new;
 my $f = $ffi->function(puts => ['string'] => 'int');
 $f->call("hello there");
 
 # attach as xsub and call (faster for repeated calls)
 $f->attach('puts');
 puts('hello there');

=head1 DESCRIPTION

This class represents an unattached platypus function.  For more
context and better examples see L<FFI::Platypus>.

=head1 METHODS

=head2 call

 my $ret = $f->call(@arguments);
 my $ret = $f->(@arguments);

Calls the function and returns the result.  You can also use the
function object like a code reference.

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Bakkiaraj Murugesan (bakkiaraj)

Dylan Cali (calid)

pipcet

Zaki Mughal (zmughal)

Fitz Elliott (felliott)

Vickenty Fesunov (vyf)

Gregor Herrmann (gregoa)

Shlomi Fish (shlomif)

Damyan Ivanov

Ilya Pavlov (Ilya33)

Petr Pisar (ppisar)

Mohammad S Anwar (MANWAR)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015,2016,2017,2018,2019 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
