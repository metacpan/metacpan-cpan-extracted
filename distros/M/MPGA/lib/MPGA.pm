package MPGA;

use strict;
use warnings;
use Attribute::Handlers; # Добавлено для поддержки атрибутов

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration use MPGA ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
 
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
  flow flow_ctx step chunk
);

our $VERSION = '0.24';
# данная версия модуля MPGA кардинально отличается от предыдущей 0.08 версии следующим:
#   - изменена логика разбора потока - теперь только прямой порядок следования аргументов,
#     без всяких reverse и pop;
#   - специальный объект для хранения контекста потока;
#   - у функций появился атрибут количества обязательных аргументов.
# однако, модуль спроектирован так, что в нем сохраняется обратная совместимость, и код
# написанный в старом стиле все равно будет работать.


# Реестр для хранения количества обязательных аргументов функций
our %REGISTRY;


# Определение атрибута :MPGAargsNum
# этот атрибут необходим функциям, чтобы указать MPGA сколько аргументов обязательно 
# нужно исполняемой функции, это для удобства работы в новом стиле. основываясь на
# это атрибуте step() предоставит функции именно такой длины массив аргументов @$args.
# исполняемая функция должна иметь примерно такой вид:
# sub fun : MPGAargsNum(3) {
#   my ($self, $args, $flow, $ctx) = @_;
#   my $args1 = shift @$args;
#   my $args2 = shift @$args;
#   my $args3 = shift @$args;
# 
#   .....
#   return;
# }
# данная запись явно дает понять, что это не обычная функция perl, а функция, которая
# написана для исполнения модулем MPGA и ей необходимы 3 обязательных аргумента.
# если же этот атрибут не указан
# sub old_style_fun {
#   my ($self, $args, $flow) = @_;
#   my $args1 = pop @$args;
#   .....
#   return;
# }
# значит функция написана в старом стиле и она сама управляет @$args и контекстом.
sub UNIVERSAL::MPGAargsNum : ATTR(CODE) {
  my ($package, $symbol, $referent, $attr, $argsNum) = @_;

  # Если данные пришли в виде массива, берем первый элемент.
  # Если как обычный скаляр — берем его как есть.
  $REGISTRY{$referent} = ref($argsNum) eq 'ARRAY' ? $argsNum->[0] : $argsNum;
}


# функция flow_ctx() принимает ссылку на массив, и в этом массиве первый
# элемент считается объектом контекста ctx, который будет передан
# во все функции потока. вы можете определять ctx как угодно.
# рекомендую пустой хэш {}, в котором можно будет хранить промежуточные
# состояния функций (естественно надо не забывать их чистить :))
sub flow_ctx {
  my $flow = shift;

  return if !$flow;
  return if ref( $flow ) ne 'ARRAY';
  return if !scalar @$flow;

  # Откусываем первый элемент и сохраняем его как контекст выполнения
  my $ctx = shift @$flow;

  # Передаем чистый поток и контекст дальше в цепочку
  flow( $flow, $ctx );

  return;
}


# функция flow() принимает три аргумента:
# первый аргумент обязательный - ссылка на массив - поток,
# второй аргумент необязательный $ctx - контекст,
# третий аргумент необязательный $max_steps - лимит шагов (0 = без ограничения).
# поток разбирается слева направо функцией step() пока не опустошится или не достигнут лимит $max_steps.
sub flow {
  my $flow      = shift;
  my $ctx       = shift; # Принимаем контекст (будет undef, если вызван обычный flow)
  my $max_steps = shift || 0;

  return if !$flow;
  return if ref( $flow ) ne 'ARRAY';

  while(scalar @$flow) {
    step( $flow, $ctx ); # Передаем $ctx в step() на каждом шаге
    last if $max_steps && --$max_steps <= 0;
  }

  return;
}


