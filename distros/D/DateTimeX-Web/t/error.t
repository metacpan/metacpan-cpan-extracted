use strict;
use warnings;
use Test::More;
use DateTimeX::Web;

BEGIN {
  eval "use Test::Exception";
  if ($@) {
    plan skip_all => 'requires Test::Exception';
    exit;
  }
}

plan 'no_plan';

{ # should croak
  my $dtx = DateTimeX::Web->new( on_error => 'croak' );

  dies_ok { $dtx->from( year => 2007, month => 15 ); };
}

{ # should not croak
  my $dtx = DateTimeX::Web->new( on_error => 'ignore' );

  lives_ok { $dtx->from( year => 2007, month => 15 ); };
}

{ # callback
  my $error;
  my $dtx = DateTimeX::Web->new( on_error => sub { $error = "error: ".shift } );

  lives_ok { $dtx->from( year => 2007, month => 15 ); };
  like $error => qr/^error: /, $error;
}
