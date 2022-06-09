package Firewall::Config::Content::Role;

#------------------------------------------------------------------------------
# 定义 Firewall::Config::Content::Role 角色属性 => 针对Class/package的调用
#------------------------------------------------------------------------------
use Moose::Role;

#------------------------------------------------------------------------------
# 定义 Content 通用属性
#------------------------------------------------------------------------------
has fwId => ( is => 'ro', isa => 'Int', required => 1, );

has fwName => ( is => 'ro', isa => 'Str', required => 1, );

has fwType => ( is => 'ro', isa => 'Str', required => 1, );

has confSign => ( is => 'ro', isa => 'Str', required => 1, );

has timestamp => ( is => 'ro', isa => 'Str', required => 1, );

has lineParsedFlags => ( is => 'ro', isa => 'ArrayRef[Int]', builder => '_buildLineParsedFlags', );

#------------------------------------------------------------------------------
# Content 子类必须实现的方法
#------------------------------------------------------------------------------
requires 'config';
requires 'confContent';
requires 'cursor';

requires 'goToHead';
requires 'nextLine';
requires 'prevLine';

requires 'nextUnParsedLine';
requires 'backtrack';
requires 'ignore';
requires 'getUnParsedLines';

1;