# функция step() принимает два аргумента:
# первый аргумент обязательный - ссылка на массив - поток,
# второй аргумент необязательный $ctx - контекст.
# поток парсится слева направо с помощью вызова функции chunk()
# в поисках первой ссылки на функцию.
# эта функция заносится в переменную $fun и будет исполняться, а все переменные
# найденные до этой функции заносятся в массив накопленных аргументов @$args.
# таким образом $flow становится короче.
#
# step() принимает поток в прямом порядке
#
# исполняемой функции $fun передаются четыре аргумента:
# sub fun {
#   my ( $self, $args, $flow, $ctx ) = @_;
#   .....
#   return;
# }
#   - $fun - сама эта функция
#   - вторым аргументом идет ссылка на массив аргументов (или undef, если перед
#     функцией в потоке не было ни одного аргумента):
#       * если у функции задан атрибут :MPGAargsNum(N) — это ссылка на массив из N
#         ближайших к функции аргументов, которые забрали с конца массива
#         накопленных аргументов
#       * если атрибут не задан — это ссылка на весь массив накопленных аргументов
#   - $flow - остаток потока
#   - $ctx - общий объект контекста (может быть undef)
#
# функция $fun может модифицировать любые свои аргументы
#   - первый аргумент - ссылка на саму себя, модифицировать ее в принципе можно, но не нужно,
#     функция передается сама себе для того, чтобы в случае необходимости она могла
#     рекурсивно возвратить саму себя в поток @$flow
#   - второй аргумент - массив аргументов @$args - аргументы могут относиться к этой функции или
#     к другой, которая идет дальше по потоку, это зависит от того определен ли у функции
#     атрибут MPGAargsNum:
#       - если определен, то в @$args именно MPGAargsNum аргументов, и их можно обрабатывать самым
#         обычным способом через shift.
#       - если не определен, то в @$args возможно не все аргументы относятся к этой функции
#         и обрабатывать их надо осторожно, чтобы не удалить из потока транзитные аргументы.
#         поэтому надо обрабатывать их через pop и получать в обратном порядке с конца.
#   - третий аргумент - поток $flow - тоже может быть модифицирован с целью изменить поток
#     выполнения программы, но так как считается, что рядовая функция не должна знать слишком много,
#     то рекомендую модифицировать поток только в плане прекращения потока в случае ошибки,
#     это достигается обнулением @$flow и возвратом undef, т.е. надо выполнить такой код:
#       @$flow = ();
#       return;
#   - четвертый аргумент - контекст ctx. если поток был определен через функцию flow_ctx, то
#     это первый элемент этого потока - контекст, который должен быть передан всем функциям этого потока.
# 
# исполняемая функция $fun может вернуть
#   - ссылку на массив - в этом случае элементы массива вставляются в начало
#       остатка потока $flow (через unshift, распаковывая массив)
#   - ссылка на хэш - в этом случае возврат трактуется как объект, который
#       вставляется в начало остатка потока $flow (через unshift)
#   - скаляр - в этом случае возврат трактуется как скаляр, который
#       вставляется в начало остатка потока $flow (через unshift)
#   - undef - в этом случае поток $flow не меняется
#   - во всех других случаях $flow не меняется
#
# после выполнения функции $fun список аргументов @$args может быть не пустым
# (транзитные аргументы), в таком случае они вставляются в начало потока @$flow
# ПЕРЕД результатом работы $fun. итоговый порядок в потоке:
# [...транзитные args..., ...результат $fun..., ...остаток потока...]
# также надо взять за правило, что функция $fun всегда должна заканчиваться return,
# иначе будет возвращен результат последнего оператора функции.
# таким образом функция всегда должна заканчиваться как-то так:
#    return [...];   - ссылка на массив
#    return {...};   - ссылка на хэш
#    return $scalar; - скаляр
#    return;         - undef
sub step {
  my $flow = shift;
  my $ctx  = shift; # Принимаем контекст

  return if !$flow;
  return if ref($flow) ne 'ARRAY';

  if(scalar @$flow) {
    my ($fun, $args) = chunk($flow);

    if ($fun) {
      my $res;

      # Если у функции объявлен атрибут :MPGAargsNum
      if ( exists $REGISTRY{$fun} ) {
        my $argsNum = $REGISTRY{$fun};

        my $actual_args = defined $args ? scalar @$args : 0;
        if ($actual_args < $argsNum) {
          print "Предупреждение: !!!!! аргументов ($actual_args) меньше чем требуется ($argsNum)\n";
          $argsNum = $actual_args;
        }

        # ПРАВИЛЬНЫЙ ВАРИАНТ:
        # Если требуется 0 аргументов — создаем пустой массив, 
        # иначе безопасно забираем $argsNum элементов с конца.
        my @pass_args = ($argsNum == 0) ? () : splice(@$args, -$argsNum);

        # Передаю стандартный набор аргументов
        $res = $fun->($fun, \@pass_args, $flow, $ctx);

        # Всё, что было в @pass_args, здесь забывается, так как переменная выходит из области видимости
      }
      else {
        # Старый режим совместимости: передаем исходный $args целиком и $ctx четвертым аргументом
        $res = $fun->($fun, $args, $flow, $ctx);
      }

      if( defined $res ) { # $fun вернула что-то определённое, НЕ undef
        if( ref( $res ) eq 'ARRAY' ) { # $fun вернула ссылку на массив
          unshift(@$flow, @$res) if scalar @$res;
        }
        else {
          unshift @$flow, $res;
        }
      }

      # Если в $args еще остались транзитные аргументы — возвращаем их в начало потока
      if (defined $args && scalar @$args) {
        unshift @$flow, @$args;
      }
    }
  }

  return;
}


