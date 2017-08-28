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

            a. make install dan=1 cpan=/path/to/your/cpan 指定cpan工具路径

            (注：当前安装目录的上一层目录必须命名命名为 'mydan')
