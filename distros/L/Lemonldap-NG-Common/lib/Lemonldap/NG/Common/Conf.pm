##@file
# Base package for Lemonldap::NG configuration system

##@class
# Implements Lemonldap::NG shared configuration system.
# In case of error or warning, the message is stored in the global variable
# $Lemonldap::NG::Common::Conf::msg
package Lemonldap::NG::Common::Conf;

use strict;
use utf8;
no strict 'refs';
use Lemonldap::NG::Common::Conf::Constants;    #inherits

# Import compacter
use Lemonldap::NG::Common::Conf::Compact;
*compactConf = \&Lemonldap::NG::Common::Conf::Compact::compactConf;

# TODO: don't import this big file, use a proxy
use Lemonldap::NG::Common::Conf::DefaultValues;    #inherits
use Lemonldap::NG::Common::Crypto
  ;    #link protected cipher Object "cypher" in configuration hash
use Config::IniFiles;

#inherits Lemonldap::NG::Common::Conf::Backends::File
#inherits Lemonldap::NG::Common::Conf::Backends::DBI
#inherits Lemonldap::NG::Common::Conf::Backends::SOAP
#inherits Lemonldap::NG::Common::Conf::Backends::LDAP

our $VERSION = '2.0.15';
our $msg     = '';
our $iniObj;

our $PlaceHolderRe = '%SERVERENV:(.*?)%';

BEGIN {
    eval {
        require threads::shared;
        threads::shared::share($iniObj);
    };
}

## @cmethod Lemonldap::NG::Common::Conf new(hashRef arg)
# Constructor.
# Succeed if it has found a way to access to Lemonldap::NG configuration with
# $arg (or default file). It can be :
# - Nothing: default configuration file is tested,
# - { confFile => "/path/to/storage.conf" },
# - { Type => "File", dirName => "/path/to/conf/dir/" },
# - { Type => "DBI", dbiChain => "DBI:MariaDB:database=lemonldap-ng;host=1.2.3.4",
# dbiUser => "user", dbiPassword => "password" },
# - { Type => "SOAP", proxy => "https://auth.example.com/config" },
# - { Type => "LDAP", ldapServer => "ldap://localhost", ldapConfBranch => "ou=conf,ou=applications,dc=example,dc=com",
#  ldapBindDN => "cn=manager,dc=example,dc=com", ldapBindPassword => "secret"},
#
# $self->{type} contains the type of configuration access system and the
# corresponding package is loaded.
# @param $arg hash reference or hash table
# @return New Lemonldap::NG::Common::Conf object
sub new {
    my $class = shift;
    my $self  = bless {}, $class;
    if ( ref( $_[0] ) ) {
        %$self = %{ $_[0] };
    }
    else {
        if ( (@_) && $#_ % 2 == 1 ) {
            %$self = @_;
        }
    }
    unless ( $self->{mdone} ) {
        unless ( $self->{type} ) {

            # Use local conf to get configStorage and localStorage
            my $localconf =
              $self->getLocalConf( CONFSECTION, $self->{confFile}, 0 );
            if ( defined $localconf ) {
                %$self = ( %$self, %$localconf );
            }
        }
        unless ( $self->{type} ) {
            $msg .= "Error: configStorage: type is not defined.\n";
            return 0;
        }
        unless ( $self->{type} =~ /^[\w:]+$/ ) {
            $msg .= "Error: configStorage: type is not well formed.\n";
        }
        $self->{type} = "Lemonldap::NG::Common::Conf::Backends::$self->{type}"
          unless $self->{type} =~ /^Lemonldap::/;
        eval "require $self->{type}";
        if ($@) {
            $msg .= "Error: failed to load $self->{type}: \n $@";
            return 0;
        }
        return 0 unless $self->prereq;
        $self->{mdone}++;
        $msg = "$self->{type} loaded.\n";
    }
    if ( $self->{localStorage} and not defined( $self->{refLocalStorage} ) ) {
        eval "use $self->{localStorage};";
        if ($@) {
            $msg .= "Error: Unable to load $self->{localStorage}: $@.\n";
        }

        # TODO: defer that until $> > 0 (to avoid creating local cache with
        # root privileges
        else {
            $self->{refLocalStorage} =
              $self->{localStorage}->new( $self->{localStorageOptions} );
        }
    }

    return $self;
}

