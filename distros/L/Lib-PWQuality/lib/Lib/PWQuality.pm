package Lib::PWQuality;
our $AUTHORITY = 'cpan:XSAWYERX';
# ABSTRACT: Perl interface to the libpwquality C library
$Lib::PWQuality::VERSION = '0.001';
## no critic

use strict;
use warnings;
use experimental qw< signatures >;
use Ref::Util qw< is_ref is_hashref >;
use FFI::CheckLib 0.06 qw< find_lib_or_die >;
use FFI::Platypus;
use FFI::C;
use Carp ();

use constant {
   'SETTINGS_INT' => {
        'DIFF_OK'          => undef,
        'MIN_LENGTH'       => undef,
        'DIG_CREDIT'       => undef,
        'UP_CREDIT'        => undef,
        'LOW_CREDIT'       => undef,
        'OTH_CREDIT'       => undef,
        'MIN_CLASS'        => undef,
        'MAX_REPEAT'       => undef,
        'MAX_CLASS_REPEAT' => undef,
        'MAX_SEQUENCE'     => undef,
        'GECOS_CHECK'      => undef,
        'DICT_CHECK'       => undef,
        'USER_CHECK'       => undef,
        'USER_SUBSTR'      => undef,
        'ENFORCING'        => undef,
        'RETRY_TIMES'      => undef,
        'ENFORCE_ROOT'     => undef,
        'LOCAL_USERS'      => undef,
    },

    'SETTINGS_STR' => {
        'BAD_WORDS' => undef,
        'DICT_PATH' => undef,
    },

    'SETTINGS_ALL' => {
        'difok'            => undef,
        'minlen'           => undef,
        'dcredit'          => undef,
        'ucredit'          => undef,
        'lcredit'          => undef,
        'ocredit'          => undef,
        'minclass'         => undef,
        'maxrepeat'        => undef,
        'maxclassrepeat'   => undef,
        'maxsequence'      => undef,
        'gecoscheck'       => undef,
        'dictcheck'        => undef,
        'usercheck'        => undef,
        'usersubstr'       => undef,
        'enforcing'        => undef,
        'badwords'         => undef,
        'dictpath'         => undef,
        'retry'            => undef,
        'enforce_for_root' => undef,
        'local_users_only' => undef,
    },
};

my $ffi = FFI::Platypus->new( 'api' => 1 );
FFI::C->ffi($ffi);

$ffi->lib( find_lib_or_die( 'lib' => 'pwquality' ) );

package Lib::PWQuality::Setting {
our $AUTHORITY = 'cpan:XSAWYERX';

$Lib::PWQuality::Setting::VERSION = '0.001';
FFI::C->enum( 'pwquality_setting' => [
        [ 'DIFF_OK'          =>  1 ],
        [ 'MIN_LENGTH'       =>  3 ],
        [ 'DIG_CREDIT'       =>  4 ],
        [ 'UP_CREDIT'        =>  5 ],
        [ 'LOW_CREDIT'       =>  6 ],
        [ 'OTH_CREDIT'       =>  7 ],
        [ 'MIN_CLASS'        =>  8 ],
        [ 'MAX_REPEAT'       =>  9 ],
        [ 'DICT_PATH'        => 10 ],
        [ 'MAX_CLASS_REPEAT' => 11 ],
        [ 'GECOS_CHECK'      => 12 ],
        [ 'BAD_WORDS'        => 13 ],
        [ 'MAX_SEQUENCE'     => 14 ],
        [ 'DICT_CHECK'       => 15 ],
        [ 'USER_CHECK'       => 16 ],
        [ 'ENFORCING'        => 17 ],
        [ 'RETRY_TIMES'      => 18 ],
        [ 'ENFORCE_ROOT'     => 19 ],
        [ 'LOCAL_USERS'      => 20 ],
        [ 'USER_SUBSTR'      => 21 ],
    ]);
}

