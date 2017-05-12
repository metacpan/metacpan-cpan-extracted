# Enbld

*Enbldは、開発環境構築のための、もう一つのパッケージマネージャーです。*

Enbldは、ソフトウェア開発に必要なソフトウェア（プログラミング言語、テキストエディタ、バージョンコントロールシステムなど）のインストールを手助けします。

- 他のパッケージマネージャーとは違って、Enbldは指定したバージョンをインストールできます。

- 他のプログラミング言語用バージョンマネージャーとは違って、Enbldは全てのプログラミング言語に同一のインストールインタフェースを提供します。

- ソフトウェアのインストール条件はperlベースのDSLを使って定義します。

        target 'git' => define {
            version 'latest'; # -> 最新バージョンをインストール
        }

        target 'perl' => define {
            version '5.18.1'; # -> 指定したバージョンをインストール
        }

# サポートするプラットフォーム

*Enbldは、OS X Mavericksで動作検証を行っています。*

しかし、ひょっとするとLinux (Debian, Ubuntu など)でも動作するかもしれません。

動作しなかった時は、ぜひレポートをお待ちしております :)

# 動作環境

 - perl 5.10.1以上

  注:Enbldは必ずsystem perl(`/usr/bin/perl`)を使います。

 - GNU Make

 - コンパイラ (gccか、clang)

 - その他、ターゲットのソフトウェアごとに必要なもの(例:scalaにはJREが必要 など)

# インストール

    $ curl -L http://goo.gl/MrbDDB | perl

Enbldを動作させるためには、PATHの設定が必要なので、表示されるメッセージに従って環境変数へ追加して下さい。

# 他のドキュメント

Enbldのイントロダクションドキュメントを表示します (perldoc lib/Enbld.pmと同じです)。

    $ enblder intro

Enbldのチュートリアルを表示します。

    $ enblder tutorial

# ウェブサイト

[https://github.com/magnolia-k/Enbld](https://github.com/magnolia-k/Enbld)

[http://code-stylistics.net/enbld](http://code-stylistics.net/enbld)

# 問題の報告

[https://github.com/magnolia-k/Enbld/issues](https://github.com/magnolia-k/Enbld/issues)

# コピーライト

copyright 2013- Magnolia <magnolia.k@me.com>.

# ライセンス

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
