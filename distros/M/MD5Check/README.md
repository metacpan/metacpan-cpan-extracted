# MD5Check

## NAME
 
MD5Check - Use it for init Web files's md5 values of your site(or other dir), and check if it changed.

检查web目录（或者其他重要系统目录）md5值，当目录文件变化提醒。用于文件防篡改。 
 
## SYNOPSIS
 
    use MD5Check;
 
### 初始化目录md5值,参数为要监控的目录 

新版本中，对初始化信息输出是实时输出到文件，需要自己定义输出文件句柄，可见bin/init.pl
 
    my $mydir=shift;
    print  md5init($mydir,$OutFD);


### 使用方法，初始化MD5值 

   生成执行文件，保存为fileinit.pl然后执行 perl fileinit.pl web目录

### 检查目录

   对目录文件进行检查，只需输入之前保存的md5 文件值。

    use MD5Check;
    my $mydir=shift; 
    print md5check($mydir);

    perl filemd5check.pl  webmd5-20160920。

  详细实例，见bin目录下的 init.pl 和 check.pl
  oneliner，perl单行程序实现功能。

###需要安装该模块，简单通过 cpanm MD5Check 安装。

    $ perl -MMD5Check -e 'init("/web")' >file
    $ perl -MMD5Check -e 'print md5check(file)'
 
     
## Git repo
 
[github] (https://github.com/bollwarm/MD5Check)

[git@oschina] (https://git.oschina.net/ijz/MD5Check.git)
 
##  AUTHOR
 
[orange] <linzhe@ijz.me>,[blog](http://ijz.me)
 
## COPYRIGHT AND LICENSE
 
Copyright (C) 2016 linzhe
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