package Lib::PWQaulity::Return {
our $AUTHORITY = 'cpan:XSAWYERX';

$Lib::PWQaulity::Return::VERSION = '0.001';
FFI::C->enum( 'pwquality_return' => [
        [ 'SUCCESS'           =>   0 ],
        [ 'FATAL_FAILURE'     =>  -1 ],
        [ 'INTEGER'           =>  -2 ],
        [ 'CFGFILE_OPEN'      =>  -3 ],
        [ 'CFGFILE_MALFORMED' =>  -4 ],
        [ 'UNKNOWN_SETTING'   =>  -5 ],
        [ 'NON_INT_SETTING'   =>  -6 ],
        [ 'NON_STR_SETTING'   =>  -7 ],
        [ 'MEM_ALLOC'         =>  -8 ],
        [ 'TOO_SIMILAR'       =>  -9 ],
        [ 'MIN_DIGITS'        => -10 ],
        [ 'MIN_UPPERS'        => -11 ],
        [ 'MIN_LOWERS'        => -12 ],
        [ 'MIN_OTHERS'        => -13 ],
        [ 'MIN_LENGTH'        => -14 ],
        [ 'PALINDROME'        => -15 ],
        [ 'CASE_CHANGES_ONLY' => -16 ],
        [ 'ROTATED'           => -17 ],
        [ 'MIN_CLASSES'       => -18 ],
        [ 'MAX_CONSECUTIVE'   => -19 ],
        [ 'EMPTY_PASSWORD'    => -20 ],
        [ 'SAME_PASSWORD'     => -21 ],
        [ 'CRACKLIB_CHECK'    => -22 ],
        [ 'RNG'               => -23 ],
        [ 'GENERATION_FAILED' => -24 ],
        [ 'USER_CHECK'        => -25 ],
        [ 'GECOS_CHECK'       => -26 ],
        [ 'MAX_CLASS_REPEAT'  => -27 ],
        [ 'BAD_WORDS'         => -28 ],
        [ 'MAX_SEQUENCE'      => -29 ],
    ]);
}

package Lib::PWQuality::Settings {
our $AUTHORITY = 'cpan:XSAWYERX';

$Lib::PWQuality::Settings::VERSION = '0.001';
use experimental qw< signatures >;

    FFI::C->struct( 'pwquality_settings_t' => [
        'diff_ok'          => 'int',
        'min_length'       => 'int',
        'dig_credit'       => 'int',
        'up_credit'        => 'int',
        'low_credit'       => 'int',
        'oth_credit'       => 'int',
        'min_class'        => 'int',
        'max_repeat'       => 'int',
        'max_class_repeat' => 'int',
        'max_sequence'     => 'int',
        'gecos_check'      => 'int',
        'dict_check'       => 'int',
        'user_check'       => 'int',
        'user_substr'      => 'int',
        'enforcing'        => 'int',
        'retry_times'      => 'int',
        'enforce_for_root' => 'int',
        'local_users_only' => 'int',

        '_bad_words'       => 'opaque',
        '_dict_path'       => 'opaque',
    ]);

    sub bad_words ($self) {
        return $self->{'bad_words'}
           //= $ffi->cast( 'opaque', 'string', $self->_bad_words() );
    }

    sub dict_path ($self) {
        return $self->{'dict_path'}
           //= $ffi->cast( 'opaque', 'string', $self->_dict_path() );
    }
}

$ffi->mangler( sub ($symbol) {
    return "pwquality_$symbol";
});

$ffi->attach(
    [ 'default_settings' => '_default_settings' ], [], 'pwquality_settings_t'
);

$ffi->attach(
    [ 'free_settings' => '_free_settings' ],
    ['pwquality_settings_t'],
    'void',
);

$ffi->attach(
    'read_config' => [ 'pwquality_settings_t', 'string', 'opaque*' ] => 'pwquality_return',
    sub ( $xsub, $self, $filename ) {
        return $xsub->( $self->settings(), $filename, undef );
    },
);

$ffi->attach(
    'set_option' => [ 'pwquality_settings_t', 'string' ] => 'pwquality_return',
    sub ( $xsub, $self, $pair ) {
        my ($name) = split /=/xms, $pair;
        exists SETTINGS_ALL()->{$name}
            or Carp::croak("Unrecognized option: '$name'");

        return $xsub->( $self->settings(), $pair );
    },
);

$ffi->attach(
    'set_int_value',
    [ 'pwquality_settings_t', 'pwquality_setting', 'int' ],
    'pwquality_return',
    sub ( $xsub, $self, $key, $value ) {
        exists SETTINGS_INT()->{$key}
            or Carp::croak("Unrecognized value: '$key'");

        return $xsub->( $self->settings(), $key, $value );
    },
);

$ffi->attach(
    'set_str_value',
    [ 'pwquality_settings_t', 'pwquality_setting', 'string' ],
    'pwquality_return',
    sub ( $xsub, $self, $key, $value ) {
        exists SETTINGS_STR()->{$key}
            or Carp::croak("Unrecognized value: '$key'");

        return $xsub->( $self->settings(), $key, $value );
    },
);

$ffi->attach(
    'get_int_value',
    [ 'pwquality_settings_t', 'pwquality_setting', 'int*' ],
    'pwquality_return',
    sub ( $xsub, $self, $key ) {
        exists SETTINGS_INT()->{$key}
            or Carp::croak("Unrecognized value: '$key'");

        my $value;
        $xsub->( $self->settings(), $key, \$value );
        return $value;
    },
);

