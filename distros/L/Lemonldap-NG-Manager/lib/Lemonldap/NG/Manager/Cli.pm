package Lemonldap::NG::Manager::Cli;

use strict;
use Mouse;
use Data::Dumper;
use Lemonldap::NG::Manager::Constants;

extends('Lemonldap::NG::Manager::Cli::Lib');

has cfgNum => (
    is      => 'rw',
    isa     => 'Int',
    trigger => sub {
        $_[0]->{req} =
          Lemonldap::NG::Manager::Cli::Request->new(
            cfgNum => $_[0]->{cfgNum} );
    }
);

has sep => ( is => 'rw', isa => 'Str', default => '/' );

has req => ( is => 'ro' );

has format => ( is => 'rw', isa => 'Str', default => "%-25s | %-25s | %-25s" );

has yes => ( is => 'rw', isa => 'Bool', default => 0 );

has force => ( is => 'rw', isa => 'Bool', default => 0 );

sub get {
    my ( $self, @keys ) = @_;
    die 'get requires at least one key' unless (@keys);
  L: foreach my $key (@keys) {
        my $value = $self->_getKey($key);
        if ( ref $value eq 'HASH' ) {
            print "$key has the following keys:\n";
            print "   $_\n" foreach ( sort keys %$value );
        }
        else {
            $value //= '';
            print "$key = $value\n";
        }
    }
}

sub set {
    my ( $self, %pairs ) = @_;
    my $format = $self->format . "\n";
    die 'set requires at least one key and one value' unless (%pairs);
    my @list;
    foreach my $key ( keys %pairs ) {
        my $oldValue = $self->_getKey($key);
        if ( ref $oldValue ) {
            die "$key seems to be a hash, modification refused";
        }
        push @list, [ $key, $oldValue, $pairs{$key} ];
    }
    unless ( $self->yes ) {
        print "Proposed changes:\n";
        printf $format, 'Key', 'Old value', 'New value';
        foreach (@list) {
            printf $format, @$_;
        }
        print "Confirm (N/y)? ";
        my $c = <STDIN>;
        unless ( $c =~ /^y(?:es)?$/ ) {
            die "Aborting";
        }
    }
    require Clone;
    my $new = Clone::clone( $self->mgr->currentConf );
    foreach my $key ( keys %pairs ) {
        $self->_setKey( $new, $key, $pairs{$key} );
    }
    return $self->_save($new);
}

sub addKey {
    my $self = shift;
    unless ( @_ % 3 == 0 ) {
        die 'usage: "addKey (?:rootKey newKey newValue)+';
    }
    my $sep = $self->sep;
    my @list;
    while (@_) {
        my $root   = shift;
        my $newKey = shift;
        my $value  = shift;
        unless ( $root =~ /$simpleHashKeys$/o or $root =~ /$sep/o ) {
            die "$root is not a simple hash. Aborting";
        }
        push @list, [ $root, $newKey, $value ];
    }
    require Clone;
    my $new = Clone::clone( $self->mgr->currentConf );
    foreach my $el (@list) {
        my @path = split $sep, $el->[0];
        if ( $#path == 0 ) {
            $new->{ $path[0] }->{ $el->[1] } = $el->[2];
        }
        elsif ( $#path == 1 ) {
            $new->{ $path[0] }->{ $path[1] }->{ $el->[1] } = $el->[2];
        }
        else {
            die $el->[0] . " has too many levels. Aborting";
        }
    }
    return $self->_save($new);
}

sub delKey {
    my $self = shift;
    unless ( @_ % 2 == 0 ) {
        die 'usage: "delKey (?:rootKey key)+';
    }
    my $sep = $self->sep;
    my @list;
    while (@_) {
        my $root = shift;
        my $key  = shift;
        unless ( $root =~ /$simpleHashKeys$/o or $root =~ /$sep/o ) {
            die "$root is not a simple hash. Aborting";
        }
        push @list, [ $root, $key ];
    }
    require Clone;
    my $new = Clone::clone( $self->mgr->currentConf );
    foreach my $el (@list) {
        my @path = split $sep, $el->[0];
        if ( $#path == 0 ) {
            delete $new->{ $path[0] }->{ $el->[1] };
        }
        elsif ( $#path == 1 ) {
            delete $new->{ $path[0] }->{ $path[1] }->{ $el->[1] };
        }
        else {
            die $el->[0] . " has too many levels. Aborting";
        }
    }
    return $self->_save($new);
}

sub lastCfg {
    my ($self) = @_;
    return $self->jsonResponse('/confs/latest')->{cfgNum};
}

sub _getKey {
    my ( $self, $key ) = @_;
    my $sep = $self->sep;
    my ( $base, @path ) = split $sep, $key;
    unless ( $base =~ /^\w+$/ ) {
        warn "Malformed key $base";
        return ();
    }
    my $value = $self->mgr->getConfKey( $self->req, $base, noCache => 1 );
    if ( $self->req->error ) {
        die $self->req->error;
    }
    if ( ref $value eq 'HASH' ) {
        while ( my $next = shift @path ) {
            unless ( exists $value->{$next} ) {
                warn "Unknown subkey $next for $key";
                next L;
            }
            $value = $value->{$next};
        }
    }
    elsif (@path) {
        warn "No subkeys for $base";
        return ();
    }
    return $value;
}