## @method int saveConf(hashRef conf, hash args)
# Serialize $conf and call store().
# @param $conf Lemonldap::NG configuration hashRef
# @param %args Parameters
# @return Number of the saved configuration, <=0 in case of error.
sub saveConf {
    my ( $self, $conf, %args ) = @_;

    my $last = $self->lastCfg;

    # If configuration was modified, return an error
    if ( not $args{force} ) {
        return CONFIG_WAS_CHANGED
          if ( $conf->{cfgNum} ne $last
            || $args{cfgDate} && $args{cfgDate} ne $args{currentCfgDate} );
        return DATABASE_LOCKED if ( $self->isLocked() or not $self->lock() );
    }
    $conf->{cfgNum} = $last + 1 unless ( $args{cfgNumFixed} );
    delete $conf->{cipher};

    # Try to store configuration
    my $tmp = $self->store($conf);

    unless ( $tmp > 0 ) {
        $msg .= "Error: Configuration $conf->{cfgNum} not stored.\n";
        $self->unlock();
        return ( $tmp ? $tmp : UNKNOWN_ERROR );
    }

    $msg .= "Configuration $conf->{cfgNum} stored.\n";
    if ( $self->{refLocalStorage} ) {
        $self->setDefault($conf);
        $self->compactConf($conf);
        eval { Lemonldap::NG::Handler::Main->reload() };
    }

    return ( $self->unlock() ? $tmp : UNKNOWN_ERROR );
}

## @method hashRef getConf(hashRef args)
# Get configuration from remote configuration storage system or from local
# cache if configuration has not been changed. If $args->{local} is set and if
# a local configuration is available, remote configuration is not tested.
#
# Uses lastCfg to test and getDBConf() to get the remote configuration
# @param $args Optional, contains {local=>1} or nothing
# @return Lemonldap::NG configuration
sub getConf {
    my ( $self, $args ) = @_;
    my $res;

    # Use only cache to get conf if $args->{local} is set
    if (    $>
        and $args->{local}
        and ref( $self->{refLocalStorage} )
        and $res = $self->{refLocalStorage}->get('conf') )
    {
        $msg .= "Get configuration from cache without verification.\n";
    }

    # Check cfgNum in conf backend
    # Get conf in backend only if a newer configuration is available
    else {
        $args->{cfgNum} ||= $self->lastCfg;
        unless ( $args->{cfgNum} ) {
            $msg .= "Error: No configuration available in backend.\n";
        }
        my $r;
        unless ( ref( $self->{refLocalStorage} ) ) {
            $msg .= "Get remote configuration (localStorage unavailable).\n";
            $r = $self->getDBConf($args);
            return undef unless ( $r->{cfgNum} );
            $self->setDefault( $r, $args->{localPrm} );
            $self->compactConf($r);
        }
        else {
            eval { $r = $self->{refLocalStorage}->get('conf') }
              if ( $> and not $args->{noCache} );
            $msg .= "Warn: $@" if ($@);

            if (    ref($r)
                and $r->{cfgNum}
                and $args->{cfgNum}
                and $r->{cfgNum} == $args->{cfgNum} )
            {
                $msg .=
                  "Configuration unchanged, get configuration from cache.\n";
                $args->{noCache} = 1;
            }
            else {
                my $r2 = $self->getDBConf($args);
                unless ( $r2->{cfgNum} ) {
                    $r = $self->{refLocalStorage}->get('conf') unless ($r);
                    $msg .=
                      $r
                      ? "Error: Using previous cached configuration\n"
                      : "Error: No configuration found in local cache\n";
                    return undef unless ($r);
                }
                else {
                    $r = $r2;
                }

                $self->setDefault( $r, $args->{localPrm} );
                $self->compactConf($r);

                # Store modified configuration in cache
                $self->setLocalConf($r)
                  if ( $self->{refLocalStorage}
                    and not( $args->{noCache} == 1 or $args->{raw} ) );
            }
        }

        # Return configuration hash
        $res = $r;
    }

    # Create cipher object and replace variable placeholder
    unless ( $args->{raw} ) {

        $self->replacePlaceholders($res) if $self->{useServerEnv};
        eval {
            $res->{cipher} = Lemonldap::NG::Common::Crypto->new( $res->{key} );
        };
        if ($@) {
            $msg .= "Bad key: $@. \n";
        }
    }

    return $res;
}

