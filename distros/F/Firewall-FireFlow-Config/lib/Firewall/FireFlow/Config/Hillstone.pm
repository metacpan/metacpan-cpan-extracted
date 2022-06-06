package Firewall::FireFlow::Config::Hillstone;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use Carp;
use Expect;
use Try::Tiny;
use namespace::autoclean;

has host => (
  is       => 'ro',
  required => 0,
);

has username => (
  is       => 'ro',
  required => 0,
);

has password => (
  is       => 'ro',
  required => 0,
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
  return {success => 1};
} ## end sub login

sub connect {
  my ( $self, $args ) = @_;
  $args = "" unless ( defined $args );
  my $host     = $self->{host};
  my $prompt   = '^.+[#>\$]\s*\z';
  my $username = $self->{username};
  my $password = $self->{password};

  # 实例化Expect
  my $exp = Expect->new;
  $self->{exp} = $exp;
  $exp->raw_pty(1);
  $exp->restart_timeout_upon_receive(1);
  $exp->log_stdout(0);

  # 设置登录逻辑
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
    ][qr/$prompt/mi => sub {
        $self->{_login_} = 1;
      }
    ],
  );
  if ( defined $ret[1] ) {
    croak $ret[3] . $ret[1];
  }
  return 1;
} ## end sub connect

sub getconfig {
  my $self     = shift;
  my @commands = ( "terminal length 0", "show configuration" );
  my $config   = $self->execCommands(@commands);
  my $lines    = "";
  if ( $config->{success} == 1 ) {
    $lines = $config->{result};
  }
  else {
    return $config;
  }
  return {
    success => 1,
    config  => $lines
  };
}

sub send {
  my ( $self, $command ) = @_;
  my $exp = $self->{exp};
  $exp->send($command);
}

sub waitfor {
  my ( $self, $prompt ) = @_;
  $prompt = '^.+[#]\s*\z' unless ( defined $prompt );
  my $exp  = $self->{exp};
  my $buff = "";
  my @ret  = $exp->expect(
    15,
    [ qr/^.+more.+$/mi => sub {
        $exp->send(" ");
        $buff .= $exp->before();
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
  return $buff;
} ## end sub waitfor

sub execCommands {
  my ( $self, @commands ) = @_;

  # 待更新配置自动保存逻辑
  if ( $self->{_login_} == 0 ) {
    my $ret = $self->login();
    return $ret unless ( $ret->{success} );
  }

  # 批处理下发队列
  my $result = "";
  for my $cmd (@commands) {
    next if $cmd =~ /^\s*$/;
    $self->send( $cmd . "\n" );
    my $buff = $self->waitfor();
    if ( $buff =~ /\^-+/mi ) {
      return {
        success     => 0,
        failCommand => $cmd,
        reason      => $result . $buff
      };
    }
    else {
      $result .= $buff;
    }
  }
  return {
    success => 1,
    result  => $result
  };
} ## end sub execCommands

__PACKAGE__->meta->make_immutable;
1;
