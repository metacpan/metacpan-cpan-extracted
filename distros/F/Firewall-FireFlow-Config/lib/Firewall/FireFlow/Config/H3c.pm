package Firewall::FireFlow::Config::H3c;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use Carp;
use Expect;
use Try::Tiny;
use namespace::autoclean;

has host => ( is => 'ro', required => 0, );

has username => ( is => 'ro', required => 0, default => 'read' );

has password => ( is => 'ro', required => 0, default => '', );

has enpassword => ( is => 'ro', required => 0, );

has proto => ( is => 'ro', required => 0, default => 'ssh', );

has _login_ => ( is => 'ro', required => 0, default => 0, );

has _enable_ => ( is => 'ro', required => 0, default => 0, );

sub login {
  my $self = shift;
  return {success => 1} if $self->{_login_};
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
  return {success => 1};
} ## end sub login

sub connect {
  my ( $self, $args ) = @_;
  $args = "" unless ( defined $args );
  my $host     = $self->{host};
  my $prompt   = '^\s*\S+[>\]]\s*$';
  my $username = $self->{username};
  my $password = $self->{password};

  # 实例化Expect函数
  my $exp = Expect->new;
  $self->{exp} = $exp;
  $exp->raw_pty(1);
  $exp->restart_timeout_upon_receive(1);
  $exp->log_stdout(0);

  # 设置登陆逻辑
  my $loginFlag = 1;
  my $command   = $self->{proto} . " $args" . " -l $username $host";
  $exp->spawn($command) || die "Cannot spawn $command: $!\n";
  my @ret = $exp->expect(
    45,
    [ qr/\(yes\/no\)\?\s*$/mi => sub {
        $exp->send("yes\n");
        exp_continue;
      }
    ],
    [ qr/assword:\s*$/mi => sub {
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
    [ qr/$prompt/mi => sub {
        $self->{_login_} = 1;
      }
    ],
  );
  if ( defined $ret[1] ) {
    croak $ret[3] . $ret[1];
  }
  if ( $exp->match() =~ /\]\s*\z/ ) {
    $self->{_enable_} = 1;
  }
  return 1;
} ## end sub connect

sub getconfig {
  my $self = shift;

  # 待确认TERMINAL LENGTH 0指令是否正确
  my @commands = ( "set screen-length tem 0", "dis cur" );
  my $config   = $self->execCommands(@commands);
  my $lines    = "";
  if ( $config->{success} == 1 ) {
    $lines = $config->{result};
  }
  else {
    return $config;
  }
  return {success => 1, config => $lines};
}

sub send {
  my ( $self, $command ) = @_;
  my $exp = $self->{exp};
  $exp->send($command);
}

sub waitfor {
  my ( $self, $prompt ) = @_;
  $prompt = '^.+[>\]]\s*\z' unless ( defined $prompt );
  my $exp  = $self->{exp};
  my $buff = "";
  my @ret  = $exp->expect(
    15,
    [ qr/^.+more.+$/mi => sub {
        $buff .= $exp->before();
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
    [ qr/$prompt/mi => sub {
        $buff .= $exp->before() . $exp->match();
      }
    ]
  );
  if ( defined $ret[1] ) {
    croak $ret[3] . $ret[1];
  }
  $buff =~ s/\x1b\[\d+D\s+\x1b\[\d+D//g;
  $buff =~ s/\r\n|\n+\n/\n/g;
  $buff =~ s/^%.+$//mg;
  $buff =~ s/^\s*$//mg;
  return $buff;
} ## end sub waitfor

sub execCommands {
  my ( $self, @commands ) = @_;

  # 配置下发前检查是否已成功登陆设备
  if ( $self->{_login_} == 0 ) {
    my $ret = $self->login();
    return $ret unless ( $ret->{success} );
  }
  $self->enable() unless ( $self->{_enable_} );

  # 批处理下发队列
  my $result = "";
  for my $cmd (@commands) {
    next if $cmd =~ /^\s*$/;
    $self->send( $cmd . "\n" );
    my $buff = $self->waitfor();
    if ( $buff =~ /(^\s*\^|error:)/mi ) {
      return {success => 0, failCommand => $cmd, reason => $result . $buff};
    }
    else {
      $result .= $buff;
    }
  }
  return {success => 1, result => $result};
} ## end sub execCommands

sub getRuleId {
  my $self = shift;
  $self->send("dis this\n");
  my $buff = $self->waitfor();
  if ( $buff =~ /rule\s+(?<ruleId>\d+)\s+pass[^\n]+\n\s*#/si ) {
    return $+{ruleId};
  }
  else {
    return;
  }
}

sub enable {
  my $self     = shift;
  my $username = $self->{username};
  my $enpasswd = $self->{enpassword} // $self->{password};
  my $exp      = $self->{exp};
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
    [ qr/\(privilege\s+is\s+.+>\s*\z\)/mi => sub {
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