## @method hashRef setDefault(hashRef conf, hashRef localPrm)
# Set default params
# @param $conf Lemonldap::NG configuration hashRef
# @param $localPrm Local parameters
# @return conf
sub setDefault {
    my ( $self, $conf, $localPrm ) = @_;
    if ( defined $localPrm ) {
        $self->{localPrm} = $localPrm;
    }
    else {
        $localPrm = $self->{localPrm};
    }
    my $defaultValues =
      Lemonldap::NG::Common::Conf::DefaultValues->defaultValues();
    if ( $localPrm and %$localPrm ) {
        foreach my $k ( keys %$localPrm ) {
            $conf->{$k} = $localPrm->{$k};
        }
    }
    foreach my $k ( keys %$defaultValues ) {
        $conf->{$k} //= $defaultValues->{$k};
    }

    # Some parameters expect key name (example), not variable ($example)
    if ( defined $conf->{whatToTrace} ) {
        $conf->{whatToTrace} =~ s/^\$//;
    }

    return $conf;
}

## @method hashRef getLocalConf(string section, string file, int loaddefault)
# Get configuration from local file
#
# @param $section Optional section name (default DEFAULTSECTION)
# @param $file Optional file name (default DEFAULTCONFFILE)
# @param $loaddefault Optional load default section parameters (default 1)
# @return Lemonldap::NG configuration
sub getLocalConf {
    my ( $self, $section, $file, $loaddefault ) = @_;
    my $r = {};

    $section ||= DEFAULTSECTION;
    $file ||=
         $self->{confFile}
      || $ENV{LLNG_DEFAULTCONFFILE}
      || DEFAULTCONFFILE;
    $loaddefault = 1 unless ( defined $loaddefault );
    my $cfg;

    # First, search if this file has been parsed
    unless ( $cfg = $iniObj->{$file} ) {

        # If default configuration cannot be read
        # - Error if configuration section is requested
        # - Silent exit for other section requests
        unless ( -r $file ) {
            if ( $section eq CONFSECTION ) {
                $msg .=
                  "Cannot read $file to get configuration access parameters.\n";
                return $r;
            }
            return $r;
        }

        # Parse ini file
        $cfg = Config::IniFiles->new( -file => $file, -allowcontinue => 1 );

        unless ( defined $cfg ) {
            $msg .= "Local config error: "
              . ( join "\n", @Config::IniFiles::errors ) . "\n";
            return $r;
        }

        # Check if default section exists
        unless ( $cfg->SectionExists(DEFAULTSECTION) ) {
            $msg .= "Default section (" . DEFAULTSECTION . ") is missing. \n";
            return $r;
        }

        # Check if configuration section exists
        if ( $section eq CONFSECTION and !$cfg->SectionExists(CONFSECTION) ) {
            $msg .= "Configuration section (" . CONFSECTION . ") is missing.\n";
            return $r;
        }
    }

    # First load all default section parameters
    if ($loaddefault) {
        foreach ( $cfg->Parameters(DEFAULTSECTION) ) {
            $r->{$_} = $cfg->val( DEFAULTSECTION, $_ );
            if ( $_ eq "require" ) {
                eval { require $r->{$_} };
                $msg .= "Error: $@" if ($@);
            }
            if (   $r->{$_} =~ /^[{\[].*[}\]]$/
                || $r->{$_} =~ /^sub\s*{.*}$/ )
            {
                eval "\$r->{$_} = $r->{$_}";
                if ($@) {
                    $msg .= "Warn: error in file $file: $@.\n";
                    return $r;
                }
            }
        }
    }

    # Stop if the requested section is the default section
    return $r if ( $section eq DEFAULTSECTION );

    # Check if requested section exists
    return $r unless $cfg->SectionExists($section);

    # Load section parameters
    foreach ( $cfg->Parameters($section) ) {
        $r->{$_} = $cfg->val( $section, $_ );

        # Remove spaces before and after value (#1488)
        $r->{$_} =~ s/^\s*(.+?)\s*/$1/;
        if ( $r->{$_} =~ /^[{\[].*[}\]]$/ || $r->{$_} =~ /^sub\s*{.*}$/ ) {
            eval "\$r->{$_} = $r->{$_}";
            if ($@) {
                $msg .= "Warn: error in file $file: $@.\n";
                return $r;
            }
        }
    }

    return $r;
}

