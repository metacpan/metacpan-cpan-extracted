# NAME

Getopt::EX::Hashed - Getopt::Long 的哈希存储对象自动化

# VERSION

Version 1.0601

# SYNOPSIS

    # script/foo
    use App::foo;
    App::foo->new->run();

    # lib/App/foo.pm
    package App::foo;

    use Getopt::EX::Hashed; {
        Getopt::EX::Hashed->configure( DEFAULT => [ is => 'rw' ] );
        has start    => ' =i  s begin ' , default => 1;
        has end      => ' =i  e       ' ;
        has file     => ' =s@ f       ' , any => qr/^(?!\.)/;
        has score    => ' =i          ' , min => 0, max => 100;
        has answer   => ' =i          ' , must => sub { $_[1] == 42 };
        has mouse    => ' =s          ' , any => [ 'Frankie', 'Benjy' ];
        has question => ' =s          ' , any => qr/^(life|universe|everything)$/i;
    } no Getopt::EX::Hashed;

    sub run {
        my $app = shift;
        use Getopt::Long;
        $app->getopt or pod2usage();
        if ($app->answer == 42) {
            $app->question //= 'life';
            ...

# DESCRIPTION

**Getopt::EX::Hashed** 是一个模块，用于为 **Getopt::Long** 和兼容模块（包括 **Getopt::EX::Long**）自动创建一个哈希对象，以存储命令行选项值。模块名称共享 **Getopt::EX** 前缀，但到目前为止，它独立于 **Getopt::EX** 中的其他模块运行。

该模块的主要目标是将初始化和规范整合到一处。它还提供了简单的验证接口。

当给出 `is` 参数时，将自动生成访问方法。如果已经定义了相同的函数，程序将导致致命错误。对象销毁时，访问器将被移除。当多个对象同时存在时，可能会出现问题。

# FUNCTION

## **has**

以下列形式声明选项参数。括号仅为清晰起见，可以省略。

    has option_name => ( param => value, ... );

例如，要定义以整数值为参数的选项 `--number`（也可用作 `-n`），请执行以下操作

    has number => spec => "=i n";

访问器以第一个名称创建。在本例中，访问器将定义为 `$app->number`。

如果给出数组引用，则可以同时声明多个名称。

    has [ 'left', 'right' ] => ( spec => "=i" );

如果名称以加号（`+`）开头，给定参数将更新现有设置。

    has '+left' => ( default => 1 );

至于 `spec` 参数，如果是第一个参数，则可以省略标签。

    has left => "=i", default => 1;

如果参数个数不是偶数，则假定默认标签存在于头部：如果第一个参数是代码引用，则使用 `action`，否则使用 `spec`。

可使用以下参数

- \[ **spec** => \] _string_

    给出选项说明。`spec =>` 标签可以省略，前提是它是第一个参数。

    在 _string_ 中，选项规格和别名用空白分隔，可以任意顺序出现。

    如果要使用一个名为 `--start` 的选项，它的值是一个整数，并且还可以与 `-s` 和 `--begin` 一起使用，请声明如下。

        has start => "=i s begin";

    上述声明将被编译为下一个字符串。

        start|s|begin=i

    符合 `Getopt::Long` 的定义。当然，也可以这样写：

        has start => "s|begin=i";

    如果名称和别名中包含下划线 (`_`)，则会用破折号 (`-`) 代替下划线定义另一个别名。

        has a_to_z => "=s";

    上述声明将被编译为下一个字符串。

        a_to_z|a-to-z=s

    如果没有特殊需要，可将空字符串（或仅空白）作为值。否则，它将不被视为选项。

- **alias** => _string_

    也可以通过 **alias** 参数指定其他别名。这与 `spec` 参数中的别名没有区别。

        has start => "=i", alias => "s begin";

- **is** => `ro` | `rw`

    要生成访问方法，必须使用 `is` 参数。设置 `ro` 表示只读，`rw` 表示读写。

    读写访问器具有 lvalue 属性，因此可以对其赋值。可以这样使用

        $app->foo //= 1;

    这比下面的写法要简单得多。

        $app->foo(1) unless defined $app->foo;

    如果要为以下所有成员设置访问器，请使用 `configure` 设置 `DEFAULT` 参数。

        Getopt::EX::Hashed->configure( DEFAULT => [ is => 'rw' ] );

    如果不喜欢可分配的访问器，可将 `ACCESSOR_LVALUE` 参数设置为 0。 因为访问器是在 `new` 时生成的，所以该值对所有成员都有效。

- **default** => _value_ | _coderef_

    设置默认值。如果没有给出缺省值，则成员初始化为 `undef`。

    如果值是 ARRAY 或 HASH 的引用，则会分配具有相同成员的新引用。这意味着成员数据将在多次调用 `new` 时共享。如果多次调用 `new` 并更改成员数据，请务必小心。

    如果给出代码引用，则在 **new** 时调用该代码引用以获取默认值。当您想在执行时而不是在声明时评估值时，这种方法非常有效。如果要定义默认操作，请使用 **action** 参数。

    如果给出 SCALAR 的引用，则选项值将存储在引用所指示的数据中，而不是哈希对象成员中。在这种情况下，无法通过访问哈希对象成员获得预期值。

- \[ **action** => \] _coderef_

    参数 `action` 带有处理选项时调用的代码引用。如果 `<action =` >> 标签是第一个参数，则可以省略。

    调用时，哈希对象作为 `$_` 传递。

        has [ qw(left right both) ] => '=i';
        has "+both" => sub {
            $_->{left} = $_->{right} = $_[1];
        };

    您可以将其用于 `"<>">> 来捕获所有内容。在这种情况下，规格参数并不重要，也不是必需的。`

        has ARGV => default => [];
        has "<>" => sub {
            push @{$_->{ARGV}}, $_[0];
        };

以下参数均用于数据验证。首先，`must` 是一个通用验证器，可以实现任何功能。其他参数是通用规则的快捷方式。

- **must** => _coderef_ | \[ _coderef_ ... \]

    参数 `must` 需要一个代码引用来验证选项值。它接收与 `action` 相同的参数，并返回布尔值。在下一个例子中，选项 **--answer** 只接受 42 作为有效值。

        has answer => '=i',
            must => sub { $_[1] == 42 };

    如果给出多个代码引用，则所有代码都必须返回 true。

        has answer => '=i',
            must => [ sub { $_[1] >= 42 }, sub { $_[1] <= 42 } ];

- **min** => _number_
- **max** => _number_

    设置参数的最小和最大限制。

- **any** => _arrayref_ | qr/_regex_/

    设置有效的字符串参数列表。每项都是字符串或 regex 引用。当参数与给定列表中的任何一项相同或匹配时，参数有效。如果参数值不是数组反射，则将其视为单项列表（通常是 regexpref）。

    以下声明几乎等同，只是第二个声明不区分大小写。

        has question => '=s',
            any => [ 'life', 'universe', 'everything' ];

        has question => '=s',
            any => qr/^(life|universe|everything)$/i;

    如果使用可选参数，不要忘记在列表中包含默认值。否则会导致验证错误。

        has question => ':s',
            any => [ 'life', 'universe', 'everything', '' ];

# METHOD

## **new**

获取初始化哈希对象的类方法。

## **optspec**

返回可提供给 `GetOptions` 函数的选项说明列表。

    GetOptions($obj->optspec)

`GetOptions` 可以通过将哈希引用作为第一个参数，将值存储在哈希对象中，但这并不是必须的。

## **getopt** \[ _arrayref_ \]

调用调用者上下文中定义的适当函数来处理选项。

    $obj->getopt

    $obj->getopt(\@argv);

以上示例是以下代码的快捷方式。

    GetOptions($obj->optspec)

    GetOptionsFromArray(\@argv, $obj->optspec)

## **use\_keys** _keys_

由于哈希键受 `Hash::Util::lock_keys` 保护，访问不存在的成员会导致错误。在使用前，请使用此函数声明新的成员键。

    $obj->use_keys( qw(foo bar) );

如果要访问任意键，请解锁对象。

    use Hash::Util 'unlock_keys';
    unlock_keys %{$obj};

您可以通过带有 `LOCK_KEYS` 参数的 `configure` 改变这种行为。

## **configure** **label** => _value_, ...

在创建对象之前，请使用类方法 `Getopt::EX::Hashed->configure()`；此信息存储在调用包的唯一区域。调用 `new()` 后，包的唯一配置将复制到对象中，并用于进一步操作。使用 `$obj->configure()` 更新对象的唯一配置。

配置参数如下。

- **LOCK\_KEYS** (default: 1)

    锁定哈希键。这样可以避免意外访问不存在的哈希条目。

- **REPLACE\_UNDERSCORE** (default: 1)

    生成用破折号替换下划线的别名。

- **REMOVE\_UNDERSCORE** (default: 0)

    生成去掉下划线的别名。

- **GETOPT** (default: 'GetOptions')
- **GETOPT\_FROM\_ARRAY** (default: 'GetOptionsFromArray')

    设置 `getopt` 方法调用的函数名。

- **ACCESSOR\_PREFIX** (default: '')

    指定后，它将作为成员名的前缀，用于生成访问方法。如果 `ACCESSOR_PREFIX` 被定义为 `opt_`，则成员 `file` 的访问器将是 `opt_file`。

- **ACCESSOR\_LVALUE** (default: 1)

    如果设置为 true，读写访问器将具有 lvalue 属性。如果不喜欢这种行为，请设置为 0。

- **DEFAULT**

    设置默认参数。在调用 `has` 时，DEFAULT 参数会插入到参数之前。因此，如果两个参数都包含相同的参数，参数列表中排在后面的参数优先。使用 `+` 的递增调用不受影响。

    DEFAULT 的典型用法是 `is` 为下面所有哈希条目准备访问方法。声明 `DEFAULT => []` 以重置。

        Getopt::EX::Hashed->configure(DEFAULT => [ is => 'ro' ]);

## **reset**

将类重置为原始状态。

# SEE ALSO

[Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong)

[Getopt::EX](https://metacpan.org/pod/Getopt%3A%3AEX), [Getopt::EX::Long](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3ALong)

# AUTHOR

Kazumasa Utashiro

# COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2021-2024 Kazumasa Utashiro

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 153:

    Unterminated C< ... > sequence
