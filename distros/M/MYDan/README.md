                         MYDan 说明


===================================安装=====================================

    安装步骤：
        1: /path/to/your/perl Makefile.PL
        2: make
        3: make install
            I.  make install 只安装模块
            II. make install box=1 安装模块和急救箱(box)
            II. make install dan=1 安装模块和所有mydan平台
            IV. make install def=1 安装模块和默认配置
            V.  make install dan=1 box=1 def=1 全安装
            VI. make install dan=1 box=1 def=1 nickname=abc 全安装 + 为mydan添加别名abc

            a. make install dan=1 cpan=/path/to/your/cpan    指定cpan工具路径
            b. make install dan=1 mydan=/path/to/your/mydan  指定mydan工具安装路径,
                 (如果没指定mydan的安装目录，会在编译目录和perl目录的父目录中找名为mydan的目录，
                      如果都没有，默认目录在/opt/mydan)

            (注：当前安装目录的上一层目录必须命名命名为 'mydan')
