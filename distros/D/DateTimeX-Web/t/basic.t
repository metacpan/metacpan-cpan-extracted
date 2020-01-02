use strict;
use warnings;
use Test::More qw(no_plan);
use DateTimeX::Web;

my %args = (
  year   => 2000,
  month  => 5,
  day    => 6,
  hour   => 15,
  minute => 37,
  second => 45,
);

{ # create a DateTime object with now
  my $dtx = DateTimeX::Web->new;

  my $dt = $dtx->now;
  ok defined $dt;
  ok $dt->isa('DateTime');
}

{ # create a DateTime object with today
  my $dtx = DateTimeX::Web->new;

  my $dt = $dtx->today;
  ok defined $dt;
  ok $dt->isa('DateTime');
}

{ # create a DateTime object with last_day_of_month
  my $dtx = DateTimeX::Web->new;

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  my $dt = $dtx->last_day_of_month( year => $year, month => $mon+1 );
  ok defined $dt;
  ok $dt->isa('DateTime');
}

{ # create a DateTime object with from_day_of_year
  my $dtx = DateTimeX::Web->new;

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  my $dt = $dtx->from_day_of_year( year => $year, day_of_year => $yday + 1);
  ok defined $dt;
  ok $dt->isa('DateTime');
}

{ # create a DateTime object with from_epoch
  my $dtx = DateTimeX::Web->new;

  my $dt = $dtx->from_epoch(time);
  ok defined $dt;
  ok $dt->isa('DateTime');
}

{ # from_epoch can have "epoch =>"
  my $dtx = DateTimeX::Web->new;

  my $dt = $dtx->from_epoch(epoch => time);
  ok defined $dt;
  ok $dt->isa('DateTime');
}

{ # create a DateTime object with from and epoch
  my $dtx = DateTimeX::Web->new;

  my $dt = $dtx->from(epoch => time);
  ok defined $dt;
  ok $dt->isa('DateTime');
}

{ # create a DateTime object with from_object
  my $dtx = DateTimeX::Web->new;

  my $dt = $dtx->from_object(DateTime->now);
  ok defined $dt;
  ok $dt->isa('DateTime');
}

{ # from_object can have "object =>"
  my $dtx = DateTimeX::Web->new;

  my $dt = $dtx->from_object(object => DateTime->now);
  ok defined $dt;
  ok $dt->isa('DateTime');
}

{ # create a DateTime object with from and object
  my $dtx = DateTimeX::Web->new;

  my $dt = $dtx->from(object => DateTime->now);
  ok defined $dt;
  ok $dt->isa('DateTime');
}

{ # create a DateTime object with from and args
  my $dtx = DateTimeX::Web->new;

  my $dt = $dtx->from( %args );
  ok defined $dt;
  ok $dt->isa('DateTime');
}