sub _setKey {
    my ( $self, $conf, $key, $value ) = @_;
    my $sep = $self->sep;
    my (@path) = split $sep, $key;
    my $last = pop @path;
    while ( my $next = shift @path ) {
        $conf = $conf->{$next};
    }
    $conf->{$last} = $value;
}

sub _save {
    my ( $self, $new ) = @_;
    require Lemonldap::NG::Manager::Conf::Parser;
    my $parser = Lemonldap::NG::Manager::Conf::Parser->new(
        {
            newConf => $new,
            refConf => $self->mgr->currentConf,
            req     => $self->req
        }
    );
    unless ( $parser->testNewConf() ) {
        printf STDERR "Modifications rejected: %s:\n", $parser->{message};
    }
    my $s = $self->mgr->confAcc->saveConf( $new, { force => $self->force } );
    if ( $s > 0 ) {
        print STDERR "Saved under number $s\n";
        $parser->{status} = [ $self->mgr->applyConf($new) ];
    }
    else {
        printf STDERR "Modifications rejected: %s:\n", $parser->{message};
        print STDERR Dumper($parser);
    }
    foreach (qw(errors warnings status)) {
        if ( $parser->{$_} and @{ $parser->{$_} } ) {
            my $s = Dumper( $parser->{$_} );
            $s =~ s/\$VAR1\s*=\s*//;
            printf STDERR "%-8s: %s", ucfirst($_), $s;
        }
    }
}

sub run {
    my $self = shift;

    print STDERR "VERY EXPERIMENTAL FEATURE, prefer web interface\n";

    # Options simply call corresponding accessor
    my $args = {};
    while ( $_[0] =~ s/^--?// ) {
        my $k = shift;
        my $v = shift;
        if ( ref $self ) {
            eval { $self->$k($v) };
            if ($@) {
                die "Unknown option -$k or bad value ($@)";
            }
        }
        else {
            $args->{$k} = $v;
        }
    }
    unless ( ref $self ) {
        $self = $self->new($args);
    }
    unless (@_) {
        die 'nothing to do, aborting';
    }
    $self->cfgNum( $self->lastCfg ) unless ( $self->cfgNum );
    my $action = shift;
    unless ( $action =~ /^(?:get|set|addKey|delKey)$/ ) {
        die
"unknown action $action. Only get, set, addKey or delKey are accepted";
    }
    $self->$action(@_);
}

package Lemonldap::NG::Manager::Cli::Request;

use Mouse;

has cfgNum => ( is => 'rw' );

has error => ( is => 'rw' );

sub params {
    my ( $self, $key ) = @_;
    return $self->{$key};
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Manager::Cli - EXPERIMENTAL command line manager for
Lemonldap::NG web SSO system.

=head1 SYNOPSIS

  #!/usr/bin/env perl
  
  use warnings;
  use strict;
  use Lemonldap::NG::Manager::Cli;
  
  # Optional: you can specify here some parameters
  my $cli = Lemonldap::NG::Manager::Cli->new(iniFile=>'t/lemonldap-ng.ini');
  
  $cli->run(@ARGV);

or use llng-manager-cli provides with this package.

  llng-manager-cli <options> <command> <keys>

=head1 DESCRIPTION

Lemonldap::NG::Manager provides a web interface to manage Lemonldap::NG Web-SSO
system.

Lemonldap::NG Manager::Cli provides an EXPERIMENTAL command line client to read
or modify configuration.

=head1 METHODS

=head2 ACCESSORS

All accessors can be set using the command line: just set a '-' before their
names. Example

  llng-manager-cli -sep ',' get macros,_whatToTrace

=head3 iniFile()

The lemonldap-ng.ini file to use is not default value.

=head3 sep()

The key separator, default to '/'. For example to read the value of macro
_whatToTrace using ',', use:

  llng-manager-cli -sep ',' get macros,_whatToTrace

=head3 cfgNum()

The configuration number. If not set, it will use the latest configuration.

=head3 yes()

If set to 1, no confirmation is asked to save new values:

  llng-manager -yes 1 set portal http://somewhere/

=head3 force()

Set it to 1 to save a configuration earlier than latest

=head3 format()

Confirmation array line format. Default to "%-25s | %-25s | %-25s"

=head2 run()

The main method: it reads option, command and launch the corresponding
subroutine.

=head3 Commands

=head4 get

Using get, you can read several keys. Example:

  llng-manager-cli get portal cookieName domain

=head1 SEE ALSO

For other features of llng-cli, see L<Lemonldap::NG::Common::Cli>

Other links: L<Lemonldap::NG::Manager>, L<http://lemonldap-ng.org/>

=head1 AUTHORS

Original idea from David Delassus in 2012.

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item David Delassus, E<lt>linkdd@cpan.orgE<gt>

=item François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Thomas Chemineau, E<lt>thomas.chemineau@gmail.comE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2015-2016 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2015-2016 by Clément Oudot, E<lt>clem.oudot@gmail.comE<gt>

=back

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut
