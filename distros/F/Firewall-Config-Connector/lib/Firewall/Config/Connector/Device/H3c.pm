package Firewall::Config::Connector::Device::H3c;

use Carp;
use Expect;
use Moose;
use Try::Tiny;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 定义设备 Connector 通用属性
#------------------------------------------------------------------------------
has host => (
  is       => 'ro',
  required => 0,
);

has username => (
  is       => 'ro',
  required => 0,
  default  => 'read'
);

has password => (
  is       => 'ro',
  required => 0,
  default  => '',
);

has enpassword => (
  is       => 'ro',
  required => 0,
);

has proto => (
  is       => 'ro',
  required => 0,
  default  => 'ssh',
);

has _login_ => (
  is       => 'ro',
  required => 0,
  default  => 0,
);

has _enable_ => (
  is       => 'ro',
  required => 0,
  default  => 0,
);

#------------------------------------------------------------------------------
# H3c 设备登陆函数入口
#------------------------------------------------------------------------------
sub login {
  my $self = shift;

  # 如果已有 _login_ 记录，直接返回结果
  return {success => 1} if $self->{_login_};

  # 尝试连接设备进行响应逻辑判断
  try {
    $self->connect() unless ( defined $self->{exp} );
  }
  catch {
    if (/RSA modulus too small/mi) {
      try { $self->connect('-v -1 -c des ') }
      catch {
        return {
          success => 0,
          reason  => $_
        };
      }
    }
    elsif (/Selected cipher type <unknown> not supported/mi) {
      try {
        $self->connect('-c des ');
      }
      catch {
        return {
          success => 0,
          reason  => $_
        };
      }
    }
    elsif (/Connection refused/mi) {
      try {
        $self->{proto} = 'telnet';
        $self->connect();
      }
      catch {
        return {
          success => 0,
          reason  => $_
        };
      }
    }
    elsif (/IDENTIFICATION HAS CHANGED/mi) {
      try {
        system "/usr/bin/ssh-keygen -R $self->{host}";
        $self->connect();
      }
      catch {
        return {
          success => 0,
          reason  => $_
        };
      }
    }
    else {
      return {
        success => 0,
        reason  => $_
      };
    }
  };

  # 输出计算结果
  return {success => 1};
} ## end sub login

#------------------------------------------------------------------------------
# H3c 设备 Expect 初始化函数入口
#------------------------------------------------------------------------------
sub connect {
  my ( $self, $args ) = @_;

  # 检查是否携带变量并初始化
  $args = "" unless ( defined $args );
  my $username = $self->{username};
  my $password = $self->{password};
  my $host     = $self->{host};
  my $prompt   = '^\s*\S+[>\]]\s*$';

  # 实例化Expect函数
  my $exp = Expect->new;
  $self->{exp} = $exp;
  $exp->raw_pty(1);
  $exp->restart_timeout_upon_receive(1);

  # 是否打印日志，一般用于排错
  $exp->log_stdout(0);

  #$exp->log_file("output.log");

  # 设置登录逻辑
  my $loginFlag = 1;
  my $command   = $self->{proto} . " $args" . " -l $username $host";
  $exp->spawn($command) || die "Cannot spawn $command: $!\n";
  my @ret = $exp->expect(
    45,
    [ qr/\(yes\/no\)\?\s*\z/mi => sub {
        $exp->send("yes\n");
        exp_continue;
      }
    ],
    [ qr/assword:\s*\z/mi => sub {
        if ($loginFlag) {
          $loginFlag = 0;
          $exp->send("$password\n");
        }
        else {
          croak "username or password is wrong!";
        }
        exp_continue;
      }
    ],
    [ qr/(ogin|name):\s*$/mi => sub {
        $exp->send("$username\n");
        exp_continue;
      }
    ],
    [ qr/$prompt/m => sub {
        $self->{_login_} = 1;
      }
    ],
  );

  # Expect是否异常
  if ( defined $ret[1] ) {
    croak $ret[3] . $ret[1];
  }

  # 是否不做到 [] 超级用户模式
  if ( $exp->match() =~ /\S+\]\s*\z/ ) {
    $self->{_enable_} = 1;
  }

  # 输出计算结果
  return 1;
} ## end sub connect

#------------------------------------------------------------------------------
# H3c 设备抓取运行配置函数入口
#------------------------------------------------------------------------------
sub getconfig {
  my $self = shift;

  # 抓取设备命令脚本，输入不分页命令加速输出
  my @commands = ("dis cur");
  my $config   = $self->execCommands(@commands);
  my $lines    = "";

  # 判断是否执行成功
  if ( $config->{success} == 1 ) {
    $lines = $config->{result};
  }
  else {
    return $config;
  }

  # 输出计算结果
  return {
    success => 1,
    config  => $lines
  };
} ## end sub getconfig

