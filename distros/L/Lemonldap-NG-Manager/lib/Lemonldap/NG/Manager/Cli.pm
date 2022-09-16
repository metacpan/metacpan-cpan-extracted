package Lemonldap::NG::Manager::Cli;

use strict;
use Crypt::URandom;
use Mouse;
use Data::Dumper;
use JSON;
use Hash::Merge::Simple;
use Lemonldap::NG::Common::Conf::ReConstants;

our $VERSION = '2.0.12';
$Data::Dumper::Useperl = 1;

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

has log    => ( is => 'rw' );
has req    => ( is => 'ro' );
has sep    => ( is => 'rw', isa => 'Str',  default => '/' );
has format => ( is => 'rw', isa => 'Str',  default => "%-25s | %-25s | %-25s" );
has yes    => ( is => 'rw', isa => 'Bool', default => 0 );
has safe   => ( is => 'rw', isa => 'Bool', default => 0 );
has force  => ( is => 'rw', isa => 'Bool', default => 0 );
has logger => ( is => 'ro', lazy => 1, builder => sub { $_[0]->mgr->logger } );
has userLogger =>
  ( is => 'ro', lazy => 1, builder => sub { $_[0]->mgr->userLogger } );
has localConf => ( is => 'ro', lazy => 1, builder => sub { $_[0]->mgr } );

