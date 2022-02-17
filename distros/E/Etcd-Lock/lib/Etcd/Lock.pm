package Etcd::Lock;
$Etcd::Lock::VERSION = '0.03';
use 5.012;

use Net::Etcd;
use boolean;

sub new {
    my $c = shift;
    my %a = @_;
    my %b;
    $b{etcd} = Net::Etcd->new( { host => $a{host} } );
    $b{ttl}  = 3600;
    foreach (qw/host key ttl/) {
        $b{$_} = $a{$_} if (exists $a{$_});
    }
    return bless \%b, $c;
}

sub lock {
    my $s = shift;
    return $s->_lock_unlock(true);
}

sub unlock {
    my $s = shift;
    return $s->_lock_unlock(false);
}

sub ttl {
    my $s = shift;
    $s->{ttl} = shift if @_;
    return $s->{ttl};
}

sub _lock_unlock ( ) {
    my $s    = shift;
    my $nval = shift;
    my $k    = $s->{key};

    my $val = $s->{etcd}->range( { key => $k } )->get_value;
    return $val unless defined $nval;
    return false if defined $val && $val eq $nval;
    my $lid = $s->_lease_id;
    if ($nval) {
        $s->{etcd}->lease( { ID => $lid, TTL => $s->{ttl} } )->grant;
        $s->{etcd}->put( { key => $k, value => $nval, lease => $lid } );
    }
    else {
        $s->{etcd}->deleterange( { key => $k } );
        $s->{etcd}->lease( { ID => $lid } )->revoke;
    }
    return true;
}

sub _lease_id {
    my $s = shift;
    state $leased_id //= $$ . time;
    return $leased_id;
}

1;

=pod

=head1 NAME

Etcd::Lock - Lock based on etcd

=for html <p>
    <a href="https://github.com/emilianobruni/etcd-lock/actions/workflows/test.yml">
        <img alt="github workflow tests" src="https://github.com/emilianobruni/etcd-lock/actions/workflows/test.yml/badge.svg">
    </a>
    <img alt="Top language: " src="https://img.shields.io/github/languages/top/emilianobruni/etcd-lock">
    <img alt="github last commit" src="https://img.shields.io/github/last-commit/emilianobruni/etcd-lock">
</p>

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use Etcd::Lock

  my $etcdLock = Etcd::Lock->new(host => 'host.name.com', key => 'lock_key');
  $etcdLock->lock();
  ... do_something ...
  $etcdLock->unlock();

=head1 DESCRIPTION

Etcd::Lock is a lock based on etcd. When a key is locked, try to lock same key
return false. Key is unlocked automatically when ttl seconds expired.

=encoding UTF-8

=head1 METHODS

=head2 lock()

Return true if key is unlocked. Now it's locked.

=head2 unlock()

Return true if key is locked. Now it's unlocked

=head2 ttl(new_ttl)

Set or return after how many seconds a lock is automatically removed.
Defaul: 3600.

=head1 BUGS/CONTRIBUTING

Please report any bugs through the web interface at L<https://github.com/EmilianoBruni/etcd-lock/issues>

If you want to contribute changes or otherwise involve yourself in development, feel free to fork the Git repository from
L<https://github.com/EmilianoBruni/etcd-lock/>.

=head1 SUPPORT

You can find this documentation with the perldoc command too.

    perldoc etcd-lock

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Lock based on etcd