#------------------------------------------------------------------------------
# H3c 设备发送指令入口函数，接收字符串
#------------------------------------------------------------------------------
sub send {
  my ( $self, $command ) = @_;
  my $exp = $self->{exp};
  $exp->send($command);
}

#------------------------------------------------------------------------------
# H3c 设备捕捉命令输入 prompt 回显
#------------------------------------------------------------------------------
sub waitfor {
  my ( $self, $prompt ) = @_;

  # 定义需要捕捉的回显字符串
  $prompt = '[>\]]\s*\z' if not defined $prompt;
  my $exp  = $self->{exp};
  my $buff = "";
  my @ret  = $exp->expect(
    15,
    [ qr/.*more.*$/mi => sub {
        $buff .= $exp->before();

        # 捕捉配置分页关键字无需写入buff
        $exp->send(" ");
        exp_continue;
      }
    ],
    [ qr/Are\s+you\s+sure\?\s*\[Y\/N\]/mi => sub {
        $buff .= $exp->before() . $exp->match();
        $exp->send("Y\n");
        exp_continue;
      }
    ],
    [ qr/press the enter key\)/mi => sub {
        $buff .= $exp->before() . $exp->match();
        $exp->send("\n");
        exp_continue;
      }
    ],
    [ qr/overwrite\?\s*\[Y\/N\]/mi => sub {
        $buff .= $exp->before() . $exp->match();
        $exp->send("Y\n");
        exp_continue;
      }
    ],
    [ qr/^\%.+\z/mi => sub {
        $buff .= $exp->before();
        $exp->send(" ");
        exp_continue;
      }
    ],
    [ qr/$prompt/m => sub {
        $buff .= $exp->before() . $exp->match();
      }
    ]
  );

  # 如果捕捉到异常记录，跳出函数
  if ( defined $ret[1] ) {
    croak $ret[3] . $ret[1];
  }

  # 处理部分非常态字符串
  $buff =~ s/\x1b\[\d+D\s+\x1b\[\d+D//g;
  $buff =~ s/\r\n|\n+\n/\n/g;
  $buff =~ s/^%.+$//mg;
  $buff =~ s/^\s*$//mg;

  # 输出计算结果
  return $buff;
} ## end sub waitfor

#------------------------------------------------------------------------------
# H3c 设备 execCommands 函数入口
#------------------------------------------------------------------------------
sub execCommands {
  my ( $self, @commands ) = @_;

  # 判断是否已登陆设备
  if ( $self->{_login_} == 0 ) {
    my $ret = $self->login();

    # 未登陆成功则返回失败
    return $ret unless ( $ret->{success} );
  }

  # 判断是否进入 enable 模式
  $self->enable() unless $self->{_enable_};
  my $result = "";
  for my $cmd (@commands) {

    # 跳过空白行
    next if $cmd =~ /^\s*$/;
    $self->send( $cmd . "\n" );
    my $buff = $self->waitfor();

    # 异常回显信号捕捉
    if ( $buff =~ /(^\s*\^|error:)/m ) {
      return {
        success     => 0,
        failCommand => $cmd,
        reason      => $result . $buff
      };
    }
    else {
      $result .= $buff;
    }
  } ## end for my $cmd (@commands)

  # 输出计算结果
  return {
    success => 1,
    result  => $result
  };
} ## end sub execCommands

#------------------------------------------------------------------------------
# H3c 设备 enable 函数入口
#------------------------------------------------------------------------------
sub enable {
  my $self     = shift;
  my $username = $self->{username};
  my $enpasswd = $self->{enpassword} // $self->{password};
  my $exp      = $self->{exp};

  # 判断需要进入 enable 后执行
  $exp->send("su\n");
  my $enableFlag = 1;
  my @ret        = $exp->expect(
    15,
    [ qr/assword:\s*$/mi => sub {
        if ($enableFlag) {
          $enableFlag = 0;
          $exp->send("$enpasswd\n");
        }
        else {
          croak "username or enpasswd is wrong!";
        }
        exp_continue;
      }
    ],
    [ qr/(ogin|name):\s*$/mi => sub {
        $exp->send("$username\n");
        exp_continue;
      }
    ],
    [ qr/\(privilege\s+level\s+is.+>\s*\z\)/mi => sub {
        $self->{_enable_} = 1;
        return 1;
      }
    ],
    [ qr/(privilege\s+is\s+.+>\s*\z)/mi => sub {
        $self->{_enable_} = 1;
        return 1;
      }
    ]
  );
  if ( defined $ret[1] ) {
    return $ret[1];
  }
} ## end sub enable

__PACKAGE__->meta->make_immutable;
1;