sub get {
    my ( $self, @keys ) = @_;
    die 'get requires at least one key' unless (@keys);
  L: foreach my $key (@keys) {
        my $value = $self->_getKey($key);
        if ( ref $value eq 'HASH' ) {
            print "$key has the following keys:\n";
            print "   $_\n" foreach ( sort keys %$value );
        }
        elsif ( ref $value eq 'ARRAY' ) {
            print "$key is an array with values:\n";
            foreach my $avalue (@$value) {
                if ( ref $avalue eq 'HASH' ) {
                    print "\tHash with following keys:\n";
                    print "\t\t$_\n" foreach ( sort keys %$avalue );
                }
                elsif ( ref $value eq 'ARRAY' ) {
                    print "\tArray with following keys:\n";
                    print "\t\t$_\n" foreach (@$avalue);
                }
                else {
                    $avalue //= '';
                    print "\tValue = $avalue\n";
                }
            }
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
        $oldValue //= '';
        $self->logger->info("CLI: Set key $key with $pairs{$key}");
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
    my $new = Clone::clone( $self->mgr->hLoadedPlugins->{conf}->currentConf );
    foreach my $key ( keys %pairs ) {
        $self->_setKey( $new, $key, $pairs{$key} );
    }
    return $self->_save($new);
}

sub del {
    my ( $self, @keys ) = @_;
    die 'del requires at least one key' unless (@keys);
    my $oldValues = {};
    foreach my $key (@keys) {
        my $value = $self->_getKey($key);
        if ( ref $value eq 'HASH' ) {
            print STDERR "$key seems to be a hash, delete refused\n";
            next;
        }
        unless ( defined $value ) {
            print STDERR "$key does not exists, skip it\n";
            next;
        }
        $oldValues->{$key} = $value;
    }
    return unless keys %$oldValues;
    unless ( $self->yes ) {
        print "Proposed changes:\n";
        printf "%-25s | %-25s\n", 'Key', 'Old value';
        foreach ( keys %$oldValues ) {
            printf "%-25s | %-25s\n", $_, $oldValues->{$_};
        }
        print "Confirm (N/y)? ";
        my $c = <STDIN>;
        unless ( $c =~ /^y(?:es)?$/ ) {
            die "Aborting";
        }
    }
    require Clone;
    my $new = Clone::clone( $self->mgr->hLoadedPlugins->{conf}->currentConf );
    foreach ( keys %$oldValues ) {
        delete $new->{$_};
    }
    return $self->_save($new);
}

sub merge {
    my ( $self, @files ) = @_;
    die 'merge requires at least one file' unless (@files);
    require Clone;
    my $old = Clone::clone( $self->mgr->hLoadedPlugins->{conf}->currentConf );
    my $new;
    my @valid_files;

    foreach my $file (@files) {

        my $merging;
        if ( $file =~ /\.ya?ml/ ) {
            eval {
                require YAML;
                $merging = YAML::LoadFile($file);
            };
            if ($@) {
                print STDERR "Skipping invalid YAML file $file: " . $@;
            }
        }
        else {
            eval {
                local $/ = undef;
                open my $fh, '<', $file or die $!;
                $merging = from_json(<$fh>);
            };
            if ($@) {
                print STDERR "Skipping invalid JSON file $file: " . $@;
            }
        }
        if ( ref($merging) eq "HASH" ) {
            $new = Hash::Merge::Simple::merge( $new, $merging );
            push @valid_files, $file;
        }
    }
    die "Nothing to do" unless ref($new) eq "HASH";

    unless ( $self->yes ) {
        print "Merge configuration changes from "
          . join( " ", @valid_files ) . " \n";
        print Dumper($new);
        print "Confirm (N/y)? ";
        my $c = <STDIN>;
        unless ( $c =~ /^y(?:es)?$/ ) {
            die "Aborting";
        }
    }

    $new = Hash::Merge::Simple::merge( $old, $new );
    _clean_hash_undef($new);
    return $self->_save($new);
}

# Remove key => undef from hashes
# This allows you to remove keys from the config
sub _clean_hash_undef {
    my ($hash) = @_;
    for my $key ( keys %$hash ) {
        if ( !defined( $hash->{$key} ) ) {
            delete $hash->{$key};
        }
        if ( ref( $hash->{$key} ) eq "HASH" ) {
            _clean_hash_undef( $hash->{$key} );
        }
    }
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
        $self->logger->info("CLI: Append key $root/$newKey $value");
        push @list, [ $root, $newKey, $value ];
    }
    require Clone;
    my $new = Clone::clone( $self->mgr->hLoadedPlugins->{conf}->currentConf );
    foreach my $el (@list) {
        my @path = split $sep, $el->[0];
        if ( $#path == 0 ) {
            $new->{ $path[0] }->{ $el->[1] } = $el->[2];
        }
        elsif ( $#path == 1 ) {
            $new->{ $path[0] }->{ $path[1] }->{ $el->[1] } = $el->[2];
        }
        elsif ( $#path == 2 ) {
            $new->{ $path[0] }->{ $path[1] }->{ $path[2] }->{ $el->[1] } =
              $el->[2];
        }
        elsif ( $#path == 3 ) {
            $new->{ $path[0] }->{ $path[1] }->{ $path[2] }->{ $path[3] }
              ->{ $el->[1] } = $el->[2];
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
        $self->logger->info("CLI: Remove key $root/$key");
        push @list, [ $root, $key ];
    }
    require Clone;
    my $new = Clone::clone( $self->mgr->hLoadedPlugins->{conf}->currentConf );
    foreach my $el (@list) {
        my @path = split $sep, $el->[0];
        if ( $#path == 0 ) {
            if (   exists $new->{ $path[0] }
                && exists $new->{ $path[0] }->{ $el->[1] } )
            {
                delete $new->{ $path[0] }->{ $el->[1] }
                  if exists $new->{ $path[0] }->{ $el->[1] };
            }
        }
        elsif ( $#path == 1 ) {
            if (   exists $new->{ $path[0] }
                && exists $new->{ $path[0] }->{ $path[1] }
                && exists $new->{ $path[0] }->{ $path[1] }->{ $el->[1] } )
            {
                delete $new->{ $path[0] }->{ $path[1] }->{ $el->[1] };
            }
        }
        elsif ( $#path == 2 ) {
            if (   exists $new->{ $path[0] }
                && exists $new->{ $path[0] }->{ $path[1] }
                && exists $new->{ $path[0] }->{ $path[1] }->{ $path[2] }
                && exists $new->{ $path[0] }->{ $path[1] }->{ $path[2] }
                ->{ $el->[1] } )
            {
                delete $new->{ $path[0] }->{ $path[1] }->{ $path[2] }
                  ->{ $el->[1] };
            }
        }
        elsif ( $#path == 3 ) {
            if (   exists $new->{ $path[0] }
                && exists $new->{ $path[0] }->{ $path[1] }
                && exists $new->{ $path[0] }->{ $path[1] }->{ $path[2] }
                && exists $new->{ $path[0] }->{ $path[1] }->{ $path[2] }
                ->{ $path[3] }
                && exists $new->{ $path[0] }->{ $path[1] }->{ $path[2] }
                ->{ $path[3] }->{ $el->[1] } )
            {
                delete $new->{ $path[0] }->{ $path[1] }->{ $path[2] }
                  ->{ $path[3] }->{ $el->[1] };
            }
        }
        else {
            die $el->[0] . " has too many levels. Aborting";
        }
    }
    return $self->_save($new);
}

sub addPostVars {
    my $self = shift;
    unless ( @_ % 4 == 0 ) {
        die 'usage: "addPostVars (?:vhost uri key value)+';
    }
    my @list;
    while (@_) {
        my $vhost = shift;
        my $uri   = shift;
        my $key   = shift;
        my $value = shift;
        $self->logger->info(
            "CLI: Append post vars $key $value to URI $uri for vhost $vhost");
        push @list, [ $vhost, $uri, $key, $value ];
    }
    require Clone;
    my $new = Clone::clone( $self->mgr->hLoadedPlugins->{conf}->currentConf );
    foreach my $el (@list) {
        $new->{post}->{ $el->[0] }->{ $el->[1] }->{vars} = []
          unless ( defined $new->{post}->{ $el->[0] }->{ $el->[1] }->{vars} );
        push(
            @{ $new->{post}->{ $el->[0] }->{ $el->[1] }->{vars} },
            [ $el->[2], $el->[3] ]
        );
    }
    return $self->_save($new);
}

sub delPostVars {
    my $self = shift;
    unless ( @_ % 3 == 0 ) {
        die 'usage: "delPostVars (?:vhost uri key)+';
    }
    my @list;
    while (@_) {
        my $vhost = shift;
        my $uri   = shift;
        my $key   = shift;
        $self->logger->info(
            "CLI: Delete post vars $key from URI $uri for vhost $vhost");
        push @list, [ $vhost, $uri, $key ];
    }
    require Clone;
    my $new = Clone::clone( $self->mgr->hLoadedPlugins->{conf}->currentConf );
    foreach my $el (@list) {
        $new->{post}->{ $el->[0] }->{ $el->[1] }->{vars} = []
          unless ( defined $new->{post}->{ $el->[0] }->{ $el->[1] }->{vars} );
        for (
            my $i = 0 ;
            $i <= $#{ $new->{post}->{ $el->[0] }->{ $el->[1] }->{vars} } ;
            $i++
          )
        {
            delete( $new->{post}->{ $el->[0] }->{ $el->[1] }->{vars}->[$i] )
              if (
                $new->{post}->{ $el->[0] }->{ $el->[1] }->{vars}->[$i]->[0] eq
                $el->[2] );
        }
    }
    return $self->_save($new);
}

sub lastCfg {
    my ($self) = @_;
    $self->logger->info("CLI: Retrieve last conf.");
    return $self->jsonResponse('/confs/latest')->{cfgNum};
}

sub save {
    my ($self) = @_;
    my $conf   = $self->jsonResponse( '/confs/' . $self->cfgNum, 'full=1' );
    my $json   = JSON->new->indent->canonical;
    print $json->encode($conf);
}

sub restore {
    my ( $self, $file ) = @_;
    unless ($file) {
        die "No file provided. Aborting";
    }
    require IO::String;
    my $conf;
    if ( $file eq '-' ) {
        $conf = join '', <STDIN>;
    }
    else {
        die "Unable to read $file" unless ( -r $file );
        open( my $f, $file ) or die $!;
        $conf = join '', <$f>;
        close $f;
        die "Empty or malformed file $file" unless ( $conf =~ /\w/s );
    }
    $self->logger->info("CLI: Restore conf.");
    my $res = $self->_post( '/confs/raw', '', IO::String->new($conf),
        'application/json', length($conf) );
    use Data::Dumper;
    print STDERR Dumper($res);
}

sub rollback {
    my ($self)      = @_;
    my $lastCfg     = $self->mgr->confAcc->lastCfg;
    my $previousCfg = $lastCfg - 1;
    my $conf =
      $self->mgr->confAcc->getConf( { cfgNum => $previousCfg, raw => 1 } )
      or die $Lemonldap::NG::Common::Conf::msg;

    $conf->{cfgNum}    = $lastCfg;
    $conf->{cfgAuthor} = scalar( getpwuid $< ) . '(command-line-interface)';
    chomp $conf->{cfgAuthor};
    $conf->{cfgAuthorIP} = '127.0.0.1';
    $conf->{cfgDate}     = time;
    $conf->{cfgVersion}  = $Lemonldap::NG::Manager::VERSION;
    $conf->{cfgLog}      = $self->log // "Rolled back configuration $lastCfg";

    my $s = $self->mgr->confAcc->saveConf($conf);
    if ( $s > 0 ) {
        $self->logger->info("CLI: Configuration $lastCfg has been rolled back");
        print STDERR "Configuration $lastCfg has been rolled back\n";
    }
    else {
        $self->logger->error("CLI: Failed to rollback configuration $lastCfg");
        print STDERR "Failed to rollback configuration $lastCfg\n";
    }
}

sub _getKey {
    my ( $self, $key ) = @_;
    my $sep = $self->sep;
    my ( $base, @path ) = split $sep, $key;
    unless ( $base =~ /^\w+$/ ) {
        warn "Malformed key $base";
        return ();
    }
    my $value = $self->mgr->hLoadedPlugins->{conf}
      ->getConfKey( $self->req, $base, noCache => 1 );
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
    my $sep    = $self->sep;
    my (@path) = split $sep, $key;
    my $last   = pop @path;
    while ( my $next = shift @path ) {
        $conf = $conf->{$next};
    }
    $conf->{$last} = $value;
}

sub _save {
    my ( $self, $new ) = @_;
    require Lemonldap::NG::Manager::Conf::Parser;
    my $parser = Lemonldap::NG::Manager::Conf::Parser->new( {
            newConf => $new,
            refConf => $self->mgr->hLoadedPlugins->{conf}->currentConf,
            req     => $self->req
        }
    );
    unless ( $parser->testNewConf( $self->localConf ) ) {
        my $msg = "Configuration rejected with message: " . $parser->message;
        $self->logger->error("CLI: $msg");
        if ( $self->safe ) {
            die "$msg";
        }
        else {
            print STDERR "$msg\n";
        }
    }
    my $saveParams = { force => $self->force };
    if ( $self->force and $self->cfgNum ) {
        $self->logger->debug( "CLI: cfgNum forced with " . $self->cfgNum );
        print STDERR "cfgNum forced with ", $self->cfgNum;
        $saveParams->{cfgNum}      = $self->cfgNum;
        $saveParams->{cfgNumFixed} = 1;
    }
    $new->{cfgAuthor} = scalar( getpwuid $< ) . '(command-line-interface)';
    chomp $new->{cfgAuthor};
    $new->{cfgAuthorIP} = '127.0.0.1';
    $new->{cfgDate}     = time;
    $new->{cfgVersion}  = $Lemonldap::NG::Manager::VERSION;
    $new->{cfgLog}      = $self->log // 'Modified with LL::NG CLI';
    $new->{key} ||= join( '',
        map { chr( int( ord( Crypt::URandom::urandom(1) ) * 94 / 256 ) + 33 ) }
          ( 1 .. 16 ) );

    my $s = $self->mgr->confAcc->saveConf( $new, %$saveParams );
    if ( $s > 0 ) {
        $self->logger->debug(
            "CLI: Configuration $s has been saved by $new->{cfgAuthor}");
        $self->logger->info("CLI: Configuration $s saved");
        print STDERR "Saved under number $s\n";
        $parser->{status} =
          [ $self->mgr->hLoadedPlugins->{conf}->applyConf($new) ];
    }
    else {
        $self->logger->error("CLI: Configuration not saved!");
        printf STDERR "Could not save configuration:";
        printf STDERR $Lemonldap::NG::Common::Conf::msg;
        printf STDERR "Modifications rejected: %s:\n", $parser->{message}
          if $parser->{message};
    }

    # Open "en" lang file to get default messages
    my $langFile = $self->mgr->templateDir . "/languages/en.json";
    $langFile =~ s/templates/static/;
    my $langMessages;
    if ( open my $json, "<", $langFile ) {
        local $/ = undef;
        $langMessages = JSON::from_json(<$json>);
    }

    # Display result
    foreach (qw(errors warnings status)) {
        if ( $parser->{$_} and @{ $parser->{$_} } ) {
            my $s = Dumper( $parser->{$_} );
            $s =~ s/\$VAR1\s*=\s*//;
            $s =~ s/__(\w+)__/$langMessages->{$1}/ if ( defined $langMessages );
            printf STDERR "%-8s: %s", ucfirst($_), $s;
        }
    }
}

sub run {
    my $self = shift;

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
    my $action = shift;
    unless ( $action =~
/^(?:get|set|del|addKey|delKey|addPostVars|delPostVars|merge|save|restore|rollback)$/
      )
    {
        die
"Unknown action $action. Only get, set, del, addKey, delKey, addPostVars, delPostVars, merge, save, restore, rollback allowed";
    }

    unless ( $action eq "restore" ) {

        # This step prevents restoring when config DB is empty (#2340)
        $self->cfgNum( $self->lastCfg ) unless ( $self->cfgNum );
    }

    $self->$action(@_);
}

package Lemonldap::NG::Manager::Cli::Request;

use Mouse;

has cfgNum => ( is => 'rw' );
has error  => ( is => 'rw' );

sub params {
    my ( $self, $key ) = @_;
    return $self->{$key};
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Manager::Cli - Command line manager for Lemonldap::NG web SSO
system.

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

Lemonldap::NG Manager::Cli provides a command line client to read or modify
configuration.

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

=head3 log()

String to insert in configuration log field (cfgLog)

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

=over

=item Original idea from David Delassus in 2012

=item LemonLDAP::NG team L<http://lemonldap-ng.org/team>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/issues>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<https://lemonldap-ng.org/download>

=head1 COPYRIGHT AND LICENSE

See COPYING file for details.

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
