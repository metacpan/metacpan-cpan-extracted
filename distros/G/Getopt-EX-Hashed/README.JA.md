# NAME

Getopt::EX::Hashed - Getopt::Long 用ハッシュ格納オブジェクトの自動化

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

**Getopt::EX::Hashed**は、**Getopt::Long**および**Getopt::EX::Long**を含む互換モジュールのコマンドラインオプション値を格納するハッシュオブジェクトを自動化するモジュールです。モジュール名は **Getopt::EX** と同じですが、今のところ **Getopt::EX** の他のモジュールとは独立して動作します。

このモジュールの主な目的は、初期化と仕様を一箇所に統合することです。また、シンプルな検証インターフェイスも提供します。

`is`パラメータが与えられると、アクセサメソッドが自動的に生成されます。同じ関数がすでに定義されている場合、プログラムは致命的なエラーを引き起こします。アクセサはオブジェクトが破棄されると削除されます。複数のオブジェクトが同時に存在する場合、問題が発生する可能性があります。

# FUNCTION

## **has**

オプション・パラメータを以下の形式で宣言します。括弧はわかりやすくするためのもので、省略してもよい。

    has option_name => ( param => value, ... );

たとえば、整数値をパラメータとしてとり、`-n`としても使えるオプション`--number`を定義するには、次のようにします。

    has number => spec => "=i n";

アクセサは最初の名前で作成されます。この例では、アクセサは `$app->number` と定義されます。

配列参照が与えられている場合、一度に複数の名前を宣言することができます。

    has [ 'left', 'right' ] => ( spec => "=i" );

名前がプラス(`+`)で始まる場合、与えられたパラメータは既存の設定を更新します。

    has '+left' => ( default => 1 );

`spec`パラメータは、最初のパラメータであればラベルを省略できます。

    has left => "=i", default => 1;

パラメータの数が偶数でない場合、デフォルトのラベルが先頭にあるとみなされます：最初のパラメータがコード参照であれば`action`、そうでなければ`spec`となります。

以下のパラメータが利用可能です。

- \[ **spec** => \] _string_

    オプション指定`spec =>` ラベルを省略できるのは、それが最初のパラメータである場合だけです。

    _string_ では、オプションの仕様とエイリアスの名前は空白で区切られ、どのような順番でも表示できます。

    `--start`というオプションを持ち、その値として整数を取り、`-s`と`--begin`という名前でも使えるようにするには、次のように宣言します。

        has start => "=i s begin";

    上記の宣言は、次の文字列にコンパイルされます。

        start|s|begin=i

    にコンパイルされ、`Getopt::Long`の定義に従います。もちろん、このように書くこともできます：

        has start => "s|begin=i";

    名前とエイリアスにアンダースコア(`_`)が含まれている場合、アンダースコアの代わりにダッシュ(`-`)を使った別のエイリアスが定義されます。

        has a_to_z => "=s";

    上記の宣言は、次の文字列にコンパイルされます。

        a_to_z|a-to-z=s

    特に何もする必要がない場合は、空文字列（または空白のみ）を値として与えます。そうでない場合は、オプションとはみなされません。

- **alias** => _string_

    **alias**パラメータで、追加のエイリアス名を指定することもできます。`spec`パラメータのものと違いはありません。

        has start => "=i", alias => "s begin";

- **is** => `ro` | `rw`

    アクセサメソッドを生成するには、`is`パラメータが必要です。読み込み専用なら`ro`、読み書きなら`rw`を指定します。

    読み書き可能なアクセサはlvalue属性を持っているので、それを代入することができます。このように使えます：

        $app->foo //= 1;

    これは、次のように書くよりずっと簡単です。

        $app->foo(1) unless defined $app->foo;

    以下のすべてのメンバにアクセッサを作りたい場合は、`configure`で`DEFAULT`パラメータを設定します。

        Getopt::EX::Hashed->configure( DEFAULT => [ is => 'rw' ] );

    `configure`で`DEFAULT`パラメータを設定します。アクセサは`new`時に生成されるので、この値はすべてのメンバに有効です。

- **default** => _value_ | _coderef_

    デフォルト値を設定します。デフォルト値が指定されない場合、メンバは`undef`として初期化されます。

    値が ARRAY または HASH の参照の場合、同じメンバを持つ新しい参照が割り当てられます。つまり、メンバ・データは複数の`new`呼び出しで共有されます。`new`を複数回呼び出してメンバ・データを変更する場合は注意してください。

    コード・リファレンスが与えられると、**new**の実行時に呼び出され、デフォルト値が得られます。これは、宣言ではなく実行時に値を評価したい場合に有効です。デフォルトのアクションを定義したい場合は、**action**パラメータを使用します。

    SCALARへの参照が与えられた場合、オプション値はハッシュオブジェクトメンバではなく、参照が示すデータに格納されます。この場合、ハッシュ・メンバにアクセスしても期待値は得られません。

- \[ **action** => \] _coderef_

    パラメータ `action` は、オプションを処理するために呼び出されるコード参照をとます。`<action =`> ラベルは、それが最初のパラメータである場合に限り、省略することができます。

    呼び出されたとき、ハッシュオブジェクトは `$_` として渡されます。

        has [ qw(left right both) ] => '=i';
        has "+both" => sub {
            $_->{left} = $_->{right} = $_[1];
        };

    これを `"<>" に使用することができます。">>ですべてを捕らえることができます。その場合、specパラメータは重要ではなく、必須でもないです。`

        has ARGV => default => [];
        has "<>" => sub {
            push @{$_->{ARGV}}, $_[0];
        };

