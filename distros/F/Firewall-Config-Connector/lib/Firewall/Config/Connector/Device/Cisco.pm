package Firewall::Config::Connector::Device::Cisco;

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use Try::Tiny;
use Expect;

#------------------------------------------------------------------------------
# 定义设备 Connector 通用属性
#------------------------------------------------------------------------------
has host => ( is => 'ro', required => 1, );

has username => ( is => 'ro', required => 0, default => 'read', );

has password => ( is => 'ro', required => 1, default => '', );

has enpassword => ( is => 'ro', required => 0, );

has proto => ( is => 'ro', required => 0, default => 'ssh', );

has _login_ => ( is => 'ro', required => 0, default => 0, );

has _enable_ => ( is => 'ro', required => 0, default => 0, );

#------------------------------------------------------------------------------
# Cisco 设备登陆函数入口
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
        return {success => 0, reason => $_};
      }
    }
    elsif (/Selected cipher type <unknown> not supported/mi) {
      try {
        $self->connect('-c des ');
      }
      catch {
        return {success => 0, reason => $_};
      }
    }
    elsif (/Connection refused/mi) {
      try {
        $self->{proto} = 'telnet';
        $self->connect();
      }
      catch {
        return {success => 0, reason => $_};
      }
    }
    elsif (/IDENTIFICATION HAS CHANGED/mi) {
      try {
        system "/usr/bin/ssh-keygen -R $self->{host}";
        $self->connect();
      }
      catch {
        return {success => 0, reason => $_};
      }
    }
    else {
      return {success => 0, reason => $_};
    }
  };

  # 如果未捕捉到异常信号，则登陆成功
  return {success => 1};
}

#------------------------------------------------------------------------------
# Cisco 设备 Expect 初始化函数入口
#------------------------------------------------------------------------------
sub connect {
  my ( $self, $args ) = @_;

  # 检查是否携带变量并初始化
  $args = "" unless ( defined $args );
  my $host     = $self->{host};
  my $prompt   = '\S+[#>]\s*\z';
  my $username = $self->{username};
  my $password = $self->{password};

  # 初始化Expect函数
  my $exp = Expect->new();
  $self->{exp} = $exp;
  $exp->raw_pty(1);
  $exp->restart_timeout_upon_receive(1);

  # 是否打印日志，一般用于排错
  $exp->log_stdout(0);

  # 初始化登陆变量
  my $login_flag = 1;
  my $command    = $self->{proto} . " $args" . " -l $username $host";
  $exp->spawn($command) || die "Cannot spawn $command: $!\n";
  my @ret = $exp->expect(
    45,
    [ qr/\(yes\/no\)\?\s*$/mi => sub {
        $exp->send("yes\n");
        exp_continue;
      }
    ],
    [ qr/assword:\s*$/mi => sub {
        if ($login_flag) {
          $login_flag = 0;
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
    [ qr/$prompt/ => sub {
        $self->{_login_} = 1;
      }
    ],
  );

  # Expect是否异常
  if ( defined $ret[1] ) {
    croak $ret[3] . $ret[1];
  }

  # 是否进入 enable 模式
  if ( $exp->match() =~ /#/ ) {
    $self->{_enable_} = 1;
  }

  # 返回计算结果
  return 1;
}

#------------------------------------------------------------------------------
# Cisco 设备抓取运行配置函数入口
#------------------------------------------------------------------------------
sub  {
  my $self = shift;

  # 抓取设备命令脚本，输入不分页命令加速输出
  my @commands = ( "term page 0", "show run | exclude !Time" );
  my $config   = $self->execCommands(@commands);
  my $lines    = "";

  # 判断是否执行成功
  if ( $config->{success} == 1 ) {
    $lines = $config->{result};

    # 处理非常态配置，影响计算哈希
    $lines =~ s/^\s*ntp\s+clock-period\s+\d+\s*$//mi;
  }
  else {
    return $config;
  }

  # 返回计算结果
  return {success => 1, config => $lines};
}

#------------------------------------------------------------------------------
# Cisco 设备发送指令入口函数，接收字符串
#------------------------------------------------------------------------------
sub send {
  my ( $self, $command ) = @_;
  my $exp = $self->{exp};
  $exp->send($command);
}

#------------------------------------------------------------------------------
# Cisco 设备捕捉命令输入 prompt 回显
#------------------------------------------------------------------------------
sub waitfor {
  my ( $self, $prompt ) = @_;

  # 定义需要捕捉的回显字符串
  $prompt = '\S+[>#]\s*\z' unless ( defined $prompt );
  my $exp  = $self->{exp};
  my $buff = "";
  my @ret  = $exp->expect(
    15,
    [ qr/^.+more\s*.+$/mi => sub {
        $exp->send(" ");

        # 捕捉配置分页关键字无需写入buff
        $buff .= $exp->before();
        exp_continue;
      }
    ],
    [ qr/\[startup-config\]\?/mi => sub {
        $exp->send("\n");
        $buff .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [ qr/Save\? \[yes\/no\]/mi => sub {
        $exp->send("yes\n");
        $buff .= $exp->before() . $exp->match();
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
  $buff =~ s/\r\n|\n+\n/\n/g;
  $buff =~ s/\x{08}+\s+\x{08}+//g;

  # 输出计算结果
  return $buff;
}

#------------------------------------------------------------------------------
# Cisco 设备 execCommands 函数入口
#------------------------------------------------------------------------------
sub execCommands {
  my ( $self, @commands ) = @_;

  # 判断是否已登陆设备
  if ( not $self->{_login_} ) {
    my $result = $self->login();

    # 未登陆成功则返回失败
    return $result unless ( $result->{success} );
  }

  # 判断是否进入 enable 模式
  $self->enable() unless ( $self->{_enable_} );

  # 初始化 result 变量，并开始执行命令
  my $result = "";

  # 遍历数组 @commands，依次执行（数组有序）
  for my $cmd (@commands) {

    # 跳过空白行
    next if $cmd =~ /^\s*$/;
    $self->send( $cmd . "\n" );
    my $buff = $self->waitfor();

    # 异常回显信号捕捉
    if ( $buff =~ /(Invalid input detected|Incomplete command)/i ) {
      return {success => 0, failCommand => $cmd, reason => $result . $buff};
    }
    else {
      $result .= $buff;
    }
  }

  # 输出计算结果
  return {success => 1, result => $result};
}

#------------------------------------------------------------------------------
# Cisco 设备 enable 函数入口
#------------------------------------------------------------------------------
sub enable {
  my $self     = shift;
  my $username = $self->{username};
  my $enpasswd = $self->{enpassword} // $self->{password};
  my $exp      = $self->{exp};

  # 判断需要进入 enable 后执行
  $exp->send("enable\n");
  my $enable_flag = 1;
  my @ret         = $exp->expect(
    10,
    [ qr/assword:\s*$/mi => sub {
        if ($enable_flag) {
          $enable_flag = 0;
          $exp->send("$enpasswd\n");
        }
        else {
          croak "username or enpasswd is wrong !";
        }
        exp_continue;
      }
    ],
    [ qr/(name|ogin):\s*$/mi => sub {
        $exp->send("$username\n");
        exp_continue;
      }
    ],
    [ qr/\S+#\s*\z/ => sub {
        return 1;
      }
    ]
  );

  # 异常回显信号捕捉
  if ( defined $ret[1] ) {
    confess $ret[3] . $ret[1];
  }
}

__PACKAGE__->meta->make_immutable;
1;
