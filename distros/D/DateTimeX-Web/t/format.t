use strict;
use warnings;
use lib 't/lib';
use Test::More qw(no_plan);
use DateTimeX::Web;

my $mysql_datetime = "2000-05-06 15:23:44";

{ # Let's replace the mail formatter with DateTime::Format::MySQL
  my $dtx = DateTimeX::Web->new( on_error => 'ignore' );

  $dtx->format( mail => 'DateTime::Format::MySQL' );

  my $dt = $dtx->from_mail( $mysql_datetime );
  ok defined $dt;
}

{ # you can omit "DateTime::Format::"
  my $dtx = DateTimeX::Web->new( on_error => 'ignore' );

  $dtx->format( mail => 'MySQL' );
  my $dt = $dtx->from_mail( $mysql_datetime );
  ok defined $dt;
}

{ # you can pass an object, too.
  my $dtx = DateTimeX::Web->new( on_error => 'ignore' );

  $dtx->format( mail => DateTime::Format::MySQL->new );
  my $dt = $dtx->from_mail( $mysql_datetime );
  ok defined $dt;
}

{ # prepend "+" to load arbitrary format
  my $dtx = DateTimeX::Web->new( on_error => 'ignore' );

  $dtx->format( mail => '+MyFormat' );
  my $dt = $dtx->from_mail( $mysql_datetime );
  ok defined $dt;
}

{ # DateTime::Format::HTTP has no new
  my $dtx = DateTimeX::Web->new( on_error => 'ignore' );
  my $dt;
  eval { $dt = $dtx->format( http => 'HTTP' ); };
  ok !$@;
  ok defined $dt;
}