以下のパラメータはすべてデータ・バリデーションのためのものです。最初の `must` は汎用バリデータで、何でも実装できます。その他は一般的なルールのショートカットです。

- **must** => _coderef_ | \[ _coderef_ ... \]

    パラメータ `must` は、オプション値を検証するためのコードリファレンスを受け取ります。`action` と同じ引数をとり、真偽値を返します。次の例では、オプション**--answer**は有効な値として42だけを取ります。

        has answer => '=i',
            must => sub { $_[1] == 42 };

    複数のコード参照が与えられた場合、すべてのコードが真を返さなければなりません。

        has answer => '=i',
            must => [ sub { $_[1] >= 42 }, sub { $_[1] <= 42 } ];

- **min** => _number_
- **max** => _number_

    引数の最小値と最大値を設定します。

- **any** => _arrayref_ | qr/_regex_/

    有効な文字列パラメータリストを設定します。各項目は文字列または正規表現参照です。引数は、指定されたリストのいずれかの項目と同じか一致する場合に有効です。値がarrayrefでない場合は、単一の項目リスト（通常は正規表現）とみなされます。

    以下の宣言はほぼ等価ですが、2番目の宣言は大文字小文字を区別しません。

        has question => '=s',
            any => [ 'life', 'universe', 'everything' ];

        has question => '=s',
            any => qr/^(life|universe|everything)$/i;

    オプションの引数を使用する場合は、リストにデフォルト値を含めることを忘れないでください。そうしないとバリデーション・エラーになります。

        has question => ':s',
            any => [ 'life', 'universe', 'everything', '' ];

# METHOD

## **new**

初期化されたハッシュオブジェクトを取得するクラスメソッド。

## **optspec**

`GetOptions`関数に渡すことができるオプション指定リストを返します。

    GetOptions($obj->optspec)

`GetOptions`は、ハッシュ参照を第1引数に与えることで、ハッシュに値を格納する機能を持っていますが、これは必要ありません。

## **getopt** \[ _arrayref_ \]

オプションを処理するために、呼び出し元のコンテキストで定義された適切な関数を呼び出します。

    $obj->getopt

    $obj->getopt(\@argv);

上記の例は、以下のコードのショートカットです。

    GetOptions($obj->optspec)

    GetOptionsFromArray(\@argv, $obj->optspec)

## **use\_keys** _keys_

ハッシュキーは`Hash::Util::lock_keys`によって保護されているため、存在しないメンバにアクセスするとエラーになります。この関数を使用して、新しいメンバー・キーを宣言してから使用してください。

    $obj->use_keys( qw(foo bar) );

任意のキーにアクセスしたい場合は、オブジェクトのロックを解除してください。

    use Hash::Util 'unlock_keys';
    unlock_keys %{$obj};

この動作は`configure`の`LOCK_KEYS`パラメータで変更できます。

## **configure** **label** => _value_, ...

オブジェクトを作成する前に、クラスメソッド`Getopt::EX::Hashed->configure()`を使用します。`new()`を呼び出すと、パッケージ固有の設定がオブジェクトにコピーされ、以降の操作に使用されます。オブジェクト固有の設定を更新するには、`$obj->configure()` を使用します。

以下の構成パラメータがあります。

- **LOCK\_KEYS** (default: 1)

    ハッシュ・キーをロックします。これは、存在しないハッシュ・エントリへの偶発的なアクセスを避けるためです。

- **REPLACE\_UNDERSCORE** (default: 1)

    アンダースコアをダッシュに置き換えたエイリアスを生成します。

- **REMOVE\_UNDERSCORE** (default: 0)

    アンダースコアを削除したエイリアスを生成します。

- **GETOPT** (default: 'GetOptions')
- **GETOPT\_FROM\_ARRAY** (default: 'GetOptionsFromArray')

    `getopt` メソッドから呼び出される関数名を設定します。

- **ACCESSOR\_PREFIX** (default: '')

    指定されると、メンバ名の前に付加されてアクセサ・メソッドとなります。`ACCESSOR_PREFIX` が `opt_` と定義されている場合、メンバ `file` のアクセサは `opt_file` になります。

- **ACCESSOR\_LVALUE** (default: 1)

    trueを指定すると、読み書き可能なアクセサはlvalue属性を持ちます。この振る舞いを好まない場合はゼロを設定してください。

- **DEFAULT**

    デフォルト・パラメータを設定します。`has`の呼び出しでは、DEFAULTパラメータが引数パラメータの前に挿入されます。そのため、同じパラメータが両方に含まれている場合は、引数リストで後の方が優先されます。`+`によるインクリメンタルコールは影響を受けないです。

    DEFAULTの典型的な使い方は`is`で、以下のすべてのハッシュ・エントリーのアクセサ・メソッドを用意することです。`DEFAULT => []`を宣言してリセットします。

        Getopt::EX::Hashed->configure(DEFAULT => [ is => 'ro' ]);

## **reset**

クラスを元の状態にリセットします。

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