$ffi->attach(
    'get_str_value',
    [ 'pwquality_settings_t', 'pwquality_setting', 'string*' ],
    'pwquality_return',
    sub ( $xsub, $self, $key ) {
        exists SETTINGS_STR()->{$key}
            or Carp::croak("Unrecognized value: '$key'");

        my $value;
        $xsub->( $self->settings(), $key, \$value );
        return $value;
    },
);

$ffi->attach(
    'generate' => [ 'pwquality_settings_t', 'int', 'string*' ] => 'pwquality_return',
    sub ( $xsub, $self, $entropy_bits ) {
        my $password;
        $xsub->( $self->settings(), $entropy_bits, \$password );
        return $password;
    },
);

$ffi->attach(
    'check',
    # settings, passwod, oldpassword, user, auxerror
    # oldpassword, user, and auxerror can all be NULL
    [ 'pwquality_settings_t', 'string', 'string', 'string', 'opaque*' ],
    'int',
    sub ( $xsub, $self, @args ) {
        my $auxerror;
        if ( @args > 3 ) {
            Carp::croak('Too many arguments to check()');
        } elsif ( @args == 3 ) {
            push @args, \$auxerror;
        }

        my $result = $xsub->( $self->settings(),@args );

        if ( $result <= 0 ) {
            return {
                'status' => $ffi->cast( 'int', 'pwquality_return', $result ),
                'score'  => -1,
            };
        }

        return {
            'status' => $ffi->cast( 'int', 'pwquality_return', 0 ),
            'score'  => $result,
        };
    },
);

$ffi->attach(
    [ 'strerror' => '_strerror' ],
    [ 'string', 'size_t', 'int', 'opaque' ],
    'string',
);

sub new ( $class, $opts = {} ) {
    my $settings = _default_settings();
    my $self     = bless { 'settings' => $settings }, $class;

    # in case $opts is a configuration filename
    if ( !is_ref($opts) && length $opts ) {
        $self->read_config($opts);
        $opts = {};
    } elsif ( !is_hashref($opts) ) {
        Carp::croak("Incorrect argument to new(): $opts");
    }

    foreach my $opt_name ( keys $opts->%* ) {
        if ( exists SETTINGS_INT()->{$opt_name} ) {
            $self->set_int_value( $opt_name, $opts->{$opt_name} );
        } elsif ( exists SETTINGS_STR()->{$opt_name} ) {
            $self->set_str_value( $opt_name, $opts->{$opt_name} );
        } else {
            Carp::croak("Option not recognized: '$opt_name'");
        }
    }

    return $self;
}

sub set_value ( $self, $key, $value ) {
    if ( exists SETTINGS_INT()->{$key} ) {
        $self->set_int_value( $key, $value );
    } elsif ( exists SETTINGS_STR()->{$key} ) {
        $self->set_str_value( $key, $value );
    } else {
        Carp::croak("Option not recognized: '$key'");
    }
}

sub get_value ( $self, $key ) {
    if ( exists SETTINGS_INT()->{$key} ) {
        $self->get_int_value($key);
    } elsif ( exists SETTINGS_STR()->{$key} ) {
        $self->get_str_value($key);
    } else {
        Carp::croak("Option not recognized: '$key'");
    }
}

sub settings ($self) {
    return $self->{'settings'};
}

