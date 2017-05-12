     _   _       _            _         
    | | | | __ _(_)_ __   ___| | _____  
    | |_| |/ _` | | '_ \ / _ \ |/ / _ \ 
    |  _  | (_| | | | | |  __/   < (_) |
    |_| |_|\__,_|_|_| |_|\___|_|\_\___/ 
    HTTP   API  into     ESMTP
                                    
English version of README is [README.md](https://github.com/azumakuniyuki/Haineko/blob/master/README.md)

Hainekoとは何か?
=================

Haineko(はいねこ)はブラウザやcurl等HTTPクライアントからJSONでメールを送信する為
のリレーサーバとして、Perl+Plack/PSGIアプリケーションとして実装されています。

Hainekoに対してJSONで記述されたメールのデータをHTTP POSTで送信すれば、外部のSMTP
サーバやメールクラウド等にリレーする事が可能です。

HainekoはPerl 5.10.1以上がインストールされている下記のOSで動作します。

* OpenBSD
* FreeBSD
* NetBSD
* Mac OS X
* Linux

リレー可能なメールクラウドの一覧
--------------------------------

* [SendGrid](http://sendgrid.com) - lib/Haineko/SMTPD/Relay/SendGrid.pm
* [Amazon SES](http://aws.amazon.com/ses/) - lib/Haineko/SMTPD/Relay/AmazonSES.pm
* [Mandrill](http://mandrill.com) - lib/Haineko/SMTPD/Relay/Mandrill.pm


必要な環境と構築方法について
============================

動作環境
--------

* Perl 5.10.1 or later

依存するPerlモジュール
----------------------

Hainekoは以下のモジュールに依存しています:

* Archive::Tar (core module from v5.9.3)
* __Authen::SASL__
* __Class::Accessor::Lite__
* __Email::MIME__
* Encode (core module from v5.7.3)
* File::Basename (core module from v5)
* File::Copy (core module from v5.2)
* File::Temp (core module from v5.6.1)
* __Furl__
* Getopt::Long (core module from v5)
* IO::File (core module from v5.3.7)
* IO::Pipe (core module from v5.3.7)
* __IO::Socket::SSL__
* IO::Zlib (core module from v5.9.3)
* __JSON::Syck__
* MIME::Base64 (core module from v5.7.3)
* Module::Load (core module from v5.9.4)
* __Net::DNS__
* Net::SMTP (core module from v5.7.3)
* __Net::SMTPS__
* __Net::CIDR::Lite__
* __Parallel::Prefork__
* __Path::Class__
* __Plack__
* __Router::Simple__
* Scalar::Util (core module from v5.7.3)
* __Server::Starter__
* Sys::Syslog (core module from v5)
* Time::Piece (core module from v5.9.5)
* __Try::Tiny__

リレー時のBASIC認証を使用する場合
---------------------------------

Hainekoにメールデータを渡す前にBASIC認証を必要とする場合は次のモジュールも必要
になります。

* __Crypt::SaltedHash__
* __Plack::MiddleWare::Auth::Basic__

Haineko::SMTPD::Relay::AmazonSESを使用する場合
----------------------------------------------

もしもHaineko::SMTPD::Relay::AmazonSESを使う場合は下記のモジュールもインストール
してください。

* __XML::Simple__ 2.20 以降

ソースコードの取得
------------------

    $ cd /usr/local/src
    $ git clone https://github.com/azumakuniyuki/Haineko.git

A. CPANからインストール(cpanmを使って)
--------------------------------------

    $ sudo cpanm Haineko
    $ export HAINEKO_ROOT=/path/to/some/dir/for/haineko
    $ hainekoctl setup --dest $HAINEKO_ROOT
    $ cd $HAINEKO_ROOT
    $ vi ./etc/haineko.cf

    And edit other files in etc/ directory if you needed.

Run by the one of the followings:

    $ plackup -o '127.0.0.1' -p 2794 -a libexec/haineko.psgi
    $ hainekoctl start --devel

B. ソースコードのディレクトリで直接実行
---------------------------------------

    $ cd ./Haineko
    $ sudo cpanm --installdeps .
    $ ./bin/hainekoctl setup --dest .
    $ vi ./etc/haineko.cf

    /etcディレクトリにある他のファイルも同様に編集
    

次のいずれかのコマンドで起動出来ます。

    $ plackup -o '127.0.0.1' -p 2794 -a libexec/haineko.psgi
    $ ./bin/hainekoctl start --devel

C. /usr/local/hainekoにインストールする
---------------------------------------

### 1. ``configure''スクリプトの準備

    $ cd ./Haineko
    $ ./bootstrap
    $ sh configure --prefix=/path/to/dir (default=/usr/local/haineko)

### 2. 依存するPerlモジュールを入れる

    $ make depend

または

    $ cpanm -L./dist --installdeps .

### 3. hainekoを構築する

    $ make && make test && sudo make install

    $ /usr/local/haineko/bin/hainekoctl setup --dest /usr/local/haineko
    $ cd /usr/local/haineko
    $ vi ./etc/haineko.cf

    /etcディレクトリにある他のファイルも同様に編集

    $ export PERL5LIB=/usr/local/haineko/lib/perl5

次のいずれかのコマンドで起動出来ます。

    $ plackup -o '127.0.0.1' -p 2794 -a libexec/haineko.psgi
    $ ./bin/hainekoctl start --devel

D. /usr/localにインストールする
-------------------------------

    $ cd ./Haineko
    $ sudo cpanm .
    $ sudo cpanm -L/usr/local --installdeps .

    $ /usr/local/bin/hainekoctl setup --dest /usr/local/etc
    $ cd /usr/local
    $ vi ./etc/haineko.cf

    /etcディレクトリにある他のファイルも同様に編集

次のいずれかのコマンドで起動出来ます。

    $ plackup -o '127.0.0.1' -p 2794 -a libexec/haineko.psgi
    $ ./bin/hainekoctl start --devel

Hainekoサーバの起動
-------------------

### plackupコマンドを使う

    $ plackup -o 127.0.0.1 -p 2794 -a libexec/haineko.psgi

### ラッパースクリプト(hainekoctl)を使う

    $ bin/hainekoctl start --devel -a libexec/haineko.psgi

下記のコマンドを実行するとhainekoctlで利用可能なオプションが表示されます。

    $ bin/hainekoctl help

/usr/local/haineko/etcにある設定ファイルについて
------------------------------------------------
Hainekoの動作に必要な設定ファイルについてはこの節で確認してください。いずれの
ファイルもYAML形式です。

### etc/haineko.cf
Hainekoの設定ファイルです。起動時に別の設定ファイルを使用したい場合は、環境変数
HAINEKO\_CONFにそのPATHを設定してください。

### etc/mailertable
宛先メールアドレスのドメイン部分によってリレー先SMTPサーバを決定する為のファイル
です。Sendmailの/etc/mail/mailertableと同じ働きをします。同じような働きをする
sendermtファイルよりも先に評価されます。

### etc/sendermt
発信者アドレスのドメイン部分によってリレー先SMTPサーバを決定する為のファイルです。
前述のmailertableの後に評価されます。

### etc/authinfo
SMTPサーバやEメールクラウドへリレーする時に必要な認証情報を定義するファイルです。
主にSMTP認証に必要なユーザ名とパスワード、Eメールクラウド用のAPIキー等を記述しま
す。

__パスワードをそのまま記述する必要があるので、Hainekoサーバを実行するユーザ以外
は読めないようにパーミッションの設定にご注意下さい。__

### etc/relayhosts
Hainekoに対してメールデータをPOSTできる接続元IPアドレスやネットワークを定義する
ファイルです。このファイルに定義されていないIPアドレスからの接続は拒否されます。

### etc/recipients
Hainekoがリレーする事が出来る宛先メールアドレスやドメインを定義するファイルです。
このファイルに定義されていないアドレス宛のメールは拒否されます。

### etc/password
HainekoにメールデータをPOSTする前に行うBASIC認証のユーザ名とパスワードを定義しま
す。hainekoctl -Aで起動するか、環境変数HAINEKO\_AUTHにパスワードファイルの位置を
設定した場合に限り、BASIC認証が必要になります。

__パスワードはハッシュを記述しますが、安全の為にHainekoサーバを実行するユーザ以
外は読めないようにパーミッションの設定にご注意下さい。__

### ブラウザで確認出来る設定ファイルの内容

ブラウザで/confにアクセスすると起動中のHainekoが読込んでいる設定ファイルの内容が
JSONで表示されます。このURLにアクセス出来るのは127.0.0.1からのみです。

環境変数
--------

### HAINEKO_ROOT

HAINEKO\_ROOTは設定ファイルのディレクトリであるetcやアプリケーション本体である
libexec/haineko.psgiの位置を決定するのに使用されます。環境変数HAINEKO\_CONFが
未定義である場合、$HAINEKO\_ROOT/etc/haineko.cfが設定ファイルとして使用されます。

### HAINEKO_CONF

HAINEKO\_CONFは設定ファイル__haineko.cf__の位置を定義します。設定ファイルはなく
ても起動は出来ますが、リレー先サーバの定義ファイルなどの位置を決定するのに必要で
す。この環境変数が定義されていない場合、環境変数$HAINEKO\_ROOT/etc/haineko.cfが
設定ファイルとして使用されます。
bin/hainekoctl -C /path/to/haineko.cfで環境変数を定義せずに起動する事も可能です。

### HAINEKO_AUTH

HainekoにメールデータをPOSTする前のBASIC認証で使用するパスワードファイルの位置を
定義します。この環境変数を設定した場合、あるいはbin/hainekoctl -Aで起動した場合
のみ、BASIC認証が必要になります。

### HAINEKO_DEBUG

Hainekoを開発モードで起動します。環境変数を設定せずにbin/hainekoctl -d, --devel
で起動してもよいです。開発モードで起動している時はGETでメールデータを渡す事がで
きます。

各言語でのサンプルコード
------------------------

Perl, Python, Ruby, PHP, Java Script(jQuery) シェルスクリプトでのサンプルコード
をソースコードの eg/ディレクトリに同梱しています。

OpenBSDで構築する再の特記事項
-----------------------------
もしもconfigureを実行する時に下記のようなエラーメッセージが表示された場合は、

    Provide an AUTOCONF_VERSION environment variable, please
    aclocal-1.10: autom4te failed with exit status: 127
    *** Error code 1

次の環境変数を設定して再実行してください。

    $ export AUTOCONF_VERSION=2.60


リポジトリ
----------
https://github.com/azumakuniyuki/Haineko

開発者
------
azumakuniyuki

ライセンス
----------

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

