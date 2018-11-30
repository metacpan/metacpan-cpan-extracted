package Lemonldap::NG::Portal::Lib::OtherSessions;

use strict;
use Mouse;

our $VERSION = '2.0.0';

has module =>
  ( is => 'rw', default => 'Lemonldap::NG::Common::Apache::Session' );

has moduleOpts => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my %opts = %{ $_[0]->{conf}->{globalStorageOptions} || {} };
        $opts{backend} = $_[0]->{conf}->{globalStorage};
        return \%opts;
    }
);

1;
