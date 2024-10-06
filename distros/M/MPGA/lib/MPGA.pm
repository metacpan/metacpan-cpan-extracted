package MPGA;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use MPGA ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
  flow step chunk
);

our $VERSION = '0.08';


# функция flow() принимает только ссылку на массив,
# который переворачивается и разбирается с конца функцией step()
# пока не опустошится
#
sub flow {
  my $flow = shift;

  return if !$flow;
  return if ref( $flow ) ne 'ARRAY';

  @$flow = reverse @$flow;

  while(scalar @$flow) {
    step( $flow );
  }

  return;
}


# функция step() принимает только ссылку на массив,
# который парсится с конца с помощью вызова функции chunk()
# в поисках первой ссылки на функцию.
# эта функция заносится в переменную $fun и будет исполняться, а все переменные
# найденные до этой функции заносятся в массив @$args. таким образом
# $flow становится короче.
#
# step() принимает уже перевернутый поток 
#
# исполняемая функция $fun принимает три аргумента:
#   - $fun - сама эта функция
#   - $args - аргументы
#   - $flow - остаток потока
#
# функция $fun может модифицировать любые свои аргументы
#   - модифицировать первый аргумент - ссылку на саму себя в принципе можно, но не нужно 
#     функция передается сама себе для того чтобы в случае необходимости она могла 
#     рекурсивно возвратить саму себя в поток @$flow
#   - второй аргумент - массив аргументов @$args - может относиться к этой функции или 
#     к другой, которая идет дальше по потоку, если функция $fun принимает аргументы, 
#     то массив @$args должен быть модифицирован 
#     в обязательном порядке, аргументы которые функция $fun принимает идут в конце
#     массива @$args и должны быть получены функцией $fun с помощью pop(@$args)
#   - третий аргумент - поток $flow - тоже может быть модифицирован с целью изменить поток
#     выполнения программы, но так как считается, рядовая функция не должна знать слишком много, 
#     то она может модифицировать этот поток только в плане прекращения потока в случае ошибки
#     из этого следует, что если исполняемая функция $fun захочет вообще
#     прервать исполнение потока $flow, то она должна обнулить @$flow
#     и вернуть undef, т.е. выполнить такой код
#       @$flow = ();
#       return;
#     возможно обнуление flow надо будет сделать в анонимной функции, тогда в ней обязательно 
#     надо определить flow из аргументов в начале функции:
#       my ( $self, $args, $flow ) = @_;
#
#     
# исполняемая функция $fun может вернуть
#   - ссылку на массив - в этом случае этот массив должен быть перевернут 
#       и занесен в конец остатка потока $flow
#   - ссылка на хэш - в этом случае возврат трактуется как объект, который
#       должен быть занесен в конец остатка потока $flow
#   - скаляр - в этом случае возврат трактуется как скаляр, который
#       должен быть занесен в конец остатка потока $flow
#   - undef - в этом случае поток $flow не меняется
#   - во всех других случаях $flow не меняется
#
# после выполнения функции $fun список аргументов @$args может быть не пустым, в
# таком случае он должен быть перевернут и добавлен в поток @$flow после добавления 
# туда результатов работы $fun
#
# также надо взять за правило, что функция $fun должна возвращать что-то только
# тогда, когда она хочет что-то добавить в поток исполнения
# она может вернуть 
#   - ссылку на массив - return [...]; тогда этот массив будет инвертирован и добавлен в поток
#   - ссылку на хэш - return {...}; добавляется в поток
#   - скаляр - return $scalar; добавляется в поток
#   - undef - return; - основной случай, ничего не добавляется в поток
#
sub step {
  my $flow = shift;

  return if !$flow;
  return if ref($flow) ne 'ARRAY';

  if(scalar @$flow) {
    my ($fun, $args) = chunk($flow);
    if ($fun) {
      my $res = $fun->($fun, $args, $flow);

      if( defined $res ) { # $fun вернула что-то определённое, НЕ undef
        if( ref( $res ) eq 'ARRAY' ) { # $fun вернула ссылку на массив
          push(@$flow, reverse @$res) if scalar @$res;
        }
        else {
          push @$flow, $res;
        }
      }

      if (scalar @$args) {
        push @$flow, reverse @$args;
      }
    }
  }

  return;
}


# функция chunk() принимает только ссылку на массив,
# в котором ищет первую с конца ссылку на функцию, всё, что не является ссылкой на функцию 
# считается аргументом функции и попадает в массив аргментов.
# возвращает массив из двух элементов ( fun, [args] )
#
sub chunk {
  my $flow = shift;

  return if ref( $flow ) ne 'ARRAY';

  my ($fun, $args);

  while(scalar @$flow) {
    my $item = pop @$flow;
    if( ref $item ne 'CODE' ) {
      push @$args, $item;
    }
    else {
      $fun = $item;
      last;
    }
  }

  return $fun, $args;
}


# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

MPGA - Make Perl Great Again - a module that makes it easy 
to write programs in the PERL programming language.

=head1 SYNOPSIS

  use MPGA;

  flow( [ "aaa", \&fun ] );

  sub fun {
    my ($self, $args, $flow) = @_;
    my ($par) = @$args;

    print "fun() infinite loop\n";
    print "par: [$par]\n";
    return [$self];
  }

=head1 DESCRIPTION

Something like "Flow driven development".

Flow is a reference to an array of arguments and functions, which.
are sequentially processed by the functions of this module.

With this module you can program something like this:

flow( [
  $args, ... $args, \&fun1,
  $another, ..., $args, \&fun2,
  $more, ..., $args, \&fun3
] );

A prerequisite is that the functions in the flow must satisfy a few.
simple conditions:
 - take three arguments - ($self, $args, $flow)
 - return a reference to an array - [ @flow_chunk ]

=head1 SEE ALSO

https://github.com/nni7/MPGA

=head1 AUTHOR

NN - Nikolay Neustroev

=head1 COPYRIGHT AND LICENSE

Copyright (C) 1997-2024 by NN

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.32.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