sub DESTROY ($self) {
    my $settings = $self->{'settings'}
        or die "Cannot clear instance without settings";

    # FIXME: This fails in tests - not sure when it should be cleaned up
    eval { _free_settings($settings); 1; };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lib::PWQuality - Perl interface to the libpwquality C library

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $pwq = Lib::PWQauality->new({ 'MIN_LENGTH' => 15 });

    # alternatively,
    # my $pwq = Lib::PWQuality->new();
    # $pwq->set_value( 'MIN_LENGTH' => 15 );
    # alternatively, alternatively,
    # $pwq->set_option('minlen=15');
    # alternatively, alternatively, alternatively,
    # my $pwq = Lib::PWQuality->new('/path/to/pwquality.conf');

    # 128 bits of entropy
    my $new_pass = $pwq->generate(128);

    # compare passwords
    my $check_result = $pwq->check( $old_pass, $new_pass );

    if ( $check_result->{'status'} > 0 ) {
        printf "New password score: %d\n",
               $check_result->{'score'};
    } else {
        printf "Failed to create password, error: %s\n",
               $check_result->{'status'};
    }

=head1 DESCRIPTION

This module implements an interface to C<libpwquality> available
L<here|https://github.com/libpwquality/libpwquality/>.

Installing it on Debian and Debian-based distros:

    apt install libpwquality1

I had written it against Debian version 1.4.2-1build1. If you find
differences, please report via GitHub and I'll do my best to handle it.

You probably already have this installed on your system.

=head1 METHODS

=head2 HIGH-LEVEL INTERFACE

The following methods are built for an easier, more convenient interface.
It might not fit strictly within the C<libpwquality> API, but it is built
on top of that API, providing a more Perlish interface.

=head3 C<new($opts)>

    # Create an instance with specific options
    my $pwq = Lib::PWQuality->new({...});

    # Create an instance with a path to a configfile
    my $pwq = Lib::PWQuality->new('/path/to/pwquality.conf');

Creates a new C<Lib::PWQuality> (C<libpwquality>) object.

If you are calling it with a hsahref, the following keys are available:

=over 4

=item * C<DIFF_OK>

=item * C<MIN_LENGTH>

=item * C<DIG_CREDIT>

=item * C<UP_CREDIT>

=item * C<LOW_CREDIT>

=item * C<OTH_CREDIT>

=item * C<MIN_CLASS>

=item * C<MAX_REPEAT>

=item * C<MAX_CLASS_REPEAT>

=item * C<MAX_SEQUENCE>

=item * C<GECOS_CHECK>

=item * C<DICT_CHECK>

=item * C<USER_CHECK>

=item * C<USER_SUBSTR>

=item * C<ENFORCING>

=item * C<RETRY_TIMES>

=item * C<ENFORCE_ROOT>

=item * C<LOCAL_USERS>

=item * C<BAD_WORDS>

=item * C<DICT_PATH>

=back

=head3 C<read_config($filename)>

    my $res = $pwq->read_config($filename);

This reads a configuration file.

Returns a string with values from L<Lib::PWQuality::Return>.

=head3 C<set_value( $key, $value )>

    my $res = $pwq->set_value( 'MIN_LENGTH' => 10 );

This is a high-level version of C<set_int_value> and C<set_str_value>.

Accepts parameter keys as specified under C<new>. Returns a string with values
from L<Lib::PWQuality::Return>.

=head3 C<get_value($key)>

    my $res = $pwq->get_value('MIN_LENGTH');

This method is a simpler form for getting a value. It helps you avoid
the call to C<get_int_value> and C<get_str_value>. It works by understanding
what kind of setting it needs to be and calls the right one.

Accepts parameter keys as specified under C<new>. Returns a string with values
from L<Lib::PWQuality::Return>.

=head3 C<set_option("$key=$val")>

    my $res = $pwq->set_option('minlen=10');

This sets options using a key=value pair. This particular method uses
different naming for the options than the one for integer or string values.

The following options are used:

=over 4

=item * C<difok>

=item * C<minlen>

=item * C<dcredit>

=item * C<ucredit>

=item * C<lcredit>

=item * C<ocredit>

=item * C<minclass>

=item * C<maxrepeat>

=item * C<maxclassrepeat>

=item * C<maxsequence>

=item * C<gecoscheck>

=item * C<dictcheck>

=item * C<usercheck>

=item * C<usersubstr>

=item * C<enforcing>

=item * C<badwords>

=item * C<dictpath>

=item * C<retry>

=item * C<enforce_for_root>

=item * C<local_users_only>

=back

Returns a string with values from L<Lib::PWQuality::Return>.

=head3 C<settings()>

    my $settings = $pwq->settings();
    printf "Minimum length: %d\n", $settings->min_length();

    # alternatively,
    # printf "Minimum length: %d\n", $pwq->get_value('MIN_LENGTH');

Returns the L<Lib::PWQuality::Settings> object.

=head3 C<check(@args)>

    # Checks strength of password
    my $res = $pwq->check( $password );

    # Checks strength of new versus old passwords
    my $res = $pwq->check( $new_password, $old_password );

    # Checks strength of new versus old passwords and uses user-data
    my $res = $pwq->check( $new_password, $old_password, $username );

Returns a hash reference that includes two fields:

    {
        'status' => STRING,
        'score'  => INTEGER,
    }

The C<status> string is a value from L<Lib::PWQuality::Return>.

The C<score> integer includes the score of the password. If you have
an error (such as giving two equivalent passwords), the score will be C<-1>.

=head3 C<generate($int)>

    my $password = $pwq->generate($entropy_bits);

Returns a new password.

=head2 LOW-LEVEL INTERFACE

This is a low-level interface which is far closer to the C<libpwquality>
interface.

=head3 C<get_int_value($key)>

    my $res = $pwq->get_int_value('MIN_LENGTH');

Accepts parameter keys as specified under C<new>. Returns a string with values
from L<Lib::PWQuality::Return>.

See available integer values under C<INTEGER VALUES> below.

Alternatively, see C<get_value>.

=head3 C<get_str_value($key)>

    my $res = $pwq->get_str_value('BAD_WORDS');

Accepts parameter keys as specified under C<new>. Returns a string with values
from L<Lib::PWQuality::Return>.

See available integer values under C<INTEGER VALUES> below.

Alternatively, see C<get_value>.

=head3 C<set_int_value( $key, $val )>

    my $res = $pwq->set_int_value( 'MIN_LENGTH' => 20 );

Accepts parameter keys as specified under C<new>. Returns a string with values
from L<Lib::PWQuality::Return>.

See available integer values under C<INTEGER VALUES> below.

Alternatively, see C<set_value>.

=head3 C<set_str_value( $key, $val )>

    my $res = $pwq->set_str_value( 'BAD_WORDS', 'foo' );

Accepts parameter keys as specified under C<new>. Returns a string with values
from L<Lib::PWQuality::Return>.

See available integer values under C<INTEGER VALUES> below.

Alternatively, see C<set_value>.

=head1 INTEGER VALUES

=over 4

=item * C<DIFF_OK>

=item * C<MIN_LENGTH>

=item * C<DIG_CREDIT>

=item * C<UP_CREDIT>

=item * C<LOW_CREDIT>

=item * C<OTH_CREDIT>

=item * C<MIN_CLASS>

=item * C<MAX_REPEAT>

=item * C<MAX_CLASS_REPEAT>

=item * C<MAX_SEQUENCE>

=item * C<GECOS_CHECK>

=item * C<DICT_CHECK>

=item * C<USER_CHECK>

=item * C<USER_SUBSTR>

=item * C<ENFORCING>

=item * C<RETRY_TIMES>

=item * C<ENFORCE_ROOT>

=item * C<LOCAL_USERS>

=back

=head1 STRING VALUES

=over 4

=item * C<BAD_WORDS>

=item * C<DICT_PATH>

=back

=head1 BENCHMARKS

It's important to take into account that C<libpwquality> is more thorough than most
password generators and password quality checkers. It is meant for user management
quality level.

However, I decided to still benchmark against the following modules:

=over 4

=item * L<Lib::PWQuality>

=item * L<App::Genpass>

=item * L<Crypt::GeneratePassword>

=item * L<Crypt::RandPass>

=item * L<Data::Random>

=item * L<String::MkPasswd>

=back

Ran 10,000 loops of generating passwords of 13 characters length
with as many characters as possible.

  App::Genpass (verify):            Rounded run time: 1.14997e+00 +/- 9.5e-04 (0.1%)
  App::Genpass (noverify):          Rounded run time: 5.2880e-01  +/- 4.5e-04 (0.1%)
  Data::Random:                     Rounded run time: 2.00317e-01 +/- 8.4e-05 (0.0%)
  String::MkPasswd:                 Rounded run time: 1.42260e-01 +/- 7.8e-05 (0.1%)
  Crypt::RandPasswd::chars():       Rounded run time: 7.3406e-02  +/- 5.1e-05 (0.1%)
  Lib::PWQuality:                   Rounded run time: 7.2583e-02  +/- 7.9e-05 (0.1%)
  Crypt::GeneratePassword::chars(): Rounded run time: 6.1873e-02  +/- 3.4e-05 (0.1%)

The fastest module of these is L<Crypt::GeneratePassword>. It is also has no non-core
dependencies. Keep into account that it is not as secure and does not use entropy.

L<Lib::PWQuality> has a few dependencies, including C<libpwquality>. If you're on
GNU/Linux, there's a good chance that C<libpwquality> is already installed. It's
featureful (including using entropy, having dictionary checks, user checks, and
quality scoring - its primary usage). It does not depend on any XS modules.

=head1 TEST COVERAGE

I'll increase these over time.

  ---------------- ------ ------ ------ ------ ------ ------ ------
  File               stmt   bran   cond    sub    pod   time  total
  ---------------- ------ ------ ------ ------ ------ ------ ------
  Lib/PWQuality.pm   81.3   21.4   50.0   93.7  100.0  100.0   74.7
  Total              81.3   21.4   50.0   93.7  100.0  100.0   74.7
  ---------------- ------ ------ ------ ------ ------ ------ ------

=head1 SEE ALSO

=over 4

=item * L<FFI::Platypus>

=item * L<FFI::CheckLib>

=item * L<FFI::C>

=back

=head1 AUTHOR

Sawyer X

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
