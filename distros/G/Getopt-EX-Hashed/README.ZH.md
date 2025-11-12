# NAME

Getopt::EX::Hashed - 为 Getopt::Long 提供哈希对象自动化

# VERSION

Version 1.0602

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

**Getopt::EX::Hashed** 是一个模块，用于为 **Getopt::Long** 及其兼容模块（包括 **Getopt::EX::Long**）自动创建用于存储命令行选项值的哈希对象。该模块名称带有 **Getopt::EX** 前缀，但目前它可独立于 **Getopt::EX** 中的其他模块工作。

本模块的主要目标是将初始化与规范定义整合在同一处。它还提供了一个简单的校验接口。

当提供 `is` 参数时，会自动生成访问器方法。如果同名函数已存在，程序将发生致命错误。对象销毁时，访问器将被移除。当同时存在多个对象时可能出现问题。

# FUNCTION

## **has**

以如下形式声明选项参数。圆括号仅为清晰起见，可省略。

    has option_name => ( param => value, ... );

例如，要定义选项 `--number`，它接受一个整数参数，同时也可用作 `-n`，请按如下操作

    has number => spec => "=i n";

访问器将以第一个名称创建。在此示例中，访问器将定义为 `$app->number`。

如果给出数组引用，可以一次声明多个名称。

    has [ 'left', 'right' ] => ( spec => "=i" );

如果名称以加号（`+`）开头，给定参数将更新现有设置。

    has '+left' => ( default => 1 );

对于 `spec` 参数，如果它是第一个参数，标签可以省略。

    has left => "=i", default => 1;

如果参数数量为奇数，第一个参数将被视为具有隐式标签：若为代码引用则为 `action`，否则为 `spec`。

可用的参数如下。

- \[ **spec** => \] _string_

    给出选项规范。仅当且仅当它是第一个参数时，可以省略 `spec =>` 标签。

    在 _string_ 中，选项规范与别名以空白分隔，且可以任意顺序出现。

    要声明一个名为 `--start` 的选项，它接受一个整数值，并且也可以使用名称 `-s` 和 `--begin`，如下声明。

        has start => "=i s begin";

    上述声明将被编译为如下字符串。

        start|s|begin=i

    其符合 `Getopt::Long` 的定义。当然，你也可以这样写：

        has start => "s|begin=i";

    如果名称和别名包含下划线（`_`），则会再定义一个把下划线替换为短横线（`-`）的别名。

        has a_to_z => "=s";

    上述声明将被编译为如下字符串。

        a_to_z|a-to-z=s

    如果不需要选项规范（spec），请将一个空字符串（或仅包含空白）作为值。没有 spec 字符串时，该成员不会被视为选项。

- **alias** => _string_

    也可以通过 **alias** 参数指定额外的别名名称。这与 `spec` 参数中的别名没有差别。

        has start => "=i", alias => "s begin";

- **is** => `ro` | `rw`

    要生成访问器方法，需要 `is` 参数。设置值 `ro` 为只读，`rw` 为读写。

    读写访问器具有左值属性，因此可以被赋值。可如下使用：

        $app->foo //= 1;

    这比下面这样写要简洁得多。

        $app->foo(1) unless defined $app->foo;

    如果你想为后续所有成员创建访问器，使用 `configure` 设置 `DEFAULT` 参数。

        Getopt::EX::Hashed->configure( DEFAULT => [ is => 'rw' ] );

    如果你不喜欢可赋值的存取器，请将 `ACCESSOR_LVALUE` 参数配置为 0。由于存取器是在调用 `new` 时生成的，该值对所有成员都有效。

- **default** => _value_ | _coderef_

    设置默认值。如果未提供默认值，成员将初始化为 `undef`。

    如果该值是对 ARRAY 或 HASH 的引用，则每次调用 `new` 都会创建一个浅拷贝。这意味着复制的是引用本身，但其内容是共享的。修改数组或哈希的内容将影响所有实例。

    如果提供了代码引用，它会在 **new** 时被调用以获得默认值。当你希望在执行时而非声明时计算该值时，这很有效。如果你想定义默认动作，请使用 **action** 参数。如果你想将代码引用设置为初始值，你必须指定一个返回代码引用的代码引用。

    如果提供了对 SCALAR 的引用，选项值将存储在该引用所指向的数据中，而不是哈希对象成员中。在这种情况下，通过访问哈希成员无法获得期望的值。

- \[ **action** => \] _coderef_

    参数 `action` 接受用于处理该选项的代码引用。只有当它是第一个参数时，才能省略 `action =>` 标记。

    调用时，哈希对象作为 `$_` 传入。

        has [ qw(left right both) ] => '=i';
        has "+both" => sub {
            $_->{left} = $_->{right} = $_[1];
        };

    你可以将其用于 `"<>"` 以处理非选项参数。在这种情况下，spec 参数无关紧要且不是必需的。

        has ARGV => default => [];
        has "<>" => sub {
            push @{$_->{ARGV}}, $_[0];
        };

