                         MYDan 说明


===================================简介=====================================

MYDan(蚂蚁蛋助手)是一个开源的运维工具，它采用自定义的协议，来管理分布在全球各个地区下隔离网络中的服务器。它具有如下特点：

简单： 简单的安装方式，网络结构简单，可以方便的使用上专线资源

安全： 密钥可以定时更新

快速： 调用机器命令和传输文件非常高效

全面： 支持linux和window环境

MYDan在生成环境中已经被广泛使用。MYDan可以作为调度系统，作业平台，堡垒机等的核心组件。

MYDan支持两种协议，ssh协议和MYDan自定义协议。推荐使用MYDan自定义的协议。

一旦MYDan在所有的机器上运行起来之后，不管机器网络隔离的多么的复杂，批量操作机器，批量传输文件，获取远程shell，灰度发布等等都变得非常简单。

同时MYDan中带着大量的常用工具：如 快速登录服务器命令（go），守护进程服务（bootstrap），时间同步服务（ntpsync），脚本和数据压缩工具（xtar），超时执行脚本工具（alarm）等等


===================================安装=====================================

安装稳定版本: 

    curl -L update.mydan.org | bash

安装最新版本: 

    curl -L update.mydan.org | MYDanInstallLatestVersion=1 bash

============================================================================

安装方式1:

    通过cpan命令安装: dan=1 box=1 def=1 cpan install MYDan

安装方式2:

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

安装方式3:

    (安装最新版本到/opt/mydan下)
    curl -s https://raw.githubusercontent.com/MYDan/openapi/master/scripts/mydan/update.sh|bash

    (等同于: curl -L http://install.mydan.org|bash)

==============================推荐使用方式===================================

第一步: 
    
    在github中fork https://github.com/MYDan/key 项目

第二步:

    把第一步的项目编辑好自己的公钥上传，私钥保留在自己电脑中

第三步:

   运行命令:

       export ORGANIZATION=lijinfeng2011  #其中MYDan为github账号
       curl -s https://raw.githubusercontent.com/MYDan/openapi/master/scripts/mydan/install.sh|bash


变量解释:(注:在没有以下5个参数的任何一个时，安装脚本不会把服务启动起来)

   1.  组织名，即githu上的组或者用户,在没配置MYDAN_KEY_UPDATE变量的情况下,用这个默认到github账号下的key项目

           export ORGANIZATION=MYDan

   2.  更新公钥的地址

           export MYDAN_KEY_UPDATE=https://raw.githubusercontent.com/MYDan/key/master/keyupdate
      
   3.  更新服务列表的地址 

           export MYDAN_PROC_UPDATE=https://raw.githubusercontent.com/MYDan/proc/master/procupdate
           

   4.  更新白名单地址

           export MYDAN_WHITELIST_UPDATE=https://raw.githubusercontent.com/MYDan/openapi/master/config/whitelist

   5.  更新mydan脚本地址

           export MYDAN_UPDATE=https://raw.githubusercontent.com/MYDan/openapi/master/scripts/mydan/update.sh


