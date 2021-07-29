package Lemonldap::NG::Portal::Lib::_tokenRule;

use strict;
use Mouse;

our $VERSION = '2.0.12';

has ottRule => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $rule = $_[0]->conf->{requireToken};
        my $hd   = $_[0]->p->HANDLER;
        $rule = $hd->buildSub( $hd->substitute($rule) );
        unless ($rule) {
            $_[0]->logger->error(
                'Unable to compile "requireToken" rule => Forcing token');
            $rule = sub { 1 };
        }
        return $rule;
    }
);

sub init {
    return 1;
}

1;