# функция chunk() принимает только ссылку на массив,
# в котором ищет первую с начала ссылку на функцию, всё, что не является ссылкой на функцию 
# считается аргументом функции и попадает в массив аргментов.
# возвращает массив из двух элементов ( fun, [args] )
#
sub chunk {
  my $flow = shift;

  return if ref( $flow ) ne 'ARRAY';

  my ($fun, $args);

  while(scalar @$flow) {
    my $item = shift @$flow; 
    if( ref $item ne 'CODE' ) {
      push @$args, $item; # Аргументы собираются слева направо в прямом порядке
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

=encoding utf8

=head1 NAME

MPGA - Make Perl Great Again - a module for Flow-Driven Development in Perl

=head1 SYNOPSIS

  use MPGA;

  # --- Basic flow without shared context ---

  sub fun : MPGAargsNum(2) {
      my ($self, $args, $flow, $ctx) = @_;
      my ($a, $b) = @$args;
      print "Got arguments: $a and $b\n";
      return;
  }

  flow( [ "transit_arg", 5, 6, \&fun ] );

  # --- Using flow_ctx with a shared context ---

  sub step_one : MPGAargsNum(2) {
      my ($self, $args, $flow, $ctx) = @_;
      $ctx->{sum_result} = $args->[0] + $args->[1];
      return;
  }

  sub step_two : MPGAargsNum(0) {
      my ($self, $args, $flow, $ctx) = @_;
      print "Sum from previous step: $ctx->{sum_result}\n";
      return;
  }

  my $my_context = { sum_result => 0 };
  flow_ctx( [ $my_context, 10, 20, \&step_one, \&step_two ] );

=head1 DESCRIPTION

A "flow" is simply an array reference containing a mix of data (arguments) 
and code references (functions). These elements are sequentially processed 
from left to right.

=head2 The Function Signature

Each function in the flow must expect four arguments:

  sub fun1 : MPGAargsNum(2) {
      my ($self, $args, $flow, $ctx) = @_;
      
      # $self - reference to this function itself
      # $args - array ref of arguments passed to this function
      # $flow - array ref of the remaining flow (can be modified)
      # $ctx  - optional context object shared across the flow
      
      return;
  }

=head2 The :MPGAargsNum(N) Attribute

The C<:MPGAargsNum(N)> attribute explicitly defines how many arguments your 
function consumes from the flow. MPGA will automatically extract the C<N> 
arguments immediately preceding the function.

Any arguments in the flow that appeared before those C<N> arguments are 
considered transit arguments. They are safely preserved and automatically 
pushed back into the flow to be consumed by subsequent functions.

(Note: Older code without this attribute receives all preceding arguments 
and must manage them manually. This backward compatibility is fully preserved).

=head2 Return Values

Functions can return values to inject new data or functions into the 
beginning of the remaining flow:

=over 4

=item * B<Array reference> C<[...]>: Elements are unpacked and prepended to the flow.

=item * B<Hash reference> C<{...}> or B<Scalar>: Prepended to the flow as a single element.

=item * B<undef> (or empty C<return;>): The flow remains unchanged.

=back

=head2 Shared Context

If you need to share state across multiple functions, use C<flow_ctx()>. 
The first element of the array is treated as a shared context object 
and is passed to all functions as the 4th argument.

=head2 Execution Limits

To protect against infinite loops, C<flow()> accepts a step limit as the 3rd 
argument (0 = unlimited):

  flow($flow_array, $ctx, 100); # Stops after 100 steps

=head1 SEE ALSO

L<MPGA::Trace> - For real-time execution monitoring.

https://github.com/nni7/MPGA

=head1 AUTHOR

Nikolay Neustroev (NN)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 1997-2026 by Nikolay Neustroev.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