## @method void setLocalConf(hashRef conf)
# Store $conf in the local cache.
# @param $conf Lemonldap::NG configuration hashRef
sub setLocalConf {
    my ( $self, $conf ) = @_;
    return unless ($>);
    eval { $self->{refLocalStorage}->set( "conf", $conf ) };
    $msg .= "Warn: $@\n" if ($@);
}

## @method hashRef getDBConf(hashRef args)
# Get configuration from remote storage system.
# @param $args hashRef that must contains a key "cfgNum" (number of the wanted
# configuration) and optionaly a key "fields" that points to an array of wanted
# configuration keys
# @return Lemonldap::NG configuration hashRef
sub getDBConf {
    my ( $self, $args ) = @_;
    return undef unless $args->{cfgNum};
    if ( $args->{cfgNum} < 0 ) {
        my @a = $self->available();
        $args->{cfgNum} =
            ( @a + $args->{cfgNum} > 0 )
          ? ( $a[ $#a + $args->{cfgNum} ] )
          : $a[0];
    }
    my $conf = $self->load( $args->{cfgNum} );
    return undef if $conf == "-1";
    $msg .= "Get configuration $conf->{cfgNum}.\n"
      if ( defined $conf->{cfgNum} );
    return $conf;
}

sub _launch {
    my $self = shift;
    my $sub  = shift;
    my @res;
    eval {
        local $SIG{ALRM} = sub { die "TIMEOUT\n" };
        eval {
            alarm( $self->{confTimeout} || 10 );
            @res = &{ $self->{type} . "::$sub" }( $self, @_ );
        };
        alarm 0;
        die $@ if $@;
    };
    if ($@) {
        $msg .= $@;
        print STDERR "MSG $msg\n";
        return undef;
    }
    return wantarray ? (@res) : $res[0];
}

## @method boolean prereq()
# Call prereq() from the $self->{type} package.
# @return True if succeed
sub prereq {
    return shift->_launch( 'prereq', @_ );
}

## @method @ available()
# Call available() from the $self->{type} package.
# @return list of available configuration numbers
sub available {
    return shift->_launch( 'available', @_ );
}

## @method int lastCfg()
# Call lastCfg() from the $self->{type} package.
# @return Number of the last configuration available
sub lastCfg {
    return shift->_launch( 'lastCfg', @_ ) || 0;
}

## @method boolean lock()
# Call lock() from the $self->{type} package.
# @return True if succeed
sub lock {
    return shift->_launch( 'lock', @_ );
}

## @method boolean isLocked()
# Call isLocked() from the $self->{type} package.
# @return True if database is locked
sub isLocked {
    return shift->_launch( 'isLocked', @_ );
}

## @method boolean unlock()
# Call unlock() from the $self->{type} package.
# @return True if succeed
sub unlock {
    return shift->_launch( 'unlock', @_ );
}

## @method int store(hashRef conf)
# Call store() from the $self->{type} package.
# @param $conf Lemondlap configuration serialized
# @return Number of new configuration stored if succeed, 0 else.
sub store {
    return shift->_launch( 'store', @_ );
}

## @method load(int cfgNum, arrayRef fields)
# Call load() from the $self->{type} package.
# @return Lemonldap::NG Configuration hashRef if succeed, 0 else.
sub load {
    return shift->_launch( 'load', @_ );
}

## @method boolean delete(int cfgNum)
# Call delete() from the $self->{type} package.
# @param $cfgNum Number of configuration to delete
# @return True if succeed
sub delete {
    my ( $self, $c ) = @_;
    my @a = $self->available();
    if ( grep( /^$c$/, @a ) ) {
        return $self->_launch( 'delete', $c );
    }
    else {
        return 0;
    }
}

sub logError {
    return shift->_launch( 'logError', @_ );
}

sub _substPlaceHolders {
    return $_[0] unless $_[0];
    $_[0] =~ s/$PlaceHolderRe/$ENV{$1}/geo;
    return $_[0];
}

## @method void replacePlaceholders(res: LLNG_Conf)
#
# Recursively replace %SERVERENV:VariableName% by $ENV{VariableName} value
sub replacePlaceholders {
    my ( $self, $conf ) = @_;
    if ( ref $conf eq 'HASH' ) {
        foreach my $key ( keys %$conf ) {
            if ( $key =~ /$PlaceHolderRe/o ) {
                my $val = $conf->{$key};
                delete $conf->{$key};
                my $nk = _substPlaceHolders($key);
                $conf->{$nk} = $val;
            }
            next unless ( $conf->{$key} );
            if ( ref $conf->{$key} ) {
                $self->replacePlaceholders( $conf->{$key} );
            }
            elsif ( $conf->{$key} =~ /$PlaceHolderRe/o ) {
                $conf->{$key} = _substPlaceHolders( $conf->{$key} );
            }
        }
    }
    elsif ( ref $conf eq 'ARRAY' ) {
        for ( my $i = 0 ; $i < @$conf ; $i++ ) {
            if ( ref $conf->[$i] ) {
                $self->replacePlaceholders( $conf->[$i] );
            }
            elsif ( $conf->[$i] =~ /$PlaceHolderRe/o ) {
                $conf->[$i] = _substPlaceHolders( $conf->[$i] );
            }
        }
    }
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Common::Conf - Perl extension written to manage Lemonldap::NG
Web-SSO configuration.

=head1 SYNOPSIS

  use Lemonldap::NG::Common::Conf;
  # Lemonldap::NG::Common::Conf reads loacl configuration from lemonldap-ng.ini.
  # Parameters can be overridden in a hash:
  my $confAccess = new Lemonldap::NG::Common::Conf(
              {
                  type=>'File',
                  dirName=>"/tmp/",

                  # To use local cache, set :
                  localStorage => "Cache::FileCache",
                  localStorageOptions = {
                      'namespace' => 'lemonldap-ng-config',
                      'default_expires_in' => 600,
                      'directory_umask' => '007',
                      'cache_root' => '/tmp',
                      'cache_depth' => 5,
                  },
              },
    ) or die "Unable to build Lemonldap::NG::Common::Conf, see Apache logs";
  # Next, get global configuration. Note that local parameters override global
  # ones
  my $config = $confAccess->getConf();

=head1 DESCRIPTION

Lemonldap::NG::Common::Conf is used by all Lemonldap::NG packages to access to
local/global configuration.

=head2 SUBROUTINES

=over

=item * B<new> (constructor)

It can takes any Lemonldap::NG parameter to override configuration. The
'confFile' parameter can be used to override lemonldap-ng.ini path.
Examples:

=over

=item * B<Set another lemonldap-ng.ini file>
  $confAccess = new Lemonldap::NG::Common::Conf(
                  { confFile => '/opt/lemonldap-ng.ini' } );
=item * B<Override global storage>:
  $confAccess = new Lemonldap::NG::Common::Conf(
                  {
                    type    => 'File',
                    dirName => '/var/lib/lemonldap-ng/conf',
                   });

=back

=item * B<getConf>: returns a hash reference to the configuration. it takes
a hash reference as first argument containing 2 optional parameters:

=over

=item * C<cfgNum => $number>: the number of the configuration wanted. If this
argument is omitted, the last configuration is returned.

=item * C<fields => [array of names]: the desired fields asked. By default,
getConf returns all (C<select * from lmConfig>).

=back

=item * B<saveConf>: stores the Lemonldap::NG configuration passed in argument
(hash reference). it returns the number of the new configuration.

=back

=head1 SEE ALSO

L<http://lemonldap-ng.org/>

=head1 AUTHORS

=over

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