以下参数均用于数据验证。首先，`must` 是通用验证器，几乎可以实现任何规则。其他的是常见规则的快捷方式。

- **must** => _coderef_ | \[ _coderef_ ... \]

    参数 `must` 接受一个用于验证选项值的代码引用。它接受与 `action` 相同的参数并返回布尔值。下面的示例中，选项 **--answer** 只有在值为 42 时才有效。

        has answer => '=i',
            must => sub { $_[1] == 42 };

    如果提供了多个代码引用，所有代码都必须返回真。

        has answer => '=i',
            must => [ sub { $_[1] >= 42 }, sub { $_[1] <= 42 } ];

- **min** => _number_
- **max** => _number_

    为参数设置最小和最大限制。

- **any** => _arrayref_ | qr/_regex_/ | _coderef_

    设置有效的字符串参数列表。每个项目可以是字符串、正则表达式引用或代码引用。当参数与给定列表中的任一项相同或匹配时即为有效。如果该值不是 arrayref，则将其视为单项列表（通常是 regexpref 或 coderef）。

    以下声明几乎等价，只是第二个不区分大小写。

        has question => '=s',
            any => [ 'life', 'universe', 'everything' ];

        has question => '=s',
            any => qr/^(life|universe|everything)$/i;

    如果你使用可选参数，别忘了在列表中包含默认值。否则会导致验证错误。

        has question => ':s',
            any => [ 'life', 'universe', 'everything', '' ];

# METHOD

## **new**

一个创建新的哈希对象的类方法。用默认值初始化所有成员，并按配置创建访问器方法。返回一个被祝福的哈希引用。如果启用了 LOCK\_KEYS，则哈希键会被锁定。

## **optspec**

返回可传递给 `GetOptions` 函数的选项规范列表。

    GetOptions($obj->optspec)

`GetOptions` 具备通过将哈希引用作为第一个参数来将值存储到哈希中的能力，但这不是必需的。

## **getopt** \[ _arrayref_ \]

调用在调用方上下文中定义的相应函数以处理选项。

    $obj->getopt

    $obj->getopt(\@argv);

上面的示例是以下代码的简写。

    GetOptions($obj->optspec)

    GetOptionsFromArray(\@argv, $obj->optspec)

## **use\_keys** _keys_

当启用 LOCK\_KEYS 时，访问不存在的成员会导致错误。请在访问之前使用此方法声明新的成员键。

    $obj->use_keys( qw(foo bar) );

如果你想访问任意键，请解锁该对象。

    use Hash::Util 'unlock_keys';
    unlock_keys %{$obj};

你可以通过带有 `LOCK_KEYS` 参数的 `configure` 来更改此行为。

## **configure** **label** => _value_, ...

在创建对象之前，使用类方法 `Getopt::EX::Hashed->configure()`；该信息按调用包分别存储。调用 `new()` 之后，包级配置会被复制到对象中供其使用。使用 `$obj->configure()` 更新对象级配置。

可用的配置参数如下。

- **LOCK\_KEYS** (default: 1)

    锁定哈希键。这可防止因拼写错误或其他失误而创建非预期的哈希条目。

- **REPLACE\_UNDERSCORE** (default: 1)

    自动创建将下划线替换为连字符的选项别名。

- **REMOVE\_UNDERSCORE** (default: 0)

    自动创建移除下划线的选项别名。

- **GETOPT** (default: 'GetOptions')
- **GETOPT\_FROM\_ARRAY** (default: 'GetOptionsFromArray')

    设置从 `getopt` 方法调用的函数名。

- **ACCESSOR\_PREFIX** (default: '')

    当指定时，它会被前置到成员名以生成访问器方法。如果 `ACCESSOR_PREFIX` 定义为 `opt_`，则成员 `file` 的访问器将是 `opt_file`。

- **ACCESSOR\_LVALUE** (default: 1)

    如果为真，读写访问器具有 lvalue 属性。如果你不喜欢这种行为，请设为零。

- **DEFAULT**

    设置默认参数。当调用 `has` 时，DEFAULT 参数会插入到显式参数之前。若两者都有同一参数，则以显式参数为准。带有 `+` 的增量调用不受影响。

    DEFAULT 的典型用法是使用 `is` 为随后的所有哈希条目准备访问器方法。声明 `DEFAULT => []` 可重置。

        Getopt::EX::Hashed->configure(DEFAULT => [ is => 'ro' ]);

## **reset**

将类重置为初始状态。

# SEE ALSO

[Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong)

[Getopt::EX](https://metacpan.org/pod/Getopt%3A%3AEX), [Getopt::EX::Long](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3ALong)

# AUTHOR

Kazumasa Utashiro

# COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2021-2025 Kazumasa Utashiro

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
