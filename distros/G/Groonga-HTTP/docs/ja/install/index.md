---
title: Install
---

# インストール

このドキュメントは、以下のプラットフォームでGroonga-HTTPをインストールする方法を説明します。

  * [AlmaLinux](#almalinux)

Groonga-HTTPをインストールする前に [Groonga][groonga] をインストールしなければなりません。

Groonga-HTTP は CPAN で提供されています。
以下の手順は、 CPAN で提供されている Groonga-HTTP を使う場合のものです。

## AlmaLinux {#almalinux}

```console
% sudo dnf install -y perl-App-cpanminus
% sudo dnf install -y gcc
% cpanm Groonga-HTTP
```

Groonga-HTTP のインストールに Carton を使いたい場合は、 Groonga-HTTP を以下の手順でインストールします。

最初に、以下のように cpanfile を記載します

```
requires 'Groonga::HTTP'
```

次に、以下のコマンドを実行します。

```console
% sudo dnf install -y perl-App-cpanminus
% sudo dnf install -y gcc
% cpanm Carton
% carton install
```

[Groonga]:https://groonga.org/
